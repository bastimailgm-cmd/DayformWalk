import Foundation

struct TravelCoordinate: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var valid: Bool { latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude) }
    func distance(to other: TravelCoordinate) -> Double {
        TrackPoint(latitude: latitude, longitude: longitude, accuracy: 0, timestamp: .distantPast).distance(to: TrackPoint(latitude: other.latitude, longitude: other.longitude, accuracy: 0, timestamp: .distantPast))
    }
}

enum TravelMaterial: String, Codable, CaseIterable, Identifiable {
    case seed, wood, stone, shell
    var id: String { rawValue }
    var name: String { switch self { case .seed: return "Samen"; case .wood: return "Holz"; case .stone: return "Steine"; case .shell: return "Muschelfunde" } }
    var symbol: String { switch self { case .seed: return "leaf.fill"; case .wood: return "tree.fill"; case .stone: return "diamond.fill"; case .shell: return "drop.fill" } }
}

struct TravelPlace: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var coordinate: TravelCoordinate
    var material: TravelMaterial
    var source: String
    var explicitPublicAccess: Bool
    var verifiedAt: Date
    var walkingMeters: Double
    var walkingSeconds: Double
    var valid: Bool { !id.isEmpty && id.count <= 160 && !name.isEmpty && name.count <= 120 && coordinate.valid && ["OpenStreetMap", "Apple Maps", "Vorschau"].contains(source) && walkingMeters.isFinite && (0...20_000).contains(walkingMeters) && walkingSeconds.isFinite && (0...36_000).contains(walkingSeconds) && verifiedAt.timeIntervalSince1970.isFinite }
}

struct TravelLeg: Codable, Equatable {
    var points: [TravelCoordinate]
    var meters: Double
    var seconds: Double
    var valid: Bool { points.count >= 2 && points.count <= 20_000 && points.allSatisfy(\.valid) && meters.isFinite && (0...30_000).contains(meters) && seconds.isFinite && (0...36_000).contains(seconds) }
}

struct TravelPlan: Codable, Equatable, Identifiable {
    var id = UUID()
    var title: String
    var story: String
    var origin: TravelCoordinate
    var stops: [TravelPlace]
    var legs: [TravelLeg]
    var completed: Set<String> = []
    var createdAt: Date
    var minutes: Int
    var ai = false
    var rewardClaimed = false
    var meters: Double { legs.reduce(0) { $0 + $1.meters } }
    var seconds: Double { legs.reduce(0) { $0 + $1.seconds } }
    var valid: Bool {
        title.count <= 120 && story.count <= 900 && origin.valid && [10,20,40].contains(minutes) && (1...3).contains(stops.count) && Set(stops.map(\.id)).count == stops.count && stops.allSatisfy(\.valid) && legs.count == stops.count + 1 && legs.allSatisfy(\.valid) && completed.isSubset(of: Set(stops.map(\.id))) && seconds <= Double(minutes * 60) && createdAt.timeIntervalSince1970.isFinite
    }
}

struct TravelVisit: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var date: Date
    var coordinate: TravelCoordinate
}

struct TravelDelivery: Codable, Equatable {
    var id = UUID()
    var pickup: TravelPlace
    var destination: TravelPlace
    var route: TravelLeg
    var baselineByDay: [String: Int]
    var startedAt: Date
    var delivered = false
    var targetSteps: Int { max(100, min(2000, Int(route.meters * 0.7))) }
    func steps(days: [String: Int]) -> Int {
        let key = IslandProgress.key(startedAt)
        return days.filter { $0.key >= key }.reduce(0) { $0 + max(0, $1.value - (baselineByDay[$1.key] ?? 0)) }
    }
    var valid: Bool { pickup.valid && destination.valid && pickup.id != destination.id && route.valid && baselineByDay.count <= 100_000 && baselineByDay.values.allSatisfy { (0...1_000_000).contains($0) } && startedAt.timeIntervalSince1970.isFinite }
}

