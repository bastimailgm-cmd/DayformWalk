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

    func validated() throws -> Archive {
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
