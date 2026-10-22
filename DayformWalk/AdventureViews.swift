import SwiftUI

struct AdventureActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 11)
            .foregroundStyle(Color.walkPaper)
            .background(Color.walkGreen.gradient, in: RoundedRectangle(cornerRadius: 12))
            .opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
    }
}

struct AdventureEntryView: View {
    var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--backpack") { BackpackView() }
        else if ProcessInfo.processInfo.arguments.contains("--editor") { IslandEditorView() }
        else { AdventureHomeView() }
        #else
        AdventureHomeView()
        #endif
    }
}

struct AdventureHomeView: View {
    @EnvironmentObject var model: WalkModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 7) { Eyebrow(text: "Ein Schritt. Eine neue Geschichte."); Text("Deine Welt lebt.").font(.system(size: 32, weight: .bold, design: .rounded)) }
                    Spacer(minLength: 2)
                    Label(model.island.shells.formatted(), systemImage: "sparkle").font(.headline).foregroundStyle(Color.walkLime)
                }
                LivingIslandView(editing: false)
                HStack {
                    NavigationLink { IslandEditorView() } label: { Label("Gestalten", systemImage: "paintbrush.pointed.fill").frame(maxWidth: .infinity) }.buttonStyle(AdventureActionStyle())
                    NavigationLink { RegionView() } label: { Label("Reisen", systemImage: "map.fill").frame(maxWidth: .infinity) }.buttonStyle(.bordered)
                }
                Panel {
                    HStack(spacing: 18) {
                        BuddyPortrait(id: model.buddy.id, level: model.buddyLevel).frame(width: 74, height: 90)
                        VStack(alignment: .leading, spacing: 8) {
                            Eyebrow(text: "Gemeinsam unterwegs")
                            Text("\(model.buddy.name) · Level \(model.buddyLevel)").font(.title3.bold())
                            Text(buddyActivity).font(.caption).foregroundStyle(.secondary)
                            ProgressView(value: Double((model.adventure.buddySteps[model.buddy.id] ?? 0) % 5000) / 5000).tint(.walkGreen)
                        }
                    }
                }
                NavigationLink { BackpackView() } label: {
                    Panel {
                        HStack { Image(systemName: "backpack.fill").font(.title).foregroundStyle(Color.walkLime); VStack(alignment: .leading, spacing: 6) { Text("Dein Entdeckungsrucksack").font(.headline); Text("\(model.adventure.availableFinds(total: model.island.totalSteps)) Fundstücke warten auf dich").font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right") }
                    }
                }.buttonStyle(.plain)
                if let trip = model.adventure.expedition, trip.finishedAt == nil { ExpeditionStatus(trip: trip) }
                Text("Worauf hast du heute Lust?").font(.title3.bold())
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    NavigationLink { ExpeditionView() } label: { AdventureTile(title: "Expeditionen", subtitle: "Dein nächstes Ziel", symbol: "safari.fill") }
                    NavigationLink { BuddyCollectionView() } label: { AdventureTile(title: "Begleiter", subtitle: "Freunde fürs Leben", symbol: "pawprint.fill") }
                    NavigationLink { StorybookView() } label: { AdventureTile(title: "Geschichten", subtitle: "\(model.adventure.chapters.count)/6 Kapitel entdeckt", symbol: "book.closed.fill") }
                    NavigationLink { MuseumView() } label: { AdventureTile(title: "Museum", subtitle: "Deine Erinnerungen", symbol: "building.columns.fill") }
                    NavigationLink { TeamView() } label: { AdventureTile(title: "Mit Freunden", subtitle: "Ein Licht für alle", symbol: "person.2.fill") }
                    NavigationLink { WeeklyStoryView() } label: { AdventureTile(title: "Deine Woche", subtitle: "Kleine Wege, große Welt", symbol: "text.book.closed.fill") }
                }.buttonStyle(.plain)
                Text("Missionen für heute").font(.title3.bold())
                ForEach(model.missions) { MissionCard(mission: $0) }
            }.padding(22)
        }.background { OceanBackdrop() }.navigationTitle("Dein Abenteuer").navigationBarTitleDisplayMode(.inline)
    }
    private var buddyActivity: String {
        let hour = Calendar.current.component(.hour, from: model.now)
        if hour < 6 || hour >= 22 { return "Schläft unter den Sternen. Morgen wartet ein neuer Weg." }
        if model.activeWalk?.status == .recording { return "Erkundet mit dir neue Wege." }
        return model.adventure.placed.contains(where: { $0.region == model.adventure.region && $0.kind == "fire" }) ? "Macht es sich am Lagerfeuer gemütlich." : "Genießt eine kleine Pause auf der Insel."
    }
}

