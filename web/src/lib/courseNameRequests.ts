import "server-only";
import { query, queryOne } from "./db";
import { ensureSchema } from "./migrations";

/**
 * Namensänderungen, die Betreiber für ihre Plätze beantragen.
 *
 * Bewusst mit Freigabe statt sofort: Der Name ist öffentlich (App, App Clip,
 * Website), und die iOS-App ordnet einen schon gespielten Golfplatz über den
 * Namen dem Verzeichnis zu (`CourseCatalogService.golfCourse(matching:)`).
 * Ein neuer Name kann dort die Zuordnung – und damit Rundenstatistik und
 * Crowd-Positionen – bestehender Spieler trennen. Das soll ein Mensch
 * entscheiden.
 *
 * Je Platz gibt es höchstens einen offenen Wunsch; ein neuer ersetzt den alten.
 */

export interface NameRequest {
  id: string;
  courseSlug: string;
  courseName: string;
  courseKind: "golf" | "minigolf" | null;
  operatorId: string | null;
  operatorName: string;
  oldName: string;
  requestedName: string;
  createdAt: string;
}

interface Row {
  id: string;
  course_slug: string;
  course_name: string | null;
  course_kind: string | null;
  operator_id: string | null;
  operator_name: string;
  old_name: string;
  requested_name: string;
  created_at: string | Date;
}

const map = (r: Row): NameRequest => ({
  id: String(r.id),
  courseSlug: r.course_slug,
  courseName: r.course_name ?? r.old_name,
  courseKind: r.course_kind === "golf" || r.course_kind === "minigolf" ? r.course_kind : null,
  operatorId: r.operator_id ? String(r.operator_id) : null,
  operatorName: r.operator_name,
  oldName: r.old_name,
  requestedName: r.requested_name,
  createdAt: new Date(r.created_at).toISOString(),
});

const SELECT = `
  SELECT r.id, r.course_slug, c.name AS course_name, c.kind AS course_kind, r.operator_id, r.operator_name,
         r.old_name, r.requested_name, r.created_at
    FROM course_name_requests r
    LEFT JOIN courses c ON c.slug = r.course_slug`;

/** Offene Wünsche – alle (Admin) oder nur für bestimmte Plätze (Portal). */
export async function pendingNameRequests(slugs?: string[]): Promise<NameRequest[]> {
  await ensureSchema();
  const rows = slugs
    ? await query<Row & Record<string, unknown>>(
        `${SELECT} WHERE r.status = 'pending' AND r.course_slug = ANY($1) ORDER BY r.created_at`,
        [slugs],
      )
    : await query<Row & Record<string, unknown>>(`${SELECT} WHERE r.status = 'pending' ORDER BY r.created_at`);
  return rows.map(map);
}

export type RequestResult = "ok" | "unchanged" | "unknown_course";

export async function requestNameChange(
  slug: string,
  requestedName: string,
  operator: { id: string; name: string },
): Promise<RequestResult> {
  await ensureSchema();
  const course = await queryOne<{ name: string }>(`SELECT name FROM courses WHERE slug = $1`, [slug]);
  if (!course) return "unknown_course";
  const name = requestedName.trim().replace(/\s+/g, " ");
  if (name === course.name.trim()) return "unchanged";
  await query(
    `UPDATE course_name_requests SET status = 'withdrawn', decided_at = now()
      WHERE course_slug = $1 AND status = 'pending'`,
    [slug],
  );
  await query(
    `INSERT INTO course_name_requests (course_slug, operator_id, operator_name, old_name, requested_name)
     VALUES ($1, $2, $3, $4, $5)`,
    [slug, operator.id, operator.name, course.name, name],
  );
  return "ok";
}

/** Betreiber zieht seinen offenen Wunsch zurück – nur für seine eigenen Plätze. */
export async function withdrawNameRequest(id: string, allowedSlugs: string[]): Promise<void> {
  await ensureSchema();
  await query(
    `UPDATE course_name_requests SET status = 'withdrawn', decided_at = now()
      WHERE id = $1 AND status = 'pending' AND course_slug = ANY($2)`,
    [id, allowedSlugs],
  );
}

/**
 * Freigeben oder ablehnen. Bei Freigabe wird der Name übernommen und der alte
 * in der internen Notiz des Platzes festgehalten.
 */
export async function decideNameRequest(id: string, approve: boolean): Promise<NameRequest | null> {
  await ensureSchema();
  const row = await queryOne<Row & Record<string, unknown>>(`${SELECT} WHERE r.id = $1 AND r.status = 'pending'`, [id]);
  if (!row) return null;
  const req = map(row);
  await query(`UPDATE course_name_requests SET status = $2, decided_at = now() WHERE id = $1`, [
    id,
    approve ? "approved" : "rejected",
  ]);
  if (approve) {
    const stamp = new Date().toLocaleDateString("de-DE");
    const note = `Name am ${stamp} geändert von „${req.courseName}“ auf „${req.requestedName}“ (Wunsch von ${req.operatorName || "Betreiber"}).`;
    await query(
      `UPDATE courses
          SET name = $2,
              admin_notes = CASE WHEN admin_notes = '' THEN $3 ELSE admin_notes || E'\\n' || $3 END,
              updated_at = now()
        WHERE slug = $1`,
      [req.courseSlug, req.requestedName, note],
    );
  }
  return req;
}
