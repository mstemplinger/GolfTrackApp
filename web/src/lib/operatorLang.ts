import "server-only";
import { cookies, headers } from "next/headers";
import {
  OPERATOR_LANG_COOKIE,
  isOperatorLang,
  operatorCopy,
  operatorLangFromAccept,
  type OperatorCopy,
  type OperatorLang,
} from "@/i18n/operator";

/** Sprache des Portals: eigene Wahl (Cookie), sonst die des Browsers (de oder en). */
export async function operatorLang(): Promise<OperatorLang> {
  const chosen = (await cookies()).get(OPERATOR_LANG_COOKIE)?.value;
  if (isOperatorLang(chosen)) return chosen;
  return operatorLangFromAccept((await headers()).get("accept-language"));
}

export async function operatorT(): Promise<{ lang: OperatorLang; t: OperatorCopy }> {
  const lang = await operatorLang();
  return { lang, t: operatorCopy(lang) };
}
