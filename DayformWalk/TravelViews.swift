import SwiftUI
import MapKit

struct TravelMapView: View {
    @EnvironmentObject var model: WalkModel
    @Environment(\.scenePhase) private var phase
    @StateObject private var explorer = TravelExplorer()
    @State private var camera: MapCameraPosition = .automatic
    @State private var centered = false
    @State private var minutes = 20
    @State private var material = "all"
    @State private var prompt = "Eine ruhige Runde mit kleinen Entdeckungen"
    @State private var showAI = false
    @State private var pendingPlan: TravelPlan?
    @State private var confirmPlan = false
    private var candidates: [TravelPlace] {
        model.travel.places.filter { !model.travel.blocked.contains($0.id) && abs($0.verifiedAt.timeIntervalSinceNow) <= 86400 }
    }
    private var ordered: [TravelPlace] {
        candidates.sorted { a, b in
            let aPreferred = a.material.rawValue == material, bPreferred = b.material.rawValue == material
            return aPreferred != bPreferred ? aPreferred : a.walkingSeconds < b.walkingSeconds
        }
    }
    private var mapPlaces: [TravelPlace] {
        var places = candidates
        var active = model.travel.plan?.stops ?? []
        if let delivery = model.travel.delivery, !delivery.delivered { active += [delivery.pickup, delivery.destination] }
        for place in active where !places.contains(where: { $0.id == place.id }) && !model.travel.blocked.contains(place.id) { places.append(place) }
        return places
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack { VStack(alignment: .leading, spacing: 6) { Eyebrow(text: "DEINE UMGEBUNG WIRD ZUM ABENTEUER"); Text("Draußen wartet mehr.").font(.system(size: 28, weight: .bold, design: .rounded)) }; Spacer() }
                map
                NavigationLink { TravelCollectionView(explorer: explorer) } label: {
                    HStack(spacing: 14) { Image(systemName: "backpack.fill").font(.title2).foregroundStyle(Color.walkGreen); VStack(alignment: .leading, spacing: 4) { Text("Aufträge & Entdeckerpass").font(.headline); Text("\(model.travel.visits.count) Orte · \(model.travel.stock.values.reduce(0,+)) Materialien").font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right") }
                        .padding(18).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }.buttonStyle(.plain)
                planner
                if let plan = model.travel.plan { planCard(plan) }
                if let surprise = candidates.first(where: { $0.id == model.travel.surpriseID }) { surpriseCard(surprise) }
                if let place = explorer.selected, !model.travel.blocked.contains(place.id) { placeCard(place) }
                if !candidates.isEmpty { placesList }
                Text(model.travel.lastReward).font(.callout).foregroundStyle(Color.walkGreen).padding(.vertical, 6).accessibilityAddTraits(.updatesFrequently)
                Text("Spiel-Fundstücke sind virtuell. Karten und Wege können veraltet sein. Bleibe auf zugänglichen öffentlichen Wegen; du musst keine Gebäude betreten. Unpassende Ziele kannst du ohne Verlust deiner bisherigen Funde ausblenden.").font(.caption).foregroundStyle(.secondary)
                Text("Standort und Wegpunkte gehen bei der Suche an Apple Maps; bei wenigen Treffern geht der Suchmittelpunkt zusätzlich an den OpenStreetMap-Overpass-Dienst. Gespeicherte Ziele, Ortsstempel und Routen liegen lokal und sind in deinem JSON-Backup enthalten.").font(.caption).foregroundStyle(.secondary)
                Link("Weitere Ziele: © OpenStreetMap-Mitwirkende · ODbL", destination: URL(string: "https://www.openstreetmap.org/copyright")!).font(.caption)
            }.padding(20)
        }.background(Color.walkPaper).navigationTitle("Entdecken").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { NavigationLink { GroqSettingsView() } label: { Image(systemName: "sparkles") }.accessibilityLabel("KI-Einstellungen") } }
        .onAppear { explorer.appear(); if let coordinate = explorer.coordinate, !centered { centered = true; camera = .region(MKCoordinateRegion(center: coordinate.cl, latitudinalMeters: 1800, longitudinalMeters: 1800)) } }
        .onDisappear { explorer.disappear() }
        .onChange(of: phase) { _, phase in if phase == .active { explorer.appear() } else { explorer.disappear() } }
        .onChange(of: explorer.coordinate) { _, coordinate in if let coordinate, !centered { centered = true; camera = .region(MKCoordinateRegion(center: coordinate.cl, latitudinalMeters: 1800, longitudinalMeters: 1800)) } }
        .alert("Karten-Abenteuer", isPresented: Binding(get: { explorer.error != nil }, set: { if !$0 { explorer.error = nil } })) { Button("OK", role: .cancel) {} } message: { Text(explorer.error ?? "") }
        .confirmationDialog("Aktuelles Abenteuer ersetzen? Gesammelte Ortsfunde bleiben erhalten; der Rundenbonus der alten Runde entfällt.", isPresented: $confirmPlan, titleVisibility: .visible) {
            Button("Neue Runde übernehmen") { if let pendingPlan { installPlan(pendingPlan) }; pendingPlan = nil }
            Button("Abbrechen", role: .cancel) { pendingPlan = nil }
        }
    }
    private var map: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $camera) {
                if explorer.userAuthorized { UserAnnotation() }
                ForEach(mapPlaces) { place in
                    Annotation(place.name, coordinate: place.coordinate.cl) {
                        Button { explorer.selected = place } label: {
                            Image(systemName: model.travel.collected(place.id, date: model.now) ? "checkmark" : place.material.symbol)
                                .font(.system(size: 17, weight: .bold)).foregroundStyle(Color.walkPaper).padding(13)
                                .background(explorer.selected?.id == place.id ? Color.walkLime : Color.walkGreen, in: Circle()).overlay { Circle().stroke(.white.opacity(0.9), lineWidth: 2) }.shadow(radius: 5)
                        }.accessibilityLabel("\(place.name), \(place.material.name)")
                    }
                }
                if let plan = model.travel.plan {
                    ForEach(Array(plan.legs.enumerated()), id: \.offset) { _, leg in MapPolyline(coordinates: leg.points.map(\.cl)).stroke(Color.walkGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round)) }
                    Annotation("Rundenstart", coordinate: plan.origin.cl) { Image(systemName: "flag.checkered").padding(8).background(.black.opacity(0.7), in: Circle()) }
                }
                if let delivery = model.travel.delivery, !delivery.delivered { MapPolyline(coordinates: delivery.route.points.map(\.cl)).stroke(.orange, style: StrokeStyle(lineWidth: 4, dash: [6,4])) }
            }.mapControls { MapCompass(); MapScaleView(); MapUserLocationButton() }.mapStyle(.standard(elevation: .flat)).frame(height: 330)
            VStack(alignment: .leading, spacing: 5) {
                Text("\(candidates.count) FUNDSTELLEN").font(.system(size: 10, weight: .bold)).tracking(1.5)
                Text(explorer.status).font(.caption2).lineLimit(2)
            }.padding(12).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16)).padding(12).padding(.trailing, 40).allowsHitTesting(false)
        }.clipShape(RoundedRectangle(cornerRadius: 26)).overlay { RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.15), lineWidth: 1) }
    }
    private var planner: some View {
        Panel {
            Eyebrow(text: "DEIN TEMPO. DEINE RUNDE.")
            Picker("Gehzeit inklusive Rückweg", selection: $minutes) { ForEach([10,20,40], id: \.self) { Text("\($0) Min").tag($0) } }.pickerStyle(.segmented)
            Picker("Bevorzugte Spiel-Fundart", selection: $material) { Text("Alle Funde").tag("all"); ForEach(TravelMaterial.allCases) { Text($0.name).tag($0.rawValue) } }
            Button { discover() } label: { Label(explorer.busy ? "Wird vorbereitet …" : "Umgebung erkunden", systemImage: "location.magnifyingglass").frame(maxWidth: .infinity) }.buttonStyle(AdventureActionStyle()).disabled(explorer.busy || !explorer.fresh)
            if !explorer.fresh {
                Button("Standort aktivieren / aktualisieren") { explorer.appear() }
                Button("iPhone-Einstellungen öffnen") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }.font(.caption)
                Text("Ein frisches GPS-Signal mit höchstens 35 m Ungenauigkeit wird benötigt.").font(.caption).foregroundStyle(.secondary)
            }
            if explorer.busy { ProgressView(explorer.status).font(.caption).tint(.walkGreen) }
            if model.travel.loadedAt != nil { Text("Orte zwischengespeichert · maximal 24 Stunden gültig. Erneute Suche frühestens nach 2 Minuten oder bei Ortswechsel.").font(.caption2).foregroundStyle(.secondary) }
            Button { createPlan(ai: false) } label: { Label("Runde mit Rückweg planen", systemImage: "point.topleft.down.to.point.bottomright.curvepath").frame(maxWidth: .infinity) }.buttonStyle(AdventureActionStyle()).disabled(explorer.busy || !explorer.fresh || candidates.isEmpty)
            DisclosureGroup("Mit Groq zum eigenen Abenteuer", isExpanded: $showAI) {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Was möchtest du erleben?", text: $prompt, axis: .vertical).lineLimit(2...4).textFieldStyle(.roundedBorder).onChange(of: prompt) { _, value in prompt = String(value.prefix(500)) }
                    Text("Dein Text, das Zeitbudget sowie anonyme Fundarten und Gehzeiten gehen an Groq. Gib keine Adresse oder persönlichen Daten in den Text ein. Der Key bleibt im iPhone-Schlüsselbund.").font(.caption).foregroundStyle(.secondary)
                    Button { createPlan(ai: true) } label: { Label("KI-Abenteuer erstellen", systemImage: "sparkles").frame(maxWidth: .infinity) }.buttonStyle(AdventureActionStyle()).disabled(explorer.busy || !explorer.fresh || candidates.isEmpty)
                    NavigationLink("API-Key & Modell einstellen") { GroqSettingsView() }
                }.padding(.top, 10)
            }
        }
    }
    private func planCard(_ plan: TravelPlan) -> some View {
        Panel {
            Eyebrow(text: plan.ai ? "GROQ-GESCHICHTE · ECHTE FUSsROUTEN" : "DEINE ENTDECKERRUNDE")
            Text(plan.title).font(.title2.bold()); Text(plan.story).font(.callout).foregroundStyle(.secondary)
            Label("ca. \(Int(ceil(plan.seconds / 60))) Min · \(Int(plan.meters)) m · mit Rückweg", systemImage: "figure.walk").font(.caption.bold())
            ProgressView(value: Double(plan.completed.count), total: Double(plan.stops.count)).tint(.walkGreen)
            ForEach(Array(plan.stops.enumerated()), id: \.element.id) { index, stop in
                Button { explorer.selected = stop } label: { HStack { Image(systemName: plan.completed.contains(stop.id) ? "checkmark.circle.fill" : "\(index + 1).circle"); Text(stop.name); Spacer(); Image(systemName: "chevron.right") } }.foregroundStyle(.primary)
            }
            Text("\(plan.completed.count)/\(plan.stops.count) Ziele · +20 Muscheln nach allen Stopps. Die Linie enthält den Rückweg; Rückkehr zum Start ist freiwillig. Zeit ist eine Schätzung ohne Pausen.").font(.caption).foregroundStyle(.secondary)
            if plan.completed.count == plan.stops.count {
                Button(plan.rewardClaimed ? "Rundenbonus erhalten" : "Rundenbonus einsammeln") { model.finishTravelPlan() }.buttonStyle(AdventureActionStyle()).disabled(plan.rewardClaimed)
            }
            HStack { Button("Route ansehen") { camera = .automatic }; Spacer(); Button("GPS-Spaziergang starten") { model.requestStart() }.disabled(model.activeWalk != nil) }
            Button("Runde beenden", role: .destructive) { model.changeTravel { travel, _, _ in travel.plan = nil } }.font(.caption)
        }
    }
    private func placeCard(_ place: TravelPlace) -> some View {
        Panel {
            Eyebrow(text: "FUNDSTELLE · \(place.source)")
            Text(place.name).font(.title2.bold())
            Label("+2 \(place.material.name) · +5 Muscheln", systemImage: place.material.symbol)
            if let coordinate = explorer.coordinate { Text("\(Int(coordinate.distance(to: place.coordinate))) m Luftlinie · Sammelradius 55 m").font(.caption).foregroundStyle(.secondary) }
            Text("Fußroute bei der Suche verfügbar. Eingang, Öffnungszeiten und Zugang vor Ort prüfen; kein Eintritt nötig.").font(.caption).foregroundStyle(.secondary)
            Button(model.travel.collected(place.id, date: model.now) ? "Heute schon eingesammelt" : "Hier einsammeln") { if let fix = explorer.fix { model.collectTravel(place, fix: fix) } }.buttonStyle(AdventureActionStyle()).disabled(explorer.busy || !explorer.canCollect(place) || model.travel.collected(place.id, date: model.now))
            HStack { Button("Fußweg in Apple Karten") { TravelMapService.navigate(place) }; Spacer(); Button("Schließen") { explorer.selected = nil } }.font(.caption)
            if let destination = candidates.first(where: { $0.id != place.id && !model.travel.collected($0.id, date: model.now) }), model.travel.delivery == nil || model.travel.delivery?.delivered == true {
                Button { startDelivery(pickup: place, destination: destination) } label: { Label("Lieferung nach \(destination.name) abholen", systemImage: "shippingbox") }.font(.caption).disabled(explorer.busy || !explorer.canCollect(place))
            }
            Button("Ziel unzugänglich · ausblenden", role: .destructive) { model.changeTravel { travel, _, _ in travel.block(place.id) }; explorer.selected = nil }.font(.caption)
        }
    }
    private var placesList: some View {
        Panel {
            HStack { Text("In deiner Nähe").font(.headline); Spacer(); Text("Spiel-Fundarten").font(.caption).foregroundStyle(.secondary) }
            ForEach(candidates) { place in
                Button { explorer.selected = place; camera = .region(MKCoordinateRegion(center: place.coordinate.cl, latitudinalMeters: 650, longitudinalMeters: 650)) } label: {
                    HStack(spacing: 12) { Image(systemName: place.material.symbol).foregroundStyle(Color.walkGreen).frame(width: 24); VStack(alignment: .leading) { Text(place.name).font(.subheadline.bold()); Text("ca. \(Int(ceil(place.walkingSeconds / 60))) Min ab letztem Suchpunkt · \(place.material.name)").font(.caption2).foregroundStyle(.secondary) }; Spacer(); Image(systemName: model.travel.collected(place.id, date: model.now) ? "checkmark.circle.fill" : "chevron.right").foregroundStyle(Color.walkGreen) }
                }.buttonStyle(.plain)
            }
            Button("Überraschungsfund suchen") { findSurprise() }.disabled(explorer.busy || !explorer.fresh)
        }
    }
    private func surpriseCard(_ place: TravelPlace) -> some View {
        Panel {
            Eyebrow(text: "FREIWILLIGER BONUSFUND")
            Text(place.name).font(.headline)
            Text("+10 Extra-Muscheln bei deinem nächsten Fund hier. Keine Eile, kein Countdown.").font(.callout)
            if let leg = explorer.surpriseLeg { Text("ca. \(Int(ceil(leg.seconds / 60))) Min für Hin- und Rückweg vom letzten Suchpunkt; kein Abzug vom Rundenbudget.").font(.caption).foregroundStyle(.secondary) }
            else { Text("Zusatzzeit nach dem nächsten Suchen erneut verfügbar. Du kannst den Fund jederzeit überspringen.").font(.caption).foregroundStyle(.secondary) }
            HStack { Button("Auf der Karte zeigen") { explorer.selected = place }; Spacer(); Button("Überspringen") { model.changeTravel { travel, _, _ in travel.surpriseID = nil }; explorer.surpriseLeg = nil } }
        }
    }
    private func discover() {
        guard let origin = explorer.coordinate, explorer.fresh else { return }
        if let date = model.travel.loadedAt, Date().timeIntervalSince(date) < 120, let center = model.travel.searchCenter, center.distance(to: origin) < 1000 { explorer.error = "Die letzte Suche liegt weniger als zwei Minuten zurück. Nutze die vorhandenen Ziele oder warte kurz."; return }
        explorer.run {
            let places = try await TravelMapService.discover(at: origin, blocked: model.travel.blocked) { explorer.status = $0 }
            try Task.checkCancellation()
            model.changeTravel { travel, _, _ in travel.places = places; travel.searchCenter = origin; travel.loadedAt = Date() }
            explorer.status = "\(places.count) Ziele mit Fußroute gefunden"; camera = .automatic
        }
    }
    private func createPlan(ai: Bool) {
        guard let origin = explorer.coordinate, explorer.fresh else { return }
        let pool = ordered.filter { !model.travel.collected($0.id, date: model.now) }
        guard !pool.isEmpty else { explorer.error = "Heute hast du diese Ziele schon gesammelt. Suche neue Ziele oder starte morgen eine neue Runde."; return }
        explorer.run {
            explorer.status = ai ? "Groq entwirft deine Geschichte …" : "Runde mit Rückweg berechnen …"
            let story: TravelAIStory
            if ai { story = try await GroqPlanner.story(prompt: prompt, minutes: minutes, places: pool, model: UserDefaults.standard.string(forKey: "groq.model") ?? "openai/gpt-oss-20b") }
            else { story = TravelAIStory(title: "Kleine Wege, große Entdeckungen", story: "Sammle neue Ortsstempel und virtuelle Materialien. Dein Begleiter freut sich über jeden Halt. Gehe in deinem Tempo und überspringe alles, was vor Ort nicht passt.", stopIDs: Array(pool.prefix(3).map(\.id))) }
            let chosen = story.stopIDs.compactMap { id in pool.first { $0.id == id } }
            let plan = try await TravelMapService.plan(from: origin, places: chosen, minutes: minutes, title: story.title, story: story.story, ai: ai)
            try Task.checkCancellation()
            if let old = model.travel.plan, !old.rewardClaimed { pendingPlan = plan; confirmPlan = true } else { installPlan(plan) }
            explorer.status = "Fußrunde inklusive Rückweg berechnet"
        }
    }
    private func installPlan(_ plan: TravelPlan) { model.changeTravel { travel, _, _ in travel.plan = plan }; camera = .automatic }
    private func findSurprise() {
        guard let origin = explorer.coordinate, explorer.fresh else { return }
        let options = candidates.filter { place in !model.travel.collected(place.id, date: model.now) && !(model.travel.plan?.stops.contains(where: { $0.id == place.id }) ?? false) }
        // Only choose existing, route-checked places close to the actual user position.
        let eligible = options.sorted { origin.distance(to: $0.coordinate) < origin.distance(to: $1.coordinate) }
        guard let place = eligible.first, origin.distance(to: place.coordinate) <= 350 else { explorer.error = "Gerade liegt kein zusätzlicher Fund in deiner Nähe. Es wurde kein Ziel erfunden."; return }
        explorer.run {
            let route = try await TravelMapService.leg(from: origin, to: place.coordinate)
            let returnRoute = try await TravelMapService.leg(from: place.coordinate, to: origin)
            guard route.meters <= 500 else { throw TravelError.noRoute }
            try Task.checkCancellation(); explorer.surpriseLeg = TravelLeg(points: route.points + returnRoute.points, meters: route.meters + returnRoute.meters, seconds: route.seconds + returnRoute.seconds)
            model.changeTravel { travel, _, _ in travel.surpriseID = place.id }
        }
    }
    private func startDelivery(pickup: TravelPlace, destination: TravelPlace) {
        explorer.run {
            let route = try await TravelMapService.leg(from: pickup.coordinate, to: destination.coordinate)
            guard let fix = explorer.fix, explorer.canCollect(pickup) else { throw TravelError.noRoute }
            var destination = destination; destination.verifiedAt = Date()
            model.beginDelivery(pickup: pickup, destination: destination, route: route, fix: fix)
        }
    }
}

