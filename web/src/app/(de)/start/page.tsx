import type { Metadata } from "next";
import Link from "next/link";
import { Footer, Header } from "@/components/Chrome";
import { CoursePicker, type PickerCourse } from "@/components/CoursePicker";
import { listCourses } from "@/lib/courses";
import { PLAY_URL } from "@/i18n/routes";

/**
 * Die Startseite von `play.golftrack.app` – der Spielbereich.
 *
 * Erreichbar wird sie über `src/proxy.ts`, das die Wurzel dieser Domain
 * hierher umschreibt. Der gewöhnliche Weg bleibt der QR-Code am Abschlag, der
 * direkt auf `/p/<kennung>` zeigt; diese Seite fängt alle auf, bei denen das
 * nicht klappt: verkratzter Code, Adresse vom Schild abgetippt, oder jemand
 * will die Runde von zu Hause vorbereiten.
 */

export const metadata: Metadata = {
  title: "Runde starten · GolfTrack",
  description:
    "Platz auswählen und mitzählen – mit der App, ohne Installation oder direkt im Browser.",
  alternates: { canonical: `${PLAY_URL}/` },
  robots: { index: false, follow: true },
};

/** Die Liste ändert sich selten; eine Minute alt darf sie sein. */
export const revalidate = 60;

export default async function StartPage() {
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
      <Header lang="de" />
      <main className="mx-auto max-w-3xl px-5 py-16 text-center sm:px-8 sm:py-20">
        <p className="marginal">Spielen</p>
        <h1 className="mt-4 font-display text-[clamp(2rem,5.5vw,3.2rem)] leading-[1.05] tracking-[-0.02em]">
          Runde starten
        </h1>
        <p className="mx-auto mt-5 max-w-lg text-lg leading-relaxed text-cream/75">
          Normalerweise scannst du den Code am Abschlag. Geht das nicht, such
          deinen Platz hier heraus – der Rest ist derselbe.
        </p>

        {courses.length === 0 ? (
          <p className="mt-10 text-cream/60">
            Noch kein Platz freigegeben.{" "}
            <Link href="/platz-melden" className="text-brass underline underline-offset-4">
              Trag deinen ein.
            </Link>
          </p>
        ) : (
          <CoursePicker courses={courses} />
        )}

        <p className="mx-auto mt-10 max-w-lg text-sm leading-relaxed text-cream/45">
          Mit installierter App öffnet sich die Runde dort. Auf dem iPhone ohne
          App genügt der App Clip, ganz ohne Installation. Sonst zählst du im
          Browser mit.
        </p>

        <p className="mt-10 text-sm">
          <Link href="/plaetze" className="text-brass underline underline-offset-4">
            Alle Plätze im Verzeichnis
          </Link>
        </p>
      </main>
      <Footer lang="de" />
    </>
  );
}
