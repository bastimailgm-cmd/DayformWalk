# Dayform Walk – native iPhone-App

## Version 4.0: Deine Umgebung wird zum Abenteuer

Im neuen Tab **Karte** findest du echte Apple-Maps-Ausflugsorte und ergänzende OpenStreetMap-Dorfziele mit berechneten Fußrouten. Die App fragt keine beliebigen KI-Koordinaten ab. In kleinen Dörfern kann die Kartenabdeckung dünn sein; dann meldet die App fehlende Ziele, statt welche zu erfinden. Apple Maps liefert keine Garantie für öffentlichen Zugang, Öffnungszeiten oder aktuelle Wegsperrungen. Gebäude müssen nicht betreten werden. Ziele lassen sich ausblenden; dadurch entfallen nur betroffene aktive Aufgaben, bereits verdiente Funde bleiben.

1. **Fundstellen:** Parks, Naturorte, Strände, Bibliotheken und Museen im Umkreis von 1,8 km. Bei wenigen Treffern kommen OpenStreetMap-Sitzbänke, Unterstände, Trinkwasserstellen, Aussichts-, Picknick- und Infopunkte hinzu. Explizite private oder gesperrte Ziele werden ausgeschlossen; fehlende Zugangsdaten sind keine Zutrittsgarantie. Bis zu acht Ziele erhalten nach einer Apple-Fußroutenberechnung virtuelle Spiel-Fundarten. Materialien werden nicht real vor Ort entnommen.
2. **10/20/40-Minuten-Runden:** Bis zu drei Stationen mit tatsächlichen Fußrouten und Rückweg. Die Wegezeit umfasst die gesamte Route, ohne Aufenthalte. Zu lange Runden verlieren letzte Stopps, bis das Budget passt. Wenn nichts passt, erscheint ein Fehler. Der Rückweg wird angezeigt, für den Bonus genügt der Besuch aller Stopps.
3. **Schatzkarten:** Vier verschiedene Ortsstempel ergeben je eine Schatzkarte: +60 Muscheln und eine platzierbare Sternenlaterne. Jeder Schatz wird einmal abgeholt.
4. **Begleiter-Spuren:** Nach drei, sechs und zehn verschiedenen Orten werden Moos, Perla und Nova freischaltbar. Bereits vorhandene Begleiter bringen stattdessen 20 Muscheln.
5. **Spielmaterialien:** Jeder Fund gibt zwei Samen, Holz, Steine oder Muschelfunde sowie fünf Spiel-Muscheln. Strand → Muschelfunde, Kulturort → Steine, Nationalpark → Holz. Andere Parks werden stabil zwischen Samen und Holz aufgeteilt. Sitzbänke und Unterstände geben Holz, Trinkwasserstellen Muschelfunde, Aussichtspunkte Steine und sonstige Dorfziele Samen.
6. **Entdeckerpass:** Ein dauerhafter Stempel pro unterschiedlichem Ort, mit Datum. Tägliche Wiederholungsbesuche geben Material; sie erzeugen keine mehrfachen Passstempel.
7. **Lieferungen:** Vor Ort an einer Fundstelle abholen. Die App fragt den aktuellen Core-Motion-Stand ab; erst neue Schritte seit Abholung zählen. Am Ziel mit frischem GPS und mindestens der erforderlichen Schrittzahl abgeben: +30 Muscheln und zwei Holz. Abbruch ist kostenlos. Lieferungen sind höchstens 24 Stunden nach Routenprüfung einlösbar; danach erneut planen.
8. **Bauprojekte:** Gewächshaus, Hafen und Himmelsatelier verbrauchen Materialrezepte, geben einmalig Muscheln und erscheinen als verschiebbare Wahrzeichen auf den Inseln.
9. **Überraschungsfunde:** Ein weiterer vorhandener Ort außerhalb der aktiven Runde, höchstens 350 m Luftlinie bzw. 500 m Fußweg entfernt. Angezeigte Zusatzzeit umfasst Hin- und Rückweg vom Suchpunkt. Optional, ohne Countdown; ein Besuch gibt zehn Extra-Muscheln. Der Zusatzweg ist nicht Teil des ursprünglichen Rundenbudgets.
10. **Groq-Abenteuerplaner:** Wunschtext eingeben und ausdrücklich eine KI-Anfrage starten. Groq darf ausschließlich anonyme IDs bereits gefundener Ziele auswählen. Koordinaten und Ortsnamen bleiben lokal. Die App prüft die ausgewählte Runde danach erneut mit Apple-Fußrouten. KI-Geschichten sind keine Navigationsanweisungen. Bei Fehlern bleibt der lokale Planer nutzbar.