struct TravelCollectionView: View {
    @EnvironmentObject var model: WalkModel
    @ObservedObject var explorer: TravelExplorer
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Jeder Weg hinterlässt etwas.").font(.system(size: 28, weight: .bold, design: .rounded))
                Panel {
                    Eyebrow(text: "DEIN MATERIALBEUTEL")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 18) { ForEach(TravelMaterial.allCases) { material in Label("\(model.travel.stock[material.rawValue, default: 0]) \(material.name)", systemImage: material.symbol).font(.subheadline.bold()).foregroundStyle(Color.walkGreen) } }
                    Text("Parks und Naturorte geben Samen oder Holz, Kulturorte Steine und Strände Muschelfunde. Es sind virtuelle Spielmaterialien.").font(.caption).foregroundStyle(.secondary)
                }
                if let delivery = model.travel.delivery { deliveryCard(delivery) }
                Panel {
                    Eyebrow(text: "SCHATZKARTEN")
                    Text("Vier Orte. Ein neuer Schatz.").font(.title3.bold())
                    let pieces = min(4, max(0, model.travel.visits.count - model.travel.treasures * 4))
                    HStack { ForEach(0..<4) { index in Image(systemName: index < pieces ? "map.fill" : "map").font(.title).foregroundStyle(index < pieces ? Color.walkGreen : .gray).frame(maxWidth: .infinity) } }
                    Text("\(pieces)/4 verschiedene Orte · Schatz \(model.travel.treasures + 1) · +60 Muscheln und eine Sternenlaterne für die Insel.").font(.caption).foregroundStyle(.secondary)
                    Button("Schatz öffnen") { model.openTravelTreasure() }.buttonStyle(AdventureActionStyle()).disabled(pieces < 4)
                }
                Panel {
                    Eyebrow(text: "BEGLEITER-SPUREN")
                    ForEach(Array(zip(["moss", "pearl", "nova"], [3,6,10])), id: \.0) { id, goal in
                        HStack { Image(systemName: "pawprint.fill").foregroundStyle(Color.walkGreen); VStack(alignment: .leading) { Text(IslandBuddy.all.first { $0.id == id }?.name ?? id).bold(); Text("\(min(goal, model.travel.visits.count))/\(goal) verschiedene Orte").font(.caption).foregroundStyle(.secondary) }; Spacer(); Button(model.travel.trails.contains(id) ? "Erhalten" : "Entdecken") { model.claimTravelTrail(id) }.disabled(model.travel.visits.count < goal || model.travel.trails.contains(id)) }
                    }
                    Text("Am Ende jeder Spur wartet ein Begleiter. Hast du ihn schon, erhältst du stattdessen 20 Muscheln.").font(.caption).foregroundStyle(.secondary)
                }
                Panel {
                    Eyebrow(text: "BAUPROJEKTE FÜR DEINE INSEL")
                    ForEach(TravelBlueprint.all) { blueprint in
                        VStack(alignment: .leading, spacing: 10) {
                            Label(blueprint.name, systemImage: blueprint.symbol).font(.headline)
                            Text(TravelMaterial.allCases.compactMap { material in blueprint.recipe[material].map { "\($0) \(material.name)" } }.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
                            Button(model.travel.crafted.contains(blueprint.id) ? "Auf deiner Insel gebaut" : "Bauen · +\(blueprint.reward) Muscheln") { model.craftTravel(blueprint.id) }.buttonStyle(AdventureActionStyle()).disabled(model.travel.crafted.contains(blueprint.id) || !blueprint.recipe.allSatisfy { model.travel.stock[$0.key.rawValue, default: 0] >= $0.value })
                            Divider()
                        }
                    }
                }
                Panel {
                    Eyebrow(text: "DEIN DORF- & ENTDECKERPASS")
                    Text("\(model.travel.visits.count) bleibende Ortsstempel").font(.title3.bold())
                    if model.travel.visits.isEmpty { Text("Dein erster Stempel wartet an einer Fundstelle. Jeden Ort kannst du täglich einmal sammeln; der Pass zählt ihn dauerhaft einmal.").font(.callout).foregroundStyle(.secondary) }
                    ForEach(model.travel.visits.values.sorted { $0.date > $1.date }.prefix(100)) { visit in HStack { Image(systemName: "seal.fill").foregroundStyle(Color.walkGreen); VStack(alignment: .leading) { Text(visit.name).font(.subheadline.bold()); Text(visit.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary) } } }
                    if model.travel.visits.count > 100 { Text("Die neuesten 100 Stempel werden angezeigt. Alle bleiben im Backup erhalten.").font(.caption) }
                }
                if !model.travel.blocked.isEmpty { Button("\(model.travel.blocked.count) ausgeblendete Ziele wieder zulassen") { model.changeTravel { travel, _, _ in travel.blocked = [] } }; Text("Danach die Umgebung erneut suchen.").font(.caption).foregroundStyle(.secondary) }
            }.padding(20)
        }.background(Color.walkPaper).navigationTitle("Aufträge & Sammlung").navigationBarTitleDisplayMode(.inline)
        .onAppear { explorer.appear() }.onDisappear { explorer.disappear() }
    }
    private func deliveryCard(_ delivery: TravelDelivery) -> some View {
        Panel {
            Eyebrow(text: "DEINE LIEFERUNG")
            Text(delivery.delivered ? "Sicher angekommen!" : "Ein Päckchen für unterwegs").font(.title3.bold())
            Text("\(delivery.pickup.name) → \(delivery.destination.name)").font(.callout)
            let steps = delivery.steps(days: model.island.stepsByDay)
            ProgressView(value: Double(min(steps, delivery.targetSteps)), total: Double(delivery.targetSteps)).tint(.walkGreen)
            Text("\(steps)/\(delivery.targetSteps) neue Schritte · ca. \(Int(ceil(delivery.route.seconds / 60))) Min Fußweg. +30 Muscheln und +2 Holz bei Ankunft.").font(.caption).foregroundStyle(.secondary)
            Button(delivery.delivered ? "Belohnung erhalten" : "Am Ziel abgeben") { if let fix = explorer.fix { model.completeDelivery(fix: fix) } }.buttonStyle(AdventureActionStyle()).disabled(delivery.delivered || steps < delivery.targetSteps || !explorer.canCollect(delivery.destination))
            Button("Ziel in Apple Karten öffnen") { TravelMapService.navigate(delivery.destination) }
            Button(delivery.delivered ? "Lieferung abschließen" : "Lieferung abbrechen", role: .destructive) { model.changeTravel { travel, _, _ in travel.delivery = nil } }.font(.caption)
            Text("Bei altem GPS-Signal oder nach 24 Stunden die Umgebung erneut suchen und eine neue Lieferung starten. Abbruch kostet keine Funde.").font(.caption2).foregroundStyle(.secondary)
        }
    }
}

