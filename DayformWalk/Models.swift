import Foundation

enum WalkStatus: String, Codable { case recording, paused, finished }

struct TrackPoint: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var accuracy: Double
    var timestamp: Date

    func distance(to other: TrackPoint) -> Double {
        let radians = Double.pi / 180
        let dLat = (other.latitude - latitude) * radians
        let dLon = (other.longitude - longitude) * radians
        let value = pow(sin(dLat / 2), 2) + cos(latitude * radians) * cos(other.latitude * radians) * pow(sin(dLon / 2), 2)
        return 6_371_000 * 2 * atan2(sqrt(value), sqrt(max(0, 1 - value)))
    }
    var isValid: Bool {
        latitude.isFinite && longitude.isFinite && accuracy.isFinite &&
        (-90...90).contains(latitude) && (-180...180).contains(longitude) && accuracy >= 0
    }
}

struct RouteSegment: Codable, Identifiable, Equatable {
    var id = UUID()
    var points: [TrackPoint] = []
    var distance: Double { zip(points, points.dropFirst()).reduce(0) { $0 + $1.0.distance(to: $1.1) } }
}

struct WalkingInterval: Codable, Identifiable, Equatable {
    var id = UUID()
    var start: Date
    var end: Date?
    var steps: Int?
    var stepUpdatedAt: Date?
    func duration(at now: Date) -> TimeInterval { max(0, (end ?? now).timeIntervalSince(start)) }
}

struct WalkEvent: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var message: String
}

struct Walk: Codable, Identifiable, Equatable {
    var id = UUID()
    var title = "Mein Spaziergang"
    var startedAt: Date
    var finishedAt: Date?
    var status: WalkStatus = .recording
    var intervals: [WalkingInterval]
    var segments: [RouteSegment] = [RouteSegment()]
    var events: [WalkEvent] = []
    var notes = ""
    var checkpoint: Date

    init(now: Date = Date()) {
        startedAt = now
        intervals = [WalkingInterval(start: now)]
        checkpoint = now
    }
    var distance: Double { segments.reduce(0) { $0 + $1.distance } }
    var points: [TrackPoint] { segments.flatMap(\.points) }
    var knownSteps: Int { intervals.reduce(0) { $0 + ($1.steps ?? 0) } }
    var hasSteps: Bool { intervals.contains { $0.steps != nil } }
    var hasIncompleteSteps: Bool { intervals.contains { $0.steps == nil } }
    func activeDuration(at now: Date = Date()) -> TimeInterval { intervals.reduce(0) { $0 + $1.duration(at: now) } }
    func pace(at now: Date = Date()) -> Double? { distance >= 50 ? activeDuration(at: now) / 60 / (distance / 1000) : nil }
    mutating func pause(at date: Date, reason: String = "Manuell pausiert") {
        guard status == .recording else { return }
        if let index = intervals.indices.last { intervals[index].end = max(date, intervals[index].start) }
        status = .paused
        checkpoint = date
        events.append(WalkEvent(date: date, message: reason))
    }
    mutating func resume(at now: Date = Date()) {
        guard status == .paused else { return }
        intervals.append(WalkingInterval(start: now))
        segments.append(RouteSegment())
        status = .recording
        checkpoint = now
    }
    mutating func finish(at now: Date = Date()) {
        if status == .recording { pause(at: now, reason: "Spaziergang beendet") }
        status = .finished
        finishedAt = now
        checkpoint = now
    }
    var gpx: String {
        func escape(_ value: String) -> String { value.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;").replacingOccurrences(of: "'", with: "&apos;") }
        let formatter = ISO8601DateFormatter()
        let route = segments.filter { !$0.points.isEmpty }.map { segment in
            "<trkseg>" + segment.points.map { p in
                "<trkpt lat=\"\(p.latitude)\" lon=\"\(p.longitude)\">" + (p.altitude.map { "<ele>\($0)</ele>" } ?? "") + "<time>\(formatter.string(from: p.timestamp))</time></trkpt>"
            }.joined() + "</trkseg>"
        }.joined()
        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?><gpx version=\"1.1\" creator=\"Dayform Walk\" xmlns=\"http://www.topografix.com/GPX/1/1\"><trk><name>\(escape(title))</name>\(route)</trk></gpx>"
    }
}

struct DaySteps: Codable, Identifiable, Equatable {
    var date: Date
    var steps: Int?
    var distance: Double?
    var floors: Int?
    var recordedThrough: Date?
    var id: Date { date }
}

struct Preferences: Codable, Equatable {
    var dailyGoal = 8_000
    var name = ""
    var lastBackupAt: Date?
}

struct Archive: Codable {
    var version = 1
    var preferences = Preferences()
    var walks: [Walk] = []
    var days: [DaySteps] = []
    var game: IslandProgress?
    var adventure: AdventureProgress?
    var travel: TravelProgress?

