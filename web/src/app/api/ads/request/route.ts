import { createAdRequest } from "@/lib/ads";
import { quoteAd } from "@/lib/adPricing";
import { clientIp, hashIp } from "@/lib/auth";
import { coursesWithin, recordAttempt, tooManyAttempts } from "@/lib/courses";
import type { AdPlacement } from "@/lib/schema";
import { adRequestSchema } from "@/lib/schema";

/**
 * Anfrage eines Anlagenbetreibers von `/werbung`. Alles landet als Entwurf im
 * Adminpanel – geschaltet wird erst nach Rückfrage und von Hand.
 */
export async function POST(request: Request) {
  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }

  const parsed = adRequestSchema.safeParse(payload);
  if (!parsed.success) {
    return Response.json(
      {
        error: "validation_failed",
        issues: parsed.error.issues.map((issue) => ({
          path: issue.path.join("."),
          message: issue.message,
        })),
      },
      { status: 422 },
    );
  }

  // Honigtopf: still bestätigen, damit Bots nichts lernen.
  if (parsed.data.company) {
    return Response.json({ ok: true }, { status: 202 });
  }

  // Ein Umkreis, in dem kein einziger Platz liegt, wäre eine Anzeige ins
  // Leere. Lieber gleich sagen als später erklären.
  const reach = await coursesWithin(parsed.data.latitude, parsed.data.longitude, parsed.data.radiusKm);
  if (reach.total === 0) {
    return Response.json({ error: "no_courses_in_radius" }, { status: 422 });
  }

  // Welche Zählkarten der Umkreis überhaupt trifft. Liegt dort kein Golfplatz,
  // entsteht auch kein Entwurf dafür – sonst stünden im Adminpanel Anzeigen,
  // die nie jemand sehen kann.
  const placements: AdPlacement[] = [];
  if (reach.minigolf > 0) placements.push("minigolf_scoring");
  if (reach.golf > 0) placements.push("golf_scoring");

  const ipHash = await hashIp(await clientIp());

  if (await tooManyAttempts(ipHash)) {
    return Response.json({ error: "rate_limited" }, { status: 429 });
  }

  // Der Preis wird hier neu gerechnet – was das Formular anzeigt, ist nur die
  // Vorschau derselben Rechnung.
  const quote = quoteAd(reach.golf, reach.minigolf, parsed.data.requestedMonths);
  await createAdRequest(parsed.data, placements, quote);
  await recordAttempt(ipHash);

  return Response.json({ ok: true, placements, quote }, { status: 201 });
}
