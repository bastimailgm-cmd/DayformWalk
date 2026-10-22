import Foundation

struct IslandRegion: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let symbol: String
    let steps: Int
    static let all = [
        IslandRegion(id: "home", name: "Lumibucht", subtitle: "Hier beginnt deine Reise.", symbol: "sun.horizon.fill", steps: 0),
        IslandRegion(id: "forest", name: "Nebelwald", subtitle: "Zwischen Farnen und alten Geschichten.", symbol: "tree.fill", steps: 20_000),
        IslandRegion(id: "coral", name: "Korallenbucht", subtitle: "Salz auf der Haut. Neues am Horizont.", symbol: "water.waves", steps: 60_000),
        IslandRegion(id: "snow", name: "Sternengipfel", subtitle: "Über den Wolken beginnt das Staunen.", symbol: "mountain.2.fill", steps: 120_000)
    ]
}

struct WorldItem: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let cost: Int
    static let all = [
        WorldItem(id: "fern", name: "Wilder Farn", symbol: "leaf.fill", cost: 12),
        WorldItem(id: "flower", name: "Sonnenblume", symbol: "camera.macro", cost: 18),
        WorldItem(id: "tree", name: "Kleiner Baum", symbol: "tree.fill", cost: 25),
        WorldItem(id: "stone", name: "Mondstein", symbol: "diamond.fill", cost: 20),
        WorldItem(id: "lamp", name: "Sternenlaterne", symbol: "lamp.desk.fill", cost: 35),
        WorldItem(id: "bench", name: "Lieblingsbank", symbol: "chair.lounge.fill", cost: 40),
        WorldItem(id: "fire", name: "Lagerfeuer", symbol: "flame.fill", cost: 45),
        WorldItem(id: "path", name: "Wegstein", symbol: "circle.grid.2x2.fill", cost: 8)
    ]
    static func item(_ id: String) -> WorldItem? { all.first { $0.id == id } }
}

struct PlacedItem: Codable, Equatable, Identifiable {
    var id = UUID()
    var kind: String
    var region: String
    var x: Double = 0.5
    var y: Double = 0.55
}

struct IslandBuddy: Identifiable {
    let id: String
    let name: String
    let trait: String
    let symbol: String
    let hatchAt: Int
    static let all = [
        IslandBuddy(id: "lumi", name: "Lumi", trait: "Neugierig. Treu. Immer dabei.", symbol: "leaf.fill", hatchAt: 0),
        IslandBuddy(id: "moss", name: "Moos", trait: "Ein stiller Freund aus dem Nebelwald.", symbol: "tree.fill", hatchAt: 6000),
        IslandBuddy(id: "pearl", name: "Perla", trait: "Sammelt Geschichten aus dem Meer.", symbol: "drop.fill", hatchAt: 16_000),
        IslandBuddy(id: "nova", name: "Nova", trait: "Ein kleiner Funke vom Sternengipfel.", symbol: "sparkles", hatchAt: 35_000)
    ]
}

