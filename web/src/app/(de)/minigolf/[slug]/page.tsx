import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Footer, Header } from "@/components/Chrome";
import { getCourse } from "@/lib/courses";
import { APP_STORE_URL, SITE_URL } from "@/i18n/routes";

/**
 * Ziel der QR-Codes an den Anlagen. Ist die App installiert, fängt der
 * Universal Link sie ab und die Runde startet direkt; ohne App landet der
 * Gast hier und bekommt den Weg zum App Store.
 */
export async function generateMetadata({
  params,
}: PageProps<"/minigolf/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const course = await getCourse(slug);
  if (!course) return { title: "Anlage nicht gefunden · GolfTrack" };

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

  const deepLink = `golftrack://minigolf?platz=${encodeURIComponent(course.slug)}`;

  return (
    <>
      <Header lang="de" />
      <main className="mx-auto max-w-3xl px-5 py-20 text-center sm:px-8">
        <p className="marginal">Minigolf</p>
        <h1 className="mt-4 font-display text-[clamp(2.2rem,6vw,3.6rem)] leading-[1.03] tracking-[-0.02em]">
          {course.name}
        </h1>
        {course.location ? <p className="mt-3 text-cream/55">{course.location}</p> : null}

        <p className="mx-auto mt-8 max-w-lg text-lg leading-relaxed text-cream/75">
          {course.welcome || "Schön, dass du da bist! Ab jetzt zählen wir für dich mit – Bahn für Bahn."}
        </p>

        <dl className="mx-auto mt-10 grid max-w-md gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-2">
          <div className="bg-night/85 p-5">
            <dt className="marginal">Bahnen</dt>
            <dd className="mt-1.5 font-mono text-3xl text-brass">{course.holes}</dd>
          </div>
          <div className="bg-night/85 p-5">
            <dt className="marginal">Kennung</dt>
            <dd className="mt-1.5 break-all font-mono text-sm text-cream/70">{course.slug}</dd>
          </div>
        </dl>

        <div className="mt-10 flex flex-wrap justify-center gap-3">
          <a href={deepLink} className="btn-brass">
            Runde in der App starten
          </a>
          <a href={APP_STORE_URL} target="_blank" rel="noreferrer" className="btn-ghost">
            GolfTrack laden
          </a>
        </div>
        <p className="mt-4 text-sm text-cream/45">
          Ohne installierte App führt der erste Knopf ins Leere – dann zuerst GolfTrack laden.
        </p>

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
