"use server";

import { cookies } from "next/headers";
import { PLAY_LANG_COOKIE, isPlayLang } from "@/i18n/play";

/** Merkt sich die Sprache aus der Sprachleiste des Spielbereichs für ein Jahr. */
export async function choosePlayLang(lang: string) {
  if (!isPlayLang(lang)) return;
  (await cookies()).set(PLAY_LANG_COOKIE, lang, {
    path: "/",
    maxAge: 60 * 60 * 24 * 365,
    sameSite: "lax",
  });
}
