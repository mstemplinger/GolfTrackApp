import Link from "next/link";
import { APP_STORE_URL, alternatePath, path, type Lang, type RouteKey } from "@/i18n/routes";
import { t } from "@/i18n/content";

/** Wortmarke: Fahne im Loch, aus reinem Markup. */
export function Wordmark({ lang, className = "" }: { lang: Lang; className?: string }) {
  return (
    <Link href={path("home", lang)} className={`tap group gap-2.5 ${className}`}>
      <span
        aria-hidden
        className="relative grid h-8 w-8 shrink-0 place-items-center rounded-full border border-brass/50 bg-moss-2/70"
      >
        <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none">
          <path d="M8 20V4l9 3.2L8 10.4" stroke="var(--color-brass)" strokeWidth="1.6" strokeLinejoin="round" />
          <ellipse cx="8" cy="20.4" rx="4.6" ry="1.5" fill="var(--color-fairway)" opacity="0.55" />
        </svg>
      </span>
      <span className="font-display text-lg font-semibold tracking-tight">
        Golf<span className="text-brass">Track</span>
      </span>
    </Link>
  );
}

const NAV: { key: RouteKey; label: (l: Lang) => string }[] = [
  { key: "directory", label: (l) => t(l).nav.directory },
  { key: "submit", label: (l) => t(l).nav.submit },
  { key: "support", label: (l) => t(l).nav.support },
];

/**
 * Kopfleiste. Die Höhe bleibt über alle Breiten gleich; ab 48rem stehen die
 * Verweise nebeneinander, darunter liegen sie hinter einem Menüknopf. Das
 * Menü ist ein `details`-Element und braucht deshalb kein Skript.
 */
export function Header({ lang, current }: { lang: Lang; current?: RouteKey }) {
  const copy = t(lang);
  const langHref = current ? alternatePath(current, lang) : alternatePath("home", lang);

  return (
    <header className="sticky top-0 z-50 border-b rule bg-night/85 backdrop-blur-md">
      <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-5 py-2.5 sm:px-8">
        <Wordmark lang={lang} />

        <nav aria-label={copy.nav.menu} className="hidden items-center gap-7 text-sm text-cream/75 md:flex">
          {NAV.map((item) => (
            <Link
              key={item.key}
              href={path(item.key, lang)}
              className={`tap transition-colors hover:text-brass ${current === item.key ? "text-brass" : ""}`}
            >
              {item.label(lang)}
            </Link>
          ))}
        </nav>

        <div className="flex items-center gap-1 sm:gap-3">
          <Link
            href={langHref}
            hrefLang={lang === "de" ? "en" : "de"}
            className="tap hidden px-2 text-xs uppercase tracking-[0.16em] text-cream/60 transition-colors hover:text-brass md:inline-flex"
          >
            {copy.nav.langSwitch}
          </Link>

          <a
            href={APP_STORE_URL}
            className="btn-brass min-h-11 !px-4 !py-2 text-sm"
            target="_blank"
            rel="noreferrer"
          >
            <span className="sm:hidden">App</span>
            <span className="hidden sm:inline">{copy.nav.appStore}</span>
          </a>

          <details className="relative md:hidden">
            <summary
              className="tap cursor-pointer list-none px-2 text-cream/75 transition-colors hover:text-brass"
              aria-label={copy.nav.menu}
            >
              <svg viewBox="0 0 24 24" aria-hidden className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.7">
                <path d="M4 7h16M4 12h16M4 17h16" strokeLinecap="round" />
              </svg>
            </summary>
            <div className="absolute right-0 top-[calc(100%+0.7rem)] z-50 w-56 rounded-sm border rule bg-night/97 p-2 shadow-[0_24px_60px_-20px_rgba(0,0,0,0.9)] backdrop-blur-md">
              <ul className="divide-y rule">
                {NAV.map((item) => (
                  <li key={item.key}>
                    <Link
                      href={path(item.key, lang)}
                      className={`tap w-full px-3 text-sm ${current === item.key ? "text-brass" : "text-cream/80"}`}
                    >
                      {item.label(lang)}
                    </Link>
                  </li>
                ))}
                <li>
                  <Link href={path("api", lang)} className="tap w-full px-3 text-sm text-cream/80">
                    {copy.nav.api}
                  </Link>
                </li>
                <li>
                  <Link
                    href={langHref}
                    hrefLang={lang === "de" ? "en" : "de"}
                    className="tap w-full px-3 text-xs uppercase tracking-[0.16em] text-cream/60"
                  >
                    {copy.nav.langSwitch}
                  </Link>
                </li>
              </ul>
            </div>
          </details>
        </div>
      </div>
    </header>
  );
}

