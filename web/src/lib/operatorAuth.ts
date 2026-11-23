import "server-only";
import { createHmac, timingSafeEqual } from "node:crypto";
import { cookies, headers } from "next/headers";
import { getOperator, type Operator } from "./operators";

/**
 * Sitzungen der Betreiber auf operator.golftrack.app – getrennt vom
 * Adminpanel: eigenes Cookie, eigener Schlüssel (abgeleitet vom
 * ADMIN_SECRET, aber mit anderem Zweck), und das Cookie gilt nur für die
 * Subdomain (ohne `Domain`-Attribut).
 *
 * Inhalt: Konto, Ablauf und der Zeitpunkt der letzten Passwortänderung.
 * Setzt das Adminpanel ein neues Passwort, passt der Zeitpunkt nicht mehr –
 * alle bestehenden Sitzungen des Kontos enden damit sofort. Ein deaktiviertes
 * oder gelöschtes Konto fällt bei der Prüfung gegen die Datenbank heraus.
 */

export const OPERATOR_COOKIE = "gt_operator";
const MAX_AGE_SECONDS = 60 * 60 * 24 * 14;

function key(): string {
  const base = process.env.ADMIN_SECRET || process.env.ADMIN_PASSWORD || "";
  return `operator-session:${base}`;
}

function sign(payload: string): string {
  return createHmac("sha256", key()).update(payload).digest("base64url");
}

function safeEqual(a: string, b: string): boolean {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}

export async function createOperatorSession(op: Operator): Promise<void> {
  const expires = Date.now() + MAX_AGE_SECONDS * 1000;
  const changed = new Date(op.passwordChangedAt).getTime();
  const payload = `${op.id}.${expires}.${changed}`;
  (await cookies()).set(OPERATOR_COOKIE, `${payload}.${sign(payload)}`, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: MAX_AGE_SECONDS,
  });
}

export async function destroyOperatorSession(): Promise<void> {
  (await cookies()).delete(OPERATOR_COOKIE);
}

/** Angemeldeter Betreiber – oder `null` (abgelaufen, gesperrt, Passwort geändert). */
export async function currentOperator(): Promise<Operator | null> {
  const raw = (await cookies()).get(OPERATOR_COOKIE)?.value;
  if (!raw) return null;
  const parts = raw.split(".");
  if (parts.length !== 4) return null;
  const [id, expires, changed, signature] = parts;
  if (!safeEqual(signature, sign(`${id}.${expires}.${changed}`))) return null;
  if (Number(expires) < Date.now()) return null;
  const op = await getOperator(id);
  if (!op || !op.active) return null;
  if (new Date(op.passwordChangedAt).getTime() !== Number(changed)) return null;
  return op;
}

// MARK: – Drosselung

const MAX_FAILURES = 8;
const WINDOW_MS = 15 * 60 * 1000;
const failures = new Map<string, number[]>();

async function clientKey(): Promise<string> {
  return (await headers()).get("x-real-ip")?.trim() || "unknown";
}

function recent(k: string): number[] {
  const cutoff = Date.now() - WINDOW_MS;
  const list = (failures.get(k) ?? []).filter((t) => t > cutoff);
  if (list.length) failures.set(k, list);
  else failures.delete(k);
  return list;
}

/** `true`, wenn diese Adresse gerade zu viele Fehlversuche hatte. */
export async function loginLocked(): Promise<boolean> {
  return recent(await clientKey()).length >= MAX_FAILURES;
}

export async function noteLoginFailure(): Promise<void> {
  const k = await clientKey();
  failures.set(k, [...recent(k), Date.now()]);
  if (failures.size > 5000) failures.clear();
}

export async function clearLoginFailures(): Promise<void> {
  failures.delete(await clientKey());
}
