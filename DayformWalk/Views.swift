import SwiftUI
import Charts
import UniformTypeIdentifiers

struct OceanBackdrop: View {
    var body: some View {
        ZStack {
            Color.walkPaper
            RadialGradient(colors: [Color.walkGreen.opacity(0.15), .clear], center: .topTrailing, startRadius: 0, endRadius: 430)
            RadialGradient(colors: [.indigo.opacity(0.22), .clear], center: .bottomLeading, startRadius: 0, endRadius: 420)
        }.ignoresSafeArea()
    }
}

struct TodayView: View {
    @EnvironmentObject var model: WalkModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        Text(model.preferences.name.isEmpty ? "Dein nächstes\nAbenteuer wartet." : "Hey \(model.preferences.name),\nlass uns rausgehen.")
                            .font(.system(size: 32, weight: .bold, design: .rounded)).tracking(-0.8)
                    }
                    Spacer(minLength: 4)
                    NavigationLink { SettingsView() } label: { Image(systemName: "slider.horizontal.3").font(.title3).padding(13).background(.ultraThinMaterial, in: Circle()) }.accessibilityLabel("Einstellungen öffnen")
                }
                Panel {
                    HStack { Eyebrow(text: "Deine Bewegung"); Spacer(); Label("iPhone", systemImage: "iphone").font(.caption2).foregroundStyle(.secondary) }
                    HStack(spacing: 24) {
                        stepRing
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Tagesziel").font(.caption).foregroundStyle(.secondary)
                            Text(model.preferences.dailyGoal.formatted()).font(.title2.bold().monospacedDigit())
                            Text(model.todaySteps == nil ? "Warte auf Schrittdaten" : model.todaySteps! >= model.preferences.dailyGoal ? "Geschafft. Gut gemacht!" : "Noch \(max(0, model.preferences.dailyGoal - (model.todaySteps ?? 0)).formatted()) Schritte")
                                .font(.caption).foregroundStyle(Color.walkGreen)
                        }
                    }.frame(maxWidth: .infinity)
                    Divider().overlay(.white.opacity(0.1))
                    HStack {
                        Metric(title: "Strecke", value: model.todayDistance.map { ($0 / 1000).formatted(.number.precision(.fractionLength(2))) } ?? "—", unit: "km", symbol: "location")
                        Metric(title: "Etagen", value: model.todayFloors.map(String.init) ?? "—", unit: "", symbol: "stairs")
                        Metric(title: "Muscheln", value: model.island.shells.formatted(), unit: "", symbol: "sparkle")
                    }
                }
                if !model.motionAuthorized {
                    Panel {
                        Label("Jeder Schritt zählt.", systemImage: "shoeprints.fill").font(.headline)
                        Text("Erlaube Bewegung & Fitness, um deine iPhone-Schritte zu lesen und deine Insel wachsen zu lassen.").font(.subheadline).foregroundStyle(.secondary)
                        MainButton(title: "Schrittzähler aktivieren", symbol: "checkmark.shield", action: model.enableMotion)
                    }
                }
                VStack(alignment: .leading, spacing: 14) {
                    HStack { Text("Deine kleine Auszeit").font(.title3.bold()); Spacer(); Text("GPS + SCHRITTE").font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(Color.walkGreen) }
                    Text("Neue Wege finden. Erinnerungen sammeln.").font(.subheadline).foregroundStyle(.secondary)
                    MainButton(title: model.activeWalk == nil ? "Spaziergang starten" : "Zur laufenden Runde", symbol: "figure.walk", action: model.requestStart)
                }
                Button { model.selectedTab = 4 } label: {
                    Panel {
                        HStack {
                            VStack(alignment: .leading, spacing: 7) { Eyebrow(text: "Deine Schritte werden zur Welt"); Text("Willkommen auf deiner Insel.").font(.title3.bold()); Text("\(model.buddy.name) wartet auf dich · Level \(model.buddyLevel)").font(.caption).foregroundStyle(.secondary) }
                            Spacer(); BuddyPortrait(id: model.buddy.id, level: model.buddyLevel).frame(width: 68, height: 78)
                        }
                        HStack { Label("\(model.island.buildings.count)/5 Orte gebaut", systemImage: "leaf"); Spacer(); Image(systemName: "arrow.up.right") }.font(.caption.bold()).foregroundStyle(Color.walkGreen)
                    }
                }.buttonStyle(.plain)
                HStack { Text("Deine Missionen").font(.title3.bold()); Spacer(); Button("Alle ansehen") { model.selectedTab = 4 }.font(.caption) }
                ForEach(model.missions.prefix(2)) { mission in MissionCard(mission: mission) }
                Label("Kein Seriendruck. Dein Fortschritt bleibt.", systemImage: "heart").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }.padding(22)
        }.background { OceanBackdrop() }.navigationTitle("dayform").navigationBarTitleDisplayMode(.inline)
            .refreshable { model.refreshMotion() }
    }
    private var stepRing: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.08), lineWidth: 11)
            Circle().trim(from: 0, to: min(1, CGFloat(model.todaySteps ?? 0) / CGFloat(model.preferences.dailyGoal)))
                .stroke(AngularGradient(colors: [.walkGreen, .cyan, .walkGreen], center: .center), style: StrokeStyle(lineWidth: 11, lineCap: .round)).rotationEffect(.degrees(-90))
            VStack(spacing: 5) {
                Image(systemName: "shoeprints.fill").foregroundStyle(Color.walkGreen)
                Text(model.todaySteps.map { $0.formatted() } ?? "—").font(.system(size: 34, weight: .bold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1).contentTransition(.numericText())
                Text("Schritte heute").font(.caption2).foregroundStyle(.secondary)
            }.padding(12)
        }.frame(width: 150, height: 150).accessibilityElement(children: .combine)
    }
}

