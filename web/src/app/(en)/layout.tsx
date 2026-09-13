import type { Metadata, Viewport } from "next";
import { Document, pageMetadata } from "@/components/Shell";

export const metadata: Metadata = pageMetadata("en", "home");
/**
 * `viewportFit: "cover"` lässt die Seite bis in die sicheren Bereiche reichen –
 * unter die Statusleiste und über den Home-Balken. Ohne das endet eine Fläche
 * mit `position: fixed; inset: 0` vor diesen Streifen, und dort scheint der
 * Inhalt dahinter durch (sichtbar geworden am Vollbild-Zähler auf dem iPhone).
 * Kopfzeile und Fuß gleichen das mit `env(safe-area-inset-*)` wieder aus.
 */
export const viewport: Viewport = { themeColor: "#08180f", viewportFit: "cover" };

export default function EnglishRootLayout({ children }: { children: React.ReactNode }) {
  return <Document lang="en">{children}</Document>;
}
