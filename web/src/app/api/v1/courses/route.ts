import { listCourses } from "@/lib/courses";
import { toFeed } from "@/lib/feed";
import { courseKind } from "@/lib/schema";

/**
 * Öffentlicher Platzkatalog – die Quelle, aus der die App ihre Plätze lädt.
 * Ohne Schlüssel abrufbar, immer nur freigegebene Einträge.
 */
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const kindParam = searchParams.get("kind");
  const kind = kindParam ? courseKind.safeParse(kindParam) : null;

  if (kindParam && !kind?.success) {
    return Response.json({ error: "invalid_kind" }, { status: 400 });
  }

  const records = await listCourses({
    status: "approved",
    kind: kind?.success ? kind.data : undefined,
    limit: 1000,
  });

  return Response.json(toFeed(records), {
    headers: {
      "Cache-Control": "public, max-age=300, s-maxage=600, stale-while-revalidate=86400",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
