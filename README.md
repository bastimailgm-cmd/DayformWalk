# Dayform Walk – native iPhone-App

Deutschsprachige SwiftUI-App für iPhone ab iOS 17. System-Schritte aus Apple Core Motion, GPS-Spaziergänge mit Hintergrundaufzeichnung, Apple-Maps-Routen, Pause/Fortsetzen/Beenden, aktive Zeit, Strecke, Tempo, Sieben-Tage-Verlauf, Notizen, GPX-Export und JSON-Backup. Kein API-Key, kein HealthKit-Entitlement, kein eigenes Backend.

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
