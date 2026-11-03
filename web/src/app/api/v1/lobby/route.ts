import { createLobby, createLobbySchema } from "@/lib/lobby";

/**
 * Lobby anlegen. Antwortet mit dem fünfstelligen Code und dem Token des
 * Gastgebers – das Token gibt es nur hier, die App hebt es auf.
 */
export async function POST(request: Request) {
  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }
  const parsed = createLobbySchema.safeParse(payload);
  if (!parsed.success) {
    return Response.json({ error: "invalid_body" }, { status: 400 });
  }
  const created = await createLobby(parsed.data);
  return Response.json(created, { status: 201, headers: { "Cache-Control": "no-store" } });
}
