# GolfTrack – Live-Screenshots für die Website

Aufgenommen am 08.08.2026 im iPhone-17-Pro-Simulator (iOS, 402×874 pt / 1206×2622 px),
Statusleiste auf 09:41 · voller Empfang · geladener Akku gesetzt (App-Store-Konvention).

**Neu aufgenommen am 03.11.2026** (App-Stand 2.6, ohne Glühbirne): die neun Bilder,
die die Website zeigt – `01`, `02`, `06`, `08`, `09`, `12`, `18`, `19`, `20` –, jeweils
auf Deutsch und Englisch. Für `19`/`20` steht der Simulator am ersten Abschlag von
Eichenried (`xcrun simctl location <udid> set 48.2842,11.8060`), die Runde ist über
„Neue Runde → Runde starten“ angelegt, damit keine Tableiste darüberliegt. Die übrigen
Dateien stammen noch vom 08.08.2026.

Zwei Sprachfassungen: `de/` und `en/`. Englisch starten mit
`-AppleLanguages '(en-GB)' -AppleLocale en_GB`, Inhalte statt Kaufseite mit
`-unlockAll` (nur DEBUG). Die Website wählt die Fassung nach Sprache und fällt
auf `de/` zurück, wo ein englisches Bild fehlt.

**Nur auf Deutsch vorhanden**, weil der Inhalt selbst deutsch ist:
die Watch-App (kein einziges .xcstrings/.lproj im Target, alle Texte sind
Literale), die 17 Audio-Trainings (deutsche MP3s) und die Golfregeln.

Die Spielmodi, ihre Beschreibungen und der Scorecard-Kopf („Loch" → „Hole")
sind seit dem 09.08.2026 übersetzt; `de/19-live-scorecard.png` wurde danach neu
aufgenommen, weil dort noch der Tippfehler „Schlagschläge" stand.

Die Daten stammen aus dem DEBUG-Seeder (`GolfTrackApp/Shared/DemoDataSeeder.swift`):
12 abgeschlossene Runden auf 3 Plätzen, WHS-Index 10.1, echte Schlägermessungen,
GPS-Schlagketten auf der jüngsten Runde. Profilname „Alex".

Wetter ist echt — Datenquelle ist Open-Meteo (api.open-meteo.com), nicht Apple
WeatherKit. Standort München.

## Zuordnung zu den Website-Sektionen

| Datei | Zeigt | Passt zu Website-Sektion |
|---|---|---|
| `00-splash.png` | Startbildschirm mit Logo | – |
| `01-home.png` | Dashboard: Handicap, letzte Runde, Wetter, Fortschritt | **Hero** (ersetzt das CSS-Mockup) |
| `02-profil-handicap.png` | Profil, WHS-Karte, Score Differentials | „WHS Handicap" |
| `03-achievements.png` | Game-Center-Grid, 9 Achievements | „9 Achievements" |
| `04-schlaegerdistanzen.png` | Schläger-Bag mit Ø/Min/Max je Schläger | „Kenne deine Bag" |
| `05-tipps-coaching.png` | Tipp des Tages + personalisierte Empfehlungen | „Coaching" |
| `06-statistiken-chart.png` | Swift-Charts-Trend über 10 Runden | „Sieh, wie sich dein Spiel entwickelt" |
| `07-verlauf.png` | Rundenliste mit Score vs. Par | – |
| `08-rundendetail.png` | Scorecard-Tabelle + Schlagkarte | „Schlag-Tracking" |
| `09-schlagkarte.png` | Schlagkarte im Vollbild mit Loch-Legende | „Jeder Schlag, verortet" |
| `10-regeln.png` | Regelkategorien | „Regelwerk" |
| `11-regel-diagramm.png` | Interaktives Penalty-Area-Diagramm | „Regelwerk – interaktive Diagramme" |
| `12-training.png` | Audio-Trainings, Kategorien, Pro-Badge | fehlt auf der Website |
| `13-rundendetail-gps.png` | GPS-Distanzen pro Loch, 6,15 km Gesamtstrecke | „Schlag-Tracking" |
| `14-caddy-ki.png` | KI-Sprachassistent Caddy, 1,99/Monat | **fehlt auf der Website** |
| `15-golftrack-pro.png` | Pro-Abo, 2,99/Monat | **fehlt auf der Website** |
| `16-spielmodi.png` | Spielmodus-Auswahl | „Spielmodi" |
| `17-platzwahl.png` | Standortbasierte Platzsuche mit Entfernung | „30.000+ Plätze" |
| `18-neue-runde.png` | Runden-Setup (Platz, Bag, Datum, Modus) | – |
| `19-live-scorecard.png` | Live-Loch: Distanz zur Fahne, Schlägerempfehlung | „Herz der App" |
| `20-scorecard-mini.png` | Live-Loch mit Mini-Scorecard unten | „Score-Verlauf" |
| `21-statistik-schlaegerdistanzen.png` | Fairways/GIR/Ø + gemessene Distanzen | „Statistiken" |
| `22-platzreife-uebersicht.png` | Platzreife: Prüfungsreife 78 %, Lernen/Fehler/Probeprüfung | „Platzreife lernen" (CPP *Platzreife*) |
| `23-platzreife-lernrunde.png` | Lernrunde mit beantworteter Frage und Erklärung | „Platzreife lernen" |
| `w1-setup.png` | Watch: Rundenstart, Golf/Minigolf, 9/18 Löcher | „Apple Watch" |
| `w2-tracker.png` | Watch: Schlagzähler mit −/Weiter/+ und LIVE-Punkt | „Direkt am Handgelenk" |