struct StoryChapter: Identifiable {
    let id: String
    let title: String
    let text: String
    let steps: Int
    let walks: Int
    let gift: String
    static let all = [
        StoryChapter(id: "arrival", title: "01 · Eine Flaschenpost", text: "Am Strand findet Lumi eine Flasche. Darin steckt eine Karte mit einem grünen Stern. Auf der Rückseite steht: Jeder Weg beginnt mit einem kleinen Schritt. Neben der Karte liegt ein Samen. Pflanzt ihr ihn?", steps: 1000, walks: 0, gift: "flower"),
        StoryChapter(id: "trail", title: "02 · Die Spur im Farn", text: "Euer erster Weg führt in den Wald. Zwischen den Farnen blitzt etwas auf: ein Mondstein. Lumi nimmt ihn vorsichtig auf. Für einen Moment leuchten die Blätter und ein verborgener Pfad wird sichtbar.", steps: 6000, walks: 1, gift: "stone"),
        StoryChapter(id: "cave", title: "03 · Hinter dem Wasserfall", text: "Der Pfad endet an einer Höhle. Die Zeichen am Eingang passen zu eurem Stein. Als Lumi ihn in die Wand legt, öffnet sich ein Spalt. Dahinter wartet kein Gold, sondern eine Laterne für alle Wege, die noch kommen.", steps: 15_000, walks: 3, gift: "lamp"),
        StoryChapter(id: "forest", title: "04 · Der schlafende Wald", text: "Im Nebelwald hört ihr ein leises Summen. Moos sitzt auf einer alten Bank und zählt Wolken. Ihr bleibt eine Weile sitzen. Auch eine Pause kann Teil eines Abenteuers sein. Zum Abschied schenkt Moos euch einen Baum.", steps: 30_000, walks: 5, gift: "tree"),
        StoryChapter(id: "sea", title: "05 · Ein Licht am Horizont", text: "Perla zeigt euch ein Licht weit draußen auf dem Meer. Es ist der alte Leuchtturm. Vielleicht könnt ihr ihn mit Freunden wieder zum Leuchten bringen. Heute entzündet ihr erst einmal ein kleines Feuer am Strand.", steps: 60_000, walks: 8, gift: "fire"),
        StoryChapter(id: "sky", title: "06 · Unter einem anderen Himmel", text: "Auf dem Gipfel ist alles still. Nova malt mit einem Lichtschweif eure bisherigen Wege in den Himmel. Ihr erkennt den Strand, die Höhle und die Bank im Wald. Eure Welt ist gewachsen. Und morgen wartet ein neuer Weg.", steps: 120_000, walks: 15, gift: "bench")
    ]
}

struct Expedition: Codable, Equatable {
    var id = UUID()
    var target: Int
    var startedAt: Date
    var baseline: Int
    var finishedAt: Date?
    var rewardClaimed = false
    var baselineByDay: [String: Int]?
    var reward: Int { target / 100 }
    func progress(total: Int, days: [String: Int]? = nil) -> Int {
        if let days, let baselineByDay {
            let start = IslandProgress.key(startedAt)
            let steps = days.filter { $0.key >= start }.reduce(0) { $0 + max(0, $1.value - (baselineByDay[$1.key] ?? 0)) }
            return min(target, steps)
        }
        return min(target, max(0, total - baseline))
    }
}

struct TeamProject: Codable, Equatable {
    var code: String
    var baseline: Int
    var contributions: [String: Int] = [:]
    var claimed = false
    var joinedDay: String?
    var baselineByDay: [String: Int]?
    static let target = 50_000
    var total: Int { contributions.values.reduce(0, +) }
    var isValid: Bool {
        code.count == 8 && code.allSatisfy { "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".contains($0) } &&
        baseline >= 0 && (baselineByDay?.count ?? 0) <= 100_000 && (baselineByDay?.values.allSatisfy { (0...1_000_000).contains($0) } ?? true) && contributions.count <= 20 && contributions.allSatisfy { UUID(uuidString: $0.key) != nil && (0...1_000_000_000).contains($0.value) }
    }
    mutating func merge(_ incoming: [String: Int], localID: String) {
        // A peer cannot overwrite this phone's own contribution.
        for (id, steps) in incoming where id != localID && UUID(uuidString: id) != nil && (0...1_000_000_000).contains(steps) {
            guard contributions[id] != nil || contributions.count < 20 else { continue }
            contributions[id] = max(contributions[id] ?? 0, steps)
        }
    }
}

struct AdventureProgress: Codable, Equatable {
    var version = 1
    var deviceID = UUID().uuidString
    var seenSteps = 0
    var openedFinds = 0
    var inventory: [String: Int] = [:]
    var placed: [PlacedItem] = []
    var region = "home"
    var selectedBuddy = "lumi"
    var buddies: Set<String> = ["lumi"]
    var buddySteps: [String: Int] = ["lumi": 0]
    var chapters: Set<String> = []
    var regionBuildings: [String: [String]] = [:]
    var expedition: Expedition?
    var completedExpeditions = 0
    var team: TeamProject?
    var weather = "clear"
    var recentFind = "Dein Rucksack wartet auf die erste Entdeckung."
    var positions: [String: [Double]] = [:]
    var earnedBadges: Set<String> = []