struct AdventureTile: View {
    let title: String
    let subtitle: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { Image(systemName: symbol).font(.title2).foregroundStyle(Color.walkGreen); Text(title).font(.subheadline.bold()); Text(subtitle).font(.caption2).foregroundStyle(.secondary) }
            .frame(maxWidth: .infinity, minHeight: 106, alignment: .leading).padding(16).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 21)).overlay { RoundedRectangle(cornerRadius: 21).stroke(.white.opacity(0.1)) }
    }
}

struct BuddyPortrait: View {
    var id: String
    var level: Int
    private var color: Color { id == "moss" ? .green : id == "pearl" ? .cyan : id == "nova" ? .purple : .walkGreen }
    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.15)).frame(width: 60, height: 12).offset(y: 33)
            RoundedRectangle(cornerRadius: id == "moss" ? 20 : 30).fill(LinearGradient(colors: [.white, color.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 59, height: 63)
            HStack(spacing: 13) { Capsule().frame(width: 5, height: 9); Capsule().frame(width: 5, height: 9) }.foregroundStyle(Color.walkPaper)
            Capsule().fill(Color.walkPaper).frame(width: 8, height: 3).offset(y: 12)
            HStack(spacing: 28) { Circle(); Circle() }.foregroundStyle(.pink.opacity(0.3)).frame(width: 43, height: 7).offset(y: 8)
            Image(systemName: IslandBuddy.all.first(where: { $0.id == id })?.symbol ?? "leaf.fill").font(.system(size: level >= 7 ? 28 : 22)).foregroundStyle(color).offset(x: 7, y: -36)
            if level >= 3 { Image(systemName: level >= 7 ? "crown.fill" : "star.fill").font(.system(size: 12)).foregroundStyle(Color.walkLime).offset(x: -21, y: -21) }
        }.accessibilityLabel("\(IslandBuddy.all.first(where: { $0.id == id })?.name ?? "Lumi"), Level \(level)")
    }
}

struct SceneObject: Identifiable {
    var id: String
    var symbol: String
    var color: Color
    var x: Double
    var y: Double
}

