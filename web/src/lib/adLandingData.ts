import "server-only";
import { getAd } from "./ads";
import { getCourse } from "./courses";

/**
 * Was die Zwischenseite einer Anzeige braucht. Entwürfe gibt es nach außen
 * nicht – die sind nie in einer App gelandet.
 */
export async function adLandingData(id: string) {
  const ad = await getAd(id);
  if (!ad || ad.status === "draft") return null;
  const course = ad.courseSlug ? await getCourse(ad.courseSlug) : null;
  return { ad, courseName: course?.name };
}
