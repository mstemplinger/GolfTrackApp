import "server-only";
import { z } from "zod";
import { query, queryOne } from "./db";
import { ensureSchema } from "./migrations";
import { getCourse, updateCourse, type CourseRecord } from "./courses";
import { teeColor, type Hole, type TeeColor } from "./schema";
import {
  MAX_CONTRIBUTIONS_PER_POINT,
  MAX_DISTANCE_FROM_COURSE_METERS,
  consensus,
  decide,
  distanceMeters,
  roundPoint,
  type GeoPoint,
  type GeometryKind,
} from "./geometryConsensus";

/**
 * Crowd-Positionen: Spieler, die es in der App erlauben, schicken nach der
 * Runde die daraus abgeleiteten Abschlag- und Grünpunkte je Loch. Keine
 * Laufspur, keine Kennung – nur Punkte. Sobald genug Beiträge zusammenpassen
 * (`geometryConsensus.ts`), landet der Wert in `hole_data` und kommt über
 * den Katalog bei allen an.
 *
 * Angaben des Betreibers (Formular mit Satellitenkarte) überschreibt das nie;
 * dort wird ein deutlicher Widerspruch nur in `course_geometry` vermerkt.
 */

const coordinate = z.object({
  lat: z.number().min(-90).max(90),
  lon: z.number().min(-180).max(180),
  /** 0…1 – wie sicher sich das Gerät ist; schwache Punkte schickt es gar nicht erst. */
  confidence: z.number().min(0).max(1),
});

export const geometryUploadSchema = z.object({
  version: z.literal(1),
  /** Gespielter Abschlag; `null`, wenn die Runde keinen kennt. */
  teeColor: teeColor.nullable().default(null),
  holes: z
    .array(
      z.object({
        hole: z.number().int().min(1).max(36),
        tee: coordinate.nullable().default(null),
        green: coordinate.nullable().default(null),
      }),
    )
    .min(1)
    .max(36),
});
export type GeometryUpload = z.infer<typeof geometryUploadSchema>;

/**
 * Punkte unter dieser Sicherheit nimmt der Server nicht an. Eine einzelne
 * Runde mit Stillstand in der Laufspur liegt bei ~0,33 (siehe
 * `CrowdGeometryService.minConfidence` in der App).
 */
const MIN_CONFIDENCE = 0.3;

export type UploadResult =
  | { status: "ok"; accepted: number; applied: number }
  | { status: "unknown_course" }
  | { status: "rejected"; reason: string };

/** Ein Punkt, der zusammengefasst wird: Loch, Art, Farbe (leer = Standard/Grün). */
interface PointKey {
  hole: number;
  kind: GeometryKind;
  color: string;
}

/**
 * Je Platz nacheinander, damit zwei gleichzeitige Uploads sich `hole_data`
 * nicht gegenseitig überschreiben. Die Seite läuft als eine pm2-Instanz.
 */
const queues = new Map<string, Promise<unknown>>();
function serialized<T>(slug: string, task: () => Promise<T>): Promise<T> {
  const previous = queues.get(slug) ?? Promise.resolve();
  const next = previous.catch(() => undefined).then(task);
  queues.set(slug, next);
  void next.finally(() => {
    if (queues.get(slug) === next) queues.delete(slug);
  });
  return next;
}

export function submitGeometry(slug: string, upload: GeometryUpload): Promise<UploadResult> {
  return serialized(slug, () => handleUpload(slug, upload));
}

