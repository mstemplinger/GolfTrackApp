# GolfTrack – Design & App Onboarding

## Überblick

GolfTrack ist eine native iOS + watchOS Golf-Companion-App in SwiftUI. Zielgruppe sind Golfspieler aller Level – von Anfängern bis zu erfahrenen Spielern mit WHS-Handicap. Die App begleitet den Nutzer auf dem Platz (Rundenerfassung, GPS-Schlagtracking, Apple Watch), analysiert seine Leistung (Statistiken, Handicap), und bildet ihn weiter (Regeln, Tipps, Platzreife-Quiz).

---

## Design-System

### Farbpalette

Die App hat ein durchgehendes **dunkles Grün-Theme** – inspiriert von Golfrasen und Natur. Alle Farben sind in `AppTheme` definiert:

| Token | Hex | Verwendung |
|---|---|---|
| `bg` | `#0E2718` | Tiefstes Hintergrund-Grün (App-Background) |
| `card` | `#163421` | Karten-Hintergrund |
| `cardAlt` | `#1C4129` | Karten-Variante, Icon-Hintergründe |
| `cardDark` | `#112D1C` | Tab Bar, dunkle Sektionen |
| `gold` | `#C9A035` | Primär-Akzent – CTAs, aktive Elemente, Icons |
| `goldDark` | `#A27F27` | Gedrückter Zustand für Gold-Buttons |
| `green` | `#28824B` | Sekundärer Grün-Akzent |
| `text` | `#FFFFFF` | Primärtext |
| `textSec` | `rgba(255,255,255,0.60)` | Sekundärtext, Labels |
| `textTer` | `rgba(255,255,255,0.40)` | Tertiärtext, Chevrons, Placeholder |

**Score-Farben:**
- Unter Par → helles Grün (`#66D97F`)
- Par (0) → Weiß
- Bogey (+1/+2) → Gold
- Double Bogey+ → Rot (`#FF6666`)

### Typografie

Durchgehend **SF Pro** (System Font). Kein Custom Font. Schriftgrößen folgen SwiftUI-Standards:
- Titel: `.title2.bold()` / `.title3.bold()`
- Headlines: `.headline` / `.subheadline.bold()`
- Body: `.body`
- Captions: `.caption` / `.caption2`

### Shapes & Abstände

- Karten: `RoundedRectangle(cornerRadius: 16)`
- Buttons innerhalb von Karten: `cornerRadius: 12–14`
- Standard-Padding horizontal: `16 pt`
- Karten-internes Padding: `18–20 pt`
- Abstände zwischen Sektionen: `16–20 pt`

### Button-Stile

- **Gold-CTA** (`.goldButton()`): goldener Hintergrund, dunkler Text, volle Breite, 16 pt Padding, cornerRadius 14
- **Green-Button** (`.greenButton()`): mittleres Grün, weiß, volle Breite
- **Card-Row-Button**: `.plain`-ButtonStyle, keine Hervorhebung

---

## Navigation

**5-Tab-Architektur** (Tab Bar am unteren Rand, goldene Akzentfarbe):

| Tab | Icon | View |
|---|---|---|
| Home | `house.fill` | `HomeView` |
| Training | `figure.golf` | `TrainingView` |
| Spielregeln | `book.fill` | `GolfRulesView` |
| Tipps | `lightbulb.fill` | `TipsView` |
| Profil | `person.fill` | `ProfileView` |

Die Tab Bar hat den Hintergrund `cardDark (#112D1C)`. Inaktive Icons sind `rgba(white, 0.45)`, aktive gold.

---

## Screens im Detail

### 1. Home (Tab 0)

**Zweck:** Dashboard – Einstiegspunkt für eine neue Runde, Überblick über aktuellen Stand.

