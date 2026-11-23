import "server-only";
import { z } from "zod";
import { query } from "./db";
import { ensureSchema } from "./migrations";
import { getCourse, type CourseRecord } from "./courses";
import { mailConfigured, sendMail } from "./mail";
import { SITE_URL } from "@/i18n/routes";

/**
 * „Fehler melden“ zu einem Platz: Betreiber oder Spieler schreiben, was an
 * den Daten nicht stimmt. Jede Meldung wird gespeichert und als Mail an den
 * Betreiber von golftrack.app geschickt (REPORT_EMAIL, sonst die öffentliche
 * Kontaktadresse). Antworten gehen per Reply-To direkt an den Meldenden.
 */

export const REPORT_CATEGORIES = ["name", "holes", "rating", "location", "closed", "other"] as const;
export const REPORT_ROLES = ["owner", "player", "other"] as const;

export const courseReportSchema = z.object({
  slug: z.string().trim().min(1).max(120),
  category: z.enum(REPORT_CATEGORIES),
  message: z.string().trim().min(10).max(3000),
  name: z.string().trim().max(120).optional().default(""),
  email: z.union([z.literal(""), z.email().max(200)]).optional().default(""),
  role: z.enum(REPORT_ROLES).optional().default("other"),
  /** Honigtopf – Menschen sehen das Feld nicht. */
  company: z.string().optional().default(""),
});
export type CourseReportInput = z.infer<typeof courseReportSchema>;

const CATEGORY_LABEL: Record<(typeof REPORT_CATEGORIES)[number], string> = {
  name: "Name oder Ort",
  holes: "Lochdaten (Par, Vorgabe, Längen)",
  rating: "Course Rating / Slope",
  location: "Lage auf der Karte",
  closed: "Anlage gibt es nicht (mehr)",
  other: "Sonstiges",
};

const ROLE_LABEL: Record<(typeof REPORT_ROLES)[number], string> = {
  owner: "Betreiber / Club",
  player: "Spieler",
  other: "Sonstiges",
};

/** Ob die Wertungen des Platzes (ganz oder teilweise) von handicap.report stammen. */
export function ratingsFromHandicapReport(course: Pick<CourseRecord, "source" | "adminNotes">): boolean {
  return course.source === "handicap.report" || course.adminNotes.includes("handicap.report");
}

function recipient(): string | null {
  return process.env.REPORT_EMAIL || process.env.NEXT_PUBLIC_CONTACT_EMAIL || null;
}

export type ReportResult = "sent" | "stored" | "unknown_course";

export async function submitCourseReport(input: CourseReportInput): Promise<ReportResult> {
  const course = await getCourse(input.slug);
  if (!course || course.status !== "approved") return "unknown_course";

  await ensureSchema();
  const [row] = await query<{ id: string }>(
    `INSERT INTO course_reports (course_slug, course_name, category, message, reporter_name, reporter_email, reporter_role)
     VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
    [course.slug, course.name, input.category, input.message, input.name, input.email, input.role],
  );

  const to = recipient();
  if (!to || !mailConfigured()) return "stored";

  const text = [
    `Neue Fehlermeldung zu „${course.name}“`,
    "",
    `Platz:     ${course.name}${course.location ? ` (${course.location})` : ""}`,
    `Seite:     ${SITE_URL}/${course.kind}/${course.slug}`,
    `Quelle:    ${course.source}${ratingsFromHandicapReport(course) ? " (Wertungen von handicap.report)" : ""}`,
    `Bereich:   ${CATEGORY_LABEL[input.category]}`,
    `Von:       ${input.name || "–"} · ${ROLE_LABEL[input.role]}`,
    `E-Mail:    ${input.email || "– (keine Antwort möglich)"}`,
    "",
    "Meldung:",
    input.message,
    "",
    `Meldungs-ID: ${row.id}`,
  ].join("\n");

  try {
    await sendMail(to, `Fehler gemeldet: ${course.name}`, text, undefined, {
      replyTo: input.email || undefined,
    });
  } catch (error) {
    console.error("course report mail failed", row.id, error);
    return "stored";
  }
  await query("UPDATE course_reports SET mailed = true WHERE id = $1", [row.id]);
  return "sent";
}
