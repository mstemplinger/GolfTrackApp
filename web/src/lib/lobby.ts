import "server-only";
import { createHash, randomBytes, randomInt } from "node:crypto";
import { z } from "zod";
import { query, queryOne } from "./db";
import { ensureSchema } from "./migrations";

/**
 * Lobby für gemeinsame Runden.
 *
 * Jeder spielt auf dem eigenen iPhone. Die App des Gastgebers legt eine Lobby
 * mit fünfstelligem Code an, die Freunde treten mit Code oder QR-Code bei.
 * Danach schickt jede App ihren Stand (Schläge, Putts, Schläger, aktuelles
 * Loch, auf Wunsch den Standort) und holt alle paar Sekunden den Stand der
 * anderen ab. Bewusst kein WebSocket: Abfragen alle paar Sekunden genügen auf
 * dem Platz, überstehen Funklöcher von allein und brauchen am Server nichts
 * außer den üblichen Routen.
 *
 * Wer dabei ist, weist sich mit einem Token aus, das nur beim Anlegen bzw.
 * Beitreten herausgegeben wird. Der Code allein zeigt nichts – erst das
 * Beitreten, und das sieht jeder in der Lobby.
 */

/** Ohne Lebenszeichen verschwindet eine Lobby samt Standorten nach dieser Zeit. */
const LOBBY_TTL_HOURS = 24;
/** Ältere Standorte gelten als veraltet und werden nicht mehr ausgeliefert. */
const LOCATION_MAX_AGE_MINUTES = 15;
export const MAX_MEMBERS = 8;

export const lobbyCodeSchema = z.string().regex(/^\d{5}$/);

const nameSchema = z.string().trim().min(1).max(30);

export const createLobbySchema = z.object({
  name: nameSchema,
  courseName: z.string().trim().max(120).default(""),
  courseSlug: z.string().trim().max(120).default(""),
  holes: z.number().int().min(1).max(36).default(18),
  tracking: z.boolean().default(true),
});

export const joinLobbySchema = z.object({ name: nameSchema });

const shotSchema = z.object({
  n: z.number().int().min(1).max(40),
  club: z.string().max(40).default(""),
  lat: z.number().min(-90).max(90).nullable().default(null),
  lon: z.number().min(-180).max(180).nullable().default(null),
  meters: z.number().min(0).max(1000).nullable().default(null),
});

const holeSchema = z.object({
  hole: z.number().int().min(1).max(36),
  strokes: z.number().int().min(0).max(40),
  putts: z.number().int().min(0).max(20).default(0),
  fairway: z.boolean().default(false),
  gir: z.boolean().default(false),
  shots: z.array(shotSchema).max(40).default([]),
});

export const pushStateSchema = z.object({
  currentHole: z.number().int().min(0).max(36).optional(),
  scores: z.array(holeSchema).max(36).optional(),
  shareLocation: z.boolean().optional(),
  location: z
    .object({
      lat: z.number().min(-90).max(90),
      lon: z.number().min(-180).max(180),
      accuracy: z.number().min(0).max(10000).default(0),
    })
    .nullable()
    .optional(),
});

export const settingsSchema = z.object({
  tracking: z.boolean().optional(),
  // Platz des Gastgebers – die Gäste übernehmen ihn automatisch.
  course: z
    .object({
      name: z.string().trim().max(120),
      slug: z.string().trim().max(120).default(""),
      holes: z.number().int().min(1).max(36),
    })
    .optional(),
  kick: z.string().uuid().optional(),
});

type LobbyRow = {
  code: string;
  course_name: string;
  course_slug: string;
  holes: number;
  tracking: boolean;
};

type MemberRow = {
  id: string;
  code: string;
  name: string;
  is_host: boolean;
  current_hole: number;
  scores: unknown;
  share_location: boolean;
  latitude: number | null;
  longitude: number | null;
  accuracy: number | null;
  location_at: Date | null;
  seen_at: Date;
};

export type Member = { id: string; code: string; isHost: boolean };

function hashToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

function newToken(): string {
  return randomBytes(24).toString("base64url");
}

async function purgeStale(): Promise<void> {
  await query(`DELETE FROM lobbies WHERE updated_at < now() - make_interval(hours => $1)`, [LOBBY_TTL_HOURS]);
}

async function touch(code: string): Promise<void> {
  await query(`UPDATE lobbies SET updated_at = now() WHERE code = $1`, [code]);
}

export async function createLobby(input: z.infer<typeof createLobbySchema>) {
  await ensureSchema();
  await purgeStale();

  // 90 000 Codes; belegte überspringen. Bei ein paar Dutzend gleichzeitigen
  // Lobbys trifft schon der erste Versuch fast immer.
  let code = "";
  for (let attempt = 0; attempt < 20; attempt++) {
    const candidate = String(randomInt(10000, 100000));
    const inserted = await query<{ code: string }>(
      `INSERT INTO lobbies (code, course_name, course_slug, holes, tracking)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (code) DO NOTHING RETURNING code`,
      [candidate, input.courseName, input.courseSlug, input.holes, input.tracking],
    );
    if (inserted.length) {
      code = candidate;
      break;
    }
  }
  if (!code) throw new Error("no_free_code");

  const token = newToken();
  const member = await queryOne<{ id: string }>(
    `INSERT INTO lobby_members (code, token_hash, name, is_host) VALUES ($1, $2, $3, true) RETURNING id`,
    [code, hashToken(token), input.name],
  );
  return { code, memberId: member!.id, token };
}

export type JoinResult =
  | { ok: true; memberId: string; token: string }
  | { ok: false; error: "not_found" | "full" };

