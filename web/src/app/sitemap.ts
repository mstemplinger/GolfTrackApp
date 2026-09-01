import type { MetadataRoute } from "next";
import { listCourses } from "@/lib/courses";
import { LANGS, SITE_URL, path, type RouteKey } from "@/i18n/routes";

/** Enthaelt die freigegebenen Anlagen – taeglich neu. */
export const revalidate = 86400;

const ROUTES: RouteKey[] = ["home", "directory", "submit", "support", "api", "privacy", "imprint"];

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const pages: MetadataRoute.Sitemap = ROUTES.flatMap((route) =>
    LANGS.map((lang) => ({
      url: `${SITE_URL}${path(route, lang)}`,
      lastModified: new Date(),
      changeFrequency: "monthly" as const,
      priority: route === "home" ? 1 : 0.7,
      alternates: {
        languages: Object.fromEntries(
          LANGS.map((other) => [other, `${SITE_URL}${path(route, other)}`]),
        ),
      },
    })),
  );

  // Nur auf Deutsch: die Seite richtet sich an Betreiber hiesiger Anlagen.
  pages.push({
    url: `${SITE_URL}/werbung`,
    lastModified: new Date(),
    changeFrequency: "monthly",
    priority: 0.4,
  });

  const minigolf = await listCourses({ status: "approved", kind: "minigolf", limit: 1000 });
  for (const course of minigolf) {
    pages.push({
      url: `${SITE_URL}/minigolf/${course.slug}`,
      lastModified: new Date(course.updatedAt),
      changeFrequency: "monthly",
      priority: 0.5,
    });
  }

  return pages;
}
