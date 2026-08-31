export const LANGS = ["de", "en"] as const;
export type Lang = (typeof LANGS)[number];

/** Sprechende Pfade je Sprache. Deutsch liegt ohne Präfix auf der Wurzel. */
const PATHS = {
  home: { de: "/", en: "/en" },
  submit: { de: "/platz-melden", en: "/en/submit-course" },
  directory: { de: "/plaetze", en: "/en/courses" },
  support: { de: "/support", en: "/en/support" },
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
