import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { adLandingData } from "@/lib/adLandingData";
import { AdLanding, adIsRunning } from "@/views/AdLanding";

/** Englische Fassung von `/werbung/<id>` – siehe dort. */
export const metadata: Metadata = {
  title: "Ad · GolfTrack",
  robots: { index: false, follow: false },
};

export default async function AdLandingPageEn({ params }: PageProps<"/en/ad/[id]">) {
  const { id } = await params;
  const data = await adLandingData(id);
  if (!data) notFound();
  return <AdLanding ad={data.ad} courseName={data.courseName} lang="en" running={adIsRunning(data.ad)} />;
}
