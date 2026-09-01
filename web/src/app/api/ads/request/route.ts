import { headers } from "next/headers";
import { createAdRequest } from "@/lib/ads";
import { hashIp } from "@/lib/auth";
import { getCourse, recordAttempt, tooManyAttempts } from "@/lib/courses";
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

  // Nur für freigegebene Minigolfanlagen – ohne QR-Code gibt es keinen Platz,
  // auf dem die Anzeige erscheinen könnte.
  const course = await getCourse(parsed.data.courseSlug);
  if (!course || course.status !== "approved" || course.kind !== "minigolf") {
    return Response.json({ error: "unknown_course" }, { status: 422 });
  }

  const headerList = await headers();
  const ip =
    headerList.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    headerList.get("x-real-ip") ||
    "unknown";
  const ipHash = await hashIp(ip);

  if (await tooManyAttempts(ipHash)) {
    return Response.json({ error: "rate_limited" }, { status: 429 });
  }

  await createAdRequest(parsed.data);
  await recordAttempt(ipHash);

  return Response.json({ ok: true }, { status: 201 });
}
