import "server-only";
import { query, queryOne } from "./db";
import { ensureSchema } from "./migrations";
import type { AdminUpdate, CourseKind, CourseStatus, Hole, SubmissionInput } from "./schema";

export interface CourseRecord {
  id: string;
  slug: string;
  kind: CourseKind;
  status: CourseStatus;
  name: string;
  location: string;
  country: string;
  holes: number;
  latitude: number | null;
  longitude: number | null;
  courseRating: number | null;
  slopeRating: number | null;
  holeData: Hole[];
  facilityNotes: string;
  welcome: string;
  website: string;
  phone: string;
  publicEmail: string;
  submitterName: string;
  submitterEmail: string;
  submitterRole: string;
  adminNotes: string;
  source: string;
  createdAt: string;
  updatedAt: string;
  reviewedAt: string | null;
  publishedAt: string | null;
}

type DbRow = Record<string, unknown>;

const asString = (v: unknown) => (v == null ? "" : String(v));
const asNumber = (v: unknown) => (v == null ? null : Number(v));
const asDate = (v: unknown) => (v == null ? null : new Date(v as string).toISOString());

function mapRow(row: DbRow): CourseRecord {
  const holeData = typeof row.hole_data === "string" ? JSON.parse(row.hole_data) : row.hole_data;
  return {
    id: asString(row.id),
    slug: asString(row.slug),
    kind: asString(row.kind) as CourseKind,
    status: asString(row.status) as CourseStatus,
    name: asString(row.name),
    location: asString(row.location),
    country: asString(row.country),
    holes: Number(row.holes),
    latitude: asNumber(row.latitude),
    longitude: asNumber(row.longitude),
    courseRating: asNumber(row.course_rating),
    slopeRating: asNumber(row.slope_rating),
    holeData: (holeData as Hole[]) ?? [],
    facilityNotes: asString(row.facility_notes),
    welcome: asString(row.welcome),
    website: asString(row.website),
    phone: asString(row.phone),
    publicEmail: asString(row.public_email),
    submitterName: asString(row.submitter_name),
    submitterEmail: asString(row.submitter_email),
    submitterRole: asString(row.submitter_role),
    adminNotes: asString(row.admin_notes),
    source: asString(row.source),
    createdAt: asDate(row.created_at) ?? new Date(0).toISOString(),
    updatedAt: asDate(row.updated_at) ?? new Date(0).toISOString(),
    reviewedAt: asDate(row.reviewed_at),
    publishedAt: asDate(row.published_at),
  };
}

/** URL-taugliche Kennung. Bleibt nach dem Druck von QR-Codes unverändert. */
export function slugify(input: string): string {
  return input
    .toLowerCase()
    .replace(/ä/g, "ae")
    .replace(/ö/g, "oe")
    .replace(/ü/g, "ue")
    .replace(/ß/g, "ss")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 60);
}

/**
 * Kurze, sprechende Kennung: erst nur der Name, bei Kollision der Ort dazu,
 * danach durchnummeriert. Sie steht später in QR-Codes und bleibt bestehen.
 */
async function uniqueSlug(name: string, location: string): Promise<string> {
  const candidates = [slugify(name) || "platz"];
  const withLocation = slugify(`${name} ${location}`);
  if (location && withLocation !== candidates[0]) candidates.push(withLocation);

  for (const candidate of candidates) {
    const existing = await queryOne("SELECT 1 FROM courses WHERE slug = $1", [candidate]);
    if (!existing) return candidate;
  }

  const root = candidates[candidates.length - 1];
  for (let attempt = 2; attempt < 60; attempt += 1) {
    const candidate = `${root}-${attempt}`;
    const existing = await queryOne("SELECT 1 FROM courses WHERE slug = $1", [candidate]);
    if (!existing) return candidate;
  }
  return `${root}-${Date.now().toString(36)}`;
}

export async function createSubmission(input: SubmissionInput): Promise<CourseRecord> {
  await ensureSchema();
  const slug = await uniqueSlug(input.name, input.location);
  const rows = await query<DbRow>(
    `INSERT INTO courses (
       slug, kind, status, name, location, country, holes, latitude, longitude,
       course_rating, slope_rating, hole_data, facility_notes, welcome, website, phone,
       public_email, submitter_name, submitter_email, submitter_role, source
     ) VALUES ($1,$2,'pending',$3,$4,$5,$6,$7,$8,$9,$10,$11::jsonb,$12,$13,$14,$15,$16,$17,$18,$19,'form')
     RETURNING *`,
    [
      slug,
      input.kind,
      input.name,
      input.location,
      input.country || "DE",
      input.holes,
      input.latitude,
      input.longitude,
      input.courseRating,
      input.slopeRating,
      JSON.stringify(input.holeData ?? []),
      input.facilityNotes,
      input.welcome,
      input.website,
      input.phone,
      input.publicEmail,
      input.submitterName,
      input.submitterEmail,
      input.submitterRole,
    ],
  );
  return mapRow(rows[0]);
}

