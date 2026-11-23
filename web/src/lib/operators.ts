import "server-only";
import { randomBytes, scrypt as scryptCb, timingSafeEqual } from "node:crypto";
import { promisify } from "node:util";
import { z } from "zod";
import { query, queryOne } from "./db";
import { ensureSchema } from "./migrations";

/**
 * Betreiberkonten für operator.golftrack.app. Ein Konto sieht die
 * Rundenstatistik der Plätze, die ihm im Adminpanel zugewiesen sind – und
 * davon nur die freigegebenen Bausteine (`permissions`).
 *
 * Passwörter vergibt das Adminpanel (zufällig, einmal angezeigt); hier liegt
 * nur der scrypt-Hash.
 */

const scrypt = promisify(scryptCb) as (pw: string, salt: Buffer, keylen: number) => Promise<Buffer>;

import { isSection, type OperatorSection } from "./sections";

export { ALL_SECTIONS, OPERATOR_SECTIONS, isSection, type OperatorSection } from "./sections";

export interface Operator {
  id: string;
  name: string;
  email: string;
  permissions: OperatorSection[];
  active: boolean;
  notes: string;
  /** Sprache der Zugangsmails und Vorgabe fürs Portal. */
  lang: "de" | "en";
  createdAt: string;
  passwordChangedAt: string;
  lastLoginAt: string | null;
  courses: string[];
}

export const operatorInputSchema = z.object({
  name: z.string().trim().min(1, "name_required").max(120),
  email: z.string().trim().toLowerCase().email("email_invalid").max(200),
  notes: z.string().trim().max(2000).default(""),
  permissions: z.array(z.string()).transform((list) => list.filter(isSection)),
  courses: z.array(z.string().trim().min(1).max(200)).max(200),
  active: z.boolean().default(true),
  lang: z.enum(["de", "en"]).default("de"),
});
export type OperatorInput = z.infer<typeof operatorInputSchema>;

// MARK: – Passwörter

/** Gut lesbares Zufallspasswort: 16 Zeichen ohne verwechselbare Zeichen. */
export function generatePassword(): string {
  const alphabet = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const bytes = randomBytes(16);
  let out = "";
  for (let i = 0; i < 16; i += 1) {
    out += alphabet[bytes[i] % alphabet.length];
    if (i === 3 || i === 7 || i === 11) out += "-";
  }
  return out;
}

export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(16);
  const hash = await scrypt(password, salt, 64);
  return `scrypt$${salt.toString("base64")}$${hash.toString("base64")}`;
}

export async function verifyPassword(password: string, stored: string): Promise<boolean> {
  const [scheme, saltB64, hashB64] = stored.split("$");
  if (scheme !== "scrypt" || !saltB64 || !hashB64) return false;
  const expected = Buffer.from(hashB64, "base64");
  const actual = await scrypt(password, Buffer.from(saltB64, "base64"), expected.length);
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}

// MARK: – Lesen

interface Row {
  id: string;
  name: string;
  email: string;
  permissions: string[] | null;
  active: boolean;
  notes: string;
  lang: string | null;
  created_at: string | Date;
  password_changed_at: string | Date;
  last_login_at: string | Date | null;
  courses: string[] | null;
}

const iso = (v: string | Date | null) => (v == null ? null : new Date(v).toISOString());

function mapRow(r: Row): Operator {
  return {
    id: String(r.id),
    name: r.name,
    email: r.email,
    permissions: (r.permissions ?? []).filter(isSection),
    active: Boolean(r.active),
    notes: r.notes ?? "",
    lang: r.lang === "en" ? "en" : "de",
    createdAt: iso(r.created_at)!,
    passwordChangedAt: iso(r.password_changed_at)!,
    lastLoginAt: iso(r.last_login_at),
    courses: (r.courses ?? []).filter(Boolean),
  };
}

const SELECT = `
  SELECT o.id, o.name, o.email, o.permissions, o.active, o.notes, o.lang, o.created_at,
         o.password_changed_at, o.last_login_at,
         COALESCE(array_agg(oc.course_slug ORDER BY oc.course_slug) FILTER (WHERE oc.course_slug IS NOT NULL), '{}') AS courses
    FROM operators o
    LEFT JOIN operator_courses oc ON oc.operator_id = o.id`;

const isUuid = (v: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);

export async function listOperators(): Promise<Operator[]> {
  await ensureSchema();
  const rows = await query<Row & Record<string, unknown>>(`${SELECT} GROUP BY o.id ORDER BY o.name`);
  return rows.map(mapRow);
}

export async function getOperator(id: string): Promise<Operator | null> {
  if (!isUuid(id)) return null;
  await ensureSchema();
  const row = await queryOne<Row & Record<string, unknown>>(`${SELECT} WHERE o.id = $1 GROUP BY o.id`, [id]);
  return row ? mapRow(row) : null;
}

