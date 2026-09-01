import Link from "next/link";
import { Footer, Header, SectionHeading } from "@/components/Chrome";
import { PhoneShot, WatchShot } from "@/components/Device";
import { HoleMap } from "@/components/HoleMap";
import { Scorecard } from "@/components/Scorecard";
import { t } from "@/i18n/content";
import { APP_STORE_URL, path, type Lang } from "@/i18n/routes";

/**
 * Startseite.
 *
 * Der Rhythmus wechselt bewusst von Abschnitt zu Abschnitt: Bühne mit Gerät,
 * Filmstreifen, Rasterwand, Uhrenpaar, Zeichnung neben Foto, reine Typografie.
 * Getrennt wird mit Haarlinien und Abstand, nicht mit Farbflächen – der
 * Hintergrund läuft als ein einziger Verlauf durch (siehe `.glow`).
 */
export function Home({ lang }: { lang: Lang }) {
  const copy = t(lang);
  const home = copy.home;
  const [titleTop, titleBottom] = home.title.split("\n");

  return (
    <>
      <Header lang={lang} />

      <main>
        {/* 01 — Bühne: Text, Gerät, darüber gelegt die Papierkarte */}
        <section className="mx-auto max-w-6xl px-5 pb-24 pt-14 sm:px-8 sm:pt-20">
          <div className="grid items-center gap-12 lg:grid-cols-[1.02fr_0.98fr] lg:gap-8">
            <div>
              <p className="marginal reveal">{home.eyebrow}</p>
              <h1
                className="reveal mt-5 font-display text-[clamp(2.5rem,7vw,4.6rem)] font-extrabold leading-[0.95] tracking-[-0.04em]"
                style={{ animationDelay: "80ms" }}
              >
                {titleTop}
                <br />
                <span className="text-brass">{titleBottom}</span>
              </h1>
              <p
                className="reveal mt-6 max-w-md text-lg leading-relaxed text-cream/75"
                style={{ animationDelay: "160ms" }}
              >
                {home.lead}
              </p>
              <div className="reveal mt-9 flex flex-wrap gap-3" style={{ animationDelay: "240ms" }}>
                <a href={APP_STORE_URL} target="_blank" rel="noreferrer" className="btn-brass">
                  <AppleMark />
                  {home.ctaPrimary}
                </a>
                <Link href={path("submit", lang)} className="btn-ghost">
                  {home.ctaSecondary}
                </Link>
              </div>
            </div>

            <div className="reveal relative mx-auto w-full max-w-md lg:mx-0 lg:max-w-none" style={{ animationDelay: "320ms" }}>
              <div className="flex justify-center lg:justify-end lg:pr-6">
                <PhoneShot
                  shot="01-home"
                  alt={home.heroShotAlt}
                  lang={lang}
                  width={296}
                  priority
                  className="rotate-[-1.2deg]"
                />
              </div>
              <Scorecard
                caption={home.scorecardCaption}
                labels={home.scorecardLabels}
                className="relative z-10 -mt-14 w-full rotate-[1.6deg] sm:-mt-20 lg:absolute lg:bottom-[-1.5rem] lg:left-0 lg:mt-0 lg:w-[21rem]"
              />
            </div>
          </div>
        </section>

        {/* 02 — Ablauf: vier Schritte als Filmstreifen */}
        <section id="runde" className="border-t rule">
          <div className="mx-auto max-w-6xl px-5 py-16 sm:px-8 sm:py-20">
            <SectionHeading index={home.roundEyebrow} title={home.roundTitle} lead={home.roundLead} />
            {/*
              Am Handy steht das Gerät über dem Text, ab 40rem daneben, ab
              48rem stehen die vier Schritte nebeneinander wie ein Filmstreifen.
            */}
            <ol className="mt-12 grid gap-9 md:grid-cols-4 md:gap-6">
              {home.roundSteps.map((step, index) => (
                <li
                  key={step.shot}
                  className="grid gap-5 sm:grid-cols-[minmax(0,13rem)_minmax(0,1fr)] sm:items-center md:block"
                >
                  <PhoneShot shot={step.shot} alt={step.alt} lang={lang} width={260} className="w-48 sm:w-full" />
                  <div className="md:mt-5">
                    <p className="marginal">{String(index + 1).padStart(2, "0")}</p>
                    <h3 className="mt-2 font-display text-xl tracking-tight">{step.title}</h3>
                    <p className="mt-2 text-sm leading-relaxed text-cream/65">{step.body}</p>
                  </div>
                </li>
              ))}
            </ol>
          </div>
        </section>

        {/* 03 — Rasterwand mit Haarlinien */}
        <section id="funktionen" className="border-t rule">
          <div className="mx-auto max-w-6xl px-5 py-16 sm:px-8 sm:py-20">
            <SectionHeading index={home.featuresEyebrow} title={home.featuresTitle} />
            <ul className="mt-12 grid gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-2 lg:grid-cols-3">
              {home.features.map((feature, index) => (
                <li key={feature.title} className="bg-black/25 p-7 transition-colors hover:bg-white/[0.04]">
                  <span className="marginal">{String(index + 1).padStart(2, "0")}</span>
                  <h3 className="mt-3 font-display text-xl tracking-tight">{feature.title}</h3>
                  <p className="mt-2.5 text-sm leading-relaxed text-cream/65">{feature.body}</p>
                </li>
              ))}
            </ul>
          </div>
        </section>

        {/* 04 — Uhr: zwei kleine Geräte neben dem Text */}
        <section id="watch" className="border-t rule">
          <div className="mx-auto grid max-w-6xl items-center gap-12 px-5 py-16 sm:px-8 sm:py-24 lg:grid-cols-[0.9fr_1.1fr]">
            <div className="flex items-end justify-center gap-5 sm:gap-8 lg:order-2 lg:justify-end">
              <WatchShot shot="w1-setup" alt={home.watchAlts[0]} width={188} className="mb-8" />
              <WatchShot shot="w2-tracker" alt={home.watchAlts[1]} width={214} />
            </div>
            <div className="lg:order-1">
              <SectionHeading index={home.watchEyebrow} title={home.watchTitle} lead={home.watchBody} />
              <ul className="mt-8 space-y-2.5">
                {home.watchPoints.map((point) => (
                  <li key={point} className="flex items-start gap-2.5 text-sm text-cream/75">
                    <span aria-hidden className="mt-[0.45rem] h-1.5 w-1.5 shrink-0 rounded-full bg-brass" />
                    {point}
                  </li>
                ))}
              </ul>
              <p className="mt-7 max-w-md border-l-2 border-brass/40 pl-4 text-sm leading-relaxed text-cream/55">
                {home.watchNote}
              </p>
            </div>
          </div>
        </section>

        {/* 05 — GPS: gezeichnetes Loch, echtes Bild daneben */}
        <section id="gps" className="border-t rule">
          <div className="mx-auto max-w-6xl px-5 py-16 sm:px-8 sm:py-24">
            <div className="grid items-center gap-14 lg:grid-cols-[1fr_0.95fr]">
              <div>
                <SectionHeading index={home.trackingEyebrow} title={home.trackingTitle} lead={home.trackingBody} />
                <ul className="mt-8 grid gap-x-8 gap-y-3 sm:grid-cols-2">
                  {home.trackingPoints.map((point) => (
                    <li key={point} className="flex items-start gap-2.5 text-sm text-cream/75">
                      <span aria-hidden className="mt-[0.45rem] h-1.5 w-1.5 shrink-0 rounded-full bg-brass" />
                      {point}
                    </li>
                  ))}
                </ul>
              </div>
              <div className="flex items-center justify-center gap-6 sm:gap-10">
                <HoleMap label={home.trackingTitle} />
                <PhoneShot
                  shot="09-schlagkarte"
                  alt={home.trackingShotAlt}
                  lang={lang}
                  width={232}
                  className="hidden sm:block"
                />
              </div>
            </div>
          </div>
        </section>

        {/* 06 — Zahlen: Text links, zwei versetzte Geräte rechts */}
        <section id="zahlen" className="border-t rule">
          <div className="mx-auto grid max-w-6xl items-center gap-14 px-5 py-16 sm:px-8 sm:py-24 lg:grid-cols-[0.95fr_1.05fr]">
            <SectionHeading index={home.statsEyebrow} title={home.statsTitle} lead={home.statsBody} />
            <div className="flex items-start justify-center gap-4 sm:gap-8 lg:justify-end">
              <PhoneShot shot="02-profil-handicap" alt={home.statsAlts[0]} lang={lang} width={240} className="mt-10" />
              <PhoneShot shot="06-statistiken-chart" alt={home.statsAlts[1]} lang={lang} width={240} />
            </div>
          </div>
        </section>

        {/* 07 — Spielformen: nur Schrift, kein Bild */}
        <section id="spielformen" className="border-t rule">
          <div className="mx-auto max-w-6xl px-5 py-16 sm:px-8 sm:py-24">
            <SectionHeading
              index={home.modesEyebrow}
              title={home.modesTitle}
              lead={home.modesLead}
              align="center"
            />
            <div className="mt-14 grid gap-10 sm:grid-cols-2 lg:grid-cols-3 lg:gap-12">
              {home.modeGroups.map((group) => (
                <div key={group.title}>
                  <h3 className="marginal border-b rule pb-3">{group.title}</h3>
                  <ul className="mt-4 space-y-3">
                    {group.items.map(([name, sub], index) => (
                      <li key={`${name}-${index}`} className="flex items-baseline gap-3">
                        <span className="font-mono text-[0.7rem] text-brass">
                          {String(index + 1).padStart(2, "0")}
                        </span>
                        <span className="font-display text-lg leading-tight tracking-tight">{name}</span>
                        {sub ? <span className="font-mono text-[0.7rem] text-cream/55">{sub}</span> : null}
                      </li>
                    ))}
                  </ul>
                </div>
              ))}
            </div>
            <p className="mt-12 text-center text-sm text-cream/55">{home.modesFooter}</p>
          </div>
        </section>

        {/* 08 — Preise */}
        <section id="preise" className="border-t rule">
          <div className="mx-auto grid max-w-6xl gap-14 px-5 py-16 sm:px-8 sm:py-24 lg:grid-cols-[1.05fr_0.95fr]">
            <div>
              <SectionHeading index={home.priceEyebrow} title={home.priceTitle} lead={home.priceFree} />
              <dl className="mt-9 divide-y rule border-y rule">
                {home.pricePlans.map((plan) => (
                  <div key={plan.title} className="grid gap-1 py-5 sm:grid-cols-[8rem_1fr] sm:gap-6">
                    <dt className="font-display text-lg tracking-tight text-brass-soft">{plan.title}</dt>
                    <dd className="text-sm leading-relaxed text-cream/65">{plan.body}</dd>
                  </div>
                ))}
              </dl>
              <p className="mt-6 text-sm text-cream/55">{home.priceNote}</p>
            </div>
            <div className="flex justify-center lg:justify-end">
              <PhoneShot shot="12-training" alt={home.priceShotAlt} lang={lang} width={268} />
            </div>
          </div>
        </section>

        {/* 09 — Anlagen */}
        <section id="courses" className="border-t rule">
          <div className="mx-auto max-w-6xl px-5 py-16 sm:px-8 sm:py-24">
            <div className="grid gap-14 lg:grid-cols-[0.95fr_1.05fr]">
              <SectionHeading index={home.coursesEyebrow} title={home.coursesTitle} lead={home.coursesBody} />
              <div>
                <dl className="grid gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-2">
                  {home.coursesPoints.map((point) => (
                    <div key={point.title} className="bg-black/25 p-6">
                      <dt className="font-display text-lg tracking-tight text-brass-soft">{point.title}</dt>
                      <dd className="mt-1.5 text-sm leading-relaxed text-cream/65">{point.body}</dd>
                    </div>
                  ))}
                </dl>
                <div className="mt-8 flex flex-wrap gap-3">
                  <Link href={path("submit", lang)} className="btn-brass">
                    {home.coursesCta}
                  </Link>
                  <Link href={path("directory", lang)} className="btn-ghost">
                    {home.directoryCta}
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* 10 — Schluss */}
        <section className="border-t rule">
          <div className="mx-auto max-w-6xl px-5 py-16 text-center sm:px-8 sm:py-24">
            <h2 className="mx-auto max-w-2xl font-display text-3xl leading-[1.08] tracking-[-0.03em] sm:text-4xl">
              {home.closingTitle}
            </h2>
            <p className="mt-4 text-cream/70">{home.closingBody}</p>
            <p className="mt-9">
              <a href={APP_STORE_URL} target="_blank" rel="noreferrer" className="btn-brass">
                <AppleMark />
                {home.ctaPrimary}
              </a>
            </p>
            <p className="mt-6 font-mono text-xs text-cream/60">{home.closingNote}</p>
          </div>
        </section>
      </main>

      <Footer lang={lang} />
    </>
  );
}

function AppleMark() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden className="h-4 w-4" fill="currentColor">
      <path d="M16.4 12.8c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9-.7 0-1.8-.9-3-.8-1.5 0-2.9.9-3.7 2.3-1.6 2.7-.4 6.8 1.1 9 .8 1.1 1.6 2.3 2.8 2.2 1.1 0 1.6-.7 2.9-.7 1.3 0 1.7.7 2.9.7 1.2 0 2-1.1 2.7-2.2.9-1.2 1.2-2.5 1.2-2.5s-2.4-.9-2.4-3.6zM14.2 5.9c.6-.8 1-1.8.9-2.9-.9 0-2 .6-2.6 1.4-.6.7-1.1 1.7-.9 2.8 1 0 2-.5 2.6-1.3z" />
    </svg>
  );
}