struct CompanionView: View {
    var level: Int
    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.18)).frame(width: 55, height: 12).offset(y: 31)
            RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: [.white, Color.walkGreen.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 57, height: 60)
            HStack(spacing: 12) { Capsule().frame(width: 5, height: 9); Capsule().frame(width: 5, height: 9) }.foregroundStyle(Color.walkPaper).offset(y: -2)
            Capsule().fill(Color.walkPaper.opacity(0.8)).frame(width: 9, height: 3).offset(y: 9)
            Image(systemName: level >= 7 ? "sparkles" : "leaf.fill").font(.system(size: 23)).foregroundStyle(level >= 7 ? Color.walkLime : Color.walkGreen).rotationEffect(.degrees(25)).offset(x: 8, y: -34)
            HStack(spacing: 28) { Circle(); Circle() }.foregroundStyle(.pink.opacity(0.28)).frame(width: 43, height: 7).offset(y: 6)
        }.accessibilityLabel("Lumi, dein Begleiter auf Level \(level)")
    }
}

struct IslandScene: View {
    var buildings: [String]
    var level: Int
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: [Color(red: 0.08, green: 0.23, blue: 0.32), Color(red: 0.04, green: 0.13, blue: 0.23)], startPoint: .topLeading, endPoint: .bottomTrailing))
                ForEach(0..<4) { index in
                    Ellipse().stroke(.cyan.opacity(0.08), lineWidth: 1).frame(width: w * 0.75 + CGFloat(index * 35), height: 100 + CGFloat(index * 36)).offset(y: 38)
                }
                Ellipse().fill(Color(red: 0.07, green: 0.25, blue: 0.23)).frame(width: w * 0.84, height: 135).offset(y: 28)
                Ellipse().fill(LinearGradient(colors: [Color(red: 0.43, green: 0.76, blue: 0.57), Color(red: 0.18, green: 0.46, blue: 0.38)], startPoint: .top, endPoint: .bottom)).frame(width: w * 0.85, height: 128).overlay { Ellipse().stroke(Color.walkLime.opacity(0.4), lineWidth: 3) }.offset(y: 12)
                Image(systemName: "tree.fill").font(.system(size: 68)).foregroundStyle(Color(red: 0.09, green: 0.35, blue: 0.27)).offset(x: -w * 0.25, y: -37)
                Image(systemName: "tree.fill").font(.system(size: 48)).foregroundStyle(Color(red: 0.15, green: 0.43, blue: 0.31)).offset(x: w * 0.24, y: -28)
                if buildings.contains("camp") { landmark("tent.fill", color: .walkLime, x: -w * 0.16, y: 8) }
                if buildings.contains("garden") { landmark("leaf.fill", color: .walkGreen, x: w * 0.23, y: 30) }
                if buildings.contains("bridge") { RoundedRectangle(cornerRadius: 4).fill(Color(red: 0.84, green: 0.66, blue: 0.43)).frame(width: 72, height: 16).rotationEffect(.degrees(-25)).offset(x: 30, y: 58) }
                if buildings.contains("cabin") { landmark("house.fill", color: .orange.opacity(0.85), x: w * 0.12, y: -30) }
                if buildings.contains("beacon") { landmark("sparkles", color: .walkLime, x: -w * 0.04, y: -70) }
                CompanionView(level: level).frame(width: 75, height: 85).offset(x: -4, y: 8)
                VStack { HStack { Label("LUMIS INSEL", systemImage: "sparkle").font(.system(size: 9, weight: .bold)).tracking(2); Spacer(); Image(systemName: "moon.stars.fill").foregroundStyle(Color.walkLime) }; Spacer(); HStack { Text(buildings.isEmpty ? "Hier beginnt etwas Schönes." : "Mit jedem Schritt ein Stück mehr Zuhause.").font(.caption2); Spacer() } }.padding(20).foregroundStyle(.white.opacity(0.8))
            }
        }.frame(height: 285).accessibilityElement(children: .ignore).accessibilityLabel("Deine Insel mit \(buildings.count) von fünf gebauten Orten und Lumi auf Level \(level)")
    }
    private func landmark(_ symbol: String, color: Color, x: CGFloat, y: CGFloat) -> some View {
        Image(systemName: symbol).font(.system(size: 36)).foregroundStyle(color).shadow(color: .black.opacity(0.2), radius: 3, y: 5).offset(x: x, y: y)
    }
}

