import { recordAdEvents } from "@/lib/ads";
import { adEventBatchSchema } from "@/lib/schema";

/**
 * Reichweite melden: wie oft eine Anzeige zu sehen war und wie oft jemand
 * darauf getippt hat. Die App sammelt das während der Runde und schickt es
 * am Ende gebündelt.
 *
 * Bewusst ohne Schlüssel und ohne Gerätekennung – gespeichert wird nur
 * „Anzeige X, Tag Y, n mal". Damit ist die Zahl nicht fälschungssicher; für
 * die Abrechnung mit einer Anlage reicht sie, für einen Werbemarkt mit
 * fremdem Geld müsste ein signierter Beleg dazukommen.
 */
export async function POST(request: Request) {
  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }

  const parsed = adEventBatchSchema.safeParse(payload);
  if (!parsed.success) {
    return Response.json({ error: "invalid_body" }, { status: 400 });
  }

  await recordAdEvents(parsed.data.events);

  return Response.json(
    { ok: true, accepted: parsed.data.events.length },
    { headers: { "Access-Control-Allow-Origin": "*" } },
  );
}

export async function OPTIONS() {
  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    },
  });
}