struct TravelBlueprint: Identifiable {
    var id: String
    var name: String
    var symbol: String
    var recipe: [TravelMaterial: Int]
    var reward: Int
    static let all = [
        TravelBlueprint(id: "greenhouse", name: "Das Gewächshaus", symbol: "leaf.circle.fill", recipe: [.seed: 6, .wood: 4, .stone: 2], reward: 100),
        TravelBlueprint(id: "harbor", name: "Der kleine Hafen", symbol: "sailboat.fill", recipe: [.wood: 8, .stone: 4, .shell: 6], reward: 150),
        TravelBlueprint(id: "observatory", name: "Das Himmelsatelier", symbol: "moon.stars.fill", recipe: [.stone: 10, .wood: 6, .seed: 4, .shell: 4], reward: 200)
    ]
}

struct TravelProgress: Codable, Equatable {
    var places: [TravelPlace] = []
    var searchCenter: TravelCoordinate?
    var loadedAt: Date?
    var claims: Set<String> = []
    var visits: [String: TravelVisit] = [:]
    var stock: [String: Int] = [:]
    var blocked: Set<String> = []
    var plan: TravelPlan?
    var delivery: TravelDelivery?
    var treasures = 0
    var trails: Set<String> = []
    var crafted: Set<String> = []
    var surpriseClaims: Set<String> = []
    var surpriseID: String?
    var lastReward = "Dein nächstes Abenteuer beginnt in deiner Umgebung."
    var valid: Bool {
        guard places.count <= 30, places.allSatisfy(\.valid), Set(places.map(\.id)).count == places.count, searchCenter?.valid ?? true else { return false }
        guard claims.count <= 200_000, blocked.count <= 10_000, visits.count <= 20_000, stock.count <= 4, stock.allSatisfy({ TravelMaterial(rawValue: $0.key) != nil && (0...10_000_000).contains($0.value) }) else { return false }
        guard visits.allSatisfy({ $0.key == $0.value.id && $0.value.id.count <= 160 && $0.value.name.count <= 120 && $0.value.coordinate.valid && $0.value.date.timeIntervalSince1970.isFinite }), treasures >= 0, treasures <= visits.count / 4 else { return false }
        return trails.isSubset(of: ["moss", "pearl", "nova"]) && crafted.isSubset(of: Set(TravelBlueprint.all.map(\.id))) && surpriseClaims.count <= 100_000 && lastReward.count <= 500 && (plan?.valid ?? true) && (delivery?.valid ?? true)
    }
    static func claimID(place: String, date: Date) -> String { IslandProgress.key(date) + "/" + place }
    func collected(_ place: String, date: Date) -> Bool { claims.contains(Self.claimID(place: place, date: date)) }
    static func arrivalAllowed(place: TravelPlace, location: TravelCoordinate, accuracy: Double, fixDate: Date, now: Date, speed: Double = -1) -> Bool {
        place.valid && location.valid && accuracy.isFinite && (0...35).contains(accuracy) && abs(fixDate.timeIntervalSince(now)) <= 20 && abs(place.verifiedAt.timeIntervalSince(now)) <= 86_400 && location.distance(to: place.coordinate) <= 55 && speed.isFinite && speed <= 4.5
    }
    mutating func checkIn(place: TravelPlace, location: TravelCoordinate, accuracy: Double, fixDate: Date, now: Date, speed: Double = -1) -> Int? {
        guard !blocked.contains(place.id), !collected(place.id, date: now), Self.arrivalAllowed(place: place, location: location, accuracy: accuracy, fixDate: fixDate, now: now, speed: speed) else { return nil }
        claims.insert(Self.claimID(place: place.id, date: now))
        if visits[place.id] == nil { visits[place.id] = TravelVisit(id: place.id, name: place.name, date: now, coordinate: place.coordinate) }
        stock[place.material.rawValue, default: 0] += 2
        var reward = 5
        if plan?.stops.contains(where: { $0.id == place.id }) == true { plan?.completed.insert(place.id) }
        if surpriseID == place.id, surpriseClaims.insert(Self.claimID(place: place.id, date: now)).inserted { reward += 10; surpriseID = nil }
        lastReward = "\(place.name): +2 \(place.material.name), +\(reward) Muscheln und ein Ortsstempel."
        return reward
    }
    mutating func openTreasure() -> Bool {
        guard visits.count / 4 > treasures else { return false }
        treasures += 1
        lastReward = "Schatzkarte \(treasures) vollständig: +60 Muscheln und eine Sternenlaterne!"
        return true
    }
    mutating func craft(_ id: String) -> Int? {
        guard !crafted.contains(id), let blueprint = TravelBlueprint.all.first(where: { $0.id == id }), blueprint.recipe.allSatisfy({ stock[$0.key.rawValue, default: 0] >= $0.value }) else { return nil }
        for (material, count) in blueprint.recipe { stock[material.rawValue, default: 0] -= count }
        crafted.insert(id); return blueprint.reward
    }
    mutating func claimTrail(_ id: String) -> Bool {
        let goals = ["moss": 3, "pearl": 6, "nova": 10]
        guard let count = goals[id], visits.count >= count, !trails.contains(id) else { return false }
        trails.insert(id); return true
    }
    mutating func finishPlan() -> Bool {
        guard var plan, !plan.rewardClaimed, plan.completed.count == plan.stops.count else { return false }
        plan.rewardClaimed = true; self.plan = plan; return true
    }
    mutating func deliver(location: TravelCoordinate, accuracy: Double, fixDate: Date, now: Date, speed: Double, days: [String: Int]) -> Bool {
        guard var delivery, !delivery.delivered, delivery.steps(days: days) >= delivery.targetSteps,
              Self.arrivalAllowed(place: delivery.destination, location: location, accuracy: accuracy, fixDate: fixDate, now: now, speed: speed) else { return false }
        delivery.delivered = true; self.delivery = delivery; return true
    }
    mutating func block(_ id: String) {
        blocked.insert(id); places.removeAll { $0.id == id }
        if plan?.stops.contains(where: { $0.id == id }) == true { plan = nil }
        if delivery?.pickup.id == id || delivery?.destination.id == id { delivery = nil }
        if surpriseID == id { surpriseID = nil }
    }
}