**Aufbau (von oben nach unten):**
- **Logo-Zeile:** „GolfTrack"-Schriftzug links + Glühbirnen-Button rechts (Tutorial)
- **Begrüßungskarte:** „Willkommen zurück, [Name]!" mit Wetter-Pill oben rechts (Temperatur + Symbol). Antippen öffnet Standort-/Platzwahl.
- **Stats-Zeile:** Zwei nebeneinander liegende Karten – WHS Handicap-Index (groß, gold) und letzte Runde (Schlagzahl vs. Par)
- **Wetter-Detailkarte:** Temperatur, Gefühlte Temp., Windgeschwindigkeit, Luftfeuchtigkeit, UV-Index. Grünes Badge „Gutes Golfwetter" oder rotes „Schlechtes Wetter".
- **Watch-Banner (konditionell):** Erscheint wenn eine Runde von der Apple Watch gestartet wurde – mit Spiegeln-Button und ×-Schließen
- **Trainingsfortschritt-Karte:** Goldener Progress-Balken (x/20 Runden für WHS-Qualifikation)
- **Laufende Runden:** Liste mit abbrechbaren Runden-Zeilen (Platz, Datum, Fortschritt). Tipp → Runde fortsetzen.
- **Action-Buttons:** „Neue Runde spielen" (gold, groß), „Platzreife Quiz", „Verlauf"

---

### 2. Neue Runde starten (`NewRoundView`)

**Präsentation:** `fullScreenCover` über Home. Navigationsleiste mit ×-Button (links) und Titel „Neue Runde" (inline).

**Formular-Sektionen:**
- **Platz:** Karten-Row mit Platzname, Lochanzahl, Par. Öffnet `CourseSelectorView` (standortbasiert). „+"-Button für neue Plätze.
- **Datum:** `DatePicker`
- **Spielmodus:** NavigationLink → `GameModePickerView`. Zeigt gewählten Modus mit Icon + Kurzbeschreibung.
- **Spieler (nur Mehrspieler):** Dynamische Textfeld-Liste. Anzahl richtet sich nach Spielmodus-Minimum/Maximum.
- **Start-Button:** Gold, pinned am unteren Rand. Wird grau wenn kein Platz gewählt. Zeigt Warning-State wenn Spielernamen fehlen.

---

### 3. Aktive Runde (`ScorecardView`)

**Zweck:** Das Herz der App – die Schlagerfassung während des Spiels.

**Aufbau:**
- **Toolbar:** „Abbrechen" links, Spielmodus-Icon + Name in der Mitte, „Abschließen"-Button rechts (gold)
- **Lochansicht (`HoleScoringView`):** Loch-Nummer, Par, Distanz. Schlagzähler mit − / + Buttons. Zusatzfelder je nach Modus (Fairway getroffen?, GIR?, Putts, Penalty). Wischgeste für nächstes/vorheriges Loch.
- **Spielstatus-Banner (Mehrspieler):** Zeigt Live-Spielstand passend zum Modus (z.B. Matchplay-Stand „Tob. führt 2 UP", Skins-Topf „€ 12", etc.)
- **Mini-Scorecard:** Horizontales Scroll-Grid aller Löcher. Farbcodierte Scores (grün/weiß/gold/rot je nach Abstand zu Par). Mehrere Zeilen bei Mehrspielermodi.
- **Shake-Geste:** Schütteln des iPhones → Alert „Spielregeln anzeigen?" → öffnet `GolfRulesView` als Sheet
- **Watch-Sync:** Bidirektionale Echtzeit-Synchronisierung mit Apple Watch

---

### 4. Training (Tab 1) – `TrainingView`

Zeigt Übungs-Content und Drills. Zugänglich auch über Home → „Trainingsplan".

---

### 5. Spielregeln (Tab 2) – `GolfRulesView`

**Zweck:** Nachschlagewerk für die wichtigsten Golfregeln.

Strukturiert nach Regelkategorien mit Icons. Tipp auf eine Regel → Detailansicht mit Erklärung + grafischen Diagrams (`GolfRulesDiagrams`).

---

### 6. Tipps & Coaching (Tab 3) – `TipsView`

**Aufbau:**
- **„Pro Tipp des Tages"-Karte:** Wechselt täglich (Tag des Jahres als Index). Icon + Titel + Kurzbeschreibung einzeilig. Chevron-Pfeil → klickbar. Öffnet `DailyTipDetailView` (Sheet mit vollem Tipptext, großem Icon, Gold-Badge).
- **Golf-Ratgeber-Link:** → `GolfGuideView` (Platzreife-Quiz + Strategie-Ratgeber)
- **Meine Statistiken-Link:** → `StatisticsView`
- **Kategorien-Grid:** 4 Kategorien in einer Card-Liste (Anfänger, Technik, Mental Game, Strategie) – jeweils farbiger Icon + Chevron → `TipsCategoryDetailView`