struct MissionCard: View {
    @EnvironmentObject var model: WalkModel
    let mission: IslandMission
    private var claimed: Bool { model.island.claimed.contains(mission.id) }
    var body: some View {
        Panel {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: claimed ? "checkmark" : mission.symbol).font(.title3).foregroundStyle(Color.walkGreen).frame(width: 42, height: 42).background(Color.walkGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 5) { Text(mission.title).font(.subheadline.bold()); Text(mission.detail).font(.caption).foregroundStyle(.secondary) }
                Spacer(minLength: 0)
                Text("+\(mission.reward)").font(.caption.bold()).foregroundStyle(Color.walkLime)
            }
            ProgressView(value: mission.progress).tint(.walkGreen)
            HStack {
                Text("\(min(mission.current, mission.target).formatted()) / \(mission.target.formatted())").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Button(claimed ? "Eingesammelt ✓" : mission.progress >= 1 ? "Belohnung abholen" : "In Bewegung") { withAnimation { model.claimMission(mission.id) } }
                    .font(.caption.bold()).disabled(claimed || mission.progress < 1).buttonStyle(.bordered).tint(.walkGreen)
            }
        }
    }
}

struct IslandView: View {
    @EnvironmentObject var model: WalkModel
    @State private var notice: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 7) { Eyebrow(text: "Ein kleines Stück von dir"); Text("Deine Insel.").font(.system(size: 34, weight: .bold, design: .rounded)).tracking(-1) }
                    Spacer()
                    Label(model.island.shells.formatted(), systemImage: "sparkle").font(.headline.monospacedDigit()).foregroundStyle(Color.walkLime).padding(13).background(.ultraThinMaterial, in: Capsule())
                }
                IslandScene(buildings: model.island.buildings, level: model.island.level)
                Panel {
                    HStack(spacing: 20) {
                        CompanionView(level: model.island.level).frame(width: 74, height: 90)
                        VStack(alignment: .leading, spacing: 8) { Eyebrow(text: "Dein Begleiter"); Text("Lumi · Level \(model.island.level)").font(.title3.bold()); Text(model.island.companion).font(.caption).foregroundStyle(.secondary); ProgressView(value: model.island.levelProgress).tint(.walkGreen); Text("Noch \((5000 - model.island.totalSteps % 5000).formatted()) Schritte bis Level \(model.island.level + 1)").font(.caption2).foregroundStyle(.secondary) }
                    }
                }
                VStack(alignment: .leading, spacing: 7) { Text("Mach es zu deinem Ort.").font(.title3.bold()); Text("100 Schritte = 1 Muschel. Baue deine Insel Stück für Stück aus.").font(.subheadline).foregroundStyle(.secondary) }
                ForEach(Array(IslandBuilding.all.enumerated()), id: \.element.id) { index, building in
                    buildingCard(building, index: index)
                }
                HStack { Text("Heute auf Entdeckung").font(.title3.bold()); Spacer(); Image(systemName: "sun.max").foregroundStyle(Color.walkLime) }
                Text("Jeden Tag neue Chancen. Keine verlorenen Serien, keine Strafe für Pausen.").font(.subheadline).foregroundStyle(.secondary)
                ForEach(model.missions) { mission in MissionCard(mission: mission) }
                Panel {
                    Label("So wächst deine Welt", systemImage: "info.circle").font(.subheadline.bold())
                    Text("Es zählen die erfassten iPhone-Tageswerte, auch außerhalb deiner Spaziergänge. Jeder Schritt wird nur einmal belohnt. Bereits gespeicherte Tage werden beim Update berücksichtigt. Muscheln haben keinen Geldwert. Dein Spielstand ist im JSON-Backup enthalten.").font(.caption).foregroundStyle(.secondary)
                }
            }.padding(22)
        }.background { OceanBackdrop() }.navigationTitle("Deine Welt").navigationBarTitleDisplayMode(.inline)
            .alert("Deine Insel wächst", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) { Button("Schön!") { notice = nil } } message: { Text(notice ?? "") }
    }
    private func buildingCard(_ building: IslandBuilding, index: Int) -> some View {
        let built = model.island.buildings.contains(building.id)
        let next = index == model.island.buildings.count
        let affordable = model.island.shells >= building.cost
        return Panel {
            HStack(spacing: 14) {
                Image(systemName: building.symbol).font(.title2).foregroundStyle(built ? Color.walkGreen : Color.walkLime).frame(width: 48, height: 48).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 5) { Text(building.name).font(.subheadline.bold()); Text(building.detail).font(.caption).foregroundStyle(.secondary) }
                Spacer(minLength: 0)
                if built { Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.walkGreen).accessibilityLabel("Bereits gebaut") }
            }
            if !built {
                Button {
                    withAnimation(.spring(response: 0.5)) { model.buildIsland(building.id) }
                    if model.island.buildings.contains(building.id) { notice = "\(building.name) gehört jetzt zu deiner Insel. Lumi freut sich auf den neuen Ort." }
                } label: { HStack { Text(next ? affordable ? "Jetzt bauen" : "Noch \(building.cost - model.island.shells) Muscheln sammeln" : "Zuerst den vorherigen Ort bauen"); Spacer(); Label("\(building.cost)", systemImage: "sparkle") }.font(.caption.bold()).padding(13).background(Color.walkGreen.opacity(next && affordable ? 0.17 : 0.04), in: RoundedRectangle(cornerRadius: 13)) }
                    .buttonStyle(.plain).foregroundStyle(next && affordable ? Color.walkGreen : .secondary).disabled(!next || !affordable)
            }
        }
    }
}