export async function joinLobby(code: string, name: string): Promise<JoinResult> {
  await ensureSchema();
  await purgeStale();
  const lobby = await queryOne<{ count: string }>(
    `SELECT (SELECT count(*) FROM lobby_members m WHERE m.code = l.code) AS count
       FROM lobbies l WHERE l.code = $1`,
    [code],
  );
  if (!lobby) return { ok: false, error: "not_found" };
  if (Number(lobby.count) >= MAX_MEMBERS) return { ok: false, error: "full" };

  const token = newToken();
  const member = await queryOne<{ id: string }>(
    `INSERT INTO lobby_members (code, token_hash, name) VALUES ($1, $2, $3) RETURNING id`,
    [code, hashToken(token), name],
  );
  await touch(code);
  return { ok: true, memberId: member!.id, token };
}

/** Mitglied hinter dem Bearer-Token – `null`, wenn es nicht (mehr) dabei ist. */
export async function authenticate(request: Request, code: string): Promise<Member | null> {
  const header = request.headers.get("authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7).trim() : "";
  if (!token) return null;
  await ensureSchema();
  const row = await queryOne<{ id: string; code: string; is_host: boolean }>(
    `UPDATE lobby_members SET seen_at = now()
      WHERE code = $1 AND token_hash = $2
      RETURNING id, code, is_host`,
    [code, hashToken(token)],
  );
  return row ? { id: row.id, code: row.code, isHost: row.is_host } : null;
}

export async function lobbyState(member: Member) {
  const lobby = await queryOne<LobbyRow>(`SELECT * FROM lobbies WHERE code = $1`, [member.code]);
  if (!lobby) return null;
  const rows = await query<MemberRow>(
    `SELECT * FROM lobby_members WHERE code = $1 ORDER BY joined_at`,
    [member.code],
  );
  const freshAfter = Date.now() - LOCATION_MAX_AGE_MINUTES * 60_000;

  return {
    code: lobby.code,
    courseName: lobby.course_name,
    courseSlug: lobby.course_slug,
    holes: lobby.holes,
    tracking: lobby.tracking,
    me: member.id,
    members: rows.map((m) => {
      const located =
        lobby.tracking &&
        m.share_location &&
        m.latitude !== null &&
        m.longitude !== null &&
        m.location_at !== null &&
        new Date(m.location_at).getTime() >= freshAfter;
      return {
        id: m.id,
        name: m.name,
        isHost: m.is_host,
        currentHole: m.current_hole,
        // Siehe project-website: jsonb kommt je nach Weg als Text zurück.
        scores: typeof m.scores === "string" ? JSON.parse(m.scores) : m.scores,
        seenAt: new Date(m.seen_at).toISOString(),
        location: located
          ? {
              lat: m.latitude,
              lon: m.longitude,
              accuracy: m.accuracy ?? 0,
              at: new Date(m.location_at!).toISOString(),
            }
          : null,
      };
    }),
  };
}

export async function pushState(member: Member, input: z.infer<typeof pushStateSchema>): Promise<void> {
  const sets: string[] = [];
  const params: unknown[] = [member.id];
  const add = (column: string, value: unknown) => {
    params.push(value);
    sets.push(`${column} = $${params.length}`);
  };

  if (input.currentHole !== undefined) add("current_hole", input.currentHole);
  // jsonb roh an den Treiber geben, nicht stringifizieren (siehe migrations.ts).
  if (input.scores !== undefined) add("scores", input.scores);
  if (input.shareLocation !== undefined) add("share_location", input.shareLocation);
  if (input.location === null || input.shareLocation === false) {
    sets.push("latitude = NULL", "longitude = NULL", "accuracy = NULL", "location_at = NULL");
  } else if (input.location) {
    add("latitude", input.location.lat);
    add("longitude", input.location.lon);
    add("accuracy", input.location.accuracy);
    sets.push("location_at = now()");
  }
  if (!sets.length) return;

  await query(`UPDATE lobby_members SET ${sets.join(", ")} WHERE id = $1`, params);
  await touch(member.code);
}

export async function updateSettings(member: Member, input: z.infer<typeof settingsSchema>): Promise<void> {
  if (input.tracking !== undefined) {
    await query(`UPDATE lobbies SET tracking = $2, updated_at = now() WHERE code = $1`, [
      member.code,
      input.tracking,
    ]);
  }
  if (input.course) {
    await query(
      `UPDATE lobbies SET course_name = $2, course_slug = $3, holes = $4, updated_at = now() WHERE code = $1`,
      [member.code, input.course.name, input.course.slug, input.course.holes],
    );
  }
  if (input.kick && input.kick !== member.id) {
    await query(`DELETE FROM lobby_members WHERE id = $1 AND code = $2`, [input.kick, member.code]);
  }
}

/** Verlässt der Gastgeber die Lobby, endet sie für alle. */
export async function leaveLobby(member: Member): Promise<void> {
  if (member.isHost) {
    await query(`DELETE FROM lobbies WHERE code = $1`, [member.code]);
  } else {
    await query(`DELETE FROM lobby_members WHERE id = $1`, [member.id]);
  }
}

/**
 * Einfache Bremse gegen das Durchprobieren der Codes. Je Prozess im Speicher –
 * die Seite läuft als eine pm2-Instanz, mehr braucht es nicht.
 */
const attempts = new Map<string, { count: number; resetAt: number }>();

export function joinAllowed(request: Request): boolean {
  const ip = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "local";
  const now = Date.now();
  const entry = attempts.get(ip);
  if (!entry || entry.resetAt < now) {
    attempts.set(ip, { count: 1, resetAt: now + 10 * 60_000 });
    if (attempts.size > 5000) {
      for (const [key, value] of attempts) if (value.resetAt < now) attempts.delete(key);
    }
    return true;
  }
  entry.count += 1;
  return entry.count <= 30;
}