struct LivingIslandView: View {
    @EnvironmentObject var model: WalkModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var editing: Bool
    private var region: IslandRegion { IslandRegion.all.first { $0.id == model.adventure.region } ?? IslandRegion.all[0] }
    private var night: Bool { let hour = Calendar.current.component(.hour, from: model.now); return hour < 6 || hour >= 20 }
    private var objects: [SceneObject] {
        let built = region.id == "home" ? model.island.buildings : model.adventure.regionBuildings[region.id, default: []]
        let coordinates: [[Double]] = [[0.28, 0.55], [0.73, 0.62], [0.57, 0.71], [0.63, 0.43], [0.44, 0.34]]
        let buildings = built.enumerated().map { index, id -> SceneObject in
            let key = region.id + "/" + id
            let position = model.adventure.positions[key] ?? coordinates[index]
            return SceneObject(id: key, symbol: IslandBuilding.all[index].symbol, color: .walkLime, x: position[0], y: position[1])
        }
        let items = model.adventure.placed.filter { $0.region == region.id }.map { SceneObject(id: $0.id.uuidString, symbol: WorldItem.item($0.kind)?.symbol ?? "leaf", color: $0.kind == "fire" ? .orange : .walkGreen, x: $0.x, y: $0.y) }
        let beaconKey = region.id + "/team-beacon"
        let beaconPosition = model.adventure.positions[beaconKey] ?? [0.78, 0.39]
        let monument = model.adventure.team?.claimed == true ? [SceneObject(id: beaconKey, symbol: "light.beacon.max.fill", color: .orange, x: beaconPosition[0], y: beaconPosition[1])] : []
        let projects = TravelBlueprint.all.enumerated().compactMap { index, blueprint -> SceneObject? in
            guard model.travel.crafted.contains(blueprint.id) else { return nil }
            let key = region.id + "/travel-" + blueprint.id
            let position = model.adventure.positions[key] ?? [0.22 + Double(index) * 0.23, 0.43]
            return SceneObject(id: key, symbol: blueprint.symbol, color: .walkGreen, x: position[0], y: position[1])
        }
        return buildings + items + monument + projects
    }
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: [night ? Color.indigo.opacity(0.5) : Color.cyan.opacity(0.25), Color.walkPaper], startPoint: .top, endPoint: .bottom))
                ForEach(0..<4) { index in Ellipse().stroke(.cyan.opacity(0.09), lineWidth: 1).frame(width: proxy.size.width * 0.8 + CGFloat(index * 22), height: 115 + CGFloat(index * 27)).offset(y: 30) }
                Ellipse().fill(.black.opacity(0.22)).frame(width: proxy.size.width * 0.88, height: 140).offset(y: 32)
                Ellipse().fill(LinearGradient(colors: landColors, startPoint: .top, endPoint: .bottom)).frame(width: proxy.size.width * 0.88, height: 142).overlay { Ellipse().stroke(.white.opacity(0.25), lineWidth: 2) }.offset(y: 15)
                Image(systemName: region.id == "snow" ? "mountain.2.fill" : region.id == "coral" ? "water.waves" : "tree.fill").font(.system(size: 62)).foregroundStyle(region.id == "snow" ? .white.opacity(0.7) : Color.walkGreen.opacity(0.35)).offset(x: -proxy.size.width * 0.26, y: -40)
                ForEach(objects) { object in MovableSceneObject(object: object, size: proxy.size, editing: editing) }
                BuddyPortrait(id: model.buddy.id, level: model.buddyLevel).frame(width: 75, height: 85).position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.52)
                    .overlay(alignment: .top) { if night { Text("z z z").font(.caption.bold()).foregroundStyle(.white.opacity(0.7)).offset(y: 70) } }
                WeatherOverlay(weather: model.adventure.weather, night: night, reduced: reduceMotion).allowsHitTesting(false)
                VStack { HStack { Text(region.name.uppercased()).font(.system(size: 10, weight: .bold)).tracking(2); Spacer(); Image(systemName: night ? "moon.stars.fill" : "sun.max.fill").foregroundStyle(Color.walkLime) }; Spacer(); HStack { Text(editing ? "Ziehe deine Orte und Fundstücke an ihren Platz." : region.subtitle).font(.caption2); Spacer() } }.padding(20).allowsHitTesting(false)
            }.clipShape(RoundedRectangle(cornerRadius: 28))
        }.frame(height: 300)
    }
    private var landColors: [Color] {
        switch region.id {
        case "forest": return [Color(red: 0.3, green: 0.57, blue: 0.48), Color(red: 0.07, green: 0.25, blue: 0.25)]
        case "coral": return [Color(red: 0.94, green: 0.79, blue: 0.56), Color(red: 0.52, green: 0.45, blue: 0.35)]
        case "snow": return [.white.opacity(0.9), .cyan.opacity(0.5)]
        default: return [Color(red: 0.43, green: 0.76, blue: 0.57), Color(red: 0.18, green: 0.46, blue: 0.38)]
        }
    }
}

struct MovableSceneObject: View {
    @EnvironmentObject var model: WalkModel
    let object: SceneObject
    let size: CGSize
    let editing: Bool
    @GestureState private var translation = CGSize.zero
    var body: some View {
        Image(systemName: object.symbol).font(.system(size: 31)).foregroundStyle(object.color).shadow(color: .black.opacity(0.2), radius: 3, y: 4)
            .frame(width: 44, height: 44).background(editing ? Color.white.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
            .position(x: size.width * object.x + translation.width, y: size.height * object.y + translation.height)
            .gesture(DragGesture(minimumDistance: 0).updating($translation) { value, state, _ in if editing { state = value.translation } }.onEnded { value in
                guard editing else { return }
                model.positionObject(object.id, x: object.x + value.translation.width / max(1, size.width), y: object.y + value.translation.height / max(1, size.height))
            }, including: editing ? .all : .none)
            .accessibilityLabel("\(object.symbol), verschiebbares Inselobjekt")
            .accessibilityAction(named: Text("Nach links")) { if editing { model.positionObject(object.id, x: object.x - 0.08, y: object.y) } }
            .accessibilityAction(named: Text("Nach rechts")) { if editing { model.positionObject(object.id, x: object.x + 0.08, y: object.y) } }
            .accessibilityAction(named: Text("Nach oben")) { if editing { model.positionObject(object.id, x: object.x, y: object.y - 0.06) } }
            .accessibilityAction(named: Text("Nach unten")) { if editing { model.positionObject(object.id, x: object.x, y: object.y + 0.06) } }
    }
}

struct WeatherOverlay: View {
    var weather: String
    var night: Bool
    var reduced: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.15, paused: reduced || (weather == "clear" && !night))) { context in
            Canvas { canvas, size in
                let time = reduced ? 0 : context.date.timeIntervalSinceReferenceDate
                for index in 0..<22 {
                    let x = Double((index * 47 + 13) % 100) / 100 * size.width
                    let y = (Double(index * 19) + time * (weather == "rain" ? 45 : 9)).truncatingRemainder(dividingBy: max(1, size.height))
                    if weather == "rain" { var path = Path(); path.move(to: CGPoint(x: x, y: y)); path.addLine(to: CGPoint(x: x - 3, y: y + 12)); canvas.stroke(path, with: .color(.cyan.opacity(0.22)), lineWidth: 1) }
                    else if weather == "snow" || (night && weather == "clear") { canvas.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 3)), with: .color(.white.opacity(0.45))) }
                }
                if weather == "mist" { canvas.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(colors: [.white.opacity(0.12), .clear, .white.opacity(0.08)]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height))) }
            }
        }.accessibilityHidden(true)
    }
}

