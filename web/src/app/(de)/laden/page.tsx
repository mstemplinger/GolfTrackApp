import type { Metadata } from "next";
import { SITE_URL } from "@/i18n/routes";
import { Download } from "@/views/Download";

/** „GolfTrack laden“ – die Weiche, verlinkt von den Anlagenseiten. */
export const metadata: Metadata = {
  title: "GolfTrack laden · App Store oder Android",
  description: "GolfTrack für iPhone und Apple Watch aus dem App Store oder als APK für Android.",
  alternates: { canonical: `${SITE_URL}/laden` },
  robots: { index: true, follow: true },
};

export default function Page() {
  return (
    <Download note="Zum Mitzählen auf einer Anlage brauchst du nichts zu laden – der QR-Code vor Ort startet die Runde auch ohne Installation." />
  );
}