extension Color {
    static let walkGreen = Color(red: 0.35, green: 0.91, blue: 0.77)
    static let walkLime = Color(red: 0.85, green: 0.94, blue: 0.57)
    static let walkPaper = Color(red: 0.035, green: 0.075, blue: 0.13)
    static let walkInk = Color(red: 0.13, green: 0.17, blue: 0.14)
    static let walkOrange = Color(red: 0.86, green: 0.44, blue: 0.29)
}

struct RootView: View {
    @EnvironmentObject var model: WalkModel
    var body: some View {
        TabView(selection: $model.selectedTab) {
            NavigationStack { TodayView() }.tabItem { Label("Heute", systemImage: "sun.max") }.tag(0)
            NavigationStack { AdventureEntryView() }.tabItem { Label("Insel", systemImage: "leaf.fill") }.tag(4)
            NavigationStack { WalksView() }.tabItem { Label("Spaziergang", systemImage: "figure.walk") }.tag(1)
            NavigationStack { DevelopmentView() }.tabItem { Label("Verlauf", systemImage: "chart.bar.xaxis") }.tag(2)
            NavigationStack { SettingsView() }.tabItem { Label("Einstellungen", systemImage: "slider.horizontal.3") }.tag(3)
        }
        .alert("Dayform Walk", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
            Button("iPhone-Einstellungen") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
        } message: { Text(model.errorMessage ?? "") }
        .preferredColorScheme(.dark)
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { VStack(alignment: .leading, spacing: 18) { content }.padding(22).frame(maxWidth: .infinity, alignment: .leading).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26)).overlay { RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.13), lineWidth: 1) }.shadow(color: .black.opacity(0.12), radius: 18, y: 8) }
}

