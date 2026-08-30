# Minigolf per QR-Code starten (und später als App Clip)

## Was in der App schon funktioniert

- **Anlagen** stehen in `GolfTrackApp/Data/MinigolfCourses.swift`.
  Jede Anlage hat eine feste `id` (Slug), die im QR-Code landet – einmal
  gedruckt, darf sie sich nie ändern. Erste Anlage: `sankt-englmar`.
- **Links** baut `GolfTrackApp/Shared/MinigolfDeepLink.swift`:
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

## Was für den App Clip noch fehlt

Ein App Clip lässt sich nicht allein im Code aktivieren – er braucht eine
Domain und einen Eintrag in App Store Connect:

1. **Domain**: `golftrack.app`, eingetragen in `MinigolfDeepLink.webBaseURL`.
2. **`apple-app-site-association`** unter `https://golftrack.app/.well-known/`
   ausliefern (ohne Weiterleitung, per https, `application/json`). Die Website
   macht das bereits: `web/src/app/.well-known/apple-app-site-association/route.ts`
   liefert `applinks` für `/minigolf/*` und `appclips` für die Clip-Bundle-ID.
3. **Associated Domains** im Target aktivieren:
   `applinks:golftrack.app` und `appclips:golftrack.app`.
4. **App-Clip-Target** in Xcode anlegen (Bundle-ID = App-ID + `.Clip`) und die
   vier Dateien mit aufnehmen: `MinigolfCourses.swift`,
   `MinigolfDeepLink.swift`, `MinigolfCourseStartView.swift` und
   `MinigolfView.swift` (wegen `MinigolfScoringView`, `MinigolfResultsView`
   und `MinigolfGameStore`). Das Clip muss unter 15 MB bleiben, also nur
   diese Dateien plus `AppTheme` – keine Audio-Lektionen, keine SwiftData-Modelle.
5. **Advanced App Clip Experience** in App Store Connect für die URL
   `https://golftrack.app/minigolf/sankt-englmar` anlegen (Titel, Untertitel,
   Header-Bild, Aktion „Öffnen").
6. **Ergebnisse übernehmen**: Das Clip schreibt in seine eigenen
   `UserDefaults`. Damit ein späterer Vollinstall den Spielstand sieht, muss
   `MinigolfGameStore` im Clip in die App-Group
   `group.com.TobiasAufschlaeger.GolfTrackappnew` schreiben.

## Neue Anlage aufnehmen

Zwei Wege: fest eingebaut über einen Eintrag in `MinigolfCourses.all` (immer
offline verfügbar, Grundlage für den App Clip) oder über golftrack.app – der
`CourseCatalogService` lädt freigegebene Anlagen nach und legt sie über die
eingebauten. Liste und Startablauf ziehen in beiden Fällen automatisch nach.
