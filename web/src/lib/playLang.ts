import { cookies, headers } from "next/headers";
import { PLAY_LANG_COOKIE, isPlayLang, langFromAcceptLanguage, type PlayLang } from "@/i18n/play";

/**
 * Sprache des Spielbereichs für die laufende Anfrage.
 *
 * Reihenfolge: `?lang=` in der Adresse (für Aushänge in einer bestimmten
 * Sprache), dann die eigene Wahl über die Sprachleiste (Cookie), dann die
 * Sprache des Browsers, sonst Deutsch.
 */
export async function playLang(query?: string | string[]): Promise<PlayLang> {
  const fromQuery = Array.isArray(query) ? query[0] : query;
  if (isPlayLang(fromQuery)) return fromQuery;

  const chosen = (await cookies()).get(PLAY_LANG_COOKIE)?.value;
  if (isPlayLang(chosen)) return chosen;

  return langFromAcceptLanguage((await headers()).get("accept-language")) ?? "de";
}
