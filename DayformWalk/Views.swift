import SwiftUI
import Charts
import UniformTypeIdentifiers

extension Color {
    static let walkGreen = Color(red: 0.23, green: 0.37, blue: 0.27)
    static let walkLime = Color(red: 0.85, green: 0.94, blue: 0.57)
    static let walkPaper = Color(red: 0.96, green: 0.96, blue: 0.93)
    static let walkInk = Color(red: 0.13, green: 0.17, blue: 0.14)
    static let walkOrange = Color(red: 0.86, green: 0.44, blue: 0.29)
}

struct RootView: View {
    @EnvironmentObject var model: WalkModel
    var body: some View {
        TabView(selection: $model.selectedTab) {
            NavigationStack { TodayView() }.tabItem { Label("Heute", systemImage: "sun.max") }.tag(0)
            NavigationStack { WalksView() }.tabItem { Label("Spaziergang", systemImage: "figure.walk") }.tag(1)
            NavigationStack { DevelopmentView() }.tabItem { Label("Verlauf", systemImage: "chart.bar.xaxis") }.tag(2)
            NavigationStack { SettingsView() }.tabItem { Label("Einstellungen", systemImage: "slider.horizontal.3") }.tag(3)
        }
        .alert("Dayform Walk", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
            Button("iPhone-Einstellungen") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
        } message: { Text(model.errorMessage ?? "") }
        .preferredColorScheme(.light)
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { VStack(alignment: .leading, spacing: 18) { content }.padding(22).frame(maxWidth: .infinity, alignment: .leading).background(.white, in: RoundedRectangle(cornerRadius: 23)) }
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
        Button(action: action) { Label(title, systemImage: symbol).font(.system(size: 15, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 18).background(color, in: RoundedRectangle(cornerRadius: 15)).foregroundStyle(.white) }
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

struct TodayView: View {
    @EnvironmentObject var model: WalkModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 9) { Eyebrow(text: "Dein Tag in Bewegung"); Text(model.preferences.name.isEmpty ? "Ein guter Tag\nfür ein paar Schritte." : "Hallo, \(model.preferences.name).\nLass uns rausgehen.").font(.system(size: 31, weight: .semibold, design: .rounded)).tracking(-1) }
                    Spacer(minLength: 0)
                    Image(systemName: "figure.walk.circle.fill").font(.system(size: 38)).foregroundStyle(Color.walkGreen)
                }
                HStack(spacing: 20) {
                    ZStack {
                        Circle().stroke(Color.walkGreen.opacity(0.12), lineWidth: 12)
                        Circle().trim(from: 0, to: min(1, CGFloat(model.todaySteps ?? 0) / CGFloat(model.preferences.dailyGoal))).stroke(Color.walkGreen, style: StrokeStyle(lineWidth: 12, lineCap: .round)).rotationEffect(.degrees(-90))
                        VStack(spacing: 5) { Image(systemName: "shoeprints.fill").font(.system(size: 18)).foregroundStyle(Color.walkGreen); Text(model.todaySteps.map { $0.formatted(.number.locale(Locale(identifier: "de_DE"))) } ?? "—").font(.system(size: 32, weight: .semibold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1); Text("Schritte heute").font(.system(size: 10)).foregroundStyle(.secondary) }
                    }.frame(width: 155, height: 155)
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: "Dein Tagesziel")
                        Text(model.preferences.dailyGoal.formatted(.number.locale(Locale(identifier: "de_DE")))).font(.system(size: 29, weight: .medium, design: .rounded))
                        Text("Von dir festgelegt.").font(.system(size: 11)).foregroundStyle(.secondary)
                        if let steps = model.todaySteps { Text(steps >= model.preferences.dailyGoal ? "Ziel erreicht ✓" : "Noch \(max(0, model.preferences.dailyGoal - steps).formatted()) Schritte").font(.system(size: 11, weight: .medium)).foregroundStyle(Color.walkGreen) }
                    }
                }.padding(23).frame(maxWidth: .infinity).background(Color.walkGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 25))
                Panel {
                    HStack {
                        Metric(title: "Tagesstrecke", value: model.todayDistance.map { ($0 / 1000).formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "de_DE"))) } ?? "—", unit: "km", symbol: "point.topleft.down.to.point.bottomright.curvepath")
                        Divider().frame(height: 45)
                        Metric(title: "Etagen aufwärts", value: model.todayFloors.map(String.init) ?? "—", unit: "", symbol: "stairs")
                    }
                    Text("\(model.motionStatus). Tageswerte kommen aus Core Motion und umfassen die mit dem iPhone erfasste Bewegung – auch außerhalb deiner Spaziergänge.").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                if !model.motionAuthorized {
                    Panel {
                        Label("Dein iPhone zählt mit.", systemImage: "sensor.fill").font(.headline)
                        Text("Erlaube Bewegung & Fitness. Dann liest die App die System-Schritte deines iPhones aus – auch aus der Hosentasche. Dafür muss kein GPS den ganzen Tag laufen.").font(.system(size: 13)).foregroundStyle(.secondary)
                        MainButton(title: "Apple-Schrittzähler aktivieren", symbol: "shoeprints.fill", action: model.enableMotion)
                    }
                }
                Panel {
                    HStack { Text("Zeit für draußen.").font(.system(size: 21, weight: .semibold, design: .rounded)); Spacer(); Image(systemName: "arrow.up.right").foregroundStyle(Color.walkGreen) }
                    Text("Starte deinen Spaziergang. Deine Route, Strecke, Zeit und Schritte bleiben zusammen.").font(.system(size: 13)).foregroundStyle(.secondary)
                    MainButton(title: model.activeWalk == nil ? "Spaziergang starten" : model.activeWalk?.status == .paused ? "Spaziergang fortsetzen" : "Zum laufenden Spaziergang", symbol: "figure.walk") { model.requestStart() }
                    Text("Während eines laufenden Spaziergangs bleibt GPS auch bei gesperrtem Bildschirm aktiv. Die App nicht wegwischen.").font(.system(size: 10)).foregroundStyle(.secondary)
                }
                HStack { Image(systemName: "lock.shield"); Text("Dein Journal liegt auf deinem iPhone.") }.font(.system(size: 10)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }.padding(20)
        }.background(Color.walkPaper).navigationTitle("dayform walk").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { model.refreshMotion() } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Tageswerte aktualisieren") } }
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
        }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 18))
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
            Section { Text("Dayform Walk 1.0 · iPhone · Core Motion + Core Location").font(.footnote).foregroundStyle(.secondary) }
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