struct IslandEditorView: View {
    @EnvironmentObject var model: WalkModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                LivingIslandView(editing: true)
                Text("Dein Ort. Deine Anordnung.").font(.title2.bold())
                Text("Gebäude und Dekorationen lassen sich mit dem Finger verschieben. Loslassen speichert die Position. Mit VoiceOver stehen Richtungsaktionen zur Verfügung.").font(.subheadline).foregroundStyle(.secondary)
                Panel {
                    Text("Stimmung deiner Insel").font(.headline)
                    Picker("Stimmung", selection: Binding(get: { model.adventure.weather }, set: { model.setAtmosphere($0) })) { Text("Klar").tag("clear"); Text("Regen").tag("rain"); Text("Nebel").tag("mist"); Text("Schnee").tag("snow") }.pickerStyle(.segmented)
                    Text("Eine frei gewählte Spielstimmung. Tag und Nacht richten sich nach der Uhrzeit auf deinem iPhone.").font(.caption).foregroundStyle(.secondary)
                }
                NavigationLink { BackpackView() } label: { Label("Inventar und Dekorationen öffnen", systemImage: "backpack.fill") }.buttonStyle(AdventureActionStyle())
                Text("Orte ausbauen").font(.title3.bold())
                ForEach(Array(IslandBuilding.all.enumerated()), id: \.element.id) { index, building in RegionBuildingCard(building: building, index: index) }
                let decorations = model.adventure.placed.filter { $0.region == model.adventure.region }
                if !decorations.isEmpty {
                    Text("Dekoration zurück ins Inventar").font(.headline)
                    ForEach(decorations) { item in HStack { Label(WorldItem.item(item.kind)?.name ?? "Fundstück", systemImage: WorldItem.item(item.kind)?.symbol ?? "leaf"); Spacer(); Button("Einpacken") { model.removeDecoration(item.id) }.font(.caption) }.padding(14).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15)) }
                }
            }.padding(22)
        }.background { OceanBackdrop() }.navigationTitle("Insel gestalten").navigationBarTitleDisplayMode(.inline)
    }
}

struct RegionBuildingCard: View {
    @EnvironmentObject var model: WalkModel
    var building: IslandBuilding
    var index: Int
    private var built: [String] { model.adventure.region == "home" ? model.island.buildings : model.adventure.regionBuildings[model.adventure.region, default: []] }
    private var cost: Int { building.cost * (model.adventure.region == "home" ? 1 : 2) }
    var body: some View {
        Panel {
            HStack { Image(systemName: building.symbol).font(.title2).foregroundStyle(Color.walkLime); VStack(alignment: .leading, spacing: 5) { Text(building.name).font(.headline); Text(building.detail).font(.caption).foregroundStyle(.secondary) }; Spacer(); if built.contains(building.id) { Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.walkGreen) } }
            if !built.contains(building.id) { Button(index == built.count ? "Bauen · \(cost) Muscheln" : "Zuerst den vorherigen Ort bauen") { model.buildRegion(building.id) }.buttonStyle(.bordered).disabled(index != built.count || model.island.shells < cost) }
        }
    }
}

