import { z } from "zod";
import { confirmCode } from "@/lib/waitlist";

const schema = z.object({
  email: z.string().trim().email().max(200),
  code: z.string().trim().regex(/^\d{6}$/),
});

/** Schritt 2: Code aus der Mail bestätigen. Fünf Fehlversuche sperren den Code. */
export async function POST(request: Request) {
  const parsed = schema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return Response.json({ error: "wrong" }, { status: 422 });
  const result = await confirmCode(parsed.data.email, parsed.data.code);
  if (result === "confirmed") return Response.json({ ok: true });
  return Response.json({ error: result }, { status: result === "locked" ? 429 : 422 });
}
