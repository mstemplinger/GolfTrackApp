import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Footer, Header } from "@/components/Chrome";
import { APP_STORE_URL } from "@/i18n/routes";

/**
 * Ziel des Lobby-QR-Codes (`golftrack.app/lobby/<code>`). Mit installierter
 * App öffnet der Universal Link direkt den Beitritt – diese Seite sieht nur,
 * wer die App noch nicht hat oder den Code mit einer fremden Kamera scannt.
 */
export const metadata: Metadata = {
  title: "Lobby beitreten · GolfTrack",
  robots: { index: false, follow: false },
};

export default async function LobbyPage({ params }: PageProps<"/lobby/[code]">) {
  const { code } = await params;
  if (!/^\d{5}$/.test(code)) notFound();

  return (
    <>
      <Header lang="de" />
      <main className="mx-auto max-w-xl px-5 py-16 text-center sm:px-8 sm:py-20">
        <p className="marginal">Gemeinsame Runde</p>
        <h1 className="mt-4 font-display text-[clamp(2rem,5.5vw,3rem)] leading-[1.05] tracking-[-0.02em]">
          Lobby {code}
        </h1>
        <p className="mx-auto mt-4 max-w-md text-cream/65">
          Öffne GolfTrack, tippe bei „Neue Runde“ auf „Mit Freunden spielen“ und gib den Code ein –
          oder scanne den QR-Code mit der Kamera, wenn die App installiert ist.
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