async function handleUpload(slug: string, upload: GeometryUpload): Promise<UploadResult> {
  const course = await getCourse(slug);
  if (!course || course.status !== "approved" || course.kind !== "golf") return { status: "unknown_course" };

  const center = courseCenter(course);
  const color = upload.teeColor ?? "";
  const rows: { key: PointKey; point: GeoPoint }[] = [];
  for (const entry of upload.holes) {
    if (entry.hole > course.holes) continue;
    for (const kind of ["tee", "green"] as const) {
      const value = entry[kind];
      if (!value || value.confidence < MIN_CONFIDENCE) continue;
      const point = roundPoint({ lat: value.lat, lon: value.lon });
      if (center && distanceMeters(point, center) > MAX_DISTANCE_FROM_COURSE_METERS) continue;
      rows.push({ key: { hole: entry.hole, kind, color: kind === "green" ? "" : color }, point });
    }
  }
  if (!rows.length) return { status: "rejected", reason: "no_usable_points" };

  await ensureSchema();
  for (const { key, point } of rows) {
    await query(
      `INSERT INTO geometry_contributions (course_slug, hole, kind, tee_color, latitude, longitude)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [slug, key.hole, key.kind, key.color, point.lat, point.lon],
    );
  }
  await prune(slug, rows.map((r) => r.key));

  const applied = await aggregate(course, uniqueKeys(rows.map((r) => r.key)));
  return { status: "ok", accepted: rows.length, applied };
}

function courseCenter(course: CourseRecord): GeoPoint | null {
  if (course.latitude != null && course.longitude != null) return { lat: course.latitude, lon: course.longitude };
  if (course.firstTeeLat != null && course.firstTeeLon != null) return { lat: course.firstTeeLat, lon: course.firstTeeLon };
  return null;
}

function uniqueKeys(keys: PointKey[]): PointKey[] {
  const seen = new Map<string, PointKey>();
  for (const key of keys) seen.set(`${key.hole}|${key.kind}|${key.color}`, key);
  return [...seen.values()];
}

/** Nur die jüngsten Beiträge je Punkt behalten, nichts älter als ein Jahr. */
async function prune(slug: string, keys: PointKey[]): Promise<void> {
  for (const key of uniqueKeys(keys)) {
    await query(
      `DELETE FROM geometry_contributions
        WHERE course_slug = $1 AND hole = $2 AND kind = $3 AND tee_color = $4
          AND id NOT IN (SELECT id FROM geometry_contributions
                          WHERE course_slug = $1 AND hole = $2 AND kind = $3 AND tee_color = $4
                          ORDER BY id DESC LIMIT $5)`,
      [slug, key.hole, key.kind, key.color, MAX_CONTRIBUTIONS_PER_POINT],
    );
  }
  await query(`DELETE FROM geometry_contributions WHERE contributed_on < current_date - 365`);
}

// MARK: – Ziel in hole_data

/**
 * Wohin ein Punkt geschrieben wird. Grün → `flagLat/flagLon`. Abschlag einer
 * Farbe, die der Platz kennt → `tees[farbe]` des Lochs. Ohne Farbe – oder
 * Gelb an einem Platz, der Gelb nicht eigens führt – → Standardabschlag
 * (`teeLat/teeLon`); Gelb ist in Deutschland der übliche Herrenabschlag, nach
 * dem auch die Scorecard-Längen meist gemessen sind. Andere Farben ohne
 * Eintrag am Platz bleiben gesammelt, werden aber nirgends eingetragen –
 * Rot neben Gelb gemittelt ergäbe einen Punkt, an dem niemand abschlägt.
 */
type Target = { field: "flag" } | { field: "tee" } | { field: "colorTee"; color: TeeColor };

function target(course: CourseRecord, key: PointKey): Target | null {
  if (key.kind === "green") return { field: "flag" };
  const known = course.tees.some((t) => t.color === key.color);
  if (known) return { field: "colorTee", color: key.color as TeeColor };
  if (key.color === "" || key.color === "yellow") return { field: "tee" };
  return null;
}

function emptyHole(number: number): Hole {
  return {
    number,
    par: null,
    hcp: null,
    length: null,
    teeLat: null,
    teeLon: null,
    flagLat: null,
    flagLon: null,
    tees: [],
  };
}

function readTarget(hole: Hole | undefined, t: Target): GeoPoint | null {
  if (!hole) return null;
  const pick = (lat: number | null | undefined, lon: number | null | undefined) =>
    lat != null && lon != null ? { lat, lon } : null;
  if (t.field === "flag") return pick(hole.flagLat, hole.flagLon);
  if (t.field === "tee") return pick(hole.teeLat, hole.teeLon);
  const tee = hole.tees?.find((x) => x.color === t.color);
  return pick(tee?.lat, tee?.lon);
}

function writeTarget(hole: Hole, t: Target, point: GeoPoint): void {
  if (t.field === "flag") {
    hole.flagLat = point.lat;
    hole.flagLon = point.lon;
  } else if (t.field === "tee") {
    hole.teeLat = point.lat;
    hole.teeLon = point.lon;
  } else {
    hole.tees = hole.tees ?? [];
    const existing = hole.tees.find((x) => x.color === t.color);
    if (existing) {
      existing.lat = point.lat;
      existing.lon = point.lon;
    } else {
      hole.tees.push({ color: t.color, length: null, lat: point.lat, lon: point.lon });
    }
  }
}

// MARK: – Zusammenfassen und eintragen

interface GeometryRow extends Record<string, unknown> {
  applied_lat: number | null;
  applied_lon: number | null;
}

async function aggregate(course: CourseRecord, keys: PointKey[]): Promise<number> {
  const holes = new Map(course.holeData.map((h) => [h.number, structuredClone(h)]));
  // Platz aus dem Formular des Betreibers: Positionen gelten als geprüft.
  const operatorProvided = course.source === "form";
  let changed = 0;

  for (const key of keys) {
    const points = await query<{ latitude: number; longitude: number }>(
      `SELECT latitude, longitude FROM geometry_contributions
        WHERE course_slug = $1 AND hole = $2 AND kind = $3 AND tee_color = $4`,
      [course.slug, key.hole, key.kind, key.color],
    );
    const result = consensus(
      points.map((p) => ({ lat: Number(p.latitude), lon: Number(p.longitude) })),
      key.kind,
    );
    if (!result) continue;

    const t = target(course, key);
    if (!t) continue;

    const previous = await queryOne<GeometryRow>(
      `SELECT applied_lat, applied_lon FROM course_geometry
        WHERE course_slug = $1 AND hole = $2 AND kind = $3 AND tee_color = $4`,
      [course.slug, key.hole, key.kind, key.color],
    );
    const current = readTarget(holes.get(key.hole), t);
    const lastApplied =
      previous?.applied_lat != null && previous?.applied_lon != null
        ? { lat: Number(previous.applied_lat), lon: Number(previous.applied_lon) }
        : null;
    const decision = decide({
      consensus: result.point,
      current,
      lastApplied,
      seenBefore: previous != null,
      operatorProvided,
    });

    // Was die Crowd ab jetzt als „ihren“ Wert betrachtet: den neu
    // eingetragenen, oder – bei Übereinstimmung – den bestehenden.
    let applied: GeoPoint | null = lastApplied;
    if (decision === "apply") {
      const hole = holes.get(key.hole) ?? emptyHole(key.hole);
      writeTarget(hole, t, result.point);
      holes.set(key.hole, hole);
      applied = result.point;
      changed += 1;
    } else if (decision === "unchanged") {
      applied = current;
    }

    await query(
      `INSERT INTO course_geometry
         (course_slug, hole, kind, tee_color, latitude, longitude, contributors, spread_m, status,
          applied_lat, applied_lon, previous_lat, previous_lon, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, now())
       ON CONFLICT (course_slug, hole, kind, tee_color) DO UPDATE SET
         latitude = EXCLUDED.latitude,
         longitude = EXCLUDED.longitude,
         contributors = EXCLUDED.contributors,
         spread_m = EXCLUDED.spread_m,
         status = EXCLUDED.status,
         applied_lat = EXCLUDED.applied_lat,
         applied_lon = EXCLUDED.applied_lon,
         updated_at = now()`,
      [
        course.slug,
        key.hole,
        key.kind,
        key.color,
        result.point.lat,
        result.point.lon,
        result.contributors,
        result.spreadMeters,
        decision === "conflict" ? "conflict" : decision === "kept" ? "kept" : "applied",
        applied?.lat ?? null,
        applied?.lon ?? null,
        // Nur beim ersten Mal gesetzt – ON CONFLICT lässt die Spalten stehen.
        current?.lat ?? null,
        current?.lon ?? null,
      ],
    );
  }

  if (!changed) return 0;

  const holeData = [...holes.values()].sort((a, b) => a.number - b.number);
  // Der erste Abschlag ist der Punkt, an dem die App den Platz erkennt. Er
  // zieht mit, solange er leer ist oder nur den alten Abschlag von Loch 1
  // wiederholt – eine eigene Angabe des Betreibers bleibt stehen.
  const oldTee = readTarget(course.holeData.find((h) => h.number === 1), { field: "tee" });
  const newTee = readTarget(holes.get(1), { field: "tee" });
  const firstTeeFollows =
    course.firstTeeLat == null ||
    course.firstTeeLon == null ||
    (oldTee != null &&
      distanceMeters(oldTee, { lat: course.firstTeeLat, lon: course.firstTeeLon }) <= 1.5);
  await updateCourse(course.id, {
    holeData,
    ...(newTee && firstTeeFollows ? { firstTeeLat: newTee.lat, firstTeeLon: newTee.lon } : {}),
  });
  return changed;
}
