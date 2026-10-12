import Link from "next/link";
import { Footer, Header } from "@/components/Chrome";
import type { AdRecord } from "@/lib/ads";

/**
 * Zwischenseite hinter jeder Anzeige in der App: `golftrack.app/werbung/<id>`
 * (englisch `/en/ad/<id>`).
 *
 * Wer in der Zählkarte auf eine Anzeige tippt, landet nicht direkt beim
 * Werbenden, sondern erst hier: oben die Anzeige mit dem Weg zur Website,
 * darunter, warum genau diese Anzeige auf diesem Platz steht. Das ist die
 * Antwort auf „Woher weiß die App, wo ich bin?" – sie weiß es nicht, sie kennt
 * nur den Platz.
 */

type Lang = "de" | "en";

const TEXT = {
  de: {
    badge: "Anzeige",
    visit: "Zur Website",
    noLink: "Diese Anzeige verweist auf keine Website.",
    ended: "Diese Anzeige läuft nicht mehr.",
    why: "Warum sehe ich diese Anzeige?",
    course: (name: string) =>
      `Sie ist für die Anlage „${name}“ gebucht und steht nur in deren Zählkarte.`,
    radius: (km: number, place: string) =>
      `Sie ist für die Golf- und Minigolfplätze im Umkreis von ${km} km${place ? ` um ${place}` : ""} gebucht. Liegt der Platz, auf dem Sie spielen, darin, steht sie in Ihrer Zählkarte.`,
    nearest:
      "Liegt ein Platz in keinem gebuchten Umkreis, zeigt GolfTrack dort die Anzeigen des nächstgelegenen Umkreises – damit auch dort keine leere Fläche steht.",
    everywhere: "Sie ist für alle Plätze gebucht, für die es keine Anzeige aus der Region gibt.",
    privacy: "Was dabei nicht passiert",
    privacyItems: [
      "Die Auswahl trifft Ihr Gerät anhand des Platzes – Ihr Standort verlässt es dafür nicht.",
      "Kein Werbenetzwerk, keine Gerätekennung, kein Profil.",
      "Gezählt wird nur, wie oft die Anzeige zu sehen war und wie oft jemand darauf getippt hat.",
    ],
    adFree: "Ohne Werbung spielen",
    adFreeText:
      "Mit „Werbefrei“ (einmalig in der App) oder einem Training- bzw. Caddy-Abo verschwindet die Fläche ganz. Die Hinweise der Anlage – Toiletten, Unterstand, Ausschank – bleiben.",
    advertise: "Selbst hier werben?",
    advertiseText: "Umkreis auf der Karte wählen, Preis steht sofort daneben.",
    advertiseLink: "Werbeplatz anfragen",
  },
  en: {
    badge: "Ad",
    visit: "Visit website",
    noLink: "This ad doesn't link to a website.",
    ended: "This ad is no longer running.",
    why: "Why am I seeing this ad?",
    course: (name: string) => `It was booked for the course “${name}” and only appears on its scorecard.`,
    radius: (km: number, place: string) =>
      `It was booked for golf and mini golf courses within ${km} km${place ? ` of ${place}` : ""}. If the course you're playing lies inside that radius, it appears on your scorecard.`,
    nearest:
      "Courses outside every booked radius show the ads of the nearest radius, so the space is never left empty.",
    everywhere: "It was booked for all courses that have no regional ad.",
    privacy: "What doesn't happen",
    privacyItems: [
      "Your device picks the ad based on the course – your location never leaves it for this.",
      "No ad network, no device identifier, no profile.",
      "We only count how often the ad was shown and how often it was tapped.",
    ],
    adFree: "Play without ads",
    adFreeText:
      "“Ad-free” (a one-time purchase in the app) or a Training or Caddy subscription removes the space entirely. The course's own notes – toilets, shelter, refreshments – stay.",
    advertise: "Advertise here yourself?",
    advertiseText: "Pick a radius on the map and see the price right away.",
    advertiseLink: "Request an ad slot",
  },
} as const;

