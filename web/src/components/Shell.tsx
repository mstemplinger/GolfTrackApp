import type { Metadata } from "next";
import { fontVariables } from "@/lib/fonts";
import { t } from "@/i18n/content";
import { SITE_URL, alternatePath, path, type Lang, type RouteKey } from "@/i18n/routes";
import "@/app/globals.css";

/** Gemeinsames Grundgerüst beider Sprachfassungen. */
export function Document({ lang, children }: { lang: Lang; children: React.ReactNode }) {
  return (
    <html lang={lang} className={`${fontVariables} h-full`}>
      <body className="grain glow min-h-full">{children}</body>
    </html>
  );
}

/** Metadaten inklusive hreflang-Verweis auf die andere Sprachfassung. */
export function pageMetadata(
  lang: Lang,
  route: RouteKey,
  overrides: { title?: string; description?: string } = {},
): Metadata {
  const copy = t(lang);
  const here = path(route, lang);
  const there = alternatePath(route, lang);
  const title = overrides.title ?? copy.meta.title;
  const description = overrides.description ?? copy.meta.description;

  return {
    metadataBase: new URL(SITE_URL),
    title,
    description,
    alternates: {
      canonical: here,
      languages: {
        de: lang === "de" ? here : there,
        en: lang === "en" ? here : there,
        "x-default": path(route, "de"),
      },
    },
    openGraph: {
      title,
      description,
      url: here,
      siteName: "GolfTrack",
      locale: copy.meta.locale,
      type: "website",
    },
    twitter: { card: "summary_large_image", title, description },
  };
}
