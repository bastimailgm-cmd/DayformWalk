import Foundation
import Combine
import CoreLocation
import CoreMotion
import UIKit

@MainActor
final class WalkModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var archive = Archive()
    @Published private(set) var todaySteps: Int?
    @Published private(set) var todayDistance: Double?
    @Published private(set) var todayFloors: Int?
    @Published private(set) var motionAuthorized = false
    @Published private(set) var locationAuthorized = false
    @Published private(set) var gpsAccuracy: Double?
    @Published private(set) var gpsStatus = "GPS ist aus"
    @Published private(set) var motionStatus = "Schrittzugriff noch nicht aktiviert"
    @Published private(set) var storageHealthy = true
    @Published private(set) var now = Date()
    @Published var errorMessage: String?
    @Published var selectedTab = 0
    private let manager = CLLocationManager()
    private let dayPedometer = CMPedometer()
    private let walkPedometer = CMPedometer()
    private var queries: [UUID: CMPedometer] = [:]
    private var persistence: Persistence?
    private var timer: AnyCancellable?
    private var routeFilter = RouteFilter()
    private var backgroundSession: CLBackgroundActivitySession?
    private var pendingStart = false
    private var recoveredWalkID: UUID?
    private var lastDay = Calendar.current.startOfDay(for: Date())
    private var secondsSinceSave = 0

    var activeWalk: Walk? { archive.walks.first { $0.status != .finished } }
    var completedWalks: [Walk] { archive.walks.filter { $0.status == .finished }.sorted { $0.startedAt > $1.startedAt } }
    var preferences: Preferences { archive.preferences }
    var stepCountingAvailable: Bool { CMPedometer.isStepCountingAvailable() }

    override init() {
        super.init()
        do {
            let store = try Persistence()
            persistence = store
            archive = try store.load()
            if let index = archive.walks.firstIndex(where: { $0.status == .recording }) {
                let stop = max(archive.walks[index].checkpoint, archive.walks[index].intervals.last?.start ?? archive.walks[index].startedAt)
                archive.walks[index].pause(at: stop, reason: "App neu gestartet: Aufzeichnung am letzten gesicherten Zeitpunkt pausiert. Fehlender Weg wurde nicht ergänzt.")
                recoveredWalkID = archive.walks[index].id
                try store.save(archive)
            }
        } catch {
            storageHealthy = false
            errorMessage = "Deine lokalen Daten konnten nicht geladen werden. Sie werden nicht überschrieben. \(error.localizedDescription)"
        }
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
        updateAuthorizationFlags()
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] date in
            guard let self else { return }
            self.now = date
            let day = Calendar.current.startOfDay(for: date)
            if day != self.lastDay { self.lastDay = day; self.refreshMotion() }
            self.secondsSinceSave += 1
            if self.secondsSinceSave >= 10, self.activeWalk?.status == .recording {
                self.secondsSinceSave = 0
                self.checkpoint()
            }
        }
        if motionAuthorized { refreshMotion() }
    }

    func becameActive() {
        updateAuthorizationFlags()
        if motionAuthorized {
            refreshMotion()
            if activeWalk?.status == .recording { beginWalkPedometer() }
            if let id = recoveredWalkID, let walk = archive.walks.first(where: { $0.id == id }), let interval = walk.intervals.last, let end = interval.end {
                queryInterval(walkID: id, intervalID: interval.id, start: interval.start, end: end)
                recoveredWalkID = nil
            }
        }
        if !locationAuthorized, activeWalk?.status == .recording { pauseWalk(reason: "Standortfreigabe wurde entzogen") }
    }

    func becameInactive() { checkpoint() }

    private func updateAuthorizationFlags() {
        motionAuthorized = CMPedometer.authorizationStatus() == .authorized
        locationAuthorized = [.authorizedAlways, .authorizedWhenInUse].contains(manager.authorizationStatus)
        if !stepCountingAvailable { motionStatus = "Dieses Gerät bietet keinen Apple-Schrittzähler." }
        else if CMPedometer.authorizationStatus() == .denied || CMPedometer.authorizationStatus() == .restricted { motionStatus = "Bewegung & Fitness ist nicht freigegeben." }
        else if motionAuthorized { motionStatus = "Apple-Schrittzähler · iPhone" }
    }

    func enableMotion() {
        guard stepCountingAvailable else { errorMessage = "Auf diesem Gerät ist kein Schrittzähler verfügbar. Auf einem echten iPhone testen."; return }
        if CMPedometer.authorizationStatus() == .denied || CMPedometer.authorizationStatus() == .restricted {
            errorMessage = "Aktiviere Bewegung & Fitness für Dayform Walk in den iPhone-Einstellungen."
            return
        }
        let start = Calendar.current.startOfDay(for: Date())
        dayPedometer.queryPedometerData(from: start, to: Date()) { [weak self] data, error in
            Task { @MainActor in
                guard let self else { return }
                self.updateAuthorizationFlags()
                if let error { self.motionStatus = "Schrittdaten nicht verfügbar"; self.errorMessage = error.localizedDescription; return }
                if let data { self.applyDay(data, date: start) }
                self.refreshMotion()
                if self.activeWalk?.status == .recording { self.beginWalkPedometer() }
            }
        }
    }

    func refreshMotion() {
        guard stepCountingAvailable, CMPedometer.authorizationStatus() == .authorized else { return }
        motionAuthorized = true
        motionStatus = "Apple-Schrittzähler · iPhone"
        let start = Calendar.current.startOfDay(for: Date())
        dayPedometer.stopUpdates()
        dayPedometer.startUpdates(from: start) { [weak self] data, error in
            Task { @MainActor in
                guard let self else { return }
                if let data { self.applyDay(data, date: start) }
                if let error { self.motionStatus = "Schrittdaten verzögert: \(error.localizedDescription)" }
            }
        }
        let calendar = Calendar.current
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: start), let next = calendar.date(byAdding: .day, value: 1, to: day) else { continue }
            let end = min(next, Date())
            guard end > day else { continue }
            query(from: day, to: end) { [weak self] data, _ in
                guard let self, let data else { return }
                self.applyDay(data, date: day)
            }
        }
    }

    private func applyDay(_ data: CMPedometerData, date: Date) {
        if let existing = archive.days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }), let recordedThrough = existing.recordedThrough, recordedThrough > data.endDate { return }
        let day = DaySteps(date: date, steps: data.numberOfSteps.intValue, distance: data.distance?.doubleValue, floors: data.floorsAscended?.intValue, recordedThrough: data.endDate)
        if let index = archive.days.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) { archive.days[index] = day }
        else { archive.days.append(day) }
        if Calendar.current.isDateInToday(date) {
            todaySteps = day.steps
            todayDistance = day.distance
            todayFloors = day.floors
        }
        save()
    }

    private func query(from start: Date, to end: Date, completion: @escaping @MainActor (CMPedometerData?, Error?) -> Void) {
        guard end > start else { return }
        let id = UUID()
        let pedometer = CMPedometer()
        queries[id] = pedometer
        pedometer.queryPedometerData(from: start, to: end) { [weak self] data, error in
            Task { @MainActor in
                self?.queries.removeValue(forKey: id)
                completion(data, error)
            }
        }
    }

    func requestStart() {
        guard storageHealthy else { errorMessage = "Bitte sichere oder repariere zuerst deinen lokalen Datenspeicher."; return }
        guard CLLocationManager.locationServicesEnabled() else { errorMessage = "Aktiviere die Ortungsdienste deines iPhones, damit die Route aufgezeichnet werden kann."; return }
        switch manager.authorizationStatus {
        case .notDetermined: pendingStart = true; manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: startOrResume()
        default: errorMessage = "Erlaube Dayform Walk den genauen Standort in den iPhone-Einstellungen."
        }
    }

    private func startOrResume() {
        guard activeWalk?.status != .recording else { selectedTab = 1; return }
        routeFilter.reset()
        if let id = activeWalk?.id, let index = archive.walks.firstIndex(where: { $0.id == id }) { archive.walks[index].resume() }
        else { archive.walks.insert(Walk(), at: 0) }
        selectedTab = 1
        checkpoint()
        manager.allowsBackgroundLocationUpdates = true
        backgroundSession = CLBackgroundActivitySession()
        manager.startUpdatingLocation()
        gpsStatus = "GPS wird gesucht …"
        gpsAccuracy = nil
        if motionAuthorized { beginWalkPedometer() }
    }

    private func beginWalkPedometer() {
        guard let walk = activeWalk, walk.status == .recording, let interval = walk.intervals.last else { return }
        let walkID = walk.id, intervalID = interval.id
        walkPedometer.stopUpdates()
        walkPedometer.startUpdates(from: interval.start) { [weak self] data, error in
            Task { @MainActor in
                guard let self else { return }
                if let data { self.applyInterval(data, walkID: walkID, intervalID: intervalID) }
                else if error != nil { self.motionStatus = "Spaziergang-Schritte werden beim Aktualisieren erneut abgefragt." }
            }
        }
    }

    private func applyInterval(_ data: CMPedometerData, walkID: UUID, intervalID: UUID) {
        guard let index = archive.walks.firstIndex(where: { $0.id == walkID }), let part = archive.walks[index].intervals.firstIndex(where: { $0.id == intervalID }) else { return }
        // A late live callback must never extend a closed interval past its end.
        if let end = archive.walks[index].intervals[part].end, data.endDate > end.addingTimeInterval(0.1) { return }
        archive.walks[index].intervals[part].steps = max(0, data.numberOfSteps.intValue)
        archive.walks[index].intervals[part].stepUpdatedAt = Date()
        save()
    }

    private func queryInterval(walkID: UUID, intervalID: UUID, start: Date, end: Date) {
        guard motionAuthorized, end > start else { return }
        query(from: start, to: end) { [weak self] data, error in
            if let data { self?.applyInterval(data, walkID: walkID, intervalID: intervalID) }
            else if error != nil { self?.motionStatus = "Schritte für ein Intervall konnten nicht nachgeladen werden." }
        }
    }

    func pauseWalk(reason: String = "Manuell pausiert") {
        guard let id = activeWalk?.id, let index = archive.walks.firstIndex(where: { $0.id == id }), archive.walks[index].status == .recording else { return }
        let end = Date()
        walkPedometer.stopUpdates()
        archive.walks[index].pause(at: end, reason: reason)
        stopLocation()
        save()
        if let interval = archive.walks[index].intervals.last { queryInterval(walkID: id, intervalID: interval.id, start: interval.start, end: end) }
    }

    func finishWalk() -> UUID? {
        guard let id = activeWalk?.id else { return nil }
        if activeWalk?.status == .recording { pauseWalk(reason: "Spaziergang beendet") }
        guard let index = archive.walks.firstIndex(where: { $0.id == id }) else { return nil }
        archive.walks[index].finish()
        save()
        if let interval = archive.walks[index].intervals.last, let end = interval.end { queryInterval(walkID: id, intervalID: interval.id, start: interval.start, end: end) }
        refreshMotion()
        return id
    }

    private func stopLocation() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        backgroundSession?.invalidate()
        backgroundSession = nil
        gpsStatus = "GPS ist aus"
        gpsAccuracy = nil
        routeFilter.reset()
    }

    private func handleLocations(_ locations: [CLLocation]) {
        guard let id = activeWalk?.id, let index = archive.walks.firstIndex(where: { $0.id == id }), archive.walks[index].status == .recording else { return }
        for location in locations.sorted(by: { $0.timestamp < $1.timestamp }) {
            let point = TrackPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.verticalAccuracy >= 0 ? location.altitude : nil, accuracy: location.horizontalAccuracy, timestamp: location.timestamp)
            let decision = routeFilter.accept(point)
            if location.horizontalAccuracy >= 0 { gpsAccuracy = location.horizontalAccuracy }
            switch decision {
            case .first, .append:
                if archive.walks[index].segments.isEmpty { archive.walks[index].segments.append(RouteSegment()) }
                archive.walks[index].segments[archive.walks[index].segments.count - 1].points.append(point)
                gpsStatus = "GPS zeichnet auf"
            case .gap:
                archive.walks[index].segments.append(RouteSegment(points: [point]))
                archive.walks[index].events.append(WalkEvent(date: point.timestamp, message: "GPS-Unterbrechung über 60 Sekunden. Zwischen den Abschnitten wurde keine Strecke ergänzt."))
                gpsStatus = "GPS zeichnet wieder auf"
            case .stationary: gpsStatus = "GPS aktiv · kaum Bewegung"
            case .rejected: gpsStatus = "GPS-Signal prüfen · ungenauer Punkt verworfen"
            }
        }
        archive.walks[index].checkpoint = Date()
        save()
    }

    private func checkpoint() {
        if let id = activeWalk?.id, let index = archive.walks.firstIndex(where: { $0.id == id }), archive.walks[index].status == .recording { archive.walks[index].checkpoint = Date() }
        save()
    }

    private func save() {
        guard storageHealthy, let persistence else { return }
        do { try persistence.save(archive) }
        catch { storageHealthy = false; errorMessage = "Speichern fehlgeschlagen. Bitte erstelle ein Backup. \(error.localizedDescription)" }
    }

    func updatePreferences(name: String, goal: Int) {
        archive.preferences.name = String(name.prefix(40))
        archive.preferences.dailyGoal = min(100_000, max(500, goal))
        save()
    }

    func updateWalk(id: UUID, title: String, notes: String) {
        guard let index = archive.walks.firstIndex(where: { $0.id == id }) else { return }
        archive.walks[index].title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Mein Spaziergang" : String(title.prefix(100))
        archive.walks[index].notes = String(notes.prefix(5000))
        save()
    }

    func removeWalk(id: UUID) {
        guard activeWalk?.id != id else { return }
        archive.walks.removeAll { $0.id == id }
        save()
    }

    func backup() throws -> Data { try Persistence.encode(archive) }
    func restore(_ data: Data) throws {
        guard activeWalk == nil else { throw UserError.finishFirst }
        var restored = try Persistence.decode(data)
        for index in restored.walks.indices where restored.walks[index].status == .recording { restored.walks[index].pause(at: restored.walks[index].checkpoint, reason: "Aus Backup wiederhergestellt") }
        guard let persistence else { throw UserError.storageUnavailable }
        try persistence.save(restored)
        archive = restored
        storageHealthy = true
        becameActive()
    }

    func retryStepQuery(walk: Walk) {
        guard motionAuthorized else { enableMotion(); return }
        for interval in walk.intervals {
            guard let end = interval.end else { continue }
            queryInterval(walkID: walk.id, intervalID: interval.id, start: interval.start, end: end)
        }
    }

    enum UserError: LocalizedError {
        case finishFirst, storageUnavailable
        var errorDescription: String? { switch self { case .finishFirst: return "Beende zuerst deinen laufenden Spaziergang."; case .storageUnavailable: return "Der lokale Speicher ist nicht verfügbar." } }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.updateAuthorizationFlags()
            if self.pendingStart {
                self.pendingStart = false
                if self.locationAuthorized { self.startOrResume() }
            }
            if !self.locationAuthorized, self.activeWalk?.status == .recording { self.pauseWalk(reason: "Standortfreigabe wurde entzogen") }
        }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in self?.handleLocations(locations) }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.gpsStatus = "GPS-Unterbrechung"
            if let error = error as? CLError, error.code == .denied { self.pauseWalk(reason: "Standortzugriff verweigert"); self.errorMessage = "Bitte prüfe die Standortfreigabe in den Einstellungen." }
        }
    }
}