struct Eyebrow: View {
    var text: String
    var body: some View { Text(text.uppercased()).font(.system(size: 10, weight: .semibold, design: .rounded)).tracking(2).foregroundStyle(Color.walkGreen) }
}

struct MainButton: View {
    var title: String
    var symbol: String
    var color: Color = .walkGreen
    var action: () -> Void
    var body: some View {
        Button(action: action) { Label(title, systemImage: symbol).font(.system(size: 15, weight: .bold)).frame(maxWidth: .infinity).padding(.vertical, 18).background(color.gradient, in: RoundedRectangle(cornerRadius: 18)).foregroundStyle(Color.walkPaper) }
        .buttonStyle(.plain)
    }
}

struct Metric: View {
    var title: String
    var value: String
    var unit: String
    var symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label(title, systemImage: symbol).font(.system(size: 11)).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) { Text(value).font(.system(size: 24, weight: .semibold, design: .rounded)).minimumScaleFactor(0.5).lineLimit(1); Text(unit).font(.system(size: 10)).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WalksView: View {
    @EnvironmentObject var model: WalkModel
    @State private var fitToken = UUID()
    @State private var confirmFinish = false
    @State private var completedID: UUID?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let walk = model.activeWalk {
                    HStack {
                        Eyebrow(text: walk.status == .recording ? "Aufzeichnung läuft" : "Spaziergang pausiert")
                        Spacer()
                        Circle().fill(walk.status == .recording ? Color.walkGreen : Color.walkOrange).frame(width: 8, height: 8)
                    }
                    ZStack(alignment: .bottomTrailing) {
                        RouteMap(segments: walk.segments, isLive: walk.status == .recording, fitToken: fitToken).frame(height: 325).clipShape(RoundedRectangle(cornerRadius: 23))
                        Button { fitToken = UUID() } label: { Image(systemName: "arrow.up.left.and.arrow.down.right").padding(12).background(.regularMaterial, in: Circle()) }.padding(14).accessibilityLabel("Ganze Route anzeigen")
                    }
                    HStack { Image(systemName: "location.fill"); Text(model.gpsStatus); Spacer(); if let accuracy = model.gpsAccuracy { Text("±\(Int(accuracy)) m") } }.font(.system(size: 11)).foregroundStyle(.secondary)
                    Panel {
                        HStack { Metric(title: "Aktive Zeit", value: Display.duration(walk.activeDuration(at: model.now)), unit: "", symbol: "stopwatch"); Metric(title: "GPS-Strecke", value: (walk.distance / 1000).formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "de_DE"))), unit: "km", symbol: "location") }
                        Divider()
                        HStack { Metric(title: "Apple-Schritte", value: walk.hasSteps ? walk.knownSteps.formatted() : "—", unit: "", symbol: "shoeprints.fill"); Metric(title: "Ø Tempo", value: Display.pace(walk.pace(at: model.now)), unit: "min/km", symbol: "speedometer") }
                        if walk.hasIncompleteSteps { Text("Schrittdaten werden nachgeladen. Ein Strich bedeutet nicht null Schritte.").font(.system(size: 10)).foregroundStyle(.secondary) }
                    }
                    HStack(spacing: 12) {
                        MainButton(title: walk.status == .recording ? "Pause" : "Fortsetzen", symbol: walk.status == .recording ? "pause.fill" : "play.fill") { if walk.status == .recording { model.pauseWalk() } else { model.requestStart() } }
                        MainButton(title: "Beenden", symbol: "stop.fill", color: .walkOrange) { confirmFinish = true }
                    }
                    if let event = walk.events.last { Label(event.message, systemImage: "info.circle").font(.system(size: 11)).foregroundStyle(.secondary) }
                    if !model.motionAuthorized { Button("Schritte für diesen Spaziergang freigeben") { model.enableMotion() }.font(.system(size: 12)) }
                } else {
                    Eyebrow(text: "Dein nächster Spaziergang")
                    Text("Geh los.\nWir halten den Weg fest.").font(.system(size: 31, weight: .semibold, design: .rounded)).tracking(-1)
                    ZStack { RoundedRectangle(cornerRadius: 23).fill(Color.walkGreen.opacity(0.09)); Image(systemName: "map.fill").font(.system(size: 75)).foregroundStyle(Color.walkGreen.opacity(0.5)) }.frame(height: 220)
                    MainButton(title: "Spaziergang starten", symbol: "play.fill", action: model.requestStart)
                    Text("Dein Standort wird nur während einer gestarteten Aufzeichnung gespeichert. Karten werden über Apple Maps geladen.").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Text("Deine Spaziergänge").font(.system(size: 21, weight: .semibold, design: .rounded)).padding(.top, 8)
                if model.completedWalks.isEmpty { Panel { Label("Hier beginnt deine Sammlung.", systemImage: "leaf"); Text("Beendete Spaziergänge findest du hier mit ihrer Karte und allen Werten.").font(.system(size: 12)).foregroundStyle(.secondary) } }
                ForEach(model.completedWalks) { walk in NavigationLink { WalkDetailView(id: walk.id) } label: { WalkRow(walk: walk) }.buttonStyle(.plain) }
            }.padding(20)
        }.background(Color.walkPaper).navigationTitle("Spaziergang").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Spaziergang beenden und speichern?", isPresented: $confirmFinish, titleVisibility: .visible) { Button("Beenden & speichern") { completedID = model.finishWalk() }; Button("Weitergehen", role: .cancel) {} }
            .navigationDestination(item: $completedID) { id in WalkDetailView(id: id) }
    }
}

