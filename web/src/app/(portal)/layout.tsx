import type { Metadata, Viewport } from "next";
import { Document } from "@/components/Shell";
import { operatorLang } from "@/lib/operatorLang";

/**
 * Eigenes Wurzel-Layout für das Betreiber-Portal (operator.golftrack.app):
 * die Sprache – und damit `<html lang>` – richtet sich nach dem Betreiber,
 * nicht nach der Adresse wie bei (de) und (en).
 */
export const metadata: Metadata = {
  title: "GolfTrack for operators",
  robots: { index: false, follow: false },
};
export const viewport: Viewport = { themeColor: "#08180f" };

export default async function PortalRootLayout({ children }: { children: React.ReactNode }) {
  return <Document lang={await operatorLang()}>{children}</Document>;
}
