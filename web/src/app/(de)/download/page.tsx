import type { Metadata } from "next";
import { SITE_URL } from "@/i18n/routes";
import { Download } from "@/views/Download";

/**
 * Ziel des QR-Codes auf den Druckplakaten (marketing/flyer). Ein Code für
 * beide Plattformen, deshalb hier die Weiche statt des App-Store-Links.
 * Dieselbe Seite wie `/laden`, nur mit einem Hinweis für Golf-Einsteiger.
 */
export const metadata: Metadata = {
  title: "GolfTrack laden · App Store oder Android",
  description: "GolfTrack für iPhone und Apple Watch aus dem App Store oder als APK für Android.",
  alternates: { canonical: `${SITE_URL}/laden` },
};

export default function Page() {
  return (
    <Download note="Neu im Golf? Starte in der App mit „Platzreife lernen“ – die Prüfungsfragen sind kostenlos dabei." />
  );
}
