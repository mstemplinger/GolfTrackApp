import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Footer, Header } from "@/components/Chrome";
import { APP_STORE_URL } from "@/i18n/routes";

/**
 * Ziel des Einladungslinks (`golftrack.app/einladen/<code>`). Mit installierter
 * App öffnet der Universal Link direkt die App, die den Code einlöst – diese
 * Seite sieht, wer GolfTrack noch nicht hat. Nach dem Laden gibt man den Code
 * im Profil unter „Freunde einladen“ ein.
 */
export const metadata: Metadata = {
  title: "Einladung zu GolfTrack",
  robots: { index: false, follow: false },
};

export default async function InvitePage({ params }: PageProps<"/einladen/[code]">) {
  const { code: raw } = await params;
  const code = raw.toUpperCase();
  if (!/^[A-HJ-NP-Z2-9]{6}$/.test(code)) notFound();

  return (
    <>
      <Header lang="de" />
      <main className="mx-auto max-w-xl px-5 py-16 text-center sm:px-8 sm:py-20">
        <p className="marginal">Einladung</p>
        <h1 className="mt-4 font-display text-[clamp(2rem,5.5vw,3rem)] leading-[1.05] tracking-[-0.02em]">
          Ein Freund lädt dich zu GolfTrack ein
        </h1>
        <p className="mx-auto mt-4 max-w-md text-cream/65">
          Lade GolfTrack, öffne das Profil und gib bei „Freunde einladen“ diesen Code ein.
          Ist die App schon installiert, öffne diesen Link einfach noch einmal.
        </p>
        <p className="mt-10 font-display text-6xl font-bold tracking-[0.2em] text-brass">{code}</p>
        <a
          href={APP_STORE_URL}
          target="_blank"
          rel="noreferrer"
          className="mt-10 inline-block rounded-2xl bg-brass px-6 py-4 font-semibold text-[#1c1400] transition hover:bg-brass-soft"
        >
          GolfTrack im App Store laden →
        </a>
      </main>
      <Footer lang="de" />
    </>
  );
}
