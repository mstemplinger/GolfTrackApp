import { headers } from "next/headers";
import { createSubmission, recordAttempt, tooManyAttempts } from "@/lib/courses";
import { hashIp } from "@/lib/auth";
import { submissionSchema } from "@/lib/schema";

/** Nimmt das öffentliche Formular entgegen. Alles landet als `pending`. */
export async function POST(request: Request) {
  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }

  const parsed = submissionSchema.safeParse(payload);
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

  const headerList = await headers();
  const ip =
    headerList.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    headerList.get("x-real-ip") ||
    "unknown";
  const ipHash = await hashIp(ip);

  if (await tooManyAttempts(ipHash)) {
    return Response.json({ error: "rate_limited" }, { status: 429 });
  }

  const record = await createSubmission(parsed.data);
  await recordAttempt(ipHash);

  return Response.json({ ok: true, slug: record.slug }, { status: 201 });
}