struct RegionView: View {
    @EnvironmentObject var model: WalkModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Hinter dem Horizont.").font(.largeTitle.bold())
                Text("Deine gesamte Bewegung öffnet neue Gebiete. In jedem kannst du fünf Orte bauen und deine Fundstücke frei verteilen.").foregroundStyle(.secondary)
                ForEach(IslandRegion.all) { region in
                    Panel {
                        HStack { Image(systemName: region.symbol).font(.largeTitle).foregroundStyle(Color.walkGreen); VStack(alignment: .leading, spacing: 5) { Text(region.name).font(.title3.bold()); Text(region.subtitle).font(.caption).foregroundStyle(.secondary) } }
                        ProgressView(value: min(1, Double(model.island.totalSteps) / Double(max(1, region.steps)))).tint(.walkGreen)
                        if model.island.totalSteps >= region.steps { Button(model.adventure.region == region.id ? "Du bist hier" : "Hierhin reisen") { model.chooseRegion(region.id); dismiss() }.buttonStyle(AdventureActionStyle()).disabled(model.adventure.region == region.id) }
                        else { Text("Noch \((region.steps - model.island.totalSteps).formatted()) Schritte bis zur Entdeckung").font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }.padding(22)
        }.background { OceanBackdrop() }.navigationTitle("Deine Weltkarte").navigationBarTitleDisplayMode(.inline)
    }
}

struct BackpackView: View {
    @EnvironmentObject var model: WalkModel
    @State private var notice = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Panel {
                    Label("Kleine Wunder unterwegs", systemImage: "backpack.fill").font(.title3.bold())
                    Text("Je 2.000 Schritte wartet ein Fundstück auf dich. Auch Schritte ohne gestartete GPS-Runde zählen.").font(.subheadline).foregroundStyle(.secondary)
                    Text("\(model.adventure.availableFinds(total: model.island.totalSteps)) ungeöffnete Funde").font(.title2.bold())
                    MainButton(title: "Fundstück entdecken", symbol: "sparkles") { model.openFind(); notice = true }.disabled(model.adventure.availableFinds(total: model.island.totalSteps) == 0)
                    Text(model.adventure.recentFind).font(.caption).foregroundStyle(.secondary)
                }
                Text("Inventar & kleiner Inselladen").font(.title3.bold())
                Text("Platzierte Gegenstände erscheinen im aktuellen Gebiet. Im Gestalten-Modus kannst du sie verschieben oder wieder einpacken.").font(.caption).foregroundStyle(.secondary)
                ForEach(WorldItem.all) { item in
                    Panel {
                        HStack { Image(systemName: item.symbol).font(.title).foregroundStyle(Color.walkGreen).frame(width: 42); VStack(alignment: .leading, spacing: 6) { Text(item.name).font(.headline); Text("\(model.adventure.inventory[item.id, default: 0]) im Rucksack").font(.caption).foregroundStyle(.secondary) }; Spacer() }
                        HStack {
                            Button("Platzieren") { model.placeDecoration(item.id) }.buttonStyle(AdventureActionStyle()).disabled(model.adventure.inventory[item.id, default: 0] == 0 || model.adventure.placed.count >= 200)
                            Button("Kaufen · \(item.cost) ✦") { model.buyDecoration(item.id) }.buttonStyle(.bordered).disabled(model.island.shells < item.cost)
                        }.font(.caption.bold())
                    }
                }
                Text("Bis zu 200 Dekorationen insgesamt. Muscheln haben keinen Geldwert; es gibt keine Käufe mit echtem Geld.").font(.caption).foregroundStyle(.secondary)
            }.padding(22)
        }.background { OceanBackdrop() }.navigationTitle("Dein Rucksack").navigationBarTitleDisplayMode(.inline)
            .alert("Dein Fundstück", isPresented: $notice) { Button("Einpacken", role: .cancel) {} } message: { Text(model.adventure.recentFind) }
    }
}