### Groq einrichten und Datenfluss

Unter **Karte → Funkeln-Symbol → Groq & Datenschutz** einen neu erzeugten Key speichern. Ein im Chat veröffentlichter Key sollte in der [Groq-Konsole](https://console.groq.com/keys) widerrufen werden. Die ausgelieferte App enthält keinen Benutzer-Key. Speicherung per iOS Keychain (`WhenUnlockedThisDeviceOnly`), außerhalb von Quellcode, Journal, JSON-Backups und Website. Der Modellname ist separat änderbar; Standard `openai/gpt-oss-20b`. Das gewählte Modell muss [strikte strukturierte Ausgaben](https://console.groq.com/docs/structured-outputs) unterstützen. Groq-Limits und Modellverfügbarkeit hängen vom Konto und Anbieter ab.

Bei einer KI-Anfrage erhält Groq Wunschtext, Zeitbudget und anonyme Zielkennungen mit Spiel-Fundarten und ungefähren Gehzeiten. Keine Namen, Koordinaten, Schritt- oder Körperdaten werden automatisch beigefügt. Persönliche Daten im Wunschtext werden allerdings mitgesendet. Apple Maps erhält für die Umgebungssuche und Routenberechnung den Standort und die Wegpunkte. Bei weniger als vier Apple-Treffern erhält der öffentliche Overpass-Dienst den auf fünf Nachkommastellen begrenzten Suchmittelpunkt. Kartendaten: [© OpenStreetMap-Mitwirkende, ODbL](https://www.openstreetmap.org/copyright). Keine eigene Standort-Cloud. Lokale Ortsstempel, Aufgaben und Routen sind Teil des JSON-Backups. Der Key ist kein Backup-Bestandteil.

### GPS-Grenzen und Verhalten

Ein Fund benötigt höchstens 55 m Abstand, GPS-Genauigkeit bis 35 m, ein höchstens 20 Sekunden altes Signal, Geschwindigkeit bis 4,5 m/s und eine höchstens 24 Stunden alte Routenprüfung. Pro Ort gibt es täglich nur einen Fund. Das soll versehentliche Fern-Funde und doppelte Auszahlungen verhindern; es ist kein manipulationssicheres Wettbewerbssystem. Alle Belohnungen sind virtuelle Spielwerte ohne Geldwert. Karten-GPS läuft nur bei geöffneter Karte/Sammlung. Für Hintergrund-GPS explizit einen Spaziergang starten; passives Tageszählen verwendet weiterhin Core Motion. Die Suche wird bei gleicher Umgebung zwei Minuten zwischengespeichert.

### Update ohne Datenverlust

**Profil → Einstellungen & Backup → JSON sichern**, dann `DayformWalk-4.0.ipa` in AltStore Classic mit derselben Apple-ID über die bestehende App installieren. App-ID bleibt `app.dayform.walk.native`. Vorhandene Backups ohne Kartenfortschritt sind weiterhin lesbar. Nicht vor dem Update deinstallieren. Alle sieben Tage in AltStore erneuern.

### Prüfung und verbleibende Gerätetests

Cloud-Build und Modelltests prüfen Kompilierung, GPS-Grenzen, einmalige Belohnungen, Ortsstempel, Rezepte, Rundenbudget, Lieferungen, KI-ID-Validierung und Backup-Migration. Debug-Simulatorbilder verwenden ausdrücklich markierte Beispieldaten; diese existieren im Release-Build nicht. Reale GPS-Suche, Check-ins, passive Schritte, Hintergrundaufzeichnung und Mehrgeräteverbindungen müssen auf echten iPhones geprüft werden. Eine Live-Groq-Anfrage mit einem gültigen neuen Key bleibt ebenfalls ein Gerätetest; der veröffentlichte Key wurde nicht verwendet.

## Version 3.0: Die lebendige Abenteuerwelt

Öffne **Insel** für den neuen Abenteuer-Hub. Die bisherigen Insel-Funktionen kommen ohne API-Key und ohne bezahltes Apple-Developer-Abo aus.

- **Rucksack:** Alle 2.000 Gesamtschritte entsteht ein Fund. Öffnen bringt eine Dekoration oder acht Muscheln. Fundnummern werden gespeichert; identische Schrittupdates erzeugen keine doppelten Funde. Historisch gespeicherte Schritte zählen mit.
- **Vier Gebiete:** Lumibucht (ab Beginn), Nebelwald (20.000), Korallenbucht (60.000), Sternengipfel (120.000 Schritte). Jedes Gebiet hat fünf baubare Orte. Außerhalb der Lumibucht kosten die Orte das Doppelte. Es gibt keine Käufe mit echtem Geld.
- **Gestalten:** Gebäude und Dekorationen ziehen und loslassen. Positionen und Inventar werden gespeichert. Alternativ bieten VoiceOver-Aktionen Richtungssteuerung. Dekorationen lassen sich wieder einpacken; insgesamt sind 200 gleichzeitig platzierbar.
- **Begleiter:** Lumi, Moos, Perla und Nova. Eier werden bei 6.000, 16.000 bzw. 35.000 Gesamtschritten ausbrütbar. Der ausgewählte Begleiter erhält neue Erfahrung und entwickelt sein Aussehen auf Level 3 und 7 weiter.
- **Geschichtenbuch:** Sechs handgeschriebene Kapitel. Schritte und gespeicherte Spaziergänge öffnen die Geschichte. Jedes Kapitel schenkt einmal ein platzierbares Andenken. Kapitel verfallen nicht.
- **Expeditionen:** Wähle 1.000, 3.000 oder 6.000 neue Schritte für 10, 30 oder 60 zusätzliche Muscheln. GPS wird dafür nicht automatisch gestartet. Eine Expedition darf mehrere Tage dauern. Abbrechen kostet keine vorhandenen Schritte, bringt aber keine Expeditionsbelohnung. Der Schrittstand wird beim Start erneut bei Core Motion abgefragt; nachgeladene ältere Tage zählen nicht rückwirkend hinein.
- **Lebendige Insel:** Die Uhrzeit bestimmt Tag und Nacht. Regen, Schnee, Nebel und Klar sind frei wählbare Spielstimmungen, kein echter Wetterbericht. Bewegungsreduzierung wird für Partikeleffekte respektiert. Dein Begleiter ruht nachts und reagiert auf Spaziergang bzw. Lagerfeuer.
- **Museum:** Dauerhafte Erinnerungsstücke für Schritte, GPS-Kilometer, Runden, Ausbau und Expeditionen. Bereits gespeicherte Meilensteine bleiben beim späteren Löschen einer Route erhalten.
- **Wochenrückblick:** Erzählung aus den letzten sieben Kalendertagen, nur mit gespeicherten Schritten und GPS-Runden. Teilen öffnet Apples Teilen-Dialog; die App versendet nichts selbst.
- **Mit Freunden:** Ein gemeinsamer Leuchtturm für 50.000 Schritte. Eine Person gründet das Projekt, andere treten mit achtstelligem Code bei. Gezählt werden die Schritte seit Beitritt. Alle Mitglieder können die Fertigstellung einmal für 100 Muscheln und eine Laterne abholen.

### Freunde verbinden – wichtig

Der Freunde-Modus verwendet Apples **Multipeer Connectivity**, verschlüsselt mit `.required`. Beide iPhones müssen die App geöffnet haben und sich in der Nähe befinden. Gleiches WLAN, aktiviertes Bluetooth und freigegebenes lokales Netzwerk helfen bei der Erkennung. Auf beiden Geräten unter **Insel → Mit Freunden** den gleichen Code verwenden und die Verbindung starten. Später erneut verbinden, um neue Beiträge abzugleichen. Es werden zufällige Mitgliedskennungen und Schrittbeiträge geteilt, keine Namen, Routen oder Standortkoordinaten. Beiträge werden über Maximalwerte zusammengeführt, nicht bei jeder Übertragung erneut addiert.

Dies ist ein **lokaler Direktabgleich**, kein Cloud-Fernabgleich. Beim Wechsel in den Hintergrund oder Verlassen der Freunde-Seite endet die Verbindung. Bis zu 20 Mitglieder können im gespeicherten Projekt enthalten sein; Apples Sitzung verbindet gleichzeitig maximal acht Geräte. Nach dem Verlassen eines Projekts bleiben bereits an andere Geräte übertragene Beiträge dort erhalten. Es ist ein Spiel mit vertrauten Freunden, kein manipulationsgeschützter Wettbewerb.

### Update und Prüfumfang

Alte Journale und Backups aus Version 1 und 2 bleiben lesbar. Alle neuen Spielstände, Inventare, Positionen und Fortschritte sind im JSON-Backup enthalten. Vor dem Update sichern und die IPA mit derselben Apple-ID über die bestehende App installieren. Nicht vorher deinstallieren.

Der Mac-Build testet zusätzlich Inventar-Verbrauch/Rückgabe, einmalige Funde und Belohnungen, Eier, getrennte Begleiter-Erfahrung, Kapitel-Reihenfolge, Expeditionen, Team-Maximalwert-Abgleich, Schutz des eigenen Beitrags, historische Nachladungen und Wochenzeiträume. Simulatorbilder verwenden Debug-Beispieldaten. GPS/Schritte und der verschlüsselte Freunde-Abgleich auf zwei physischen iPhones müssen nach Installation am Gerät geprüft werden.

## Version 2.0: Deine Schritte. Deine Insel.

Neue dunkle SwiftUI-Oberfläche mit nativen Material-Karten, mintfarbenem Fortschrittsring und eigener Inselansicht. Die Insel und Lumi sind direkt in SwiftUI gezeichnet, ohne externe Bilder, Netzwerkdienste oder KI-Key.

- Je 100 erfasste Tages-Schritte gibt es eine Muschel; Restschritte zählen über Tage hinweg weiter. Schritte aus Spaziergängen werden nicht zusätzlich auf dieselben Tages-Schritte gerechnet.
- Lumi steigt alle 5.000 Schritte ein Level auf und verändert sich auf Level 3 und 7.
- Fünf nacheinander baubare Orte: Basislager (30), Garten (60), Brücke (100), Hütte (150), Sternenwarte (220 Muscheln).
- Tägliche Missionen: 1.000 Schritte (+10), persönliches Tagesziel (+25), gespeicherter Spaziergang ab fünf Minuten (+15). Belohnungen werden bewusst abgeholt, höchstens einmal je Mission und Tag.
- Das Ziel einer Tagesmission bleibt beim ersten Schritteintrag für diesen Tag fest. Nachträgliches Absenken des Ziels erzeugt keine zusätzlichen Belohnungen. Pausen kosten keinen Fortschritt; es gibt keine verlorenen Serien.
- Historisch im Journal gespeicherte Schritte werden beim Update berücksichtigt. Mehrfaches Öffnen, Nachladen oder erneute identische Core-Motion-Abfragen erzeugen keine doppelten Schritt-Belohnungen.
- Spielstand und Käufe sind Teil des JSON-Backups. Alte Backups ohne Spielstand bleiben importierbar. Deinstallation entfernt lokale Daten: vor dem Update sichern und mit derselben Apple-ID über die bestehende App installieren.

Die Simulator-Prüfung nutzt nur im Debug-Build ausdrücklich gestartete Vorschau-Daten (`--preview`, optional `--island`). Der ausgelieferte Release-Build enthält diesen Modus nicht. Simulatorbilder sind Design-Vorschauen mit Beispieldaten und kein Messnachweis.

Deutschsprachige SwiftUI-App für iPhone ab iOS 17. System-Schritte aus Apple Core Motion, GPS-Spaziergänge mit Hintergrundaufzeichnung, Apple-Maps-Routen, Pause/Fortsetzen/Beenden, aktive Zeit, Strecke, Tempo, Sieben-Tage-Verlauf, Notizen, GPX-Export und JSON-Backup. Ein API-Key ist nur für die optionale Groq-Funktion nötig. Kein HealthKit-Entitlement, kein eigenes Backend.

## Windows + iPhone: der Installationsweg

Ein Link im Browser kann diese native App herunterladen, aber nicht die Signierung ersetzen. Auf Windows wird die IPA auf einem Cloud-Mac gebaut. AltStore Classic signiert sie danach mit deiner eigenen Apple-ID und installiert sie auf deinem iPhone. Eine bezahlte Apple-Developer-Mitgliedschaft ist für diesen persönlichen Installationsweg nicht erforderlich.

1. Lade die fertige `DayformWalk-unsigned.ipa` herunter. „Unsigned“ ist beabsichtigt: Die Signatur wird erst über deine eigene Apple-ID erstellt. Du kannst deine Apple-ID und dein Passwort für dich behalten.
2. Installiere **AltServer / AltStore Classic für Windows** nach der offiziellen Anleitung: <https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows>. Verwende die dort verlinkten Apple-Versionen von iTunes und iCloud beziehungsweise die beschriebenen Alternativschritte für iCloud aus dem Microsoft Store.
3. Verbinde dein iPhone per Kabel, bestätige das Vertrauen zum Computer und richte die WLAN-Synchronisierung ein. Wähle in AltServer „Install AltStore“ und dein iPhone. Die Anmeldung mit deiner Apple-ID erledigst du selbst in AltServer.
4. Vertraue deinem Entwicklerprofil unter iPhone-Einstellungen → Allgemein → VPN & Geräteverwaltung. Aktiviere bei Bedarf den Entwicklermodus unter Datenschutz & Sicherheit und folge dem angezeigten Neustartablauf.
5. Speichere die IPA auf dem iPhone in „Dateien“. Öffne AltStore Classic → My Apps → **+** und wähle die IPA, während AltServer auf Windows erreichbar ist. Verwende **Classic** für diesen IPA-Installationsweg.
6. Öffne Dayform Walk und erlaube die unten beschriebenen Zugriffe.

Kostenlose Profile laufen nach sieben Tagen ab. Erneuere sie rechtzeitig in AltStore über „Refresh All“ mit erreichbarem AltServer. Apple begrenzt kostenlose Installationen auf drei aktive Apps einschließlich AltStore. Entferne Dayform Walk zum Erneuern nicht, weil eine Deinstallation lokale Daten entfernen kann. Exportiere regelmäßig ein Backup.

Quellen: [AltStore Windows](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows), [AltStore Erneuern und App-Limit](https://faq.altstore.io/altstore-classic/your-altstore), [Apple Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account).

## Erste Einrichtung

1. Tippe auf **Apple-Schrittzähler aktivieren** und erlaube **Bewegung & Fitness**. Das iPhone liefert seine eigenen System-Schritte. Trage es bei dir, zum Beispiel in der Hosentasche.
2. Unter Einstellungen kannst du deinen Namen und dein eigenes Schrittziel ändern.
3. Beim ersten Spaziergang fragt die App nach deinem Standort. Erlaube den Standortzugriff und aktiviere **Genauer Standort**. Starte die Aufzeichnung, während die App im Vordergrund ist.
4. Danach kannst du den Bildschirm sperren. Während des laufenden Spaziergangs ist Hintergrund-GPS konfiguriert. Ein Standortindikator kann sichtbar sein. Die App nicht aus dem App-Umschalter wegwischen.
5. Bei einer Pause werden GPS und die Spaziergang-Schrittupdates beendet. Beim Fortsetzen beginnt ein neues Intervall und ein neuer Routenabschnitt.
6. **Beenden & speichern** sichert den Spaziergang. Titel und Notizen lassen sich später ergänzen.

## Was genau gemessen wird

- **Tages-Schritte:** Apples `CMPedometer`, vom Tagesbeginn bis jetzt. Keine eigene Schüttelerkennung und keine Ableitung aus GPS. iOS erfasst die Bewegung im System; beim Öffnen kann die App historische Werte nachladen. Die App braucht für das passive Tageszählen keinen dauerhaft laufenden GPS-Dienst. Updates können verzögert erscheinen.
- **Spaziergang-Schritte:** Apple-Schritte der aktiven Start-/Fortsetzen-Intervalle. Pausen werden nicht addiert. Nach Pause/Beenden werden die endgültigen Intervallwerte erneut bei Apple abgefragt. Solange Daten fehlen, bleibt der Wert als offen erkennbar.
- **GPS-Strecke:** Summe der gefilterten Routenabschnitte. Grobe Ungenauigkeiten, Rauschen und unplausible Sprünge werden verworfen. Bei längeren GPS-Ausfällen beginnt ein neuer Abschnitt. Es wird keine Strecke quer über die Lücke erfunden.
- **Aktive Zeit:** Start bis Pause beziehungsweise Ende, über alle aktiven Intervalle. Zeit läuft bei gesperrtem Bildschirm anhand echter Zeitstempel weiter.
- **Tempo:** aktive Zeit pro aufgezeichnetem GPS-Kilometer. Empfangslücken können es verfälschen. Ein sehr kurzer Weg zeigt noch keinen Tempowert.

Es sind die Schritte **dieses iPhones**, keine mit Apple Watch und anderen Quellen zusammengeführte Apple-Health-Gesamtsumme. Messgenauigkeit hängt auch von Gerät, Trageweise, Empfang und Apples Erkennung ab. Es wird keine hundertprozentige Zählgenauigkeit versprochen.

Wenn iOS die App beendet, du sie wegwischst oder das Gerät neu startest, ist eine lückenlose GPS-Aufzeichnung nicht garantiert. Beim nächsten Start wird eine unterbrochene Aufzeichnung am letzten gesicherten Zeitpunkt pausiert und markiert. Sie kann bewusst fortgesetzt werden. Für den Tag kann Core Motion trotzdem historische Schritte bereitstellen.

## Datenschutz und Sicherung

Journal und Routen liegen im Application-Support-Verzeichnis der App auf dem iPhone und werden atomar gespeichert. Der Dateischutz erlaubt Schreiben nach dem ersten Entsperren auch bei anschließend gesperrtem Bildschirm. Die App besitzt keinen Analysedienst und lädt keine Fitnessdaten zu einem eigenen Server hoch. Apple Maps benötigt für Karten üblicherweise eine Internetverbindung und verwendet Apples Kartendienste.

Unter **Einstellungen → Journal als JSON exportieren** kannst du in „Dateien“ sichern. Ein Import ersetzt nach Bestätigung das Journal. Eine laufende Aufzeichnung muss vorher beendet werden. In den Details lässt sich eine Route als GPX teilen. Backups und GPX enthalten genaue Bewegungsdaten.

## Cloud-Build ohne eigenen Mac

Das Repository enthält einen GitHub-Actions-Workflow **iPhone-App bauen** auf einem standardmäßigen `macos-15`-Runner. In öffentlichen Repositories sind Standard-Runner laut GitHub kostenlos. Private Repositories verwenden das jeweilige Minutenkontingent und können abhängig von Konto und Abrechnung Kosten verursachen.

Unter GitHub → Actions → iPhone-App bauen → Run workflow starten. Nach einem erfolgreichen Lauf das Artefakt **DayformWalk-iPhone** herunterladen und entpacken. Darin liegt die IPA. Es werden keine Apple-Zugangsdaten, Zertifikate oder Signing-Secrets an GitHub übergeben. Der Build erstellt eine unsignierte IPA für die anschließende persönliche Signierung mit AltStore.

Quelle: [GitHub-Runner und Kostenmodell](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job).

Mit einem Mac lässt sich dasselbe Projekt in Xcode öffnen oder über `bash scripts/build-ipa.sh` bauen.

## Prüfungen

`Tests/main.swift` prüft Distanz, GPS-Rauschen und Sprünge, getrennte Lücken, Pausenzeiten, Schrittintervalle, GPX-Export und Backup-Roundtrip. Der Build kompiliert diese Tests und anschließend die echte iPhone-App. Eine physische iPhone-Prüfung – insbesondere ein Spaziergang mit gesperrtem Bildschirm und ein Vergleich der Schrittwerte – muss nach der Installation am Gerät erfolgen. Ein erfolgreicher Cloud-Build ersetzt diese Geräteprüfung nicht.

Praktischer Test: 100 Schritte mit dem iPhone in der Hosentasche gehen und mit dem aktualisierten Tageswert vergleichen; dann einen Spaziergang starten, den Bildschirm für mehrere Minuten sperren, weitergehen und nach dem Entsperren Route und Werte prüfen. Eine Pause mit Bewegung dazwischen darf die Spaziergang-Schritte nicht erhöhen, die Tages-Schritte aber schon.
