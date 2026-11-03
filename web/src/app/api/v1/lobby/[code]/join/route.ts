import { joinAllowed, joinLobby, joinLobbySchema, lobbyCodeSchema } from "@/lib/lobby";

/** Mit Code oder gescanntem QR-Code beitreten. */
export async function POST(request: Request, ctx: RouteContext<"/api/v1/lobby/[code]/join">) {
  if (!joinAllowed(request)) {
    return Response.json({ error: "rate_limited" }, { status: 429 });
  }
  const { code } = await ctx.params;
  if (!lobbyCodeSchema.safeParse(code).success) {
    return Response.json({ error: "not_found" }, { status: 404 });
  }
  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }
  const parsed = joinLobbySchema.safeParse(payload);
  if (!parsed.success) {
    return Response.json({ error: "invalid_body" }, { status: 400 });
  }

  const result = await joinLobby(code, parsed.data.name);
  if (!result.ok) {
    return Response.json({ error: result.error }, { status: result.error === "full" ? 409 : 404 });
  }
  return Response.json(
    { code, memberId: result.memberId, token: result.token },
    { status: 201, headers: { "Cache-Control": "no-store" } },
  );
}
