# golftrack.app

Website und Platzkatalog für GolfTrack. Drei Dinge in einem:

1. **Öffentliche Seite** — Startseite, Platzverzeichnis, Hilfe, Impressum und Datenschutz, auf Deutsch (`/`) und Englisch (`/en`).
2. **Anmeldeformular** — Golfclubs und Minigolfanlagen tragen sich unter `/platz-melden` selbst ein.
3. **Adminpanel und API** — unter `/admin` werden Einsendungen geprüft und freigegeben, unter `/api/v1/courses` holt die App sie ab.

Technik: Next.js 16 (App Router), Tailwind 4, Postgres. Kein CMS, keine Cookies, kein Tracking.

---

## Wo es läuft

Alles auf dem eigenen Server (`178.104.241.202`, „Toob360Server"), neben TOOB360 und BePartOfGreat:

| Teil          | Ort                                              |
|---------------|--------------------------------------------------|
| Anwendung     | `/var/www/golftrack`, als pm2-Dienst `golftrack` auf Port 3200 |
| Datenbank     | Postgres 16 auf demselben Rechner, Datenbank `golftrack` |
| Webserver     | nginx, vhost `/etc/nginx/sites-available/golftrack` |
| Zugangsdaten  | `/var/www/golftrack/.env.production` (nur root, nicht im Repository) |

## Ausliefern

```bash
sh deploy/deploy.sh
```

Überträgt die Quellen per rsync, installiert, baut auf dem Server und lädt den pm2-Dienst neu. Zum Schluss wird die API einmal abgefragt — antwortet sie nicht, bricht das Skript ab.

Nützlich am Server:

```bash
ssh root@178.104.241.202 'pm2 logs golftrack --lines 50'
```

## Lokal entwickeln

```bash
npm install
npm run dev
```

Dafür braucht es eine `DATABASE_URL` in `.env.local`. Am einfachsten ein eigenes Postgres:

```bash
createdb golftrack_dev
echo 'DATABASE_URL=postgresql://localhost:5432/golftrack_dev' >> .env.local
```

Das Schema legt die Anwendung beim ersten Zugriff selbst an; einen Migrationsschritt gibt es nicht. Für das Adminpanel müssen zusätzlich `ADMIN_PASSWORD` und `ADMIN_SECRET` gesetzt sein (siehe `.env.example`).

## Aufbau

```
src/
  app/
    (de)/…            deutsche Seiten – liegen ohne Präfix auf der Wurzel
    (en)/en/…         englische Seiten
    (de)/admin/…      Adminpanel (nicht indexiert)
    api/v1/courses/   öffentliche Platzdaten für die App
    api/v1/ads/       Anzeigen für den Werbeplatz in der App
    api/submissions/  Endpunkt des Anmeldeformulars
    api/ads/request/  Endpunkt der Buchungsanfrage von /werbung
    .well-known/      apple-app-site-association für Universal Links
  components/         Kopf, Fuß, Scorekarte, Lochkarte
  i18n/               sämtliche Texte (content.ts) und Pfade (routes.ts)
  lib/                Datenbank, Schema, Validierung, Anmeldung
  views/              die eigentlichen Seiten
deploy/               Auslieferung, pm2- und nginx-Konfiguration
```

Texte ändert man ausschließlich in `src/i18n/content.ts` — beide Sprachen stehen dort nebeneinander, damit auffällt, wenn eine fehlt. Eine weitere Sprache ist ein zusätzlicher Schlüssel dort plus ein Eintrag in `routes.ts`.

## Schrift, Logo, Knöpfe

Display- und Fließtext sind serifenlos: **Manrope** für Überschriften (700–800, negative Laufweite), **Instrument Sans** für den Fließtext, **DM Mono** für Marginalien und Zahlen. Die frühere Serife Fraunces ist raus – sie passte weder zur App-Oberfläche noch zur Wortmarke im eigenen Logo, die selbst ein geometrischer Grotesk ist. Alle drei kommen über `next/font/google` und werden mit der Seite ausgeliefert, nicht von Google nachgeladen.

Das Logo in Kopf und Fuß ist das echte Zeichen der App, kopiert aus `GolfTrackApp/Assets.xcassets/AppLogo.imageset/AppLogo.png` nach `public/logo.png` (192 px). Der Schriftzug im Logo bleibt ungenutzt: er nimmt dort nur rund ein Neuntel der Bildhöhe ein, für lesbare 16 px bräuchte man ein 137 px hohes Logo. Deshalb Zeichen als Bild, Name als echter Text. Wird das Logo in der App geändert, hier neu kopieren:

```bash
sips --resampleWidth 192 ../GolfTrackApp/Assets.xcassets/AppLogo.imageset/AppLogo.png --out public/logo.png
```

Knöpfe folgen der App: flächiges Messing, Radius 0.85 rem, dunkle Schrift, kein Farbverlauf und kein Leuchtschein.

## Bildschirmfotos aus der App

Unter `public/app/de/` und `public/app/en/` liegen die Aufnahmen aus dem Simulator, auf 750 px Breite gerechnet. Quelle und Zuordnung stehen in `../marketing/screenshots/README.md`; neu aufnehmen und danach hierher kopieren:

```bash
sips --resampleWidth 750 ../marketing/screenshots/de/01-home.png --out public/app/de/01-home.png
```

Watch-Aufnahmen (`w*.png`) werden nicht skaliert, sie sind schon klein.

Eingebunden werden sie über `components/Device.tsx` (`PhoneShot`, `WatchShot`). Englisch gibt es nur für einen Teil der Bilder; welche das sind, steht dort in `EN_SHOTS`, alles andere fällt auf die deutsche Fassung zurück. Kommt ein englisches Bild dazu, muss der Name in diese Liste.

## Prüfen, bevor ausgeliefert wird

```bash
npm run typecheck && npm run lint
```

Dazu am Browser bei 380 px messen, nicht schauen: kein waagerechter Überlauf (`scrollWidth === innerWidth`), jede Trefferfläche mindestens 44 px hoch, jede Farbkombination mit Schrift über 4,5:1. Ausgenommen sind allein Verweise mitten im Fließtext und die Zahlenfelder der Lochtabelle (36 px, begründet in `globals.css` bei `.field--tight`).

## Wenn `next dev` scheinbar hängt

Das Projekt liegt unter `~/Documents` und damit in einem Ordner, den iCloud synchronisiert. Werden Dateien in die Cloud ausgelagert, liest Node sie einzeln zurück: `next dev` gibt dann minutenlang gar nichts aus, und Seitenaufrufe brauchen Minuten statt Millisekunden. Erkennen lässt sich das an `compressed,dataless`:

```bash
ls -lO node_modules/next/constants.js
```

Kurzfristig hilft `rm -rf node_modules && npm ci` (schreibt lokale Dateien). Dauerhaft hilft nur, das Projekt aus dem synchronisierten Ordner zu nehmen oder es von der Synchronisierung auszunehmen.

## Adminpanel

`/admin`, Anmeldung mit `ADMIN_PASSWORD`. Jede Einsendung lässt sich ansehen, korrigieren und freigeben. Freigegebene Plätze erscheinen im Verzeichnis und in der API — das Verzeichnis spätestens nach einer Minute, bei einer Freigabe sofort.

Beim Bearbeiten steht ganz unten, was die App aus dem Eintrag macht. Das ist die schnellste Kontrolle, ob Par- und HCP-Werte vollständig sind: unvollständige Reihen liefert die API bewusst als leeres Array aus, damit in der App keine halben Scorekarten landen.

Die Kennung (`slug`) landet in QR-Codes und Universal Links. Sie lässt sich ändern, **aber nur bevor QR-Codes gedruckt sind**.

## API

| Methode | Pfad                        | Zweck                            |
|---------|-----------------------------|----------------------------------|
| GET     | `/api/v1/courses`           | alle freigegebenen Anlagen       |
| GET     | `/api/v1/courses?kind=golf` | nur Golfplätze                   |
| GET     | `/api/v1/courses/{slug}`    | eine einzelne Anlage             |
| POST    | `/api/submissions`          | Formular (Rate-Limit, Honigtopf) |
| GET     | `/api/v1/ads`               | laufende Anzeigen für die App    |
| POST    | `/api/v1/ads/event`         | Sichtkontakte und Tipps zählen   |
| POST    | `/api/ads/request`          | Buchungsanfrage von `/werbung`   |

Die Feldnamen entsprechen `BundledCourseEntry` und `MinigolfCourseEntry` in der iOS-App, damit dort nichts umgerechnet werden muss. Beschreibung der Felder: `/api-docs`.

## Anbindung in der App

`GolfTrackApp/Services/CourseCatalogService.swift` lädt den Katalog, legt ihn in Application Support ab und führt ihn mit den eingebauten Plätzen zusammen (bei Namensgleichheit gewinnt der eingebaute Eintrag). Ohne Netz bleibt der letzte Stand nutzbar; die eingebauten Plätze funktionieren immer.

Verwendet wird der Dienst in `AddCourseSheetView` (Platzauswahl), `MinigolfView` (Anlagenliste) und `ContentView` (QR- und Universal-Links).

## Werbung

Unter den Spielernamen in der Minigolf-Zählkarte steht ein Feld, das sich verkaufen lässt. Verwaltet wird es unter `/admin/werbung`, angefragt von Betreibern unter `/werbung`.

- Eine Anzeige gehört entweder zu einer Anlage (`course_slug`) oder gilt überall. **Die Anlage geht vor** — wer den Platz vor Ort bezahlt hat, bekommt ihn auch.
- `status`: `draft` (nur im Adminpanel), `active` (läuft), `paused`. Anfragen über das Formular landen als `draft` mit `source = 'form'`.
- Die App lädt über `/api/v1/ads` **alle** laufenden Anzeigen und wählt vor Ort selbst aus. Grund: auf einer Anlage im Wald ist selten Netz, und der Platz soll trotzdem gefüllt sein.
- Gezählt wird in `ad_stats` nur „Anzeige X, Tag Y, n mal gesehen / getippt". Keine Gerätekennung, kein Standort, nichts Personenbezogenes — deshalb braucht der Slot keinen Einwilligungsdialog. Die Zahlen sind damit auch nicht fälschungssicher; für die Abrechnung mit einer Anlage reicht das, für einen Werbemarkt mit fremdem Geld nicht.
- In der App: `GolfTrackApp/Services/AdCatalogService.swift` (Laden, Auswahl, Zähler) und `Views/Minigolf/MinigolfAdSlotView.swift` (Darstellung). Wer ein Abo oder den Einmalkauf `GolfTrack_werbefrei` hat, sieht die Fläche gar nicht.

## Sicherung

Die Plätze stecken allein in der Datenbank. Eine Sicherung ist eine Zeile:

```bash
ssh root@178.104.241.202 'sudo -u postgres pg_dump golftrack' > golftrack-$(date +%F).sql
```
