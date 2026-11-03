import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Footer, Header } from "@/components/Chrome";
import { CourseHintList } from "@/components/CourseHintList";
import { PlayLangPicker } from "@/components/PlayLangPicker";
import { WebScorecard } from "@/components/WebScorecard";
import { getCourse } from "@/lib/courses";
import { PLAY_URL, SITE_URL } from "@/i18n/routes";
import { playCopy, siteLang } from "@/i18n/play";
import { playLang } from "@/lib/playLang";

/**
 * Das Ziel des QR-Codes am Abschlag: `play.golftrack.app/p/<kennung>`.
 *
 * Eine Adresse, drei Wege – wer welchen nimmt, entscheidet das Gerät, nicht
 * diese Seite:
 *
 * 1. **GolfTrack installiert** → iOS fängt den Universal Link ab, die App
 *    öffnet die Runde. Diese Seite wird nie geladen.
 * 2. **iPhone ohne App** → Safari bietet über `apple-itunes-app` die
 *    App-Clip-Karte an, der Clip startet ohne Installation.
 * 3. **Alles andere** – Android, Rechner, oder Karte weggewischt → die
 *    Zählkarte hier im Browser.
 *
 * Die Platzart steht bewusst nicht in der Adresse; sie kommt aus dem
 * Verzeichnis. Ein Schild am Abschlag soll nicht davon abhängen, ob jemand
 * „golf" oder „minigolf" richtig abschreibt.
 *
 * Die Seite spricht sieben Sprachen (`i18n/play.ts`) – oben steht die
 * Sprachleiste. Begrüßung und Hinweise schreibt der Betreiber selbst; die
 * bleiben in seiner Sprache.
 */

const APP_STORE_ID = "6767996957";
const APP_CLIP_BUNDLE_ID = "com.TobiasAufschlaeger.GolfTrackandwatch.Clip";

export async function generateMetadata({
  params,
  searchParams,
}: PageProps<"/p/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const copy = playCopy(await playLang((await searchParams).lang));
  const course = await getCourse(slug);
  // Dieselbe Bedingung wie in der Seite: Ungeprüfte Einreichungen dürfen
  // ihren Namen und Begrüßungstext nicht über Titel und Linkvorschau zeigen.
  if (!course || course.status !== "approved") {
    return { title: copy.notFound, robots: { index: false } };
  }

  return {
    title: copy.playMetaTitle(course.name),
    description: course.welcome || copy.playMetaDescription(course.name),
    alternates: { canonical: `${PLAY_URL}/p/${course.slug}` },
    // Die Seite ist das Ziel eines Codes vor Ort, kein Suchergebnis. Der
    // ausführliche Eintrag steht unter /golf/<slug> bzw. /minigolf/<slug>.
    robots: { index: false, follow: true },
    other: {
      // `app-clip-display=card` ist der Unterschied zwischen dem schmalen
      // Standardbanner („Öffnen" für die App) und der großen App-Clip-Karte.
      // Ohne den Zusatz sieht jemand ohne App den Clip gar nicht angeboten.
      "apple-itunes-app": `app-id=${APP_STORE_ID}, app-clip-bundle-id=${APP_CLIP_BUNDLE_ID}, app-clip-display=card`,
    },
  };
}

export default async function PlayPage({ params, searchParams }: PageProps<"/p/[slug]">) {
  const { slug } = await params;
  const lang = await playLang((await searchParams).lang);
  const copy = playCopy(lang);
  const site = siteLang(lang);
  const course = await getCourse(slug);
  if (!course || course.status !== "approved") notFound();

  const isGolf = course.kind === "golf";
  const deepLink = `golftrack://${course.kind}?platz=${encodeURIComponent(course.slug)}`;
  const detailPath = `/${course.kind}/${course.slug}`;
  const pars = course.holeData
    .map((hole) => hole.par)
    .filter((par): par is number => par !== null);

  return (
    <>
      <Header lang={site} langSwitch={false} />
      <main lang={lang} className="mx-auto max-w-3xl px-5 py-16 text-center sm:px-8 sm:py-20">
        <PlayLangPicker lang={lang} label={copy.langLabel} />
        <p className="marginal mt-8">{isGolf ? copy.kindGolf : copy.kindMinigolf}</p>
        <h1 className="mt-4 font-display text-[clamp(2rem,5.5vw,3.2rem)] leading-[1.05] tracking-[-0.02em]">
          {course.name}
        </h1>
        {course.location ? <p className="mt-3 text-cream/55">{course.location}</p> : null}

        <p className="mx-auto mt-7 max-w-lg text-lg leading-relaxed text-cream/75">
          {course.welcome || (isGolf ? copy.welcomeGolf : copy.welcomeMinigolf)}
        </p>

        {/*
          Der Knopf hilft nur, wenn die App schon installiert ist. Sie fängt
          diese Adresse dann ohnehin selbst ab – dieser Weg bleibt für den
          Fall, dass jemand den Link weitergeschickt hat.
        */}
        {/*
          Der große Knopf ist der Weg, den die meisten hier brauchen: Wer die
          App hätte, wäre gar nicht auf dieser Seite gelandet. Er springt nur
          zur Zählkarte weiter unten – deshalb ein Anker, kein neuer Schritt.
        */}
        <a
          href="#zaehlkarte"
          className="btn-brass mx-auto mt-9 flex w-full max-w-lg flex-col gap-0.5 rounded-2xl py-4 text-lg shadow-[0_10px_30px_-10px_var(--color-brass)]"
        >
          <span>{copy.playNoApp} ↓</span>
          <span className="text-xs font-medium opacity-70">{copy.playNoAppHint}</span>
        </a>

        <div className="mt-4 flex flex-wrap justify-center gap-3">
          <a href={deepLink} className="btn-ghost">
            {copy.openInApp}
          </a>
          <a href={`${SITE_URL}/laden`} className="btn-ghost">
            {copy.getApp}
          </a>
        </div>

        <CourseHintList hints={course.facilityHints} />

        <div id="zaehlkarte" className="scroll-mt-6">
          <WebScorecard
            slug={course.slug}
            kind={course.kind}
            holes={course.holes}
            pars={pars}
            lang={lang}
          />
        </div>

        <p className="mx-auto mt-8 max-w-lg text-sm leading-relaxed text-cream/45">
          {copy.playFootnote}
        </p>

        <p className="mt-10 text-sm">
          <Link href={detailPath} className="text-brass underline underline-offset-4">
            {copy.moreAbout(course.name)}
          </Link>
        </p>
      </main>
      <Footer lang={site} />
    </>
  );
}
