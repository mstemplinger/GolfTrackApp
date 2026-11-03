import type { Metadata } from "next";
import Link from "next/link";
import { Footer, Header } from "@/components/Chrome";
import { CoursePicker, type PickerCourse } from "@/components/CoursePicker";
import { listCourses } from "@/lib/courses";
import { PlayLangPicker } from "@/components/PlayLangPicker";
import { PLAY_URL, path } from "@/i18n/routes";
import { playCopy, siteLang } from "@/i18n/play";
import { playLang } from "@/lib/playLang";

/**
 * Die Startseite von `play.golftrack.app` – der Spielbereich.
 *
 * Erreichbar wird sie über `src/proxy.ts`, das die Wurzel dieser Domain
 * hierher umschreibt. Der gewöhnliche Weg bleibt der QR-Code am Abschlag, der
 * direkt auf `/p/<kennung>` zeigt; diese Seite fängt alle auf, bei denen das
 * nicht klappt: verkratzter Code, Adresse vom Schild abgetippt, oder jemand
 * will die Runde von zu Hause vorbereiten.
 *
 * In sieben Sprachen (`i18n/play.ts`). Weil die Sprache vom Cookie und vom
 * Browser abhängt, wird die Seite je Anfrage gebaut und nicht mehr zwischen-
 * gespeichert.
 */

export async function generateMetadata({ searchParams }: PageProps<"/start">): Promise<Metadata> {
  const copy = playCopy(await playLang((await searchParams).lang));
  return {
    title: copy.startMetaTitle,
    description: copy.startMetaDescription,
    alternates: { canonical: `${PLAY_URL}/` },
    robots: { index: false, follow: true },
  };
}

export default async function StartPage({ searchParams }: PageProps<"/start">) {
  const lang = await playLang((await searchParams).lang);
  const copy = playCopy(lang);
  const site = siteLang(lang);
  const records = await listCourses({ status: "approved", limit: 1000 });
  const courses: PickerCourse[] = records.map((course) => ({
    slug: course.slug,
    name: course.name,
    location: course.location,
    kind: course.kind,
    holes: course.holes,
  }));

  return (
    <>
      <Header lang={site} langSwitch={false} />
      <main lang={lang} className="mx-auto max-w-3xl px-5 py-16 text-center sm:px-8 sm:py-20">
        <PlayLangPicker lang={lang} label={copy.langLabel} />
        <p className="marginal mt-8">{copy.startMarginal}</p>
        <h1 className="mt-4 font-display text-[clamp(2rem,5.5vw,3.2rem)] leading-[1.05] tracking-[-0.02em]">
          {copy.startTitle}
        </h1>
        <p className="mx-auto mt-5 max-w-lg text-lg leading-relaxed text-cream/75">{copy.startIntro}</p>

        {courses.length === 0 ? (
          <p className="mt-10 text-cream/60">
            {copy.startEmpty}{" "}
            <Link href={path("submit", site)} className="text-brass underline underline-offset-4">
              {copy.startEmptyLink}
            </Link>
          </p>
        ) : (
          <CoursePicker courses={courses} lang={lang} />
        )}

        <p className="mx-auto mt-10 max-w-lg text-sm leading-relaxed text-cream/45">{copy.startFootnote}</p>

        <p className="mt-10 text-sm">
          <Link href={path("directory", site)} className="text-brass underline underline-offset-4">
            {copy.startDirectory}
          </Link>
        </p>
      </main>
      <Footer lang={site} />
    </>
  );
}
