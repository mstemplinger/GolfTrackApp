# Minigolf per QR-Code starten – App und App Clip

## Was in der App schon funktioniert

- **Anlagen** stehen in `GolfTrackShared/MinigolfCourses.swift`.
  Jede Anlage hat eine feste `id` (Slug), die im QR-Code landet – einmal
  gedruckt, darf sie sich nie ändern. Erste Anlage: `sankt-englmar`.
- **Links** baut `GolfTrackShared/MinigolfDeepLink.swift`:
  - `golftrack://minigolf?platz=sankt-englmar` – funktioniert sofort, sobald
    GolfTrack installiert ist.
  - `https://golftrack.app/minigolf/sankt-englmar` – Universal Link, zugleich
    die App-Clip-Adresse.
- **Ablauf nach dem Scan**: `MinigolfCourseStartView` – Begrüßung → „Kurz
  erklärt?" (drei Slides oder überspringen) → Spielernamen → Runde läuft.
- **QR-Code zum Aushängen**: gibt es in der Platzliste auf golftrack.app zum
  Herunterladen – bewusst nicht in der App. Die App zeigt unter
  *Minigolf → Minigolfplätze* nur die Anlagen selbst, ein Tipp darauf startet
  denselben Ablauf wie der Scan.

## Stand des App Clips

Gebaut am 1.9.2026. Ziel `GolfTrackClip`, Bundle
`com.TobiasAufschlaeger.GolfTrackandwatch.Clip`, 2,5 MB von erlaubten 15 MB.

Erledigt:

1. **`apple-app-site-association`** liefert `applinks` für `/minigolf/*` und
   `appclips` für die Clip-Bundle-ID – mit der richtigen Team-Kennung
   `NY363CML59`. Vorher stand dort `CH9C3LJXC8`; damit hat der Universal Link
   nie funktioniert, auch nicht für die installierte App.
2. **Associated Domains** in beiden Entitlements-Dateien der App und in
   `GolfTrackClip/GolfTrackClip.entitlements`. Fehlte vorher vollständig.
3. **App-ID und Capabilities** hat Xcode über automatische Signierung
   angelegt (`xcodebuild … -allowProvisioningUpdates`).
4. **Clip-Ziel** in Xcode, mit eigenem Einstiegspunkt
   `GolfTrackClip/GolfTrackClipApp.swift`.

Der Code wird nicht dateiweise doppelt geführt, sondern über den Ordner
`GolfTrackShared/`, der in beiden Zielen als synchronisierter Ordner hängt.
Dafür musste `MinigolfView.swift` (1453 Zeilen) auseinander: die Zählkarte und
die Zustandstypen sind geteilt, die Anlagenliste bleibt der App vorbehalten –
an ihr hängen Platzkatalog, Distanzwerkzeug und Werbung.

**Keine Werbung im Clip.** Apple untersagt sie (Richtlinie 2.5.16(a), dazu
2.5.18). Der Werbecode gehört deshalb gar nicht zum Clip-Ziel; zusätzlich
prüft `AppClipEnvironment.isRunningAsAppClip` zur Laufzeit den
`NSAppClip`-Eintrag. Fürs Geschäft heißt das: Runden über den Clip erzeugen
keine Sichtkontakte für die Anlage.

### Was noch offen ist

1. **App-Version mit dem Clip hochladen.** Erst dann existiert die
   App-Clip-Ressource in App Store Connect.
2. **Advanced App Clip Experiences** – eine je Anlagen-Adresse, sonst
   erscheint beim Scannen keine Karte. Dafür gibt es
   `marketing/asc-appclip-experiences.py`:

   ```bash
   # nachsehen, was fehlt
   python3 marketing/asc-appclip-experiences.py --issuer <ISSUER-UUID>

   # anlegen
   python3 marketing/asc-appclip-experiences.py --issuer <ISSUER-UUID> \
       --image marketing/appclip-karte.png --apply
   ```

   Die Anlagen holt das Skript aus `/api/v1/courses?kind=minigolf`, es legt
   nur an, was fehlt, und ohne `--apply` ändert es nichts. Die Karte muss ein
   PNG in 3000 × 2000 sein.
3. **Ergebnisse übernehmen**: Der Clip schreibt in seine eigenen
   `UserDefaults`. Damit ein späterer Vollinstall den Spielstand sieht, müsste
   `MinigolfGameStore` in die App-Group
   `group.com.TobiasAufschlaeger.GolfTrackappnew` schreiben. Noch offen.

### Ohne echten Scan ausprobieren

```bash
SIMCTL_CHILD__XCAppClipURL="https://golftrack.app/minigolf/sankt-englmar" \
  xcrun simctl launch booted com.TobiasAufschlaeger.GolfTrackandwatch.Clip
```

Der Clip wertet `_XCAppClipURL` in `#if DEBUG` aus; im Release gibt es den
Zweig nicht.

## Neue Anlage aufnehmen

Zwei Wege: fest eingebaut über einen Eintrag in `MinigolfCourses.all` (immer
offline verfügbar, Grundlage für den App Clip) oder über golftrack.app – der
`CourseCatalogService` lädt freigegebene Anlagen nach und legt sie über die
eingebauten. Liste und Startablauf ziehen in beiden Fällen automatisch nach.