Watch-Bilder aus dem Apple Watch Series 11 (46mm), watchOS 26.4, standalone gestartet
(ohne gepaartes iPhone). Der GPS-Schlagpunkt-Screen ließ sich nicht aufnehmen: der
watchOS-Simulator liefert ohne gepaartes iPhone keinen CoreLocation-Fix, die Ansicht
bleibt auf „GPS wird geladen…" stehen. Das ist ein Simulator-Limit, kein App-Fehler.

## Neu aufnehmen

```bash
xcrun simctl launch <udid> com.TobiasAufschlaeger.GolfTrackandwatch -seedDemoData YES
```

Der Seeder löscht vorher alle Plätze, Runden und Bags. Er existiert nur in DEBUG-Builds;
in Release ist `seedDemoDataIfRequested()` ein No-op.

## iPad (`ipad/de/`)

Aufgenommen am 15.10.2026 im iPad Pro 13-inch (M5), 2064×2752 px – das ist die
Größe, die App Store Connect für den 13-Zoll-iPad-Slot verlangt. Nur Platzreife:
`p1-platzreife-uebersicht.png` (zweispaltige Übersicht), `p2-platzreife-pruefung.png`
(Probeprüfung mit Fragenübersicht als Seitenleiste), `p3-platzreife-lernrunde.png`.

Lernstand und Prüfungsergebnisse kommen aus `-seedDemoData` (DemoDataSeeder →
`seedPlatzreife`). Direkt in den Lernbereich startet die App mit
`SIMCTL_CHILD_GOLFTRACK_DEEPLINK="golftrack://platzreife"`.

## iPhone 6,9 Zoll (`de-69/`)

Aufgenommen am 15.10.2026 im iPhone 17 Pro Max (iOS 26.5), 1320×2868 px – die Größe für
den 6,9-Zoll-Slot (`APP_IPHONE_69`) in App Store Connect. Die 1206×2622-Bilder in `de/`
nimmt Apple dort nicht an. Bisher nur die fünf Bilder der Produktseite *Platzreife*:
`22-platzreife-uebersicht`, `23-platzreife-lernrunde`, `10-regeln`, `11-regel-diagramm`,
`01-home`. Start wie oben mit `-seedDemoData YES -unlockAll` und
`SIMCTL_CHILD_GOLFTRACK_DEEPLINK="golftrack://platzreife"`, Standort per
`xcrun simctl location <udid> set 48.137,11.575` (sonst lädt das Wetter auf der Startseite nicht),
Abspeichern mit `marketing/shoot.sh` (prüft die Größe).

## App-Store-Bilder 6,9 Zoll (`de-69/`, `en-69/`) – Stand 04.11.2026

Neu aufgenommen im iPhone 17 Pro Max (iOS 26.5) mit `marketing/appstore/capture.sh`
(startet die App frisch mit `-seedDemoData YES -unlockAll`, Statusleiste 9:41):
`01-home`, `02-profil-handicap` (nur de), `19-live-scorecard` (`GOLFTRACK_OPEN=round`,
Standort Eichenried), `24-mitspieler` (`GOLFTRACK_OPEN=roundPartners`),
`25-driving-range` (`GOLFTRACK_OPEN=range`, danach sieben Bälle von Hand eingetippt),
`22-platzreife-uebersicht` (Deep Link), `26-schlaegerwahl` (Schlägerblatt nach „+“).

Daraus macht `marketing/appstore/store-shots.mjs` die gestalteten Store-Bilder
(Überschrift + Gerät auf App-Hintergrund) nach `marketing/appstore/out/<sprache>/`.
Fehlt ein Bild in `<sprache>-69/`, nimmt der Generator die Website-Aufnahme derselben
Sprache (`06`, `09`, `12` kommen so aus `de/`/`en/`). `event-banners.mjs` baut die
Bilder für In-App-Events (1920×1080 Karte, 1080×1920 Detailseite, ohne Schrift).