    var isValid: Bool {
        version == 1 && UUID(uuidString: deviceID) != nil && seenSteps >= 0 && seenSteps <= 100_000_000_000 &&
        openedFinds >= 0 && openedFinds <= 50_000_000 && completedExpeditions >= 0 && completedExpeditions <= 1_000_000 &&
        IslandRegion.all.contains { $0.id == region } && buddies.contains(selectedBuddy) && buddies.contains("lumi") &&
        buddies.isSubset(of: Set(IslandBuddy.all.map(\.id))) && chapters.isSubset(of: Set(StoryChapter.all.map(\.id))) &&
        inventory.count <= 8 && inventory.allSatisfy { WorldItem.item($0.key) != nil && (0...10_000_000).contains($0.value) } &&
        placed.count <= 200 && Set(placed.map(\.id)).count == placed.count && placed.allSatisfy { item in WorldItem.item(item.kind) != nil && IslandRegion.all.contains(where: { $0.id == item.region }) && item.x.isFinite && item.y.isFinite && (0.12...0.88).contains(item.x) && (0.32...0.76).contains(item.y) } &&
        buddySteps.count <= 4 && buddySteps.allSatisfy { buddies.contains($0.key) && (0...100_000_000_000).contains($0.value) } &&
        regionBuildings.count <= 3 && regionBuildings.allSatisfy { entry in IslandRegion.all.contains(where: { $0.id == entry.key && $0.id != "home" }) && entry.value.count <= 5 && entry.value == Array(IslandBuilding.all.map(\.id).prefix(entry.value.count)) } &&
        positions.count <= 220 && positions.values.allSatisfy { $0.count == 2 && $0.allSatisfy(\.isFinite) && (0.12...0.88).contains($0[0]) && (0.32...0.76).contains($0[1]) } &&
        earnedBadges.isSubset(of: ["first", "tenkm", "tenwalks", "hundred", "builder", "explorer"]) &&
        ["clear", "rain", "mist", "snow"].contains(weather) && recentFind.count <= 300 && (team?.isValid ?? true) && expeditionValid
    }
    private var expeditionValid: Bool {
        guard let expedition else { return true }
        return [1000, 3000, 6000].contains(expedition.target) && (expedition.baselineByDay?.count ?? 0) <= 100_000 && (expedition.baselineByDay?.values.allSatisfy { (0...1_000_000).contains($0) } ?? true) && expedition.baseline >= 0 && expedition.baseline <= seenSteps && expedition.startedAt.timeIntervalSince1970.isFinite && (expedition.finishedAt == nil || expedition.finishedAt! >= expedition.startedAt)
    }
    mutating func sync(total: Int, days: [String: Int]? = nil) {
        let delta = max(0, total - seenSteps)
        buddySteps[selectedBuddy, default: 0] += delta
        seenSteps = max(seenSteps, total)
        if var team {
            var contribution = max(0, total - team.baseline)
            if let days, let baseline = team.baselineByDay, let joined = team.joinedDay {
                contribution = days.filter { $0.key >= joined }.reduce(0) { $0 + max(0, $1.value - (baseline[$1.key] ?? 0)) }
            }
            team.contributions[deviceID] = max(team.contributions[deviceID] ?? 0, contribution)
            self.team = team
        }
    }
    func availableFinds(total: Int) -> Int { max(0, total / 2000 - openedFinds) }
    mutating func openFind(total: Int) -> Int? {
        guard availableFinds(total: total) > 0 else { return nil }
        let index = openedFinds
        openedFinds += 1
        if index % 4 == 3 { recentFind = "Eine schimmernde Muschelgruppe: +8 Muscheln."; return 8 }
        let item = WorldItem.all[(index / 4 + index % 4) % WorldItem.all.count]
        inventory[item.id, default: 0] += 1
        recentFind = "Gefunden: \(item.name). Im Inventar kannst du deinen Fund platzieren."
        return 0
    }
    mutating func hatch(_ id: String, total: Int) -> Bool {
        guard let buddy = IslandBuddy.all.first(where: { $0.id == id }), total >= buddy.hatchAt, !buddies.contains(id) else { return false }
        buddies.insert(id); buddySteps[id] = 0; return true
    }
    mutating func claimChapter(_ id: String, total: Int, walks: Int) -> Bool {
        guard let chapter = StoryChapter.all.first(where: { !chapters.contains($0.id) }), chapter.id == id, total >= chapter.steps, walks >= chapter.walks else { return false }
        chapters.insert(id); inventory[chapter.gift, default: 0] += 1; return true
    }
    mutating func startExpedition(target: Int, total: Int, now: Date, days: [String: Int]? = nil) -> Bool {
        guard [1000, 3000, 6000].contains(target), expedition == nil || expedition!.rewardClaimed || expedition!.finishedAt != nil else { return false }
        expedition = Expedition(target: target, startedAt: now, baseline: total, baselineByDay: days); return true
    }
    mutating func claimExpedition(total: Int, now: Date, days: [String: Int]? = nil) -> Int? {
        guard var trip = expedition, trip.finishedAt == nil, !trip.rewardClaimed, trip.progress(total: total, days: days) == trip.target else { return nil }
        trip.rewardClaimed = true; trip.finishedAt = now; expedition = trip; completedExpeditions += 1; return trip.reward
    }
    mutating func place(_ kind: String) -> Bool {
        guard WorldItem.item(kind) != nil, inventory[kind, default: 0] > 0, placed.count < 200 else { return false }
        inventory[kind, default: 0] -= 1
        placed.append(PlacedItem(kind: kind, region: region, x: 0.3 + Double(placed.count % 4) * 0.12, y: 0.45 + Double(placed.count % 3) * 0.08))
        return true
    }
    mutating func remove(_ id: UUID) {
        guard let item = placed.first(where: { $0.id == id }) else { return }
        placed.removeAll { $0.id == id }; inventory[item.kind, default: 0] += 1
    }
}

