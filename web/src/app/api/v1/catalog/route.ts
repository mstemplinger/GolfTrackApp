import { catalogStatus } from "@/lib/courses";

/**
 * Ist im Katalog etwas dazugekommen? Die App fragt das bei jedem Start und
 * lädt `/api/v1/courses` nur, wenn sich der Stand geändert hat. Welche Plätze
 * neu sind und ob sie im Umkreis liegen, rechnet das Gerät selbst aus – der
 * Standort verlässt es dafür nicht.
 */
export async function GET() {
  const status = await catalogStatus();
  return Response.json(
    { version: 1, ...status },
    {
      headers: {
        "Cache-Control": "public, max-age=60, s-maxage=60",
        "Access-Control-Allow-Origin": "*",
      },
    },
  );
}
