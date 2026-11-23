"use server";

import { createOperatorAdRequest, openOperatorAdRequests } from "@/lib/ads";
import { quoteAd } from "@/lib/adPricing";
import { coursesWithin, getCourse } from "@/lib/courses";
import { currentOperator } from "@/lib/operatorAuth";
import { printRequestSchema, submitPrintRequest } from "@/lib/printRequests";
import { operatorAdRequestSchema, type AdPlacement } from "@/lib/schema";
import { coursePoint } from "./access";

/**
 * Anfragen aus dem Betreiber-Portal. Jede Aktion prüft Konto und Platz selbst –
 * eine Server-Aktion ist von außen aufrufbar, die Seite davor schützt nichts.
 * Kein `redirect()` (siehe ../../actions.ts): die Formulare zeigen ihr Ergebnis
 * selbst an.
 */

export type ToolResult =
  | { ok: true }
  | {
      ok: false;
      error: "auth" | "invalid" | "not_approved" | "no_location" | "no_courses" | "too_many" | "unavailable";
      fields?: string[];
    };

/** Mehr offene Entwürfe je Konto nimmt das Portal nicht an – gegen Doppelklicks und Versehen. */
const MAX_OPEN_AD_REQUESTS = 5;

function fieldsOf(issues: { path: PropertyKey[] }[]): string[] {
  return [...new Set(issues.map((issue) => String(issue.path[0] ?? "")).filter(Boolean))];
}

async function ownCourse(slug: string) {
  const op = await currentOperator();
  if (!op || typeof slug !== "string" || !op.courses.includes(slug)) return null;
  const course = await getCourse(slug);
  return course ? { op, course } : null;
}

/**
 * Anzeige anfragen: nur auf dem eigenen Platz oder im Umkreis um ihn. Landet
 * wie die Anfrage von /werbung als Entwurf im Adminpanel – geschaltet wird
 * erst nach Rückfrage. Der Preis wird hier neu gerechnet; das Formular zeigt
 * nur die Vorschau derselben Rechnung.
 */
export async function requestOperatorAd(slug: string, payload: unknown): Promise<ToolResult> {
  const owned = await ownCourse(slug);
  if (!owned) return { ok: false, error: "auth" };
  const { op, course } = owned;
  if (course.status !== "approved") return { ok: false, error: "not_approved" };

  const parsed = operatorAdRequestSchema.safeParse(payload);
  if (!parsed.success) return { ok: false, error: "invalid", fields: fieldsOf(parsed.error.issues) };
  const input = parsed.data;

  if ((await openOperatorAdRequests(op.id)) >= MAX_OPEN_AD_REQUESTS) return { ok: false, error: "too_many" };

  if (input.target === "course") {
    const golf = course.kind === "golf";
    const placement: AdPlacement = golf ? "golf_scoring" : "minigolf_scoring";
    const quote = quoteAd(golf ? 1 : 0, golf ? 0 : 1, input.requestedMonths);
    await createOperatorAdRequest(op.id, input, { courseSlug: course.slug, placeName: course.name, centre: null }, [placement], quote);
    return { ok: true };
  }

  const centre = coursePoint(course);
  if (!centre) return { ok: false, error: "no_location" };
  const reach = await coursesWithin(centre.lat, centre.lon, input.radiusKm);
  if (reach.total === 0) return { ok: false, error: "no_courses" };
  // Nur die Zählkarten, die der Umkreis wirklich trifft (wie bei /werbung).
  const placements: AdPlacement[] = [];
  if (reach.minigolf > 0) placements.push("minigolf_scoring");
  if (reach.golf > 0) placements.push("golf_scoring");
  const quote = quoteAd(reach.golf, reach.minigolf, input.requestedMonths);
  await createOperatorAdRequest(op.id, input, { courseSlug: "", placeName: course.name, centre }, placements, quote);
  return { ok: true };
}

/**
 * Werbemittel anfragen. Geht wie auf /werbung/golfplatz nur per Mail an uns,
 * mit Konto und Platzkennung im Text. Platzname und Ort kommen aus dem
 * Verzeichnis, nicht aus dem Formular.
 */
export async function requestOperatorPrint(slug: string, payload: unknown): Promise<ToolResult> {
  const owned = await ownCourse(slug);
  if (!owned) return { ok: false, error: "auth" };
  const { op, course } = owned;

  const fields = (payload ?? {}) as Record<string, unknown>;
  const parsed = printRequestSchema.safeParse({
    club: course.name,
    location: course.location,
    name: fields.name,
    email: fields.email,
    phone: fields.phone,
    items: fields.items,
    message: fields.message,
    consent: true,
    company: "",
  });
  if (!parsed.success) return { ok: false, error: "invalid", fields: fieldsOf(parsed.error.issues) };

  const result = await submitPrintRequest(parsed.data, [
    `Portal:    Betreiberkonto „${op.name}“ <${op.email}>`,
    `Kennung:   ${course.slug} (${course.kind === "golf" ? "Golfplatz" : "Minigolf"})`,
  ]);
  return result === "sent" ? { ok: true } : { ok: false, error: "unavailable" };
}
