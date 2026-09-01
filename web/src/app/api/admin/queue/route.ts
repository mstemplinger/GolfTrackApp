import { revalidatePath } from "next/cache";
import { z } from "zod";
import { getAd, listAds, setAdStatus } from "@/lib/ads";
import { apiTokenConfigured, apiTokenMatches } from "@/lib/auth";
import { getCourse, listCourses, setStatus } from "@/lib/courses";

/**
 * Das Adminpanel für Maschinen: offene Anfragen lesen, freigeben, ablehnen.
 *
 * Gedacht für den Rechner, der in Abständen nachsieht und per Telegram
 * nachfragt (`docs/freigabe-telegram-windows.md`). Die Oberfläche unter
 * `/admin` kann das alles auch – aber sie läuft über Server Actions, deren
 * Kennungen sich bei jedem Bauen ändern; von außen ist daran nichts zu
 * greifen. Deshalb dieser schmale, stabile Weg.
 *
 * Anmeldung: `Authorization: Bearer <ADMIN_API_TOKEN>`. Ohne gesetzten
 * Schlüssel antwortet die Schnittstelle gar nicht – ein leerer Wert darf
 * niemals zufällig passen.
 */

export const dynamic = "force-dynamic";

const NO_STORE = { "Cache-Control": "no-store" };

function siteURL(): string {
  return (process.env.NEXT_PUBLIC_SITE_URL ?? "https://golftrack.app").replace(/\/$/, "");
}

function guard(request: Request): Response | null {
  if (!apiTokenConfigured()) {
    return Response.json({ error: "not_configured" }, { status: 503, headers: NO_STORE });
  }
  if (!apiTokenMatches(request.headers.get("authorization"))) {
    return Response.json({ error: "unauthorized" }, { status: 401, headers: NO_STORE });
  }
  return null;
}

/** Nach einer Statusänderung: die Seiten erneuern, auf denen der Platz steht. */
function revalidateCoursePages(slug?: string): void {
  revalidatePath("/admin");
  revalidatePath("/plaetze");
  revalidatePath("/en/courses");
  revalidatePath("/sitemap.xml");
  if (slug) revalidatePath(`/minigolf/${slug}`);
}

/**
 * Was offen ist. Plätze mit `pending`, Werbeanfragen mit `draft` **und**
 * `source = 'form'` – von Hand angelegte Entwürfe sind keine Anfrage und
 * sollen niemanden aus dem Feierabend holen.
 */
export async function GET(request: Request) {
  const denied = guard(request);
  if (denied) return denied;

  const base = siteURL();
  const [courses, ads] = await Promise.all([listCourses({ status: "pending" }), listAds()]);

  return Response.json(
    {
      checkedAt: new Date().toISOString(),
      courses: courses.map((course) => ({
        id: course.id,
        slug: course.slug,
        kind: course.kind,
        name: course.name,
        location: course.location,
        country: course.country,
        holes: course.holes,
        website: course.website,
        phone: course.phone,
        publicEmail: course.publicEmail,
        welcome: course.welcome,
        facilityNotes: course.facilityNotes,
        submitterName: course.submitterName,
        submitterEmail: course.submitterEmail,
        submitterRole: course.submitterRole,
        createdAt: course.createdAt,
        adminURL: `${base}/admin/${course.id}`,
      })),
      ads: ads
        .filter((ad) => ad.status === "draft" && ad.source === "form")
        .map((ad) => ({
          id: ad.id,
          courseSlug: ad.courseSlug,
          title: ad.title,
          subtitle: ad.subtitle,
          advertiser: ad.advertiser,
          imageURL: ad.imageURL,
          linkURL: ad.linkURL,
          submitterName: ad.submitterName,
          submitterEmail: ad.submitterEmail,
          submitterPhone: ad.submitterPhone,
          requestNote: ad.requestNote,
          createdAt: ad.createdAt,
          adminURL: `${base}/admin/werbung/${ad.id}`,
        })),
    },
    { headers: NO_STORE },
  );
}

const decisionSchema = z.object({
  type: z.enum(["course", "ad"]),
  id: z.string().min(1),
  /**
   * `approve` schaltet frei, `reject` nimmt vom Tisch. Abgelehnte Anzeigen
   * werden `paused` und nicht gelöscht: die Anfrage bleibt im Adminpanel
   * lesbar, falls der Betreiber nachfragt.
   */
  action: z.enum(["approve", "reject"]),
});

export async function POST(request: Request) {
  const denied = guard(request);
  if (denied) return denied;

  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400, headers: NO_STORE });
  }

  const parsed = decisionSchema.safeParse(payload);
  if (!parsed.success) {
    return Response.json(
      {
        error: "validation_failed",
        issues: parsed.error.issues.map((issue) => ({
          path: issue.path.join("."),
          message: issue.message,
        })),
      },
      { status: 422, headers: NO_STORE },
    );
  }

  const { type, id, action } = parsed.data;

  if (type === "course") {
    const before = await getCourse(id);
    if (!before) return Response.json({ error: "not_found" }, { status: 404, headers: NO_STORE });
    // Schon entschieden: nichts tun, aber den Stand melden. So kippt ein
    // doppelt angetippter Knopf keine Entscheidung von vorhin um.
    if (before.status !== "pending") {
      return Response.json(
        { ok: true, changed: false, type, id, status: before.status, name: before.name },
        { headers: NO_STORE },
      );
    }
    const record = await setStatus(id, action === "approve" ? "approved" : "rejected");
    revalidateCoursePages(record?.slug);
    revalidatePath(`/admin/${id}`);
    return Response.json(
      { ok: true, changed: true, type, id, status: record?.status, name: record?.name, slug: record?.slug },
      { headers: NO_STORE },
    );
  }

  const before = await getAd(id);
  if (!before) return Response.json({ error: "not_found" }, { status: 404, headers: NO_STORE });
  if (before.status !== "draft") {
    return Response.json(
      { ok: true, changed: false, type, id, status: before.status, title: before.title },
      { headers: NO_STORE },
    );
  }
  const record = await setAdStatus(id, action === "approve" ? "active" : "paused");
  revalidatePath("/admin/werbung");
  revalidatePath(`/admin/werbung/${id}`);
  revalidatePath("/api/v1/ads");
  return Response.json(
    { ok: true, changed: true, type, id, status: record?.status, title: record?.title },
    { headers: NO_STORE },
  );
}
