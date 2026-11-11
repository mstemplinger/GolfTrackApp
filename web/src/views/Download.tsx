import Link from "next/link";
import { headers } from "next/headers";
import { Footer, Header } from "@/components/Chrome";
import { APP_STORE_URL, path } from "@/i18n/routes";

/**
 * Die Weiche zwischen App Store und Android-APK.
 *
 * Wer auf „laden“ tippt oder einen Code scannt, soll nicht raten müssen, ob
 * der App-Store-Link auf seinem Gerät überhaupt etwas taugt. Das passende
 * Angebot steht oben und ist hervorgehoben; erkannt wird es am User-Agent,
 * im Zweifel bleibt das iPhone vorn.
 *
 * Genutzt von `/laden` (Anlagenseiten) und `/download` (QR-Code auf den
 * Druckplakaten). Beide unterscheiden sich nur im Hinweis unten.
 */
export async function Download({ note }: { note: string }) {
  const agent = (await headers()).get("user-agent") ?? "";
  const android = /android/i.test(agent);

  const options = [
    {
      key: "ios",
      label: "iPhone & Apple Watch",
      title: "Im App Store laden",
      text: "Die volle App mit Zählkarte, Laufspur, Statistik und Apple Watch.",
      href: APP_STORE_URL,
      external: true,
    },
    {
      key: "android",
      label: "Android",
      title: "APK für Android laden",
      text: "Direkt von golftrack.app, bis die App im Play Store erscheint.",
      href: path("android", "de"),
      external: false,
    },
  ];
  if (android) options.reverse();

  return (
    <>
      <Header lang="de" />
      <main className="mx-auto max-w-xl px-5 py-16 text-center sm:px-8 sm:py-20">
        <p className="marginal">Download</p>
        <h1 className="mt-4 font-display text-[clamp(2rem,5.5vw,3rem)] leading-[1.05] tracking-[-0.02em]">
          GolfTrack laden
        </h1>
        <p className="mx-auto mt-4 max-w-md text-cream/65">
          Kostenlos. Wähle dein Gerät.
        </p>

        <div className="mt-10 grid gap-4 text-left">
          {options.map((option, index) => {
            const primary = index === 0;
            const className = primary
              ? "block rounded-2xl bg-brass p-6 text-[#1c1400] transition hover:bg-brass-soft"
              : "block rounded-2xl border rule bg-moss/30 p-6 transition hover:bg-moss/50";
            const body = (
              <>
                <span className={`text-xs font-semibold uppercase tracking-[0.14em] ${primary ? "opacity-70" : "text-brass"}`}>
                  {option.label}
                </span>
                <span className="mt-1.5 block font-display text-2xl font-bold tracking-[-0.02em]">
                  {option.title} →
                </span>
                <span className={`mt-2 block text-sm leading-relaxed ${primary ? "opacity-80" : "text-cream/60"}`}>
                  {option.text}
                </span>
              </>
            );
            return option.external ? (
              <a key={option.key} href={option.href} target="_blank" rel="noreferrer" className={className}>
                {body}
              </a>
            ) : (
              <Link key={option.key} href={option.href} className={className}>
                {body}
              </Link>
            );
          })}
        </div>

        <p className="mt-10 text-sm text-cream/45">{note}</p>
      </main>
      <Footer lang="de" />
    </>
  );
}