    func validated() throws -> Archive {
        if let game, !game.isValid { throw ValidationError.invalid }
        if let adventure, !adventure.isValid { throw ValidationError.invalid }
        if let travel, !travel.valid { throw ValidationError.invalid }
        guard version == 1, (500...100_000).contains(preferences.dailyGoal), walks.count <= 10_000, Set(walks.map(\.id)).count == walks.count, walks.filter({ $0.status != .finished }).count <= 1 else { throw ValidationError.invalid }
        for walk in walks {
            guard walk.intervals.count <= 10_000, walk.segments.count <= 10_000, walk.points.count <= 200_000, walk.startedAt.timeIntervalSince1970.isFinite else { throw ValidationError.invalid }
            for interval in walk.intervals {
                guard (interval.steps ?? 0) >= 0, interval.duration(at: walk.finishedAt ?? Date()) < 31_536_000, interval.end == nil || interval.end! >= interval.start else { throw ValidationError.invalid }
            }
            guard walk.points.allSatisfy(\.isValid) else { throw ValidationError.invalid }
        }
        guard days.allSatisfy({ ($0.steps ?? 0) >= 0 && ($0.distance ?? 0) >= 0 }) else { throw ValidationError.invalid }
        return self
    }
    enum ValidationError: LocalizedError { case invalid; var errorDescription: String? { "Diese Datei ist kein gültiges Dayform-Walk-Backup." } }
}

struct IslandBuilding: Identifiable {
    let id: String
    let name: String
    let detail: String
    let symbol: String
    let cost: Int
    static let all: [IslandBuilding] = [
        .init(id: "camp", name: "Dein Basislager", detail: "Ein Zuhause für dich und Lumi.", symbol: "tent.fill", cost: 30),
        .init(id: "garden", name: "Wilder Garten", detail: "Ein grüner Rückzugsort am Wasser.", symbol: "leaf.fill", cost: 60),
        .init(id: "bridge", name: "Die kleine Brücke", detail: "Verbinde die beiden Inselufer.", symbol: "point.topleft.down.to.point.bottomright.curvepath", cost: 100),
        .init(id: "cabin", name: "Hütte am Meer", detail: "Dein nächster Lieblingsplatz.", symbol: "house.fill", cost: 150),
        .init(id: "beacon", name: "Sternenwarte", detail: "Ein Licht für neue Abenteuer.", symbol: "sparkles", cost: 220)
    ]
}

struct IslandProgress: Codable, Equatable {
    var stepsByDay: [String: Int] = [:]
    var goalByDay: [String: Int] = [:]
    var claimed: Set<String> = []
    var buildings: [String] = []
    var bonus = 0
    var spent = 0
    static func key(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
    var totalSteps: Int { stepsByDay.values.reduce(0, +) }
    var shells: Int { totalSteps / 100 + bonus - spent }
    var level: Int { 1 + totalSteps / 5000 }
    var levelProgress: Double { Double(totalSteps % 5000) / 5000 }
    var companion: String { level < 3 ? "Kleiner Entdecker" : level < 7 ? "Waldgefährte" : "Inselhüter" }
    var isValid: Bool {
        stepsByDay.count <= 100_000 && goalByDay.count <= 100_000 && claimed.count <= 300_000 &&
        stepsByDay.values.allSatisfy { (0...1_000_000).contains($0) } &&
        goalByDay.values.allSatisfy { (500...100_000).contains($0) } &&
        bonus >= 0 && bonus <= 100_000_000 && spent >= 0 && spent <= 100_000_000 && shells >= 0 &&
        buildings == Array(IslandBuilding.all.map(\.id).prefix(buildings.count)) && buildings.count <= IslandBuilding.all.count
    }
    mutating func sync(days: [DaySteps], goal: Int) {
        for day in days {
            guard let steps = day.steps, (0...1_000_000).contains(steps) else { continue }
            let key = Self.key(day.date)
            stepsByDay[key] = max(stepsByDay[key] ?? 0, steps)
            if goalByDay[key] == nil { goalByDay[key] = goal }
        }
    }
    mutating func build(_ id: String) -> Bool {
        guard buildings.count < IslandBuilding.all.count else { return false }
        let next = IslandBuilding.all[buildings.count]
        guard next.id == id, shells >= next.cost else { return false }
        spent += next.cost
        buildings.append(id)
        return true
    }
    func missions(on date: Date, walks: [Walk]) -> [IslandMission] {
        let key = Self.key(date)
        let steps = stepsByDay[key] ?? 0
        let goal = goalByDay[key] ?? 8000
        let walkCount = walks.filter { $0.status == .finished && Self.key($0.finishedAt ?? $0.startedAt) == key && $0.activeDuration() >= 300 }.count
        return [
            IslandMission(id: key + "/steps", title: "Die erste Spur", detail: "1.000 Schritte sammeln", symbol: "shoeprints.fill", current: steps, target: 1000, reward: 10),
            IslandMission(id: key + "/goal", title: "Dein eigener Rhythmus", detail: "Dein Tagesziel erreichen", symbol: "scope", current: steps, target: goal, reward: 25),
            IslandMission(id: key + "/walk", title: "Frische Luft", detail: "Einen Spaziergang ab 5 Minuten speichern", symbol: "figure.walk", current: walkCount, target: 1, reward: 15)
        ]
    }
    mutating func claim(_ id: String, on date: Date, walks: [Walk]) -> Bool {
        guard !claimed.contains(id), let mission = missions(on: date, walks: walks).first(where: { $0.id == id }), mission.current >= mission.target else { return false }
        bonus += mission.reward
        claimed.insert(id)
        return true
    }
}

struct IslandMission: Identifiable {
    var id: String
    var title: String
    var detail: String
    var symbol: String
    var current: Int
    var target: Int
    var reward: Int
    var progress: Double { min(1, Double(current) / Double(max(1, target))) }
}

struct RouteFilter {
    enum Decision { case rejected, stationary, first, append, gap }
    private(set) var lastAccepted: TrackPoint?
    private(set) var lastFix: Date?
    mutating func reset() { lastAccepted = nil; lastFix = nil }
    mutating func accept(_ point: TrackPoint, now: Date = Date()) -> Decision {
        guard point.isValid, point.accuracy <= 40, abs(now.timeIntervalSince(point.timestamp)) <= 20 else { return .rejected }
        if let lastFix, point.timestamp <= lastFix { return .rejected }
        let gap = lastFix.map { point.timestamp.timeIntervalSince($0) > 60 } ?? false
        lastFix = point.timestamp
        if gap { lastAccepted = point; return .gap }
        guard let last = lastAccepted else { lastAccepted = point; return .first }
        let elapsed = point.timestamp.timeIntervalSince(last.timestamp)
        let distance = last.distance(to: point)
        guard elapsed > 0, distance / elapsed <= 4.5 else { return .rejected }
        let threshold = max(4, min(12, (last.accuracy + point.accuracy) * 0.18))
        guard distance >= threshold else { return .stationary }
        lastAccepted = point
        return .append
    }
}

enum Display {
    static func duration(_ seconds: TimeInterval) -> String {
        let value = max(0, Int(seconds))
        return value >= 3600 ? String(format: "%d:%02d:%02d", value / 3600, (value / 60) % 60, value % 60) : String(format: "%02d:%02d", value / 60, value % 60)
    }
    static func pace(_ value: Double?) -> String {
        guard let value, value.isFinite, value >= 0, value < 1000 else { return "—" }
        let seconds = Int((value * 60).rounded())
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
