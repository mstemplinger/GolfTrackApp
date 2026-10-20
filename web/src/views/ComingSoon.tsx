import Image from "next/image";
import Link from "next/link";
import { Countdown } from "@/components/Countdown";
import { AndroidCta } from "@/components/AndroidCta";
import { PreviewForm } from "@/components/PreviewForm";
import { PuttScene } from "@/components/PuttScene";
import { APP_STORE_URL, type Lang } from "@/i18n/routes";
import { LAUNCH_AT } from "@/lib/launch";

/**
 * Angaben für Zähler und Kurzimpressum – bewusst dieselben wie auf
 * toob360.com, damit beide Seiten bis zum Start gleich auftreten.
 */
const OPERATOR = {
  name: "Toob360 / Tobias Aufschläger",
  street: "Hadamarstraße 22E",
  city: "93051 Regensburg",
  country: "Deutschland",
  phone: "+49 151 70084818",
  phoneHref: "tel:+4915170084818",
  email: "contact@golftrack.app",
};

const COPY = {
  de: {
    tag: "Bald verfügbar",
    title: "Die neue Website kommt.",
    text: "Scorekarte, Platzverzeichnis und QR-Codes für Minigolfanlagen – alles an einem Ort. Bis zur Freischaltung erreichst du uns per Telefon und E-Mail, und die App gibt es schon jetzt im App Store – und als APK für Android.",
    scene: "Ein Golfball mit Augen rollt übers Grün ins Loch.",
    when: "Freischaltung am Sonntag, 1. November 2026 um 00:00 Uhr",
    app: "Zur App im App Store",
    mail: "E-Mail schreiben",
    call: "Anrufen",
    imprint: "Impressum",
    privacy: "Datenschutz",
    support: "Support",
    other: { href: "/en", label: "EN", name: "English version" },
  },
  en: {
    tag: "Coming soon",
    title: "The new website is on its way.",
    text: "Scorecard, course directory and QR codes for mini golf venues – all in one place. Until launch you can reach us by phone and e-mail, and the app is already on the App Store – and as an APK for Android.",
    scene: "A golf ball with eyes rolls across the green into the hole.",
    when: "Launching Sunday, 1 November 2026 at 00:00 (CET)",
    app: "Get the app on the App Store",
    mail: "Send an e-mail",
    call: "Call us",
    imprint: "Legal notice",
    privacy: "Privacy",
    support: "Support",
    other: { href: "/", label: "DE", name: "Deutsche Fassung" },
  },
} as const;

export function ComingSoon({ lang, now }: { lang: Lang; now: number }) {
  const c = COPY[lang];
  return (
    <div className="flex min-h-dvh flex-col px-4 pb-[env(safe-area-inset-bottom)] pt-[env(safe-area-inset-top)]">
      <header className="mx-auto flex w-full max-w-5xl items-center justify-between py-4">
        <span className="flex items-center gap-2.5">
          <Image src="/logo.png" alt="" aria-hidden width={192} height={192} sizes="36px" className="h-9 w-9 rounded-[0.6rem]" priority />
          <span className="font-display text-lg font-extrabold tracking-[-0.03em]">
            Golf<span className="text-brass">Track</span>
          </span>
        </span>
        <Link
          href={c.other.href}
          hrefLang={lang === "de" ? "en" : "de"}
          aria-label={c.other.name}
          className="tap justify-center rounded-full border border-cream/20 px-4 text-sm font-semibold text-cream/80 hover:border-brass hover:text-brass"
        >
          {c.other.label}
        </Link>
      </header>

      <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col items-center justify-center gap-7 py-8 text-center">
        <PuttScene label={c.scene} />
        <p className="text-xs font-semibold uppercase tracking-[0.22em] text-brass">{c.tag}</p>
        <h1 className="text-4xl leading-[1.05] sm:text-6xl">{c.title}</h1>
        <p className="max-w-xl text-base leading-relaxed text-muted sm:text-lg">{c.text}</p>
        <Countdown target={LAUNCH_AT} serverNow={now} lang={lang} />
        <p className="text-sm text-muted">{c.when}</p>
        <div className="flex w-full flex-col items-stretch justify-center gap-3 sm:w-auto sm:flex-row">
          <a
            href={APP_STORE_URL}
            className="tap justify-center rounded-full bg-brass px-6 font-semibold text-night transition hover:bg-brass-soft"
          >
            {c.app}
          </a>
          <a
            href={OPERATOR.phoneHref}
            className="tap justify-center rounded-full border border-cream/25 px-6 font-semibold text-cream hover:border-brass hover:text-brass"
          >
            {c.call}
          </a>
          <a
            href={`mailto:${OPERATOR.email}`}
            className="tap justify-center rounded-full border border-cream/25 px-6 font-semibold text-cream hover:border-brass hover:text-brass"
          >
            {c.mail}
          </a>
        </div>
        <AndroidCta lang={lang} align="center" />
        <PreviewForm lang={lang} />
      </main>

      <footer className="mx-auto w-full max-w-5xl border-t border-cream/10 py-5 text-sm text-muted">
        <ul className="flex flex-wrap justify-center gap-x-6">
          <li><Link className="tap hover:text-cream" href="/bald/impressum">{c.imprint}</Link></li>
          <li><Link className="tap hover:text-cream" href={lang === "de" ? "/datenschutz" : "/en/privacy"}>{c.privacy}</Link></li>
          <li><Link className="tap hover:text-cream" href={lang === "de" ? "/support" : "/en/support"}>{c.support}</Link></li>
        </ul>
        <p className="mt-1 text-center text-xs text-muted/70">© 2026 GolfTrack · 93051 Regensburg</p>
      </footer>
    </div>
  );
}

/** Impressum mit dem, was § 5 DDG verlangt – und nicht mehr. */
export function ShortImprint() {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center px-4 py-12">
      <div className="paper w-full max-w-md rounded-md p-7 sm:p-9">
        <h1 className="text-3xl text-ink">Impressum</h1>
        <p className="mt-1 text-sm text-ink/60">Angaben gemäß § 5 DDG</p>
        <address className="mt-6 not-italic leading-relaxed text-ink">
          {OPERATOR.name}
          <br />
          {OPERATOR.street}
          <br />
          {OPERATOR.city}
          <br />
          {OPERATOR.country}
        </address>
        <h2 className="mt-6 text-lg text-ink">Kontakt</h2>
        <p className="mt-1 leading-relaxed text-ink">
          Telefon:{" "}
          <a className="font-semibold underline decoration-brass underline-offset-4" href={OPERATOR.phoneHref}>
            {OPERATOR.phone}
          </a>
          <br />
          E-Mail:{" "}
          <a className="font-semibold underline decoration-brass underline-offset-4" href={`mailto:${OPERATOR.email}`}>
            {OPERATOR.email}
          </a>
        </p>
      </div>
      <Link href="/bald" className="tap mt-6 text-sm text-muted hover:text-cream">
        ← Zurück
      </Link>
    </div>
  );
}
