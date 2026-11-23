import "server-only";
import { z } from "zod";
import { query } from "./db";
import { ensureSchema } from "./migrations";
import { getCourse } from "./courses";
import { teeColor } from "./schema";

/**
 * Anonyme Rundenstatistik für Platzbetreiber (Phase 1: nur sammeln).
 *
 * Spieler, die es erlauben, schicken nach einer Runde eine grobe Zusammen-
 * fassung: Tag, Tagesabschnitt, Dauer in 15-Minuten-Stufen, Gruppengröße und
 * Schläge je Loch. Keine Namen, keine Geräte- oder Rundenkennung, keine
 * Uhrzeit, keine Koordinaten. Gespeichert wird auch kein Eingangszeitpunkt –
 * die Zeile kennt nur den Spieltag.
 *
 * Ausgewertet wird später nur als Summe ab `MIN_ROUNDS_FOR_DISPLAY` Runden
 * (Konzept: docs/betreiber-dashboard-konzept.md).
 */

export const MIN_ROUNDS_FOR_DISPLAY = 10;
/** Rohzeilen bleiben gut ein Jahr – genug für den Vorjahresvergleich. */
export const RETENTION_DAYS = 400;
/** Ältere Runden nimmt der Server nicht mehr an (Warteschlange auf dem Gerät). */
const MAX_AGE_DAYS = 30;

export const SLOTS = ["morning", "midday", "afternoon", "evening"] as const;
export const SOURCES = ["app", "clip", "web"] as const;

const strokes = z.number().int().min(0).max(20);

export const roundStatsSchema = z
  .object({
    version: z.literal(1),
    kind: z.enum(["golf", "minigolf"]),
    /** Spieltag in Ortszeit des Geräts, `YYYY-MM-DD`. */
    day: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    slot: z.enum(SLOTS),
    /** 1 = Montag … 7 = Sonntag. */
    weekday: z.number().int().min(1).max(7),
    holesPlayed: z.number().int().min(1).max(36),
    /** Auf 15 Minuten gerundet; `null`, wenn die Dauer nicht belastbar ist. */
    durationMinutes: z.number().int().min(15).max(600).multipleOf(15).nullable().default(null),
    teeColor: teeColor.nullable().default(null),
    /** Je Spieler die Schläge je Loch (0 = nicht gespielt). Ohne Namen. */
    strokes: z.array(z.array(strokes).min(1).max(36)).min(1).max(8),
    /** Nur Golf und nur, wenn erfasst: Putts je Loch, gleiche Form. */
    putts: z.array(z.array(strokes).min(1).max(36)).min(1).max(8).nullable().default(null),
    source: z.enum(SOURCES),
  })
  .refine((v) => v.strokes.every((row) => row.length === v.strokes[0].length), "uneven_rows")
  .refine((v) => !v.putts || v.putts.length === v.strokes.length, "putts_shape");

export type RoundStatsUpload = z.infer<typeof roundStatsSchema>;

export type RoundStatsResult =
  | { status: "ok" }
  | { status: "unknown_course" }
  | { status: "rejected"; reason: string };

function dayAgeInDays(day: string): number | null {
  const parsed = Date.parse(`${day}T12:00:00Z`);
  if (Number.isNaN(parsed)) return null;
  return (Date.now() - parsed) / 86_400_000;
}

export async function submitRoundStats(slug: string, upload: RoundStatsUpload): Promise<RoundStatsResult> {
  const course = await getCourse(slug);
  if (!course || course.status !== "approved" || course.kind !== upload.kind) return { status: "unknown_course" };

  const age = dayAgeInDays(upload.day);
  // Halber Tag Spielraum nach vorn für Zeitzonen.
  if (age == null || age < -0.6 || age > MAX_AGE_DAYS) return { status: "rejected", reason: "bad_day" };

  const holes = upload.strokes[0].length;
  if (holes > course.holes) return { status: "rejected", reason: "too_many_holes" };
  // Nur gespielte Spieler behalten (eine Zeile voller Nullen ist ein leerer Platzhalter).
  const keep = upload.strokes.map((row) => row.some((s) => s > 0));
  const strokesRows = upload.strokes.filter((_, i) => keep[i]);
  if (!strokesRows.length) return { status: "rejected", reason: "empty" };
  const puttRows = upload.kind === "golf" && upload.putts ? upload.putts.filter((_, i) => keep[i]) : null;

  await ensureSchema();
  await query(
    `INSERT INTO round_stats
       (course_slug, kind, played_on, slot, weekday, holes_played, duration_min,
        tee_color, players, strokes, putts, source)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::jsonb, $11::jsonb, $12)`,
    [
      slug,
      upload.kind,
      upload.day,
      upload.slot,
      upload.weekday,
      Math.min(upload.holesPlayed, holes),
      upload.durationMinutes,
      upload.kind === "golf" ? (upload.teeColor ?? "") : "",
      strokesRows.length,
      // jsonb roh an den Treiber – nicht stringifizieren (siehe courses.ts).
      strokesRows,
      puttRows,
      upload.source,
    ],
  );
  await query(`DELETE FROM round_stats WHERE played_on < current_date - ${RETENTION_DAYS}`);
  return { status: "ok" };
}