/** Betreiber, die einen bestimmten Platz sehen – für die Platzseite im Admin. */
export async function operatorsForCourse(slug: string): Promise<{ id: string; name: string }[]> {
  await ensureSchema();
  return query<{ id: string; name: string }>(
    `SELECT o.id, o.name FROM operators o JOIN operator_courses oc ON oc.operator_id = o.id
      WHERE oc.course_slug = $1 ORDER BY o.name`,
    [slug],
  );
}

// MARK: – Schreiben

async function setCourses(id: string, courses: string[]): Promise<void> {
  await query(`DELETE FROM operator_courses WHERE operator_id = $1`, [id]);
  for (const slug of [...new Set(courses)]) {
    await query(`INSERT INTO operator_courses (operator_id, course_slug) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [
      id,
      slug,
    ]);
  }
}

export type SaveResult = { status: "ok"; id: string } | { status: "email_taken" };

/** Neues Konto mit vorgegebenem (zufälligem) Passwort. */
export async function createOperator(input: OperatorInput, password: string): Promise<SaveResult> {
  await ensureSchema();
  const taken = await queryOne(`SELECT 1 FROM operators WHERE email = $1`, [input.email]);
  if (taken) return { status: "email_taken" };
  const row = await queryOne<{ id: string }>(
    `INSERT INTO operators (name, email, password_hash, permissions, active, notes, lang)
     VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
    [input.name, input.email, await hashPassword(password), input.permissions, input.active, input.notes, input.lang],
  );
  const id = String(row!.id);
  await setCourses(id, input.courses);
  return { status: "ok", id };
}

export async function updateOperator(id: string, input: OperatorInput): Promise<SaveResult> {
  await ensureSchema();
  const taken = await queryOne(`SELECT 1 FROM operators WHERE email = $1 AND id <> $2`, [input.email, id]);
  if (taken) return { status: "email_taken" };
  await query(
    `UPDATE operators SET name = $2, email = $3, permissions = $4, active = $5, notes = $6, lang = $7 WHERE id = $1`,
    [id, input.name, input.email, input.permissions, input.active, input.notes, input.lang],
  );
  await setCourses(id, input.courses);
  return { status: "ok", id };
}

export async function resetOperatorPassword(id: string, password: string): Promise<void> {
  await ensureSchema();
  // password_changed_at beendet zugleich alle bestehenden Sitzungen (siehe operatorAuth.ts).
  await query(`UPDATE operators SET password_hash = $2, password_changed_at = now() WHERE id = $1`, [
    id,
    await hashPassword(password),
  ]);
}

export async function deleteOperator(id: string): Promise<void> {
  await ensureSchema();
  await query(`DELETE FROM operators WHERE id = $1`, [id]);
}

// MARK: – Anmeldung

/** Konto zu E-Mail und Passwort – nur aktive Konten. */
// MARK: – Selbstverwaltung im Portal

/** Prüft das aktuelle Passwort eines Kontos (für Änderungen durch den Betreiber selbst). */
export async function verifyOperatorPassword(id: string, password: string): Promise<boolean> {
  await ensureSchema();
  const row = await queryOne<{ password_hash: string }>(`SELECT password_hash FROM operators WHERE id = $1`, [id]);
  return row ? verifyPassword(password, row.password_hash) : false;
}

/** Name und E-Mail ändern – E-Mail nur, wenn kein anderes Konto sie hat. */
export async function updateOperatorProfile(
  id: string,
  name: string,
  email: string,
): Promise<{ status: "ok" } | { status: "email_taken" }> {
  await ensureSchema();
  const normalized = email.trim().toLowerCase();
  const taken = await queryOne(`SELECT 1 FROM operators WHERE email = $1 AND id <> $2`, [normalized, id]);
  if (taken) return { status: "email_taken" };
  await query(`UPDATE operators SET name = $2, email = $3 WHERE id = $1`, [id, name.trim(), normalized]);
  return { status: "ok" };
}

export async function checkCredentials(email: string, password: string): Promise<Operator | null> {
  await ensureSchema();
  const row = await queryOne<{ id: string; password_hash: string; active: boolean }>(
    `SELECT id, password_hash, active FROM operators WHERE email = $1`,
    [email.trim().toLowerCase()],
  );
  // Auch ohne Treffer einmal hashen, damit die Antwortzeit nichts verrät.
  const ok = await verifyPassword(password, row?.password_hash ?? "scrypt$AAAAAAAAAAAAAAAAAAAAAA==$" + "A".repeat(88));
  if (!row || !row.active || !ok) return null;
  await query(`UPDATE operators SET last_login_at = now() WHERE id = $1`, [row.id]);
  return getOperator(String(row.id));
}