struct TravelAIStory: Codable, Equatable {
    var title: String
    var story: String
    var stopIDs: [String]
    func validated(allowed: Set<String>) throws -> TravelAIStory {
        guard !title.isEmpty, title.count <= 100, !story.isEmpty, story.count <= 800, (1...3).contains(stopIDs.count), Set(stopIDs).count == stopIDs.count, Set(stopIDs).isSubset(of: allowed) else { throw TravelError.invalidAI }
        return self
    }
}

enum TravelError: LocalizedError {
    case invalidAI, noRoute, noPlaces, budget, noKey, network, http(Int)
    var errorDescription: String? {
        switch self {
        case .invalidAI: return "Die KI-Antwort enthält keine gültige Auswahl. Es wurden keine erfundenen Ziele übernommen."
        case .noRoute: return "Für dieses Ziel konnte keine passende Fußroute bestätigt werden."
        case .noPlaces: return "Hier wurden keine geeigneten Ziele mit verfügbarer Fußroute gefunden. Versuche einen anderen öffentlichen Startpunkt oder mehr Gehzeit."
        case .budget: return "Keine Runde passt in die gewählte Gehzeit. Wähle mehr Zeit oder einen anderen öffentlichen Startpunkt."
        case .noKey: return "Speichere zuerst deinen neuen Groq-API-Key im Schlüsselbund. Lokale Runden funktionieren ohne KI."
        case .network: return "Der Dienst ist gerade nicht erreichbar. Bitte versuche es später erneut."
        case .http(let status): return status == 401 ? "Groq lehnt den API-Key ab. Bitte ersetze ihn in den KI-Einstellungen." : status == 429 ? "Das Groq-Limit ist erreicht. Lokale Runden bleiben verfügbar." : "Die KI-Anfrage ist fehlgeschlagen (HTTP \(status))."
        }
    }
}