struct BuddyCollectionView: View {
    @EnvironmentObject var model: WalkModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Manche Wege geht man zusammen.").font(.title.bold())
                Text("Bewegung brütet neue Begleiter aus. Nur dein ausgewählter Freund sammelt mit deinen nächsten Schritten Erfahrung. Ab Level 3 und 7 verändert sich sein Aussehen.").font(.subheadline).foregroundStyle(.secondary)
                ForEach(IslandBuddy.all) { buddy in
                    let owned = model.adventure.buddies.contains(buddy.id)
                    let steps = model.adventure.buddySteps[buddy.id, default: 0]
                    Panel {
                        HStack(spacing: 18) {
                            if owned { BuddyPortrait(id: buddy.id, level: 1 + steps / 5000).frame(width: 80, height: 95) }
                            else { Image(systemName: "oval.portrait.fill").font(.system(size: 60)).foregroundStyle(Color.walkLime.opacity(0.65)).overlay { Image(systemName: buddy.symbol).foregroundStyle(Color.walkPaper) }.frame(width: 80, height: 95) }
                            VStack(alignment: .leading, spacing: 7) { Text(buddy.name).font(.title3.bold()); Text(buddy.trait).font(.caption).foregroundStyle(.secondary); Text(owned ? "Level \(1 + steps / 5000) · \(steps.formatted()) gemeinsame Schritte" : "Schlüpft bei \(buddy.hatchAt.formatted()) Gesamtschritten").font(.caption2).foregroundStyle(Color.walkGreen) }
                        }
                        if owned { Button(model.buddy.id == buddy.id ? "Geht mit dir" : "Als Begleiter wählen") { model.chooseBuddy(buddy.id) }.buttonStyle(.bordered).disabled(model.buddy.id == buddy.id) }
                        else { ProgressView(value: min(1, Double(model.island.totalSteps) / Double(buddy.hatchAt))).tint(.walkGreen); Button("Ei ausbrüten") { withAnimation { model.hatchBuddy(buddy.id) } }.buttonStyle(AdventureActionStyle()).disabled(model.island.totalSteps < buddy.hatchAt) }
                    }
                }
            }.padding(22)
        }.background { OceanBackdrop() }.navigationTitle("Deine Begleiter").navigationBarTitleDisplayMode(.inline)
    }
}

struct ExpeditionStatus: View {
    @EnvironmentObject var model: WalkModel
    var trip: Expedition
    var body: some View {
        Panel {
            Label("Deine Expedition läuft", systemImage: "safari.fill").font(.headline)
            ProgressView(value: Double(trip.progress(total: model.island.totalSteps, days: model.island.stepsByDay)) / Double(trip.target)).tint(.walkGreen)
            Text("\(trip.progress(total: model.island.totalSteps, days: model.island.stepsByDay).formatted()) / \(trip.target.formatted()) Schritte · +\(trip.reward) Muscheln").font(.caption).foregroundStyle(.secondary)
            if trip.progress(total: model.island.totalSteps, days: model.island.stepsByDay) >= trip.target { MainButton(title: "Expedition abschließen", symbol: "checkmark.seal.fill", action: model.claimExpedition) }
        }
    }
}

struct ExpeditionView: View {
    @EnvironmentObject var model: WalkModel
    @State private var cancel = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Ein Ziel, das zu dir passt.").font(.title.bold())
                Text("Eine Expedition zählt neue Tages-Schritte ab ihrem Start. Du darfst jederzeit pausieren oder erst morgen weitergehen. Sie startet kein GPS und läuft unabhängig von einer aufgezeichneten Route.").font(.subheadline).foregroundStyle(.secondary)
                if let trip = model.adventure.expedition, trip.finishedAt == nil {
                    ExpeditionStatus(trip: trip)
                    MainButton(title: model.activeWalk == nil ? "GPS-Spaziergang dazu starten" : "Zur aufgezeichneten Runde", symbol: "figure.walk", action: model.requestStart)
                    Button("Expedition abbrechen", role: .destructive) { cancel = true }.font(.caption)
                } else {
                    ForEach([1000, 3000, 6000], id: \.self) { target in
                        Panel { Label(target == 1000 ? "Eine kleine Auszeit" : target == 3000 ? "Ein Weg ins Grüne" : "Ein großes Abenteuer", systemImage: "safari.fill").font(.headline); Text("\(target.formatted()) Schritte · +\(target / 100) Muscheln").font(.subheadline).foregroundStyle(.secondary); MainButton(title: "Expedition starten", symbol: "play.fill") { model.beginExpedition(target) } }
                    }
                }
                Text("\(model.adventure.completedExpeditions) Expeditionen abgeschlossen").font(.caption).foregroundStyle(Color.walkGreen)
            }.padding(22)
        }.background { OceanBackdrop() }.navigationTitle("Expeditionen").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Diese Expedition ohne Belohnung beenden? Deine Schritte bleiben erhalten.", isPresented: $cancel, titleVisibility: .visible) { Button("Expedition abbrechen", role: .destructive, action: model.cancelExpedition); Button("Weiter sammeln", role: .cancel) {} }
    }
}