struct WalkRow: View {
    var walk: Walk
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "figure.walk").font(.system(size: 23)).frame(width: 45, height: 48).background(Color.walkGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(Color.walkGreen)
            VStack(alignment: .leading, spacing: 6) { Text(walk.title).font(.system(size: 15, weight: .semibold)); Text(walk.startedAt.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 10)).foregroundStyle(.secondary); Text("\((walk.distance / 1000).formatted(.number.precision(.fractionLength(2)))) km · \(Display.duration(walk.activeDuration())) · \(walk.hasSteps ? walk.knownSteps.formatted() : "—") Schritte").font(.system(size: 11)).foregroundStyle(.secondary) }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(.secondary)
        }.padding(18).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct WalkDetailView: View {
    @EnvironmentObject var model: WalkModel
    @Environment(\.dismiss) private var dismiss
    let id: UUID
    @State private var title = ""
    @State private var notes = ""
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var confirmDelete = false
    @State private var fitToken = UUID()
    private var walk: Walk? { model.archive.walks.first { $0.id == id } }
    var body: some View {
        ScrollView {
            if let walk {
                VStack(alignment: .leading, spacing: 20) {
                    Eyebrow(text: walk.startedAt.formatted(date: .complete, time: .shortened))
                    RouteMap(segments: walk.segments, fitToken: fitToken).frame(height: 300).clipShape(RoundedRectangle(cornerRadius: 23))
                    Panel {
                        HStack { Metric(title: "Strecke", value: (walk.distance / 1000).formatted(.number.precision(.fractionLength(2))), unit: "km", symbol: "location"); Metric(title: "Aktive Zeit", value: Display.duration(walk.activeDuration()), unit: "", symbol: "stopwatch") }
                        Divider()
                        HStack { Metric(title: "Apple-Schritte", value: walk.hasSteps ? walk.knownSteps.formatted() : "—", unit: "", symbol: "shoeprints.fill"); Metric(title: "Ø Tempo", value: Display.pace(walk.pace()), unit: "min/km", symbol: "speedometer") }
                        if walk.hasIncompleteSteps { Text("Mindestens ein Schrittintervall ist noch offen.").font(.system(size: 11)).foregroundStyle(.secondary) }
                        Button("Schritte bei Apple erneut abfragen") { model.retryStepQuery(walk: walk) }.font(.system(size: 12))
                    }
                    Panel {
                        Text("Dein Eintrag").font(.headline)
                        TextField("Name deines Spaziergangs", text: $title).textFieldStyle(.roundedBorder)
                        TextField("Notizen: Wie war dein Spaziergang?", text: $notes, axis: .vertical).lineLimit(3...8).textFieldStyle(.roundedBorder)
                        Button("Änderungen speichern") { model.updateWalk(id: id, title: title, notes: notes) }.font(.system(size: 13, weight: .semibold))
                    }
                    if !walk.events.isEmpty {
                        Panel { Text("Aufzeichnungsprotokoll").font(.headline); ForEach(walk.events) { event in VStack(alignment: .leading, spacing: 4) { Text(event.date.formatted(date: .omitted, time: .shortened)).font(.system(size: 10, weight: .semibold)); Text(event.message).font(.system(size: 12)).foregroundStyle(.secondary) } } }
                    }
                    MainButton(title: "Route als GPX teilen", symbol: "square.and.arrow.up") {
                        do { let url = FileManager.default.temporaryDirectory.appendingPathComponent("Dayform-Walk-\(id.uuidString).gpx"); try walk.gpx.write(to: url, atomically: true, encoding: .utf8); shareURL = url; showShare = true }
                        catch { model.errorMessage = error.localizedDescription }
                    }
                    Text("GPX enthält deine genaue Route. Teile die Datei nur bewusst.").font(.system(size: 10)).foregroundStyle(.secondary)
                    Button("Spaziergang löschen", role: .destructive) { confirmDelete = true }.font(.system(size: 12)).frame(maxWidth: .infinity)
                }.padding(20).onAppear { title = walk.title; notes = walk.notes }
            }
        }.background(Color.walkPaper).navigationTitle("Dein Spaziergang").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShare) { if let shareURL { ShareSheet(items: [shareURL]) } }
            .confirmationDialog("Diesen Spaziergang endgültig löschen?", isPresented: $confirmDelete, titleVisibility: .visible) { Button("Löschen", role: .destructive) { model.removeWalk(id: id); dismiss() }; Button("Abbrechen", role: .cancel) {} }
    }
}

