import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { Footer, Header, PageHeader } from "@/components/Chrome";
import { SITE_URL } from "@/i18n/routes";
import { isPlaceholder, site } from "@/lib/site";
import { PrintRequestForm } from "@/views/PrintRequestForm";

/**
 * Druckwerbung für Golfplätze: elliptische Werbesäulen fürs Clubhaus und die
 * Bauzaunplane für den Zaun am ersten Abschlag. Die Motive kommen aus
 * `marketing/flyer/` (`ellipse-column.mjs`, `fence-banner.mjs`), die Bilder
 * hier sind Renderings daraus.
 *
 * Liegt unter `/werbung/`, damit sie schon vor der Freischaltung offen ist
 * (siehe OPEN in `proxy.ts`) – `/werbung` selbst zeigt bis dahin den Zähler.
 * Ein fester Pfad geht in Next vor `[id]`, die Anzeigen-Zwischenseite stört
 * also nicht.
 */
export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: "GolfTrack auf Ihrem Golfplatz · Werbesäulen und Bauzaunplane",
  description:
    "Werbesäulen fürs Clubhaus und eine Plane für den ersten Abschlag: Ihre Spieler scannen den Code und haben die Scorekarte auf dem Handy. Unverbindlich anfragen.",
  alternates: { canonical: "/werbung/golfplatz" },
};

const COLUMNS = [
  { name: "Golf", size: "60 × 200 cm", text: "„Deine Runde. Jeder Schlag gezählt.“ – Scorekarte, GPS zur Fahne, Apple Watch." },
  { name: "Minigolf", size: "60 × 180 cm", text: "„Minigolf. Ohne Zettel.“ – für Anlagen mit Minigolf oder Adventure-Golf." },
  { name: "Golf lernen", size: "50 × 155 cm", text: "„Platzreife. Range. Erste Runde.“ – für Schnupperkurse und Einsteiger." },
];

const STEPS = [
  { index: "01", title: "Anfragen", text: "Formular unten ausfüllen: welche Werbemittel, wohin, wie viele." },
  { index: "02", title: "Vorschlag", text: "Wir melden uns mit Motiv, Lieferzeit und Konditionen – auf Wunsch mit Ihrem Platznamen." },
  { index: "03", title: "Aufstellen", text: "Säulen stehen ohne Sockel, die Plane kommt mit Ösen an den Zaun. Fertig." },
];