export function Footer({ lang }: { lang: Lang }) {
  const copy = t(lang);
  const year = new Date().getFullYear();
  return (
    <footer className="mt-24 border-t rule bg-moss/40">
      <div className="mx-auto grid max-w-6xl gap-8 px-5 py-14 sm:px-8 md:grid-cols-[1.4fr_1fr_1fr_1fr] md:gap-10">
        <div>
          <Wordmark lang={lang} />
          <p className="mt-4 max-w-xs text-sm leading-relaxed text-cream/60">{copy.footer.tagline}</p>
          <p className="mt-4 text-xs text-cream/60">{copy.footer.madeIn}</p>
        </div>
        <FooterColumn title={copy.footer.product}>
          <FooterLink href={APP_STORE_URL} external>
            {copy.nav.appStore}
          </FooterLink>
          <FooterLink href={path("directory", lang)}>{copy.nav.directory}</FooterLink>
          <FooterLink href={path("support", lang)}>{copy.nav.support}</FooterLink>
        </FooterColumn>
        <FooterColumn title={copy.footer.forCourses}>
          <FooterLink href={path("submit", lang)}>{copy.nav.submit}</FooterLink>
          <FooterLink href={path("api", lang)}>{copy.nav.api}</FooterLink>
        </FooterColumn>
        <FooterColumn title={copy.footer.legal}>
          <FooterLink href={path("imprint", lang)}>{copy.legal.imprintTitle}</FooterLink>
          <FooterLink href={path("privacy", lang)}>{copy.legal.privacyTitle}</FooterLink>
        </FooterColumn>
      </div>
      <div className="border-t rule">
        <p className="mx-auto max-w-6xl px-5 py-5 text-xs text-cream/60 sm:px-8">
          © {year} Tobias Aufschläger · GolfTrack
        </p>
      </div>
    </footer>
  );
}

function FooterColumn({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h2 className="marginal mb-1">{title}</h2>
      <ul className="divide-y rule border-t rule md:divide-y-0 md:border-0">{children}</ul>
    </div>
  );
}

function FooterLink({
  href,
  children,
  external,
}: {
  href: string;
  children: React.ReactNode;
  external?: boolean;
}) {
  const style = "tap text-sm text-cream/70 transition-colors hover:text-brass";
  return (
    <li>
      {external ? (
        <a href={href} target="_blank" rel="noreferrer" className={style}>
          {children}
        </a>
      ) : (
        <Link href={href} className={style}>
          {children}
        </Link>
      )}
    </li>
  );
}

/**
 * Kopf einer Unterseite.
 *
 * Alle Seiten benutzen dieselbe Hülle (`max-w-6xl`), damit die linke Kante
 * über die ganze Website an derselben Stelle liegt. Die Zeilenlänge wird an
 * den Kindern begrenzt, nicht an der Hülle.
 */
export function PageHeader({
  index,
  title,
  lead,
}: {
  index: string;
  title: string;
  lead?: string;
}) {
  return (
    <div className="border-b rule">
      <div className="mx-auto max-w-6xl px-5 py-14 sm:px-8 sm:py-16">
        <p className="marginal">{index}</p>
        <h1 className="mt-3 max-w-3xl font-display text-[clamp(2.1rem,5vw,3.4rem)] leading-[1.02] tracking-[-0.02em]">
          {title}
        </h1>
        {lead ? <p className="mt-4 max-w-2xl leading-relaxed text-cream/70">{lead}</p> : null}
      </div>
    </div>
  );
}

/**
 * Abschnittsüberschrift mit Nummer am Rand, wie in einem Heft.
 * `align` bestimmt, ob der Block links steht oder mittig – damit nicht jeder
 * Abschnitt gleich aussieht.
 */
export function SectionHeading({
  index,
  title,
  lead,
  align = "left",
  className = "",
}: {
  index: string;
  title: string;
  lead?: string;
  align?: "left" | "center";
  className?: string;
}) {
  const centred = align === "center";
  return (
    <div className={`${centred ? "mx-auto max-w-2xl text-center" : "max-w-2xl"} ${className}`}>
      <p className="marginal">{index}</p>
      <h2 className="mt-3 font-display text-3xl leading-[1.1] tracking-tight sm:text-4xl">{title}</h2>
      {lead ? <p className="mt-4 leading-relaxed text-cream/70">{lead}</p> : null}
    </div>
  );
}
