import { listCourses } from "@/lib/courses";
import { APP_STORE_URL, PLAY_URL, SITE_URL } from "@/i18n/routes";
import { site } from "@/lib/site";

/**
 * `/llms.txt` – Kurzfassung der Website in Markdown für KI-Suche und
 * Sprachmodelle (Vorschlag von llmstxt.org). Läuft wegen der Dateiendung nicht
 * durch den Proxy, ist also auch vor der Freischaltung erreichbar.
 *
 * Preise und Funktionen spiegeln `i18n/content.ts`; bei Änderungen dort hier
 * mitziehen.
 */
export const revalidate = 86400;

export async function GET() {
  const courses = await listCourses({ status: "approved", limit: 10000 });
  const golf = courses.filter((c) => c.kind === "golf").length;
  const minigolf = courses.length - golf;

  const body = `# GolfTrack

> GolfTrack ist eine App zum Zählen von Golf- und Minigolfrunden für iPhone, Apple Watch und Android. Sie führt die Scorekarte, rechnet das WHS-Handicap, zeigt auf einer Schlagkarte, wo jeder Schlag gelandet ist, und misst per GPS die Entfernung zur Fahne. Grundfunktionen sind kostenlos und ohne Konto nutzbar. Entwickelt in Deutschland von ${site.operator}.

GolfTrack (English): a golf and minigolf scoring app for iPhone, Apple Watch and Android – scorecard, WHS handicap, shot map and GPS distances. Free core features, no account needed.

## Funktionen

- Scorekarte für Golf (Zählspiel, Stableford u. a.) und Minigolf, auch für Gruppen
- WHS-Handicap-Berechnung aus den gespielten Runden
- Schlagkarte und Laufspur per GPS, Entfernung zum Grün, Schlägerweiten
- Apple-Watch-App zum Zählen am Handgelenk, Live Activity auf dem Sperrbildschirm
- Statistiken (Fairways, Greens in Regulation, Putts), Verlauf, Erfolge über Game Center
- Driving-Range-Modus mit Schläger und Weite
- Mit Freunden spielen: gemeinsame Runde per 5-stelligem Code oder QR-Code
- Platzreife lernen: Fragen zur Platzreifeprüfung mit Lernstand
- Minigolf ohne Installation: QR-Code an der Anlage öffnet App Clip oder Browser
- Sprachen: Deutsch, Englisch, Französisch, Italienisch, Spanisch, Polnisch, Tschechisch

## Preise

- Kostenlos: Runden, Scorekarte, Handicap, Statistiken
- GolfTrack Pro: 5 € im Monat, 50 € im Jahr oder 80 € einmalig – alle Audio-Trainings, keine Werbung

## Plätze

Das Verzeichnis enthält ${golf} ${golf === 1 ? "Golfplatz" : "Golfplätze"} und ${minigolf} ${minigolf === 1 ? "Minigolfanlage" : "Minigolfanlagen"}, vor allem in Deutschland. Jeder Platz hat eine eigene Seite mit Löchern, Par und Abschlägen.

- [Alle Plätze](${SITE_URL}/plaetze): Verzeichnis der Golf- und Minigolfplätze
- [Platz eintragen](${SITE_URL}/platz-melden): Betreiber melden ihre Anlage kostenlos an
- [Werbeplatz buchen](${SITE_URL}/werbung): Anzeigen in der App im Umkreis einer Anlage

## Links

- [Startseite](${SITE_URL}/): Überblick über die App
- [English version](${SITE_URL}/en)
- [App Store](${APP_STORE_URL}): GolfTrack für iPhone und Apple Watch
- [Android](${SITE_URL}/android): APK zum direkten Herunterladen
- [Hilfe & häufige Fragen](${SITE_URL}/support)
- [API](${SITE_URL}/api-docs): öffentliche Schnittstelle zu den Platzdaten
- [Spielen im Browser](${PLAY_URL}/start)

## Optional

- [Datenschutz](${SITE_URL}/datenschutz)
- [Impressum](${SITE_URL}/impressum)
- [Sitemap](${SITE_URL}/sitemap.xml)
`;

  return new Response(body, {
    headers: { "Content-Type": "text/markdown; charset=utf-8" },
  });
}
