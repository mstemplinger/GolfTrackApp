# Konzept: Betreiber-Dashboard („Platz-Statistik“)

Stand 2026-11-23 · Ziel: Golf- und Minigolfbetreibern eine bezahlte Auswertung ihres Platzes anbieten – nur aus zusammengefassten, nicht personenbezogenen Zahlen.

---

## 1. Ausgangslage: Was heute tatsächlich gesammelt wird

| Daten | Wo | Auf dem Server? | Nutzbar fürs Dashboard? |
|---|---|---|---|
| Runden, Schläge, Putts, Fairway/GIR, Schläger je Loch (`Round`, `HoleScore`, `Shot`) | iPhone (SwiftData/iCloud) | **nein** | erst mit neuer Freigabe |
| Laufspur (`RoundTrack`) | iPhone | **nein** | nein – bleibt auf dem Gerät |
| Minigolf-Runden (App Clip, Browser-Scorekarte) | Gerät / localStorage | **nein** | erst mit neuer Freigabe |
| Driving-Range-Schläge (`RangeSession`) | iPhone | **nein** | später (Hersteller-Report) |
| Abschlag-/Grünpunkte (`geometry_contributions`) | Server, nur Tag, keine Kennung | ja (Opt-in) | ja: Geometrie, grober Aktivitätszähler |
| Werbeeinblendungen/Klicks (`ad_stats`) | Server, je Anzeige und Tag | ja | ja: Reichweite für Werbekunden |
| Lobby (Namen, Schläge, Standort) | Server, wird nach 1 Tag gelöscht | kurzzeitig | **nein** – anderer Zweck, zugesagte Löschung |

**Wichtigste Erkenntnis:** Fürs Dashboard sind auf dem Server heute praktisch keine Daten vorhanden. Die Datenschutzerklärung sagt ausdrücklich (`web/src/views/Legal.tsx:170`):

> „Runden, Scores und – falls eingeschaltet – Positionsdaten bleiben auf deinem Gerät … Sie werden nicht an mich übertragen“

Das Dashboard braucht deshalb einen **neuen, eigenen Datenfluss mit Einwilligung**. Bestehende Daten (Lobby, Spuren) dürfen dafür nicht umgewidmet werden (DSGVO-Zweckbindung, Apple 5.1.2(ii)).

---

## 2. Der neue Datenfluss: „Rundenstatistik teilen“

Er funktioniert nach demselben Muster wie die Crowd-Positionen (`CrowdGeometryService`), das sich schon bewährt hat: Opt-in, Warteschlange auf dem Gerät, keine Kennung, nur der Tag.

### Was die App nach einer abgeschlossenen Runde schickt

```json
POST /api/v1/courses/{slug}/round-stats
{
  "kind": "golf",              // oder "minigolf"
  "day": "2026-11-23",
  "slot": "afternoon",         // morning <11 / midday 11–14 / afternoon 14–18 / evening >18
  "weekday": 1,                // 1 = Montag
  "holesPlayed": 18,
  "durationBucket": 270,       // Minuten, auf 15 min gerundet; nur wenn plausibel
  "teeColor": "yellow",        // nur Golf
  "players": 3,                // Gruppengröße, ohne Namen
  "holes": [ { "n": 1, "strokes": 5, "putts": 2 }, … ],   // je Spieler gemittelt oder je Spieler ohne Namen
  "source": "app"              // app | clip | web
}
```

**Nicht übertragen werden:** Name, Geräte-/Runden-ID, genaue Uhrzeit, Laufspur, Koordinaten, Handicap und Schläger. Die IP-Adresse wird wie bei der Geometrie nur flüchtig zur Missbrauchsbremse gezählt.

**Absicherung gegen Rückschlüsse:**
- Uhrzeit nur als Tagesabschnitt, Dauer nur in 15-Minuten-Stufen (und nur, wenn sie zur Lochzahl passt).
- Der Server speichert **keinen Eingangszeitpunkt** und keine Netzadresse (nginx loggt den Pfad nicht). Eine Verzögerung von 24 h beim Senden ist deshalb unnötig – und im App Clip, der oft nur einmal startet, auch nicht machbar. *(Umgesetzt 2026-11-23 so, abweichend vom ersten Entwurf.)*
- Leere Spielerzeilen werden verworfen, Runden älter als 30 Tage abgelehnt.