struct MuseumBadge: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let detail: String
    let current: Int
    let target: Int
    var earned: Bool { current >= target }
    static func all(game: IslandProgress, adventure: AdventureProgress, walks: [Walk]) -> [MuseumBadge] {
        let finished = walks.filter { $0.status == .finished }
        let meters = Int(finished.reduce(0) { $0 + $1.distance })
        return [
            .init(id: "first", title: "Der erste Weg", symbol: "figure.walk", detail: "Einen Spaziergang speichern", current: finished.count, target: 1),
            .init(id: "tenkm", title: "Wege voller Erinnerungen", symbol: "map.fill", detail: "10 GPS-Kilometer sammeln", current: meters, target: 10_000),
            .init(id: "tenwalks", title: "Draußen zu Hause", symbol: "sun.max.fill", detail: "10 Spaziergänge speichern", current: finished.count, target: 10),
            .init(id: "hundred", title: "Hunderttausend kleine Schritte", symbol: "shoeprints.fill", detail: "100.000 Schritte sammeln", current: game.totalSteps, target: 100_000),
            .init(id: "builder", title: "Ein Zuhause geschaffen", symbol: "house.fill", detail: "Alle fünf Orte der Lumibucht bauen", current: game.buildings.count, target: 5),
            .init(id: "explorer", title: "Auf Expedition", symbol: "safari.fill", detail: "Fünf Expeditionen abschließen", current: adventure.completedExpeditions, target: 5)
        ]
    }
}

struct WeeklyStory {
    var steps = 0
    var walks = 0
    var kilometers = 0.0
    var activeDays = 0
    init(days: [DaySteps], walks: [Walk], now: Date, calendar: Calendar = .current) {
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let start = calendar.date(byAdding: .day, value: -7, to: end)!
        let weekDays = days.filter { $0.date >= start && $0.date < end }
        steps = weekDays.reduce(0) { $0 + ($1.steps ?? 0) }
        activeDays = weekDays.filter { ($0.steps ?? 0) > 0 }.count
        let weekWalks = walks.filter { $0.status == .finished && ($0.finishedAt ?? $0.startedAt) >= start && ($0.finishedAt ?? $0.startedAt) < end }
        self.walks = weekWalks.count
        kilometers = weekWalks.reduce(0) { $0 + $1.distance } / 1000
    }
    var text: String { "In den letzten sieben Tagen hast du an \(activeDays) Tagen Bewegung gesammelt: \(steps.formatted()) Schritte und \(walks) gespeicherte Spaziergänge mit \(kilometers.formatted(.number.precision(.fractionLength(1)))) GPS-Kilometern. Hinter jeder Zahl steckt ein kleiner Weg. Schön, dass du ihn gegangen bist." }
}
