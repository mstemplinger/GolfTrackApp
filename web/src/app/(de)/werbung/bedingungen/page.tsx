import type { Metadata } from "next";
import { AdTerms } from "@/views/Legal";

export const metadata: Metadata = {
  title: "Bedingungen für Werbekunden · GolfTrack",
  description: "Bedingungen für die Buchung von Werbeplätzen in der App GolfTrack.",
  alternates: { canonical: "/werbung/bedingungen" },
};

export default function Page() {
  return <AdTerms />;
}
