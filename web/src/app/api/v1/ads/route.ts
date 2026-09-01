import { listDeliverableAds } from "@/lib/ads";
import { toAdFeed } from "@/lib/feed";
import { adPlacement } from "@/lib/schema";

/**
 * Anzeigen für die App. Ohne Schlüssel abrufbar, immer nur aktive Einträge,
 * deren Zeitraum heute läuft.
 *
 * Die App holt bewusst alle Anzeigen auf einmal und wählt vor Ort selbst aus:
 * so bleibt der Werbeplatz auch dann gefüllt, wenn auf der Anlage kein Netz
 * ist. `?placement=` grenzt auf einen Platz in der Oberfläche ein.
 */
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const placementParam = searchParams.get("placement");
  const placement = placementParam ? adPlacement.safeParse(placementParam) : null;

  if (placementParam && !placement?.success) {
    return Response.json({ error: "invalid_placement" }, { status: 400 });
  }

  const records = await listDeliverableAds(placement?.success ? placement.data : undefined);

  return Response.json(toAdFeed(records), {
    headers: {
      "Cache-Control": "public, max-age=300, s-maxage=600, stale-while-revalidate=86400",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