### Einwilligung
- Ein neuer Schalter in den Einstellungen unter Positions-Tracking bzw. Datenschutz: **„Anonyme Rundenstatistik für Platzbetreiber teilen“**, standardmäßig aus.
- Einmal fragen, am besten im `RoundCompleteSheet` nach der ersten Runde auf einem Katalogplatz: „Hilf deinem Platz – teile anonym, wie lange und wie schwer die Bahnen waren.“
- **App Clip und Minigolf in der App:** Schalter „Ergebnis anonym an die Anlage melden“ im Ergebnisbildschirm (gilt danach für weitere Runden). Gerade bei Minigolf liegen dort die meisten Runden, und genau dafür bezahlen Betreiber.
- **Browser-Scorekarte:** ausdrücklicher Knopf „Anonym an die Anlage melden“ je Runde – keine gespeicherte Einwilligung nötig.

### Speicherung (Server)

```sql
CREATE TABLE round_stats (
  id            bigserial PRIMARY KEY,
  course_slug   text NOT NULL,
  kind          text NOT NULL CHECK (kind IN ('golf','minigolf')),
  played_on     date NOT NULL,
  slot          text NOT NULL,
  weekday       smallint NOT NULL,
  holes_played  smallint NOT NULL,
  duration_min  smallint,            -- 15-min-Stufen, NULL wenn unplausibel
  tee_color     text NOT NULL DEFAULT '',
  players       smallint NOT NULL,
  holes         jsonb NOT NULL,      -- [{n, strokes, putts}]
  source        text NOT NULL
);
-- Rohzeilen nach 13 Monaten löschen; Monatsaggregate bleiben.
CREATE TABLE round_stats_monthly (… course_slug, month, kennzahlen jsonb …);
```

---

## 3. Was der Betreiber sieht

**Grundregel:** Eine Zahl erscheint erst, wenn mindestens **10 Runden** im gewählten Zeitraum und Filter dahinterstehen. Darunter steht „noch zu wenige Runden“. Das verhindert Rückschlüsse auf einzelne Gruppen.

### Minigolf
1. **Runden pro Woche** mit Verlauf und Vergleich zum Vorjahr, aufgeteilt nach Quelle (App/Clip/Web)
2. **Stoßzeiten:** Raster aus Wochentag und Tagesabschnitt
3. **Bahn-Ranking:** Durchschnittsschläge je Bahn, Anteil Hole-in-One, Anteil Maximalschläge (7)
4. **Auffälligkeiten:** eine Bahn, die gegenüber ihrem eigenen 8-Wochen-Schnitt plötzlich ≥ 0,8 Schläge schwerer wird, ist vermutlich beschädigt. Das gibt einen Hinweis und auf Wunsch eine Mail.
5. **Gruppengröße und Spieldauer** (Median)

### Golf
1. Runden/Woche, 9 vs. 18 Löcher, Verteilung der Abschlagfarben
2. **Pace of Play:** Median-Spieldauer je Wochentag/Tageszeit
3. **Lochschwierigkeit:** Ø Schläge über Par je Loch, verglichen mit dem Course-HCP. Zeigt, ob die HCP-Reihenfolge der Löcher noch zur Realität passt.
4. Ø Putts je Grün (Hinweis auf schwierige Grüns)

### Für alle
- **Werbe-Reichweite** aus `ad_stats`, sofern die Anlage selbst wirbt
- **Geometrie-Status:** welche Löcher schon per Crowd bestätigt sind
- **Export** als CSV und PDF-Monatsbericht für die Vereinssitzung

---

## 4. Zugang für Betreiber

Heute gibt es nur das Ein-Personen-Adminpanel (`web/src/lib/auth.ts`: ein Passwort, signiertes Cookie). Für Betreiber braucht es einen eigenen, schlanken Zugang:

- **Magic Link per Mail** an die geprüfte Adresse des Platzes (`courses.public_email` oder `submitter_email` nach Freigabe). Kein Passwort.
- Neue Tabelle `operator_access (course_slug, email, role, verified_at, plan, paid_until)`.
- Route `/betreiber/{slug}`, die ausschließlich Aggregate liest. Rohzeilen erreicht diese Route nie.
- **Missbrauchsschutz:** Die Statistik eines Platzes gibt es nur für eine Adresse, die du einmal von Hand freigegeben hast. Das passiert im Adminpanel, so wie heute bei Plätzen und Werbung.

---

## 5. Preis und Pakete (Vorschlag)

