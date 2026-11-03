import { authenticate, lobbyCodeSchema, lobbyState, settingsSchema, updateSettings } from "@/lib/lobby";

/** Nur der Gastgeber: gegenseitiges Orten an/aus, Platz wechseln, Mitspieler entfernen. */
export async function POST(request: Request, ctx: RouteContext<"/api/v1/lobby/[code]/settings">) {
  const { code } = await ctx.params;
  if (!lobbyCodeSchema.safeParse(code).success) {
    return Response.json({ error: "not_found" }, { status: 404 });
  }
  const member = await authenticate(request, code);
  if (!member) return Response.json({ error: "unauthorized" }, { status: 401 });
  if (!member.isHost) return Response.json({ error: "forbidden" }, { status: 403 });

  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }
  const parsed = settingsSchema.safeParse(payload);
  if (!parsed.success) {
    return Response.json({ error: "invalid_body" }, { status: 400 });
  }

  await updateSettings(member, parsed.data);
  const state = await lobbyState(member);
  if (!state) return Response.json({ error: "not_found" }, { status: 404 });
  return Response.json(state, { headers: { "Cache-Control": "no-store" } });
}