export default function Page() {
  const email = isPlaceholder(site.email) ? null : site.email;

  return (
    <>
      <Header lang="de" current="advertise" />
      <PageHeader
        index="14 — Werbung · Golfplätze"
        title="GolfTrack auf Ihrem Platz"
        lead="Werbesäulen fürs Clubhaus und eine Plane für den ersten Abschlag. Ihre Spieler scannen den Code und haben die Scorekarte auf dem Handy – Schläge, Putts, Entfernung zur Fahne."
      />

      <main className="mx-auto max-w-6xl px-5 py-14 sm:px-8 sm:py-16">
        <p>
          <Link href="#anfragen" className="btn-brass">
            Werbemittel anfragen
          </Link>
        </p>

        <section className="mt-14" aria-labelledby="saeulen">
          <h2 id="saeulen" className="marginal">
            Werbesäulen
          </h2>
          <figure className="mt-5 overflow-hidden rounded-[4px] bg-[#0E2718]">
            <Image
              src="/werbemittel/saeulen-trio.jpg"
              alt="Drei elliptische GolfTrack-Werbesäulen: Golf lernen in Gold, Golf in Dunkelgrün, Minigolf in Creme"
              width={1600}
              height={1200}
              sizes="(min-width: 72rem) 72rem, 100vw"
              className="h-auto w-full"
              priority
            />
          </figure>
          <div className="mt-8 grid gap-10 lg:grid-cols-[1fr_20rem] lg:gap-16">
            <div>
              <p className="max-w-2xl leading-relaxed text-cream/75">
                Elliptische Säulen aus stabiler Wellpappe, vorne und hinten bedruckt. Sie stehen ohne
                Sockel und ohne Strom – im Clubhaus, im Pro-Shop, am Sekretariat oder neben dem
                Starterhaus. Der QR-Code sitzt auf Augenhöhe und führt direkt zur App, kostenlos für
                iPhone, Apple Watch und Android.
              </p>
              <ul className="mt-8 grid gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-3">
                {COLUMNS.map((column) => (
                  <li key={column.name} className="bg-night/85 p-5">
                    <p className="marginal">{column.size}</p>
                    <h3 className="mt-2 font-display text-lg tracking-tight">{column.name}</h3>
                    <p className="mt-2 text-sm leading-relaxed text-cream/70">{column.text}</p>
                  </li>
                ))}
              </ul>
            </div>
            <figure className="self-start overflow-hidden rounded-[4px] bg-[#0E2718]">
              <Image
                src="/werbemittel/saeulen-rueckseiten.jpg"
                alt="Rückseiten der drei Werbesäulen mit senkrechtem GolfTrack-Schriftzug"
                width={1600}
                height={1200}
                sizes="(min-width: 64rem) 20rem, 100vw"
                className="h-auto w-full"
              />
              <figcaption className="p-3 text-xs leading-relaxed text-cream/60">
                Auch von hinten erkennbar: senkrechter Schriftzug auf jeder Rückseite.
              </figcaption>
            </figure>
          </div>
        </section>

        <section className="mt-20 border-t rule pt-14" aria-labelledby="plane">
          <h2 id="plane" className="marginal">
            Bauzaunplane am ersten Abschlag
          </h2>
          <figure className="mt-5 overflow-hidden rounded-[4px] bg-[#0E2718]">
            <Image
              src="/werbemittel/plane-abschlag-3d.jpg"
              alt="GolfTrack-Plane am Zaun auf einer Mauer hinter dem ersten Abschlag: „Ab hier zählt jeder Schlag.“ mit QR-Code"
              width={1600}
              height={900}
              sizes="(min-width: 72rem) 72rem, 100vw"
              className="h-auto w-full"
            />
          </figure>
          <p className="mt-8 max-w-2xl leading-relaxed text-cream/75">
            340 × 173 cm, wetterfestes PVC, gesäumt, mit 20 Ösen – hängt an jedem Bauzaun oder
            Doppelstabmattenzaun. Steht der Zaun zwischen Abschlag und Driving Range, gibt es zwei
            Planen, eine auf jeder Seite.
          </p>

          <div className="mt-10 grid gap-8 md:grid-cols-2">
            <figure>
              <div className="overflow-hidden rounded-[4px] bg-[#0E2718]">
                <Image
                  src="/werbemittel/plane-abschlag-motiv.jpg"
                  alt="Motiv Abschlagseite: „Ab hier zählt jeder Schlag.“, Scorekarte auf dem Handy, drei Schritte und großer QR-Code"
                  width={1600}
                  height={814}
                  sizes="(min-width: 48rem) 36rem, 100vw"
                  className="h-auto w-full"
                />
              </div>
              <figcaption className="mt-3 text-sm leading-relaxed text-cream/70">
                <strong className="font-semibold text-cream">Abschlagseite.</strong> Die Wartezeit bis
                zum Start ist die beste Zeit zum Scannen: QR-Code 42 cm groß, Mitte rund 1,5 m über
                dem Weg, aus gut vier Metern lesbar.
              </figcaption>
            </figure>
            <figure>
              <div className="overflow-hidden rounded-[4px] bg-[#0E2718]">
                <Image
                  src="/werbemittel/plane-range-motiv.jpg"
                  alt="Motiv Range-Seite in Gold: „Jeder Ball zählt.“, großes App-Symbol und Suchfeld mit „GolfTrack“"
                  width={1600}
                  height={814}
                  sizes="(min-width: 48rem) 36rem, 100vw"
                  className="h-auto w-full"
                />
              </div>
              <figcaption className="mt-3 text-sm leading-relaxed text-cream/70">
                <strong className="font-semibold text-cream">Range-Seite.</strong> Durch Gitter und
                Ballfangnetz scannt niemand einen Code. Deshalb kein QR, sondern große Schrift und der
                Name zum Suchen – lesbar auch aus 50 Metern.
              </figcaption>
            </figure>
          </div>

          <figure className="mt-10 overflow-hidden rounded-[4px] bg-[#0E2718]">
            <Image
              src="/werbemittel/plane-range-3d.jpg"
              alt="Die goldene Range-Seite der Plane, gesehen von der Driving Range durch das Ballfangnetz"
              width={1600}
              height={900}
              sizes="(min-width: 72rem) 72rem, 100vw"
              className="h-auto w-full"
            />
            <figcaption className="p-3 text-xs leading-relaxed text-cream/60">
              Von der Driving Range aus gesehen, durch das Ballfangnetz.
            </figcaption>
          </figure>
        </section>

        <section className="mt-20 border-t rule pt-14" aria-labelledby="ablauf">
          <h2 id="ablauf" className="marginal">
            So läuft es
          </h2>
          <ol className="mt-5 grid gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-3">
            {STEPS.map((step) => (
              <li key={step.index} className="bg-night/85 p-6">
                <p className="marginal">{step.index}</p>
                <h3 className="mt-3 font-display text-xl tracking-tight">{step.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-cream/70">{step.text}</p>
              </li>
            ))}
          </ol>
        </section>

        <section id="anfragen" className="mt-16 scroll-mt-8 border-t rule pt-14">
          <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_18rem] lg:gap-12">
            <PrintRequestForm email={email} />
            <aside className="lg:pt-1">
              <h2 className="marginal">Lieber direkt schreiben?</h2>
              <p className="mt-4 text-sm leading-relaxed text-cream/70">
                Geht auch – mit dem Namen des Platzes im Betreff.
              </p>
              {email ? (
                <a
                  href={`mailto:${email}?subject=${encodeURIComponent("Werbemittel für unseren Golfplatz")}`}
                  className="btn-ghost mt-4 w-full"
                >
                  Mail schreiben
                </a>
              ) : null}
              <p className="mt-6 text-xs leading-relaxed text-cream/55">
                Sie möchten stattdessen in der App werben, bei den Spielern der Plätze ringsum?
              </p>
              <Link href="/werbung" className="btn-ghost mt-3 w-full">
                Werbeplatz in der App
              </Link>
            </aside>
          </div>
        </section>
      </main>

      <Footer lang="de" />
    </>
  );
}