| Paket | Inhalt | Preis |
|---|---|---|
| **Frei** | Runden/Monat als eine Zahl, Geometrie-Status | 0 € – Köder, macht neugierig |
| **Platz-Statistik** | alles aus Kapitel 3, 12 Monate Verlauf, Auffälligkeits-Mails | 15 €/Monat oder 150 €/Jahr |
| **Paket mit Werbung** | Statistik + Werbeplatz auf eigener Anlage | Rabatt auf den Werbepreis |

Abrechnung zuerst per Rechnung oder Überweisung, so wie heute bei der Werbung. Stripe erst, wenn sich Nachfrage zeigt.

Zur Einordnung: Bei einer Minigolfanlage mit 3.000 Runden pro Saison sind schon 5 % teilende Spieler 150 Runden und damit für Monatswerte knapp ausreichend. **Die Teilnahmequote im App Clip ist der entscheidende Hebel**, deshalb dort der Haken am Rundenende.

---

## 6. Recht und Store – Pflichtschritte vor dem Start

1. **Datenschutzerklärung** (`Legal.tsx`): einen neuen Abschnitt „Anonyme Rundenstatistik“ nach dem Muster von „Platzpositionen teilen“ einfügen. Inhalt: Rechtsgrundlage Einwilligung (Art. 6 Abs. 1 lit. a DSGVO, § 25 Abs. 1 TDDDG), welche Felder übertragen werden, Speicherdauer, Weitergabe nur als Summen ab 10 Runden. Den Satz in Zeile 170 um „… oder teilst die Rundenstatistik“ ergänzen.
2. **App Store Connect → App-Datenschutz:** „Gameplay-Inhalte“ und ggf. „Produktinteraktion“ eintragen, als *nicht mit Identität verknüpft* und *nicht zum Tracking*. Vor der nächsten Einreichung die Checkliste `~/.claude/app-review-checkliste.md` abarbeiten.
3. **Lokalisierung:** Schaltertext und Einwilligungsdialog in alle 7 Sprachen übersetzen, auch im App Clip.
4. **Android-Port:** denselben Schalter einbauen oder die Funktion dort bewusst weglassen. Die Datenschutzseite muss das unterscheiden.
5. **Betreiber-AGB:** Ergänzung zu `/werbung/bedingungen`. Die Zahlen sind Näherungen aus freiwillig teilenden Spielern und nicht vollständig.

---

## 7. Umsetzung in Schritten

> **Stand 2026-11-23:** Phase 1 ist gebaut (Server, App, Clip, Web, Datenschutztext, Übersetzungen) – noch nicht deployt/eingereicht.

| Phase | Inhalt | Aufwand (grob) |
|---|---|---|
| **0 – Nachfrage testen** | 5–10 Betreiber aus dem Formular anschreiben, Mock-Dashboard (Screenshots mit Beispieldaten) zeigen, Zahlungsbereitschaft abfragen | 1–2 Tage |
| **1 – Daten sammeln** | Tabelle + Endpunkt `round-stats`, `RoundStatsService` in App/Clip/Web-Scorekarte, Schalter + Dialog, Datenschutztext, ASC-Labels | 3–5 Tage |
| **2 – Admin-Ansicht** | Auswertung zuerst nur im eigenen Adminpanel, um zu sehen, ob genug Daten zusammenkommen | 1–2 Tage |
| **3 – Betreiberzugang** | Magic Link, `/betreiber/{slug}`, Diagramme, Mindestmengen-Regel, CSV/PDF | 4–6 Tage |
| **4 – Bezahlen & Mails** | Pakete, Rechnung, Auffälligkeits-Mails | 2–3 Tage |

**Phase 1 sollte bald mit dem nächsten App-Update kommen.** Daten gibt es erst ab dem Moment, in dem gesammelt wird. Wenn die Betreiber im Frühjahr 2027 überzeugt sind, sollten schon ein paar Monate Verlauf vorhanden sein.

---

## 8. Spätere Ausbaustufen (gleiche Datenbasis)

- **Geometrie-API** (Abschlag/Grün aus `course_geometry`) als Lizenz für andere Golf-Apps. Diese Daten sind schon vorhanden und enthalten nichts Personenbezogenes.
- **Range-Report** für Schlägerhersteller und Fitter (Ø Weite je Schläger nach Handicap-Klasse). Dafür ist eine eigene Einwilligung nötig, weil es ein anderer Zweck ist als die Platzstatistik.
- **Regionalbericht** für Tourismusämter (Minigolfrunden je Region und Saison).