struct DevelopmentView: View {
    @EnvironmentObject var model: WalkModel
    private var days: [DaySteps] { let start = Calendar.current.startOfDay(for: Date()); return (0..<7).reversed().compactMap { offset in guard let date = Calendar.current.date(byAdding: .day, value: -offset, to: start) else { return nil }; return model.archive.days.first { Calendar.current.isDate($0.date, inSameDayAs: date) } ?? DaySteps(date: date) } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Eyebrow(text: "Deine letzten sieben Tage")
                Text("Schritt für Schritt.\nDein eigener Rhythmus.").font(.system(size: 30, weight: .semibold, design: .rounded)).tracking(-1)
                Panel {
                    Text("Tägliche Schritte").font(.headline)
                    Chart(days) { day in
                        if let steps = day.steps { BarMark(x: .value("Tag", day.date, unit: .day), y: .value("Schritte", steps)).foregroundStyle(Color.walkGreen.gradient).cornerRadius(4) }
                    }.chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true) } }.frame(height: 200)
                    Text("System-Schritte von diesem iPhone. Fehlende Werte sind keine Nullwerte. Die letzten sieben Tage können über Core Motion nachgeladen werden; bereits gespeicherte Tage bleiben im Journal.").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Panel {
                    ForEach(days.reversed()) { day in HStack { Text(day.date.formatted(.dateTime.weekday(.wide).day().month())); Spacer(); Text(day.steps.map { $0.formatted() } ?? "—").fontWeight(.semibold) }.font(.system(size: 13)) }
                }
                Panel {
                    HStack { Metric(title: "Spaziergänge", value: model.completedWalks.count.formatted(), unit: "", symbol: "figure.walk"); Metric(title: "GPS-Gesamtstrecke", value: (model.completedWalks.reduce(0) { $0 + $1.distance } / 1000).formatted(.number.precision(.fractionLength(1))), unit: "km", symbol: "map") }
                }
            }.padding(20)
        }.background(Color.walkPaper).navigationTitle("Dein Verlauf").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { model.refreshMotion() } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Schrittverlauf aktualisieren") } }
    }
}

