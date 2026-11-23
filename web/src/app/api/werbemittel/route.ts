import { clientIp, hashIp } from "@/lib/auth";
import { recordAttempt, tooManyAttempts } from "@/lib/courses";
import { printRequestSchema, submitPrintRequest } from "@/lib/printRequests";

/** Anfrage eines Golfplatzes nach Werbesäulen, Bauzaunplane oder Plakaten (`/werbung/golfplatz`). */
export async function POST(request: Request) {
  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }

  const parsed = printRequestSchema.safeParse(payload);
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

  // Dasselbe Limit wie bei den anderen Formularen: 5 pro Stunde und Adresse.
  const ipHash = await hashIp(await clientIp());
  if (await tooManyAttempts(ipHash)) return Response.json({ error: "rate_limited" }, { status: 429 });

  const result = await submitPrintRequest(parsed.data);
  if (result === "unavailable") return Response.json({ error: "mail_unavailable" }, { status: 503 });
  await recordAttempt(ipHash);

  return Response.json({ ok: true }, { status: 201 });
}
