# GolfTrack – Live-Screenshots für die Website

Aufgenommen am 08.08.2026 im iPhone-17-Pro-Simulator (iOS, 402×874 pt / 1206×2622 px),
Statusleiste auf 09:41 · voller Empfang · geladener Akku gesetzt (App-Store-Konvention).

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
