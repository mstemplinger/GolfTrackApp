import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Footer, Header } from "@/components/Chrome";
import { CourseHintList } from "@/components/CourseHintList";
import { getCourse } from "@/lib/courses";
import { PLAY_URL, SITE_URL } from "@/i18n/routes";

/**
 * Der Katalogeintrag einer Minigolfanlage.
 *
 * Zum Spielen geht es von hier weiter auf `play.golftrack.app/p/<kennung>`;
 * dort entscheidet sich App, App Clip oder Browser. Bewusst **kein**
 * `apple-itunes-app`-Hinweis auf dieser Seite: Wer im Verzeichnis stöbert,
 * soll nicht bei jedem Platz eine App-Clip-Karte vorgesetzt bekommen.
 */
export async function generateMetadata({
  params,
}: PageProps<"/minigolf/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const course = await getCourse(slug);
  // Dieselbe Bedingung wie in der Seite: Ungeprüfte Einreichungen dürfen
  // ihren Namen und Begrüßungstext nicht über Titel und Linkvorschau zeigen.
  if (!course || course.status !== "approved") {
    return { title: "Anlage nicht gefunden · GolfTrack", robots: { index: false } };
  }

  return {
    title: `${course.name} · Minigolf mit GolfTrack`,
    description:
      course.welcome ||
      `Zähle deine Runde auf der Anlage ${course.name} mit GolfTrack mit – Bahn für Bahn, für die ganze Gruppe.`,
    alternates: { canonical: `${SITE_URL}/minigolf/${course.slug}` },
    robots: { index: true, follow: true },
  };
}

export default async function MinigolfLandingPage({ params }: PageProps<"/minigolf/[slug]">) {
  const { slug } = await params;
  const course = await getCourse(slug);
  if (!course || course.status !== "approved") notFound();


  return (
    <>
      <Header lang="de" />
      <main className="mx-auto max-w-3xl px-5 pt-12 pb-20 text-center sm:px-8 sm:pt-16">
        <p className="marginal">Minigolf · {course.holes} Bahnen</p>
        <h1 className="mt-4 font-display text-[clamp(2.2rem,6vw,3.6rem)] leading-[1.03] tracking-[-0.02em]">
          {course.name}
        </h1>
        {course.location ? <p className="mt-3 text-cream/55">{course.location}</p> : null}

        {/*
          Wer hier landet, will spielen – der Knopf steht deshalb ganz oben
          und groß, vor allem anderen. Er führt auf die Spielseite, nicht
          direkt in die App: Erst auf play.golftrack.app entscheidet sich
          App, App Clip oder Browser, und zwar dann, wenn jemand wirklich
          spielen will. Wer nur im Verzeichnis stöbert, bekommt so keine
          App-Clip-Karte vorgesetzt.
        */}
        <div className="mx-auto mt-9 max-w-sm">
          <a
            href={`${PLAY_URL}/p/${course.slug}`}
            className="btn-brass w-full !min-h-16 !rounded-2xl !text-xl shadow-[0_10px_40px_-8px_rgba(201,160,53,0.55)]"
          >
            Runde starten ›
          </a>
          <p className="mt-3 text-sm text-cream/50">
            Kostenlos · ohne Anmeldung · auch ohne Installation
          </p>
          <Link href="/laden" className="btn-ghost mt-5 w-full">
            GolfTrack laden
          </Link>
        </div>

        <p className="mx-auto mt-12 max-w-lg text-lg leading-relaxed text-cream/75">
          {course.welcome || "Schön, dass du da bist! Ab jetzt zählen wir für dich mit – Bahn für Bahn."}
        </p>

        <CourseHintList hints={course.facilityHints} />

        {course.facilityNotes ? (
          <p className="mx-auto mt-10 max-w-lg rounded-sm border rule bg-moss/30 p-5 text-sm leading-relaxed text-cream/65">
            {course.facilityNotes}
          </p>
        ) : null}

        <p className="mt-12 text-sm">
          <Link href="/plaetze" className="text-brass underline underline-offset-4">
            Alle Anlagen
          </Link>
        </p>
      </main>
      <Footer lang="de" />
    </>
  );
}
