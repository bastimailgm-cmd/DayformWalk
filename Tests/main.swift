import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError("FEHLER: \(message)") }
}
let start = Date(timeIntervalSince1970: 1_790_000_000)
func point(_ lat: Double, _ lon: Double, _ seconds: Double, accuracy: Double = 5) -> TrackPoint { TrackPoint(latitude: lat, longitude: lon, altitude: nil, accuracy: accuracy, timestamp: start.addingTimeInterval(seconds)) }
let a = point(52, 13, 0)
let b = point(52.0001, 13, 10)
expect(abs(a.distance(to: b) - 11.1195) < 0.1, "Geodätische Distanz")
var route = RouteFilter()
if case .first = route.accept(a, now: start) {} else { fatalError("Erster Punkt") }
if case .stationary = route.accept(point(52.000001, 13, 2), now: start.addingTimeInterval(2)) {} else { fatalError("GPS-Rauschen") }
if case .append = route.accept(b, now: start.addingTimeInterval(10)) {} else { fatalError("Plausible Bewegung") }
if case .rejected = route.accept(point(53, 13, 11), now: start.addingTimeInterval(11)) {} else { fatalError("Unmöglicher Sprung") }
if case .rejected = route.accept(point(52, 13, 12, accuracy: 100), now: start.addingTimeInterval(12)) {} else { fatalError("Schlechte Genauigkeit") }
if case .gap = route.accept(point(53, 13, 100), now: start.addingTimeInterval(100)) {} else { fatalError("GPS-Lücke getrennt") }
var walk = Walk(now: start)
walk.segments = [RouteSegment(points: [a, b]), RouteSegment(points: [point(53, 13, 100), point(53.0001, 13, 110)])]
expect(walk.distance < 23, "Lücke nicht als gerade Strecke ergänzen")
walk.pause(at: start.addingTimeInterval(60))
walk.resume(at: start.addingTimeInterval(180))
walk.finish(at: start.addingTimeInterval(240))
expect(walk.activeDuration(at: start.addingTimeInterval(1000)) == 120, "Pausen nicht mitzählen")
expect(!walk.hasSteps, "Unbekannte Schritte nicht als gemessene null ausgeben")
walk.intervals[0].steps = 100
walk.intervals[1].steps = 110
expect(walk.knownSteps == 210, "Getrennte Intervalle summieren")
expect(!walk.hasIncompleteSteps, "Schrittintervalle vollständig")
walk.title = "<Weg & Runde>"
expect(walk.gpx.contains("&lt;Weg &amp; Runde&gt;"), "GPX-Titel sicher maskieren")
expect(walk.gpx.components(separatedBy: "<trkseg>").count == 3, "GPX-Segmente erhalten")
var archive = Archive()
archive.walks = [walk]
_ = try archive.validated()
let encoder = JSONEncoder()
let decoded = try JSONDecoder().decode(Archive.self, from: encoder.encode(archive))
expect(decoded.walks[0] == walk, "Backup-Roundtrip")
archive.walks.append(walk)
do { _ = try archive.validated(); fatalError("Doppelte IDs sollten abgewiesen werden") } catch {}
expect(Display.duration(3661) == "1:01:01", "Dauerformat")
expect(Display.pace(5.999) == "6:00", "Tempoformat-Rundung")
print("Modelltests bestanden: GPS-Filter, Lücken, Pausen, Schritte, Backup und GPX.")

var island = IslandProgress()
let gameDay = DaySteps(date: start, steps: 6240)
island.sync(days: [gameDay], goal: 6000)
expect(island.shells == 62, "100 Schritte ergeben eine Muschel")
island.sync(days: [gameDay, gameDay], goal: 500)
expect(island.shells == 62 && island.totalSteps == 6240, "Updates und doppelte Tage belohnen nicht doppelt")
island.sync(days: [DaySteps(date: start, steps: 2000)], goal: 500)
expect(island.shells == 62, "Verzögerte kleinere Abfragen nehmen nichts weg")
let missions = island.missions(on: start, walks: [])
expect(missions[1].target == 6000, "Tagesziel der Mission bleibt nach Zieländerung stabil")
expect(island.claim(missions[1].id, on: start, walks: []), "Erreichte Mission abholen")
expect(!island.claim(missions[1].id, on: start, walks: []), "Mission nur einmal belohnen")
expect(!island.claim(missions[2].id, on: start, walks: []), "Nicht erreichte Mission gibt keine Belohnung")
expect(!island.build("garden"), "Bau-Reihenfolge einhalten")
expect(island.build("camp"), "Bezahlbaren Ort bauen")
expect(!island.build("camp"), "Ort nur einmal kaufen")
expect(!island.build("garden"), "Unzureichendes Guthaben blockiert Bau")
expect(island.shells == 57, "Kauf und Bonus korrekt verrechnet")
var gameArchive = Archive()
gameArchive.game = island
let gameDecoded = try JSONDecoder().decode(Archive.self, from: encoder.encode(gameArchive))
expect(gameDecoded.game == island, "Spielstand bleibt im Backup erhalten")
_ = try gameDecoded.validated()
expect(decoded.game == nil, "Backups von Version 1 bleiben lesbar")
var invalidGame = island
invalidGame.spent = 999999
expect(!invalidGame.isValid, "Negatives Guthaben aus Backup abweisen")
let nextDay = start.addingTimeInterval(86400)
expect(!island.claim(missions[1].id, on: nextDay, walks: []), "Abgelaufene Mission nicht am Folgetag abholen")
var eligible = Walk(now: start)
eligible.finish(at: start.addingTimeInterval(301))
let walkMission = island.missions(on: start, walks: [eligible])[2]
expect(island.claim(walkMission.id, on: start, walks: [eligible]), "Gespeicherte Runde ab fünf Minuten belohnen")
expect(!island.claim(walkMission.id, on: start, walks: [eligible]), "Runde nicht erneut belohnen")
print("Spieltests bestanden: Migration, Guthaben, idempotente Schritte, Missionen, Käufe und Backups.")
