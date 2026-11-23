import { clientIp, hashIp } from "@/lib/auth";
import { recordAttempt, tooManyAttempts } from "@/lib/courses";
import { courseReportSchema, submitCourseReport } from "@/lib/courseReports";

/** „Fehler melden“ zu einem Platz. Speichert die Meldung und schickt sie per Mail. */
export async function POST(request: Request) {
  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }

  const parsed = courseReportSchema.safeParse(payload);
  if (!parsed.success) {
    return Response.json(
      {
        error: "validation_failed",
        issues: parsed.error.issues.map((issue) => ({ path: issue.path.join("."), message: issue.message })),
      },
      { status: 422 },
    );
  }

  // Honigtopf: still bestätigen, damit Bots nichts lernen.
  if (parsed.data.company) return Response.json({ ok: true }, { status: 202 });

  // Dasselbe Limit wie beim Platzformular: 5 pro Stunde und Adresse.
  const ipHash = await hashIp(await clientIp());
  if (await tooManyAttempts(ipHash)) return Response.json({ error: "rate_limited" }, { status: 429 });

  const result = await submitCourseReport(parsed.data);
  if (result === "unknown_course") return Response.json({ error: "unknown_course" }, { status: 404 });
  await recordAttempt(ipHash);

  return Response.json({ ok: true, mailed: result === "sent" }, { status: 201 });
}