export function AdLanding({
  ad,
  lang,
  running,
  courseName,
}: {
  ad: AdRecord;
  lang: Lang;
  running: boolean;
  /** Klarname der Anlage bei einer platzgebundenen Anzeige. */
  courseName?: string;
}) {
  const t = TEXT[lang];
  const scope = ad.courseSlug
    ? t.course(courseName || ad.courseSlug)
    : ad.radiusKm && ad.latitude != null && ad.longitude != null
      ? t.radius(ad.radiusKm, ad.placeName)
      : t.everywhere;
  const showsNearest = !ad.courseSlug && ad.radiusKm != null;

  return (
    <>
      <Header lang={lang} current={lang === "de" ? "advertise" : undefined} />
      <main className="mx-auto max-w-3xl px-5 py-14 sm:px-8 sm:py-16">
        <article className="rounded-[4px] bg-[#0E2718] p-5 sm:p-6">
          <div className="flex items-center gap-4">
            {ad.imageURL ? (
              // eslint-disable-next-line @next/next/no-img-element -- fremde Adresse, absichtlich ohne Optimierung
              <img src={ad.imageURL} alt="" className="size-20 shrink-0 rounded-xl object-cover" />
            ) : (
              <span className="grid size-20 shrink-0 place-items-center rounded-xl bg-[#1C4129] text-2xl text-[#C9A035]">
                ★
              </span>
            )}
            <div className="min-w-0">
              <span className="rounded-[3px] bg-white/10 px-1.5 py-px font-mono text-[0.6rem] uppercase tracking-[0.12em] text-white/60">
                {t.badge}
              </span>
              <h1 className="mt-1.5 font-display text-2xl leading-tight tracking-tight text-white sm:text-3xl">
                {ad.title}
              </h1>
              {ad.subtitle ? <p className="mt-1 text-sm text-white/70">{ad.subtitle}</p> : null}
              {ad.advertiser ? <p className="mt-1 text-xs text-white/50">{ad.advertiser}</p> : null}
            </div>
          </div>

          <div className="mt-6">
            {!running ? (
              <p className="text-sm text-white/60">{t.ended}</p>
            ) : ad.linkURL ? (
              <a href={ad.linkURL} rel="sponsored noopener" className="btn-brass w-full sm:w-auto">
                {t.visit} →
              </a>
            ) : (
              <p className="text-sm text-white/60">{t.noLink}</p>
            )}
            {running && ad.linkURL ? (
              <p className="mt-2 break-all font-mono text-xs text-white/45">{ad.linkURL}</p>
            ) : null}
          </div>
        </article>

        <section className="mt-12">
          <h2 className="font-display text-2xl tracking-tight">{t.why}</h2>
          <p className="mt-3 leading-relaxed text-cream/75">{scope}</p>
          {showsNearest ? <p className="mt-3 leading-relaxed text-cream/75">{t.nearest}</p> : null}

          <h3 className="marginal mt-10">{t.privacy}</h3>
          <ul className="mt-3 space-y-2 leading-relaxed text-cream/75">
            {t.privacyItems.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>

          <h3 className="marginal mt-10">{t.adFree}</h3>
          <p className="mt-3 leading-relaxed text-cream/75">{t.adFreeText}</p>

          <div className="mt-12 border-t rule pt-8">
            <h3 className="font-display text-xl tracking-tight">{t.advertise}</h3>
            <p className="mt-2 text-sm text-cream/70">{t.advertiseText}</p>
            <Link href="/werbung#anfragen" className="btn-ghost mt-4">
              {t.advertiseLink}
            </Link>
          </div>
        </section>
      </main>
      <Footer lang={lang} />
    </>
  );
}

/** Läuft die Anzeige heute? Dieselbe Regel wie `listDeliverableAds`. */
export function adIsRunning(ad: AdRecord, today = new Date().toISOString().slice(0, 10)): boolean {
  if (ad.status !== "active") return false;
  if (ad.startsOn && today < ad.startsOn) return false;
  if (ad.endsOn && today > ad.endsOn) return false;
  return true;
}
