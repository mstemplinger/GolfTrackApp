import { claimAllowed, claimReferral, claimSchema, referralCodeSchema } from "@/lib/referral";

/** Ein eingeladener Freund löst den Code ein – per Universal Link oder von Hand. */
export async function POST(request: Request, ctx: RouteContext<"/api/v1/referral/[code]/claim">) {
  if (!claimAllowed(request)) {
    return Response.json({ error: "rate_limited" }, { status: 429 });
  }
  const { code: raw } = await ctx.params;
  const code = raw.toUpperCase();
  if (!referralCodeSchema.safeParse(code).success) {
    return Response.json({ error: "not_found" }, { status: 404 });
  }
  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }
  const parsed = claimSchema.safeParse(payload);
  if (!parsed.success) {
    return Response.json({ error: "invalid_body" }, { status: 400 });
  }
  const result = await claimReferral(code, parsed.data.device);
  if (!result.ok) {
    const status = result.error === "not_found" ? 404 : 409;
    return Response.json({ error: result.error }, { status, headers: { "Cache-Control": "no-store" } });
  }
  return Response.json({ ok: true }, { status: 201, headers: { "Cache-Control": "no-store" } });
}
