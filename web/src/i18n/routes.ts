export const LANGS = ["de", "en"] as const;
export type Lang = (typeof LANGS)[number];

/** Sprechende Pfade je Sprache. Deutsch liegt ohne Präfix auf der Wurzel. */
const PATHS = {
  home: { de: "/", en: "/en" },
  submit: { de: "/platz-melden", en: "/en/submit-course" },
  directory: { de: "/plaetze", en: "/en/courses" },
  support: { de: "/support", en: "/en/support" },
  /**
   * Die Betreiberseite gibt es nur auf Deutsch – das Angebot richtet sich an
   * Anlagen im deutschsprachigen Raum, und das Buchungsformular ist es auch.
   * Der englische Pfad zeigt deshalb bewusst auf dieselbe Seite statt ins
   * Leere; im englischen Menü taucht sie gar nicht erst auf.
   */
  advertise: { de: "/werbung", en: "/werbung" },
  privacy: { de: "/datenschutz", en: "/en/privacy" },
  imprint: { de: "/impressum", en: "/en/legal-notice" },
  api: { de: "/api-docs", en: "/en/api-docs" },
} as const;

export type RouteKey = keyof typeof PATHS;

export function path(key: RouteKey, lang: Lang): string {
  return PATHS[key][lang];
}

/** Gegenstück zur aktuellen Seite in der anderen Sprache. */
export function alternatePath(key: RouteKey, lang: Lang): string {
  return path(key, lang === "de" ? "en" : "de");
}

export const APP_STORE_URL = "https://apps.apple.com/app/id6767996957";
export const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL ?? "https://golftrack.app";
/**
 * Kurzform für gedruckte QR-Codes: `play.golftrack.app/p/<kennung>`.
 *
 * Eigene Subdomain aus zwei Gründen. Erstens kürzer, also ein gröberes
 * QR-Muster, das vom Schild am Abschlag auch aus zwei Metern liest. Zweitens
 * deckt ein einziger Eintrag als Advanced App Clip Experience über den
 * Präfix-Vergleich alle Plätze ab – sonst bräuchte jeder Platz seinen eigenen.
 */
export const PLAY_URL = process.env.NEXT_PUBLIC_PLAY_URL ?? "https://play.golftrack.app";