struct SettingsView: View {
    @EnvironmentObject var model: WalkModel
    @State private var name = ""
    @State private var goal = 8000
    @State private var showExport = false
    @State private var backupDocument = BackupDocument(data: Data())
    @State private var showImport = false
    @State private var importData: Data?
    @State private var confirmImport = false
    var body: some View {
        Form {
            Section("Dein Tagesziel") {
                TextField("Dein Name (optional)", text: $name)
                Stepper("\(goal.formatted()) Schritte", value: $goal, in: 500...100_000, step: 500)
                Button("Ziel speichern") { model.updatePreferences(name: name, goal: goal) }
            }
            Section("Zugriff & Aufzeichnung") {
                Label(model.motionAuthorized ? "Bewegung & Fitness freigegeben" : "Bewegung & Fitness fehlt", systemImage: model.motionAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle")
                Button("Schrittzugriff aktivieren", action: model.enableMotion)
                Label(model.locationAuthorized ? "Standort freigegeben" : "Standort wird beim Start angefragt", systemImage: "location")
                Button("iPhone-Einstellungen öffnen") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
                Text("Für die Route: genauer Standort und Start des Spaziergangs bei geöffneter App. Während des Spaziergangs darfst du den Bildschirm sperren. Ein blauer Standortindikator kann sichtbar sein. GPS endet bei Pause oder Beenden. Wegwischen, Neustart und Systemabbrüche können Aufzeichnungen unterbrechen.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Datensicherung") {
                Button("Journal als JSON exportieren") { do { backupDocument = BackupDocument(data: try model.backup()); showExport = true } catch { model.errorMessage = error.localizedDescription } }
                Button("JSON-Backup importieren") { showImport = true }
                Text("Deine Schritte und Routen werden lokal gespeichert. Ein Backup enthält genaue Bewegungsdaten. Die App überträgt dein Journal nicht an einen eigenen Server. Apple Maps lädt Karten über Apple.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Was die Werte bedeuten") {
                Text("Schritte kommen von Apples CMPedometer, nicht aus GPS oder einer selbst gebauten Schüttelerkennung. Das iPhone muss mitgetragen werden. Es sind iPhone-Schritte, keine mit der Apple Watch zusammengeführte Health-Gesamtsumme. Apple liefert Schrittupdates teilweise verzögert.")
                Text("GPS-Strecke und Core-Motion-Tagesstrecke können voneinander abweichen. Ungenaue GPS-Punkte und unmögliche Sprünge werden verworfen. Empfangslücken werden auf der Karte getrennt angezeigt. Bei Pausen werden weder Zeit noch Schritte zum Spaziergang gerechnet; deine Tageswerte zählen weiter.")
            }.font(.footnote)
            Section("Kostenlose Installation") {
                Text("Die App benötigt keinen API-Key und keine bezahlte Apple-Developer-Mitgliedschaft. Bei kostenloser Signierung über AltStore läuft das Profil nach sieben Tagen ab. Rechtzeitig über AltServer erneuern und die App dabei nicht löschen, damit lokale Daten erhalten bleiben.").font(.footnote)
                Link("AltStore Classic: Windows-Anleitung", destination: URL(string: "https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows")!)
            }
            Section { Text("Dayform Walk 3.0 · Deine lebendige Abenteuerwelt.").font(.footnote).foregroundStyle(.secondary) }
        }.navigationTitle("Deine Einstellungen")
            .onAppear { name = model.preferences.name; goal = model.preferences.dailyGoal }
            .fileExporter(isPresented: $showExport, document: backupDocument, contentType: .json, defaultFilename: "Dayform-Walk-Backup") { result in if case .failure(let error) = result { model.errorMessage = error.localizedDescription } }
            .fileImporter(isPresented: $showImport, allowedContentTypes: [.json]) { result in
                do { let url = try result.get(); let granted = url.startAccessingSecurityScopedResource(); defer { if granted { url.stopAccessingSecurityScopedResource() } }; let data = try Data(contentsOf: url); _ = try Persistence.decode(data); importData = data; confirmImport = true }
                catch { model.errorMessage = error.localizedDescription }
            }
            .confirmationDialog("Backup ersetzt dein lokales Journal und deine Einstellungen. Fortfahren?", isPresented: $confirmImport, titleVisibility: .visible) { Button("Backup wiederherstellen", role: .destructive) { if let importData { do { try model.restore(importData) } catch { model.errorMessage = error.localizedDescription } } }; Button("Abbrechen", role: .cancel) { importData = nil } }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
