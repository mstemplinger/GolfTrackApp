import { referralStatus, statusSchema } from "@/lib/referral";

/**
 * Eigener Einladungscode samt Stand. Bewusst POST: die Gerätekennung gehört
 * nicht in eine Adresse, die in Protokollen landet.
 */
export async function POST(request: Request) {
  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }
  const parsed = statusSchema.safeParse(payload);
  if (!parsed.success) {
    return Response.json({ error: "invalid_body" }, { status: 400 });
  }
  const status = await referralStatus(parsed.data.device);
  return Response.json(status, { headers: { "Cache-Control": "no-store" } });
}
