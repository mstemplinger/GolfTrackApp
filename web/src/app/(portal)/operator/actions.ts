"use server";

import { cookies } from "next/headers";
import { MIN_OPERATOR_PASSWORD, OPERATOR_LANG_COOKIE, isOperatorLang } from "@/i18n/operator";
import { requestNameChange, withdrawNameRequest } from "@/lib/courseNameRequests";
import { sendEmailChangedNotice } from "@/lib/operatorMail";
import {
  checkCredentials,
  getOperator,
  resetOperatorPassword,
  updateOperatorProfile,
  verifyOperatorPassword,
} from "@/lib/operators";
import {
  clearLoginFailures,
  createOperatorSession,
  currentOperator,
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

// MARK: – Mein Konto

export interface AccountState {
  status?: "ok" | "error";
  /** Schlüssel in OperatorCopy.account (err…, saved, passwordChanged, requested). */
  message?: string;
  /** Für welchen Platz die Meldung gilt (Namensänderung). */
  slug?: string;
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** Name und E-Mail. Für eine neue E-Mail braucht es das aktuelle Passwort. */
export async function updateProfile(_prev: AccountState, formData: FormData): Promise<AccountState> {
  const op = await currentOperator();
  if (!op) return { status: "error", message: "errWrongPassword" };
  const name = String(formData.get("name") ?? "").trim();
  const email = String(formData.get("email") ?? "")
    .trim()
    .toLowerCase();
  if (!name || name.length > 120) return { status: "error", message: "errNameRequired" };
  if (!EMAIL_RE.test(email) || email.length > 200) return { status: "error", message: "errEmailInvalid" };

  const emailChanged = email !== op.email;
  if (emailChanged) {
    if (await loginLocked()) return { status: "error", message: "errLocked" };
    if (!(await verifyOperatorPassword(op.id, String(formData.get("currentPassword") ?? "")))) {
      await noteLoginFailure();
      return { status: "error", message: "errWrongPassword" };
    }
  }
  const result = await updateOperatorProfile(op.id, name, email);
  if (result.status === "email_taken") return { status: "error", message: "errEmailTaken" };
  if (emailChanged) await sendEmailChangedNotice(op.lang, name, op.email, email);
  return { status: "ok", message: "saved" };
}

/** Neues Passwort – beendet andere Sitzungen, diese bleibt angemeldet. */
export async function changePassword(_prev: AccountState, formData: FormData): Promise<AccountState> {
  const op = await currentOperator();
  if (!op) return { status: "error", message: "errWrongPassword" };
  if (await loginLocked()) return { status: "error", message: "errLocked" };
  const current = String(formData.get("currentPassword") ?? "");
  const next = String(formData.get("newPassword") ?? "");
  const repeat = String(formData.get("repeatPassword") ?? "");
  if (!(await verifyOperatorPassword(op.id, current))) {
    await noteLoginFailure();
    return { status: "error", message: "errWrongPassword" };
  }
  if (next.length < MIN_OPERATOR_PASSWORD || next.length > 200) return { status: "error", message: "errTooShort" };
  if (next !== repeat) return { status: "error", message: "errMismatch" };
  if (next === current) return { status: "error", message: "errSame" };
  await resetOperatorPassword(op.id, next);
  // Der Zeitstempel ist neu – mit ihm eine frische Sitzung für dieses Gerät.
  const fresh = await getOperator(op.id);
  if (fresh) await createOperatorSession(fresh);
  return { status: "ok", message: "passwordChanged" };
}

/** Neuer Name für einen eigenen Platz – wirksam erst nach Freigabe im Adminpanel. */
export async function requestCourseName(_prev: AccountState, formData: FormData): Promise<AccountState> {
  const op = await currentOperator();
  const slug = String(formData.get("slug") ?? "");
  if (!op || !op.courses.includes(slug)) return { status: "error", message: "errNameRequired", slug };
  const name = String(formData.get("name") ?? "").trim();
  if (!name || name.length > 120) return { status: "error", message: "errNameRequired", slug };
  const result = await requestNameChange(slug, name, { id: op.id, name: op.name });
  if (result === "unchanged") return { status: "error", message: "errNameUnchanged", slug };
  if (result !== "ok") return { status: "error", message: "errNameRequired", slug };
  return { status: "ok", message: "requested", slug };
}

export async function withdrawCourseName(formData: FormData): Promise<void> {
  const op = await currentOperator();
  if (!op) return;
  await withdrawNameRequest(String(formData.get("id") ?? ""), op.courses);
}
