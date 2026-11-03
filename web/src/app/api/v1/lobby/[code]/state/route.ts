import { authenticate, lobbyCodeSchema, lobbyState, pushState, pushStateSchema } from "@/lib/lobby";

/**
 * Eigenen Stand melden (Schläge, aktuelles Loch, Standort) und gleich den
 * Stand aller zurückbekommen – spart der App eine zweite Abfrage.
 */
export async function POST(request: Request, ctx: RouteContext<"/api/v1/lobby/[code]/state">) {
  const { code } = await ctx.params;
  if (!lobbyCodeSchema.safeParse(code).success) {
    return Response.json({ error: "not_found" }, { status: 404 });
  }
  const member = await authenticate(request, code);
  if (!member) return Response.json({ error: "unauthorized" }, { status: 401 });

  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }
  const parsed = pushStateSchema.safeParse(payload);
  if (!parsed.success) {
    return Response.json({ error: "invalid_body" }, { status: 400 });
  }

  await pushState(member, parsed.data);
  const state = await lobbyState(member);
  if (!state) return Response.json({ error: "not_found" }, { status: 404 });
  return Response.json(state, { headers: { "Cache-Control": "no-store" } });
}