struct GroqSettingsView: View {
    @State private var key = ""
    @State private var saved = false
    @State private var message = ""
    @AppStorage("groq.model") private var modelName = "openai/gpt-oss-20b"
    var body: some View {
        Form {
            Section("Dein Groq-Zugang") {
                Label(saved ? "Key im iPhone-Schlüsselbund gespeichert" : "Noch kein API-Key gespeichert", systemImage: saved ? "lock.shield.fill" : "key")
                SecureField("Neuen Groq-API-Key eingeben", text: $key).textInputAutocapitalization(.never).autocorrectionDisabled().privacySensitive()
                Button("Sicher speichern") { do { try GroqKeychain.save(key); key = ""; saved = true; message = "Gespeichert. Du kannst jetzt auf der Karte ein KI-Abenteuer erstellen." } catch { message = error.localizedDescription } }.disabled(key.isEmpty)
                if saved { Button("Gespeicherten Key entfernen", role: .destructive) { GroqKeychain.remove(); saved = GroqKeychain.read() != nil; message = saved ? "Entfernen fehlgeschlagen." : "Key entfernt." } }
                if !message.isEmpty { Text(message).font(.callout) }
            }
            Section("Modell mit strikter JSON-Ausgabe") {
                TextField("Modell-ID", text: $modelName).textInputAutocapitalization(.never).autocorrectionDisabled().onChange(of: modelName) { _, value in modelName = String(value.prefix(100)) }
                Text("Standard: openai/gpt-oss-20b. Das Modell muss bei Groq verfügbar sein und Structured Outputs im Strict-Modus unterstützen. Kontolimits können sich ändern.").font(.caption)
            }
            Section("Was verlässt dein iPhone?") {
                Text("Nur nach deinem Tippen auf KI-Abenteuer erstellen: dein Wunschtext, Gehzeitbudget sowie anonyme Zielkennungen mit Spiel-Fundarten und Gehzeiten. Keine Koordinaten, Ortsnamen, Körperdaten oder Schrittverläufe. Schreibe keine persönlichen Angaben in den Wunschtext.")
                Text("Der API-Key wird nur im Authorization-Header direkt an Groq gesendet. Er steht weder im App-Quellcode noch im JSON-Backup. Ortsvorschläge kommen von Apple Maps und ergänzend OpenStreetMap; Fußrouten von Apple Maps. Die KI kann keine eigenen Koordinaten hinzufügen.")
                Text("Ein im Chat veröffentlichter Key sollte bei Groq widerrufen werden. Hier bitte einen neu erzeugten Key eingeben.")
                Link("Groq-Konsole öffnen", destination: URL(string: "https://console.groq.com/keys")!)
                Link("Unterstützte strukturierte Ausgaben", destination: URL(string: "https://console.groq.com/docs/structured-outputs")!)
            }
            Section { Text("Ohne Key bleiben Umgebungssuche, lokale Runden und alle Sammelaufgaben nutzbar. Bei einem KI-Fehler wird kein KI-Ergebnis vorgetäuscht; plane dann eine lokale Runde.") }
        }.navigationTitle("Groq & Datenschutz").onAppear { saved = GroqKeychain.read() != nil }
    }
}

struct TravelProfileView: View {
    var body: some View {
        List {
            Section("Dein Dayform") { NavigationLink { DevelopmentView() } label: { Label("Schritte & Verlauf", systemImage: "chart.bar.xaxis") }; NavigationLink { SettingsView() } label: { Label("Einstellungen & Backup", systemImage: "slider.horizontal.3") }; NavigationLink { GroqSettingsView() } label: { Label("Groq & Datenschutz", systemImage: "sparkles") } }
            Section { Text("Sichere vor jedem App-Update dein JSON-Backup. Installiere mit derselben Apple-ID über die bestehende App, damit deine Insel und Ortsstempel erhalten bleiben.").font(.callout).foregroundStyle(.secondary) }
        }.navigationTitle("Profil")
    }
}
