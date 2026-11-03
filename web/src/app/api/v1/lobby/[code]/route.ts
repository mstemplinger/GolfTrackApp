import { authenticate, leaveLobby, lobbyCodeSchema, lobbyState } from "@/lib/lobby";

/** Stand der Lobby: alle Mitspieler mit Schlägen und – falls geteilt – Standort. */
export async function GET(request: Request, ctx: RouteContext<"/api/v1/lobby/[code]">) {
  const { code } = await ctx.params;
  if (!lobbyCodeSchema.safeParse(code).success) {
    return Response.json({ error: "not_found" }, { status: 404 });
  }
  const member = await authenticate(request, code);
  if (!member) return Response.json({ error: "unauthorized" }, { status: 401 });

  const state = await lobbyState(member);
  if (!state) return Response.json({ error: "not_found" }, { status: 404 });
  return Response.json(state, { headers: { "Cache-Control": "no-store" } });
}

/** Lobby verlassen. Beim Gastgeber endet sie damit für alle. */
export async function DELETE(request: Request, ctx: RouteContext<"/api/v1/lobby/[code]">) {
  const { code } = await ctx.params;
  if (!lobbyCodeSchema.safeParse(code).success) {
    return Response.json({ error: "not_found" }, { status: 404 });
  }
  const member = await authenticate(request, code);
  if (!member) return Response.json({ ok: true });
  await leaveLobby(member);
  return Response.json({ ok: true });
}
