import { cookies, headers } from "next/headers";

/**
 * Adminzugang: ein Passwort aus der Umgebung, danach ein signiertes Cookie.
 * Kein Nutzerkonto, keine Sitzungstabelle – für ein Ein-Personen-Backoffice
 * ist das die kleinste Lösung, die sauber trägt.
 */

export const COOKIE = "gt_admin";
const MAX_AGE_SECONDS = 60 * 60 * 12;

function secret(): string {
  return process.env.ADMIN_SECRET || process.env.ADMIN_PASSWORD || "";
}

async function sign(payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret()),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload));
  return Buffer.from(signature).toString("base64url");
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i += 1) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

export function adminConfigured(): boolean {
  return Boolean(process.env.ADMIN_PASSWORD);
}

export function passwordMatches(candidate: string): boolean {
  const expected = process.env.ADMIN_PASSWORD ?? "";
  return expected.length > 0 && timingSafeEqual(candidate, expected);
}

export async function createSession(): Promise<void> {
  const expires = Date.now() + MAX_AGE_SECONDS * 1000;
  const value = `${expires}.${await sign(String(expires))}`;
  (await cookies()).set(COOKIE, value, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: MAX_AGE_SECONDS,
  });
}

export async function destroySession(): Promise<void> {
  (await cookies()).delete(COOKIE);
}

export async function isAuthenticated(): Promise<boolean> {
  return validSession((await cookies()).get(COOKIE)?.value);
}

/** Prüft den Wert des Sitzungs-Cookies – auch für den Proxy, der kein `cookies()` hat. */
export async function validSession(raw: string | undefined): Promise<boolean> {
  if (!adminConfigured()) return false;
  if (!raw) return false;
  const [expires, signature] = raw.split(".");
  if (!expires || !signature) return false;
  if (Number(expires) < Date.now()) return false;
  return timingSafeEqual(signature, await sign(expires));
}

/**
 * Absender-IP fürs Rate-Limit. nginx setzt `X-Real-IP` hart auf
 * `$remote_addr`; `X-Forwarded-For` beginnt dagegen mit dem, was der Client
 * selbst mitschickt, und taugt deshalb nicht als Schlüssel.
 */
export async function clientIp(): Promise<string> {
  return (await headers()).get("x-real-ip")?.trim() || "unknown";
}

/**
 * Drosselung des Passwort-Logins: höchstens `LOGIN_MAX_FAILURES` Fehlversuche
 * je IP in `LOGIN_WINDOW_MS`. Im Speicher genügt das, weil die Seite in genau
 * einem Prozess läuft (siehe `deploy/ecosystem.config.js`).
 */
const LOGIN_MAX_FAILURES = 5;
const LOGIN_WINDOW_MS = 15 * 60 * 1000;
const loginFailures = new Map<string, number[]>();

function recentFailures(ip: string): number[] {
  const cutoff = Date.now() - LOGIN_WINDOW_MS;
  const recent = (loginFailures.get(ip) ?? []).filter((time) => time > cutoff);
  if (recent.length > 0) loginFailures.set(ip, recent);
  else loginFailures.delete(ip);
  return recent;
}

/**
 * Prüft das Passwort mit Drosselung. `"locked"`, solange die IP gesperrt ist –
 * dann wird das Passwort gar nicht erst verglichen.
 */
export async function attemptLogin(candidate: string): Promise<"ok" | "wrong" | "locked"> {
  const ip = await clientIp();
  if (recentFailures(ip).length >= LOGIN_MAX_FAILURES) return "locked";
  if (passwordMatches(candidate)) {
    loginFailures.delete(ip);
    return "ok";
  }
  loginFailures.set(ip, [...recentFailures(ip), Date.now()]);
  return "wrong";
}

/** Stabiler, nicht rückrechenbarer Schlüssel pro Absender fürs Rate-Limit. */
export async function hashIp(ip: string): Promise<string> {
  const data = new TextEncoder().encode(`${ip}:${secret()}`);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Buffer.from(digest).toString("base64url").slice(0, 32);
}

/**
 * Zweiter Weg ins Backoffice: ein fester Schlüssel im `Authorization`-Kopf,
 * für Maschinen statt Menschen (siehe `docs/freigabe-telegram-windows.md`).
 * Bewusst getrennt vom Adminpasswort – der Schlüssel liegt auf einem anderen
 * Rechner und lässt sich austauschen, ohne das Passwort zu ändern.
 */
export function apiTokenConfigured(): boolean {
  return (process.env.ADMIN_API_TOKEN ?? "").length >= 16;
}

export function apiTokenMatches(authorizationHeader: string | null): boolean {
  if (!apiTokenConfigured()) return false;
  const expected = process.env.ADMIN_API_TOKEN ?? "";
  const candidate = (authorizationHeader ?? "").replace(/^Bearer\s+/i, "").trim();
  return candidate.length > 0 && timingSafeEqual(candidate, expected);
}
