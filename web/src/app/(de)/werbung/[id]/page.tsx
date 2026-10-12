import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound, redirect } from "next/navigation";
import { adLandingData } from "@/lib/adLandingData";
import { AdLanding, adIsRunning } from "@/views/AdLanding";

/**
 * Ziel jeder Anzeige in der App. Die App öffnet immer diese deutsche Adresse;
 * wer Deutsch nicht als Sprache eingestellt hat, wird auf `/en/ad/<id>`
 * weitergeleitet – die App selbst kennt fünf Sprachen, die Website zwei.
 */
export const metadata: Metadata = {
  title: "Anzeige · GolfTrack",
  robots: { index: false, follow: false },
};

export default async function AdLandingPage({ params }: PageProps<"/werbung/[id]">) {
  const { id } = await params;
  const data = await adLandingData(id);
  if (!data) notFound();

  const accept = (await headers()).get("accept-language") ?? "";
  if (accept && !/^\s*de\b/i.test(accept)) redirect(`/en/ad/${data.ad.id}`);

  return <AdLanding ad={data.ad} courseName={data.courseName} lang="de" running={adIsRunning(data.ad)} />;
}
