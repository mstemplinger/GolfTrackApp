"use server";

import { cookies } from "next/headers";
import { OPERATOR_LANG_COOKIE, isOperatorLang } from "@/i18n/operator";
import { checkCredentials } from "@/lib/operators";
import {
  clearLoginFailures,
  createOperatorSession,
  destroyOperatorSession,
  loginLocked,
  noteLoginFailure,
} from "@/lib/operatorAuth";

export interface LoginState {
  error?: "wrong" | "locked";
  /** Bleibt nach einem Fehlversuch im Feld stehen (React leert das Formular). */
  email?: string;
  /** Angemeldet – der Browser lädt dann die Startseite des Portals neu. */
  done?: boolean;
}

/**
 * Anmeldung im Betreiber-Portal.
 *
 * Bewusst kein `redirect()`: Next rendert das Ziel einer Weiterleitung aus
 * einer Server-Aktion direkt in derselben Antwort – am Proxy vorbei, der auf
 * der Subdomain „/“ auf „/operator“ umschreibt. Heraus kam die Startseite
 * von golftrack.app. Deshalb navigiert der Browser selbst (LoginForm).
 */
export async function login(_prev: LoginState, formData: FormData): Promise<LoginState> {
  const email = String(formData.get("email") ?? "");
  if (await loginLocked()) return { error: "locked", email };
  const password = String(formData.get("password") ?? "");
  const op = email && password ? await checkCredentials(email, password) : null;
  if (!op) {
    await noteLoginFailure();
    return { error: "wrong", email };
  }
  await clearLoginFailures();
  await createOperatorSession(op);
  // Noch keine eigene Sprachwahl? Dann die des Kontos (aus dem Adminpanel).
  const jar = await cookies();
  if (!isOperatorLang(jar.get(OPERATOR_LANG_COOKIE)?.value)) {
    jar.set(OPERATOR_LANG_COOKIE, op.lang, { path: "/", maxAge: 60 * 60 * 24 * 365, sameSite: "lax" });
  }
  return { done: true };
}

export async function logout(): Promise<void> {
  await destroyOperatorSession();
}

/** Eigene Sprachwahl für ein Jahr merken. */
export async function setOperatorLang(lang: string): Promise<void> {
  if (!isOperatorLang(lang)) return;
  (await cookies()).set(OPERATOR_LANG_COOKIE, lang, { path: "/", maxAge: 60 * 60 * 24 * 365, sameSite: "lax" });
}
