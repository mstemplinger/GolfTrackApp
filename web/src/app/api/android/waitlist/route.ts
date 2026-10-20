import { z } from "zod";
import { clientIp, hashIp } from "@/lib/auth";
import { recordAttempt, tooManyAttempts } from "@/lib/courses";
import { mailConfigured } from "@/lib/mail";
import { purgeUnconfirmed, requestCode } from "@/lib/waitlist";

const schema = z.object({
  email: z.string().trim().email().max(200),
  lang: z.enum(["de", "en"]).default("de"),
  /** Honigtopf – Menschen sehen das Feld nicht. */
  website: z.string().optional(),
});

/** Schritt 1: Adresse eintragen, Code per Mail. */
export async function POST(request: Request) {
  const parsed = schema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return Response.json({ error: "invalid_email" }, { status: 422 });
  if (parsed.data.website) return Response.json({ ok: true, status: "sent" }, { status: 202 });
  if (!mailConfigured()) return Response.json({ error: "mail_unavailable" }, { status: 503 });

  const ipHash = await hashIp(await clientIp());
  if (await tooManyAttempts(ipHash, 5)) return Response.json({ error: "rate_limited" }, { status: 429 });
  await recordAttempt(ipHash);
  await purgeUnconfirmed();

  try {
    const status = await requestCode(parsed.data.email, parsed.data.lang);
    if (status === "too_many_codes") return Response.json({ error: "too_many_codes" }, { status: 429 });
    return Response.json({ ok: true, status });
  } catch {
    return Response.json({ error: "send_failed" }, { status: 502 });
  }
}