struct StorybookView: View {
    @EnvironmentObject var model: WalkModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Die Karte mit dem grünen Stern").font(.title.bold())
                Text("Ein Abenteuer in sechs Kapiteln. Neue Wege bringen die Geschichte weiter; die Belohnungen warten auf dich, ohne abzulaufen.").font(.subheadline).foregroundStyle(.secondary)
                ForEach(StoryChapter.all) { chapter in
                    let claimed = model.adventure.chapters.contains(chapter.id)
                    let next = StoryChapter.all.first { !model.adventure.chapters.contains($0.id) }?.id == chapter.id
                    let ready = model.island.totalSteps >= chapter.steps && model.completedWalks.count >= chapter.walks
                    Panel {
                        Label(chapter.title, systemImage: claimed ? "book.fill" : next && ready ? "book" : "lock.fill").font(.headline)
                        if claimed || (next && ready) {
                            Text(chapter.text).font(.subheadline).lineSpacing(6).foregroundStyle(.secondary)
                            Text("Andenken: \(WorldItem.item(chapter.gift)?.name ?? "Fundstück")").font(.caption).foregroundStyle(Color.walkLime)
                            if !claimed { Button("Kapitel entdecken & Andenken sammeln") { model.claimChapter(chapter.id) }.font(.caption.bold()).buttonStyle(AdventureActionStyle()) }
                        } else {
                            Text("\(min(model.island.totalSteps, chapter.steps).formatted()) / \(chapter.steps.formatted()) Schritte · \(min(model.completedWalks.count, chapter.walks)) / \(chapter.walks) Spaziergänge").font(.caption).foregroundStyle(.secondary)
                            if !next { Text("Entdecke zuerst das vorherige Kapitel.").font(.caption2).foregroundStyle(.secondary) }
                        }
                    }
                }
            }.padding(22)
        }.background { OceanBackdrop() }.navigationTitle("Dein Geschichtenbuch").navigationBarTitleDisplayMode(.inline)
    }
}

struct MuseumView: View {
    @EnvironmentObject var model: WalkModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Kleine Schritte. Bleibende Erinnerungen.").font(.title.bold())
                Text("Einmal entdeckte Meilensteine bleiben in deinem Museum, auch wenn du später eine Route aus dem Journal löschst.").font(.subheadline).foregroundStyle(.secondary)
                ForEach(model.museum) { badge in
                    let earned = badge.earned || model.adventure.earnedBadges.contains(badge.id)
                    Panel {
                        HStack(spacing: 16) { Image(systemName: badge.symbol).font(.largeTitle).foregroundStyle(earned ? Color.walkLime : .gray); VStack(alignment: .leading, spacing: 7) { Text(badge.title).font(.headline); Text(badge.detail).font(.caption).foregroundStyle(.secondary) } }
                        if earned { Label("Für immer in deiner Sammlung", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(Color.walkGreen) }
                        else { ProgressView(value: min(1, Double(badge.current) / Double(badge.target))).tint(.walkGreen); Text("\(badge.current.formatted()) / \(badge.target.formatted())").font(.caption2).foregroundStyle(.secondary) }
                    }
                }
            }.padding(22)
        }.background { OceanBackdrop() }.navigationTitle("Inselmuseum").navigationBarTitleDisplayMode(.inline)
    }
}

struct WeeklyStoryView: View {
    @EnvironmentObject var model: WalkModel
    @State private var share = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Eyebrow(text: "Die letzten sieben Tage")
                Text("Deine Woche hat Spuren hinterlassen.").font(.largeTitle.bold())
                Panel { Image(systemName: "sun.horizon.fill").font(.system(size: 45)).foregroundStyle(Color.walkLime); Text(model.weeklyStory.text).font(.title3).lineSpacing(7); Divider(); HStack { Metric(title: "Schritte", value: model.weeklyStory.steps.formatted(), unit: "", symbol: "shoeprints.fill"); Metric(title: "Runden", value: model.weeklyStory.walks.formatted(), unit: "", symbol: "figure.walk") } }
                Text("Gezählt werden gespeicherte Tageswerte und abgeschlossene GPS-Runden. Fehlende Schrittdaten werden nicht geschätzt.").font(.caption).foregroundStyle(.secondary)
                MainButton(title: "Rückblick teilen", symbol: "square.and.arrow.up") { share = true }
            }.padding(22)
        }.background { OceanBackdrop() }.navigationTitle("Dein Wochenrückblick").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $share) { ShareSheet(items: [model.weeklyStory.text]) }
    }
}

