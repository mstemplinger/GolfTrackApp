import Link from "next/link";
import { Footer, Header, PageHeader } from "@/components/Chrome";
import { t } from "@/i18n/content";
import { isPlaceholder, site } from "@/lib/site";
import { APP_STORE_URL, path, type Lang } from "@/i18n/routes";

/**
 * Hilfeseite. Die häufigen Fragen sind aufklappbar – am Handy ist eine Liste
 * aus zwölf Absätzen sonst eine lange Wand, durch die niemand scrollt.
 * `details` braucht dafür kein Skript.
 */
export function Support({ lang }: { lang: Lang }) {
  const copy = t(lang).support;
  const nav = t(lang).nav;

  return (
    <>
      <Header lang={lang} current="support" />
      <PageHeader index="12 — Hilfe" title={copy.title} lead={copy.lead} />

      <main className="mx-auto max-w-6xl px-5 py-14 sm:px-8 sm:py-16">
        <div className="grid gap-12 lg:grid-cols-[1fr_20rem] lg:gap-16">
          <section>
            <h2 className="marginal">{copy.faqTitle}</h2>
            <div className="mt-4 divide-y rule border-y rule">
              {copy.faq.map((entry) => (
                <details key={entry.q} className="group">
                  <summary className="tap w-full cursor-pointer items-start justify-between gap-4 py-4 text-left">
                    <span className="font-display text-lg leading-snug tracking-tight sm:text-xl">{entry.q}</span>
                    <span
                      aria-hidden
                      className="mt-1 shrink-0 text-brass transition-transform group-open:rotate-45"
                    >
                      <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.6">
                        <path d="M12 5v14M5 12h14" strokeLinecap="round" />
                      </svg>
                    </span>
                  </summary>
                  <p className="max-w-2xl pb-5 leading-relaxed text-cream/70">{entry.a}</p>
                </details>
              ))}
            </div>
          </section>

          <aside className="lg:pt-1">
            <h2 className="marginal">{copy.contactTitle}</h2>
            <ul className="mt-4 divide-y rule border-y rule">
              <li>
                {isPlaceholder(site.email) ? (
                  <span className="tap text-cream/50">{site.email}</span>
                ) : (
                  <a
                    href={`mailto:${site.email}`}
                    className="tap w-full text-brass underline underline-offset-4 hover:text-brass-soft"
                  >
                    {site.email}
                  </a>
                )}
              </li>
              {site.phone ? (
                <li>
                  <a href={`tel:${site.phone.replace(/[^+\d]/g, "")}`} className="tap w-full text-cream/80">
                    {site.phone}
                  </a>
                </li>
              ) : null}
              <li>
                <a
                  href={APP_STORE_URL}
                  target="_blank"
                  rel="noreferrer"
                  className="tap w-full text-cream/80 hover:text-brass"
                >
                  {nav.appStore}
                </a>
              </li>
            </ul>

            <Link href={path("submit", lang)} className="btn-brass mt-8 w-full">
              {nav.submit}
            </Link>
          </aside>
        </div>
      </main>

      <Footer lang={lang} />
    </>
  );
}