export async function listCourses(options: {
  status?: CourseStatus;
  kind?: CourseKind;
  limit?: number;
} = {}): Promise<CourseRecord[]> {
  await ensureSchema();
  const conditions: string[] = [];
  const params: unknown[] = [];
  if (options.status) {
    params.push(options.status);
    conditions.push(`status = $${params.length}`);
  }
  if (options.kind) {
    params.push(options.kind);
    conditions.push(`kind = $${params.length}`);
  }
  const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";
  params.push(options.limit ?? 500);
  const rows = await query<DbRow>(
    `SELECT * FROM courses ${where} ORDER BY created_at DESC LIMIT $${params.length}`,
    params,
  );
  return rows.map(mapRow);
}

export async function countByStatus(): Promise<Record<CourseStatus, number>> {
  await ensureSchema();
  const rows = await query<DbRow>("SELECT status, COUNT(*) AS total FROM courses GROUP BY status");
  const result: Record<CourseStatus, number> = { pending: 0, approved: 0, rejected: 0 };
  for (const row of rows) {
    result[asString(row.status) as CourseStatus] = Number(row.total);
  }
  return result;
}

export async function getCourse(idOrSlug: string): Promise<CourseRecord | null> {
  await ensureSchema();
  const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(idOrSlug);
  const row = isUuid
    ? await queryOne<DbRow>("SELECT * FROM courses WHERE id = $1", [idOrSlug])
    : await queryOne<DbRow>("SELECT * FROM courses WHERE slug = $1", [idOrSlug]);
  return row ? mapRow(row) : null;
}

const COLUMN_FOR: Record<keyof AdminUpdate, string> = {
  name: "name",
  location: "location",
  country: "country",
  holes: "holes",
  latitude: "latitude",
  longitude: "longitude",
  courseRating: "course_rating",
  slopeRating: "slope_rating",
  holeData: "hole_data",
  facilityNotes: "facility_notes",
  welcome: "welcome",
  website: "website",
  phone: "phone",
  publicEmail: "public_email",
  adminNotes: "admin_notes",
  slug: "slug",
};

export async function updateCourse(id: string, patch: AdminUpdate): Promise<CourseRecord | null> {
  await ensureSchema();
  const assignments: string[] = [];
  const params: unknown[] = [];
  for (const [key, value] of Object.entries(patch) as [keyof AdminUpdate, unknown][]) {
    if (value === undefined) continue;
    const column = COLUMN_FOR[key];
    if (!column) continue;
    if (key === "holeData") {
      params.push(JSON.stringify(value));
      assignments.push(`${column} = $${params.length}::jsonb`);
    } else {
      params.push(value);
      assignments.push(`${column} = $${params.length}`);
    }
  }
  if (!assignments.length) return getCourse(id);
  assignments.push("updated_at = now()");
  params.push(id);
  const rows = await query<DbRow>(
    `UPDATE courses SET ${assignments.join(", ")} WHERE id = $${params.length} RETURNING *`,
    params,
  );
  return rows[0] ? mapRow(rows[0]) : null;
}

export async function setStatus(id: string, status: CourseStatus): Promise<CourseRecord | null> {
  await ensureSchema();
  const rows = await query<DbRow>(
    `UPDATE courses
        SET status = $1,
            reviewed_at = now(),
            updated_at = now(),
            published_at = CASE WHEN $1 = 'approved' AND published_at IS NULL THEN now() ELSE published_at END
      WHERE id = $2
      RETURNING *`,
    [status, id],
  );
  return rows[0] ? mapRow(rows[0]) : null;
}

export async function deleteCourse(id: string): Promise<void> {
  await ensureSchema();
  await query("DELETE FROM courses WHERE id = $1", [id]);
}

/** Einfaches Rate-Limit: maximal `max` Einreichungen pro IP und Stunde. */
export async function tooManyAttempts(ipHash: string, max = 5): Promise<boolean> {
  await ensureSchema();
  await query("DELETE FROM submission_attempts WHERE created_at < now() - interval '24 hours'");
  const row = await queryOne<DbRow>(
    "SELECT COUNT(*) AS total FROM submission_attempts WHERE ip_hash = $1 AND created_at > now() - interval '1 hour'",
    [ipHash],
  );
  return Number(row?.total ?? 0) >= max;
}

export async function recordAttempt(ipHash: string): Promise<void> {
  await query("INSERT INTO submission_attempts (ip_hash) VALUES ($1)", [ipHash]);
}