**Kategorie-Farben:**
- Anfänger: helles Grün
- Technik: Gold
- Mental Game: Lila
- Strategie: Orange

---

### 7. Profil (Tab 4) – `ProfileView`

**Aufbau (von oben nach unten):**
- **Avatar:** Kreisfoto mit Gold-Rand (aus Fotobibliothek). Fallback: Erster Buchstabe des Namens auf gold-gefülltem Kreis. Tippen → Foto-Picker + Crop-Sheet.
- **Name:** Editierbar inline. Textfeld + Checkmark-Button.
- **Stats-Zeile:** 3 Cards – Runden gespielt, Bestleistung (Score vs. Par), Ø Putts
- **WHS Handicap-Karte:** Großer Handicap-Index (z.B. „18.4"), Formel-Erklärung, Grid der besten Score-Differentials (gold hervorgehoben). Placeholder unter 3 Runden.
- **Dokumente-Karte (`DocumentsCard`):** Mitgliedskarte, Quittungen, scannbare Dokumente
- **Game Center:** Achievement-Grid (2 Spalten), Progress-Rings, Leaderboard-Button
- **Einstellungen-Liste:**
  - Distanzeinheit (Meter / Yards)
  - Meine Schläger (`ClubBagView`)
  - Golfplätze verwalten (`CourseListView`)
  - Minigolf
  - API-Einstellungen
  - Hilfe & Anleitung
  - Tutorial neu starten

---

### 8. Statistiken – `StatisticsView`

**Aufbau:**
- **Overview-Grid:** 2-spaltig – Runden gespielt, WHS Handicap, Bestleistung, Ø Score vs. Par, Ø Putts, GIR %
- **Trend-Chart:** Swift Charts – Area + Linie + Punkte der letzten 10 Runden (Score vs. Par). Gestrichelte Nulllinie = Par. X-Achse: Datum, Y-Achse: Score.
- **Averages-Karte:** Fairways %, GIR %, Ø Schläge
- **Schlägerdistanzen:** Ø Distanz pro Schläger, absteigend sortiert, Anzahl Schläge in Klammern. Einheit aus App-Einstellung.

---

### 9. Verlauf – `HistoryView` / `RoundDetailView`

Liste aller abgeschlossenen Runden (`RoundRowView`). Jede Zeile zeigt Platz, Datum, Score vs. Par, Spielmodus-Icon. Tipp → `RoundDetailView` mit vollständigem Loch-für-Loch-Scorecard, GPS-Schlagkarte (`RoundShotMapView`), Spielmodus-Statistiken.

---

### 10. Platzreife-Quiz – `PlatzreifeQuizView`

Interaktives Multiple-Choice-Quiz zu den Golfregeln. Fortschrittsanzeige, Score am Ende, Wiederholung möglich.

---

## Apple Watch Companion App

**Eigene watchOS-App** (GolfTrackWatch), läuft eigenständig oder synchronisiert mit iPhone.

### Design-Sprache (Watch)

Identische Farbkonstanten wie iPhone (deepes Grün `#0F2413`, Gold `#C9A035`), aber als lokale `let`-Konstanten da watchOS kein `AppTheme` teilt. Kompakteres Layout für die kleine Uhrenfläche.

### Screens:

**1. Setup-Screen (`SetupView`)**
- Header: Golf-Icon + „GOLFTRACK", darunter „Neue Runde"
- Platzliste (vom iPhone synchronisiert): auswählbare Rows mit Platzname, Lochzahl, Par
- Löcher-Auswahl (9 / 18) wenn kein Platz gewählt
- „Starten"-Button (gold, volle Breite)
- Wartescreen wenn iPhone eine Runde erstellt (Spinner + Text)

**2. Schlagzähler (`StrokeTrackerView`)**
- **Status-Leiste (oben):**
  - Links: ← ZURÜCK-Button (ab Loch 2) oder LIVE-Dot (Loch 1)
  - Mitte: „LOCH X · 18"
  - Rechts: Golf-Icon-Toggle (Auto-Erkennung an/aus, gold wenn aktiv) + GPS-Location-Button
- **Undo-Banner (konditionell):** Gold-Button „Schlag rückgängig" erscheint 4 Sekunden nach auto-erkanntem Schwung
- **Schlagzähler (Mitte):** Große Zahl (58pt, rounded bold), Beschriftung „Schläge" darüber. Numerische Übergansanimation.
- **Buttons (unten):** `[−]` · `[WEITER →]` · `[+]` – Minus und Plus sind schmal (44pt), Weiter/Fertig füllt den Rest (gold)

**3. GPS-Shot-Tracker (`WatchShotView`)**
Sheet mit zwei Schritten: Abschlagpunkt → Auftreffpunkt setzen. GPS-Status-Indikator (Spinner / grünes GPS-Icon + Genauigkeit). Ergebnisscreen mit Distanz in Metern und Yards.

**4. Rundenabschluss (`RoundSummaryView`)**
Gesamtschläge groß, Loch-für-Loch-Liste, „Neue Runde"-Button (gold).

### Watch-Features:
- **Automatische Schwungerkennung** via CoreMotion (`CMMotionManager`): Beschleunigung > 2.8g UND Rotation > 4.0 rad/s → Schwung erkannt. 3-Sekunden-Debounce. Haptisches Feedback.
- **GPS-Schlagkette:** Jede Schlagposition wird gespeichert und als Strecke (von → bis) an die iPhone-App gesendet
- **Bidirektionale Sync** via WatchConnectivity: Schlagzahlen werden in Echtzeit gespiegelt

---

## Datenmodell (SwiftData)

| Modell | Felder (Auswahl) |
|---|---|
| `Course` | name, numberOfHoles, totalPar, teeBoxes, location |
| `Round` | date, course, gameMode, isCompleted, scores, shots |
| `HoleScore` | holeNumber, par, distance, strokes, fairwayHit, greenInRegulation, putts, penalty |
| `Shot` | holeIndex, fromCoordinate, toCoordinate, distanceMeters, timestamp |
| `PlayerHoleScore` | playerName, holeNumber, strokes (für Mehrspieler-Modi) |
| `QuizResult` | score, totalQuestions, date |

---

## Spielmodi

| Modus | Beschreibung |
|---|---|
| Stroke Play | Standard – Gesamtschlagzahl |
| Stableford | Punkte nach Par-Abstand |
| Match Play | Loch-für-Loch gegen Gegner |
| Skins | Jedes Loch hat einen Geldbetrag |
| Better Ball | Team-Modus, bester Score zählt |
| Best Ball | Alle spielen, bester Schlag je Loch |
| Scramble | Team-Modus, alle spielen vom besten Auftreffpunkt |
| Erado | Jeder Spieler hat ein „Leben" |
| Minigolf | Separates Minigolf-Scoring |

---

## Services & Integrationen

- **WeatherKit** – Echtzeitwetter für den aktuellen Standort/Platz
- **CoreLocation** – GPS-Ortung auf iPhone und Apple Watch
- **WatchConnectivity (WCSession)** – iPhone ↔ Watch Datenaustausch
- **Game Center** – Bestenlisten (Stroke Play, Stableford) + Achievements
- **CoreMotion** – Automatische Schwungerkennung auf Apple Watch
- **Live Activities** – Lock-Screen-Widget während einer aktiven Runde
- **SwiftData** – Lokale Persistenz aller Runden, Plätze, Schläge
- **golftrack://** Deep-Link-Schema – Widget kann direkt zur aktiven Runde springen

---

## Onboarding

Beim ersten App-Start zeigt `OnboardingOverlayView` ein interaktives Tutorial-Overlay das die wichtigsten UI-Elemente mit Tooltips erklärt. Wird in `AppStorage("hasSeenOnboarding")` gespeichert. Kann jederzeit im Profil neu gestartet werden.

---

## Lokalisierung

Die App ist zweisprachig: **Deutsch** (Hauptsprache) und **Englisch**. Alle User-facing Strings sind in `Localizable.xcstrings` (String Catalog, Xcode 15+) hinterlegt. SwiftUI `Text("...")` verwendet automatisch `LocalizedStringKey`.
