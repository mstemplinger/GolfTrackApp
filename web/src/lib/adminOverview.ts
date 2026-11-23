import "server-only";
import { query } from "./db";
import { ensureSchema } from "./migrations";

/**
 * Zahlen für die Startseite des Adminpanels – alles mit einfachen
 * Zähl-Abfragen. Jede Abfrage für sich abgesichert: Fehlt eine Tabelle oder
 * scheitert eine Abfrage, zeigt die Übersicht dort „–“ statt gar nichts.
 */

export interface AdminOverview {
  pending: number | null;
  approvedGolf: number | null;
  approvedMinigolf: number | null;
  adRequests: number | null;
  adsActive: number | null;
  rounds30: number | null;
  reports30: number | null;
  waitlist: number | null;
  latestReports: LatestReport[];
}

export interface LatestReport {
  id: string;
  courseSlug: string;
  courseName: string;
  category: string;
  message: string;
  reporterRole: string;
  createdAt: string;
}

async function count(sql: string): Promise<number | null> {
  try {
    const rows = await query<{ total: string | number }>(sql);
    return Number(rows[0]?.total ?? 0);
  } catch {
    return null;
  }
}

export async function adminOverview(): Promise<AdminOverview> {
  await ensureSchema();
  const [pending, approvedGolf, approvedMinigolf, adRequests, adsActive, rounds30, reports30, waitlist, latestReports] =
    await Promise.all([
      count(`SELECT COUNT(*) AS total FROM courses WHERE status = 'pending'`),
      count(`SELECT COUNT(*) AS total FROM courses WHERE status = 'approved' AND kind = 'golf'`),
      count(`SELECT COUNT(*) AS total FROM courses WHERE status = 'approved' AND kind = 'minigolf'`),
      count(`SELECT COUNT(*) AS total FROM ads WHERE status = 'draft' AND source = 'form'`),
      count(`SELECT COUNT(*) AS total FROM ads WHERE status = 'active'`),
      count(`SELECT COUNT(*) AS total FROM round_stats WHERE played_on >= current_date - 30`),
      count(`SELECT COUNT(*) AS total FROM course_reports WHERE created_at >= now() - interval '30 days'`),
      count(`SELECT COUNT(*) AS total FROM android_waitlist WHERE confirmed_at IS NOT NULL`),
      latest(),
    ]);
  return {
    pending,
    approvedGolf,
    approvedMinigolf,
    adRequests,
    adsActive,
    rounds30,
    reports30,
    waitlist,
    latestReports,
  };
}

async function latest(): Promise<LatestReport[]> {
  try {
    const rows = await query<{
      id: string;
      course_slug: string;
      course_name: string;
      category: string;
      message: string;
      reporter_role: string;
      created_at: string | Date;
    }>(
      `SELECT id, course_slug, course_name, category, message, reporter_role, created_at
         FROM course_reports ORDER BY created_at DESC LIMIT 5`,
    );
    return rows.map((r) => ({
      id: String(r.id),
      courseSlug: r.course_slug,
      courseName: r.course_name || r.course_slug,
      category: r.category,
      message: r.message,
      reporterRole: r.reporter_role,
      createdAt: new Date(r.created_at).toISOString(),
    }));
  } catch {
    return [];
  }
}
