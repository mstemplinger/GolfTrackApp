# Android-Port von GolfTrack – gemeinsame Regeln

Die iOS-App (SwiftUI/SwiftData) liegt in `../GolfTrackApp`, `../GolfTrackShared`. Die Android-App
(Kotlin + Jetpack Compose, Material3) liegt in `android/`, Paket `app.golftrack`.

## Ziel der ersten Version (APK zum Download von golftrack.app)
- Alles, was auf iOS **kostenlos** ist, möglichst 1:1 nachbauen (Funktion, Texte, Aufbau, Farben).
- **Nicht enthalten:** KI-Caddy (ElevenLabs) und Training/Audiobooks (Abo bzw. Einmalkauf). Wo iOS
  dorthin verlinkt, bleibt der Einstieg sichtbar, aber mit `LaterBadge()` und Ziel
  `nav.navigate(Routes.comingLater(LaterFeature.CADDY | AUDIOBOOKS))`. Keine Paywalls, keine Käufe.
- **Werbung** (Werbepartner im Umkreis) wie auf iOS – aber **ohne** Werbefrei-Kauf.
- Kein Game Center, keine Apple Watch, keine Widgets, keine Live Activity, kein App Clip.
  Achievements (Game Center) lokal anzeigen ist okay, wenn es einfach geht – sonst weglassen.
- Sprache: Deutsch (Texte wörtlich aus den Swift-Quellen / `Localizable.xcstrings`-Schlüsseln übernehmen).

## Gemeinsame Bausteine (NICHT ändern – nur benutzen)
- `data/Models.kt` – Course, Round, HoleScore, Shot, PlayerHoleScore, TrackPoint, RoundTrack, GolfBag,
  GolfClub, QuizResult, DistanceUnit, AppFocus, LatLon (unveränderliche data classes, `copy`).
- `data/GameMode.kt`, `data/Scoring.kt` (HandicapCalculator, GameScoringEngine).
- `data/GolfStore.kt` – JSON-Speicher. Lesen: `val data by GolfStore.data.collectAsState()`.
  Schreiben: `GolfStore.upsertRound(...)`, `updateRound(id) { it.copy(...) }`, `upsertCourse`, ….
- `data/Prefs.kt` – Ersatz für `@AppStorage`: `rememberPrefBool("key")`, `Prefs.string(...)`.
  Gleiche Schlüsselnamen wie auf iOS verwenden.
- `data/catalog/*` – Platzverzeichnis (`CourseCatalog`, `GolfCourseEntry`, `MinigolfCourseEntry`).
- `ui/theme/AppTheme.kt` – Farben (`AppTheme.bg/card/gold/...`), `GolfTrackTheme`.
- `ui/common/Components.kt` – `AppScaffold(title, onBack)`, `Card`, `GoldButton`.
- `ui/common/Haptics.kt` – `Haptics.tap()/selection()/success()/stroke()/celebrate()` … wie iOS.
- `ui/common/Location.kt` – `rememberLocation(highAccuracy)` liefert `LatLon?` (fragt Berechtigung).
- `ui/common/Routes.kt` – alle Navigationsziele. Querverweise nur über diese Konstanten.
- `ui/AppRoot.kt` – Tabs + NavHost (registriert `homeRoutes`, `golfRoutes`, `recordsRoutes`,
  `minigolfRoutes`, `guideRoutes`, `profileRoutes`).

Fehlt dir etwas in den gemeinsamen Dateien, baue es in deinem eigenen Paket und erwähne es im
Abschlussbericht. Einzige Ausnahme: eine neue Bibliothek darfst du mit EINER zusätzlichen Zeile im
`dependencies { }`-Block von `app/build.gradle.kts` eintragen (per Edit, nichts anderes dort ändern).
Keine Google-Play-Dienste voraussetzen (APK läuft auch ohne Play Store). Karten: osmdroid
(ist schon eingebunden; User-Agent auf `app.golftrack` setzen). Luftbild optional über Esri World
Imagery wie auf der Website.

## Bauen
Aus `android/`: `./gradlew :app:compileDebugKotlin -q 2>&1 | grep -E "^e:"`.
Mehrere Agenten arbeiten parallel in anderen Paketen. Fehler in Dateien außerhalb deines Pakets
ignorierst du (kurz warten, erneut bauen) – niemals fremde Dateien anfassen. Halte dein Paket
jederzeit kompilierbar (in kleinen Schritten arbeiten). Nicht committen.

## Stil
Kotlin idiomatisch, Kommentare auf Deutsch und sparsam wie im Swift-Original. Material3 nur als
Basis – das Aussehen soll dem iOS-Original folgen (dunkelgrün, Karten, Gold-Akzente).
