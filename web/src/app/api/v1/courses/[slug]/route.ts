import { getCourse } from "@/lib/courses";
import { toFeedCourse } from "@/lib/feed";

/** Ein einzelner Platz – gleiche Felder wie im Katalog. */
export async function GET(_request: Request, ctx: RouteContext<"/api/v1/courses/[slug]">) {
  const { slug } = await ctx.params;
  const record = await getCourse(slug);

  if (!record || record.status !== "approved") {
    return Response.json({ error: "not_found" }, { status: 404 });
  }

  return Response.json(toFeedCourse(record), {
    headers: {
      "Cache-Control": "public, max-age=300, s-maxage=600, stale-while-revalidate=86400",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