struct TeamView: View {
    @EnvironmentObject var model: WalkModel
    @State private var code = ""
    @State private var leave = false
    @State private var share = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Image(systemName: "light.beacon.max.fill").font(.system(size: 55)).foregroundStyle(Color.walkLime)
                Text("Ein Leuchtturm für alle.").font(.largeTitle.bold())
                Text("Sammelt gemeinsam 50.000 Schritte und bringt den alten Leuchtturm zum Leuchten. Ohne Rangliste. Ohne Standortfreigabe.").font(.subheadline).foregroundStyle(.secondary)
                if let team = model.adventure.team {
                    Panel {
                        Eyebrow(text: "Euer Einladungscode")
                        Text(team.code).font(.system(size: 30, weight: .bold, design: .monospaced)).textSelection(.enabled)
                        Button("Einladung teilen") { share = true }.buttonStyle(.bordered)
                        ProgressView(value: min(1, Double(team.total) / Double(TeamProject.target))).tint(.walkGreen)
                        Text("\(team.total.formatted()) / 50.000 gemeinsame Schritte").font(.headline)
                        Text("Dein Beitrag: \(team.contributions[model.adventure.deviceID, default: 0].formatted()) Schritte seit dem Beitritt · \(team.contributions.count) Mitglieder gespeichert").font(.caption).foregroundStyle(.secondary)
                        if team.total >= TeamProject.target { Button(team.claimed ? "Leuchtturm fertig ✓" : "Leuchtturm vollenden · +100 ✦ & Laterne") { model.claimTeam() }.buttonStyle(AdventureActionStyle()).disabled(team.claimed) }
                    }
                    FriendsConnectionView(sync: model.friends)
                    Button("Projekt verlassen", role: .destructive) { leave = true }.font(.caption)
                } else {
                    Panel {
                        Text("Gemeinsam anfangen").font(.headline)
                        MainButton(title: "Projekt gründen", symbol: "person.2.fill", action: model.createTeam)
                        TextField("Einladungscode (8 Zeichen)", text: $code).textInputAutocapitalization(.characters).autocorrectionDisabled().textFieldStyle(.roundedBorder).onChange(of: code) { _, value in code = String(value.uppercased().prefix(8)) }
                        Button("Mit Code beitreten") { model.joinTeam(code) }.buttonStyle(.bordered).disabled(code.count != 8)
                    }
                }
                Panel {
                    Label("So funktioniert die Verbindung", systemImage: "lock.shield.fill").font(.headline)
                    Text("Zum Abgleichen müssen beide iPhones dieselbe App-Version und denselben Code verwenden. Öffnet diese Seite auf beiden Geräten, bleibt in der Nähe und startet die Verbindung. WLAN und Bluetooth einschalten und den Zugriff aufs lokale Netzwerk erlauben. Ein gemeinsames WLAN hilft.").font(.caption).foregroundStyle(.secondary)
                    Text("Geteilt werden nur zufällige Mitgliedskennungen und Schrittbeiträge seit Beitritt. Keine Namen oder Routen. Die Übertragung ist verschlüsselt. Es gibt keinen Cloud-Server und keinen automatischen Fernabgleich. Beim Verlassen der App stoppt die Verbindung; später erneut verbinden.").font(.caption).foregroundStyle(.secondary)
                }
            }.padding(22)
        }.background { OceanBackdrop() }.navigationTitle("Mit Freunden").navigationBarTitleDisplayMode(.inline)
            .onDisappear { model.friends.stop() }
            .confirmationDialog("Projekt verlassen? Die bisher auf anderen Geräten gespeicherten Beiträge bleiben dort erhalten.", isPresented: $leave, titleVisibility: .visible) { Button("Verlassen", role: .destructive, action: model.leaveTeam); Button("Bleiben", role: .cancel) {} }
            .sheet(isPresented: $share) { if let team = model.adventure.team { ShareSheet(items: ["Baue mit mir den Dayform-Leuchtturm! Einladungscode: \(team.code). In Dayform Walk → Insel → Mit Freunden → Mit Code beitreten."]) } }
    }
}

struct FriendsConnectionView: View {
    @EnvironmentObject var model: WalkModel
    @ObservedObject var sync: FriendsSync
    var body: some View {
        Panel {
            Label(sync.status, systemImage: sync.connected > 0 ? "person.2.wave.2.fill" : "antenna.radiowaves.left.and.right").font(.subheadline)
            MainButton(title: sync.running ? "Verbindung beenden" : "Jetzt mit Freunden verbinden", symbol: sync.running ? "stop.fill" : "wifi") { if sync.running { sync.stop() } else { model.connectFriends() } }
        }
    }
}
