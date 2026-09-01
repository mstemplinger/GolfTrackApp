import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Footer, Header } from "@/components/Chrome";
import { getCourse } from "@/lib/courses";
import { APP_STORE_URL, SITE_URL } from "@/i18n/routes";

/**
 * Ziel der QR-Codes an den Golfplätzen – das Gegenstück zu `/minigolf/<slug>`.
 * Ist die App installiert, fängt der Universal Link sie ab; ohne App startet
 * der App Clip mit der schlanken Zählkarte; ganz ohne beides landet der Gast
 * hier.
 */
export async function generateMetadata({
  params,
}: PageProps<"/golf/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const course = await getCourse(slug);
  if (!course) return { title: "Platz nicht gefunden · GolfTrack" };

  return {
    title: `${course.name} · Golf mit GolfTrack`,
    description:
      course.welcome ||
      `Zähle deine Runde auf ${course.name} mit GolfTrack mit – Loch für Loch, gegen Par.`,
    alternates: { canonical: `${SITE_URL}/golf/${course.slug}` },
    robots: { index: true, follow: true },
    other: {
      // Landet jemand doch im Browser, bietet Safari oben den App Clip an.
      "apple-itunes-app": `app-id=${APP_STORE_ID}, app-clip-bundle-id=${APP_CLIP_BUNDLE_ID}`,
    },
  };
}

const APP_STORE_ID = "6767996957";
const APP_CLIP_BUNDLE_ID = "com.TobiasAufschlaeger.GolfTrackandwatch.Clip";

export default async function GolfLandingPage({ params }: PageProps<"/golf/[slug]">) {
  const { slug } = await params;
  const course = await getCourse(slug);
  if (!course || course.status !== "approved" || course.kind !== "golf") notFound();

  const deepLink = `golftrack://golf?platz=${encodeURIComponent(course.slug)}`;
  const pars = course.holeData
    .map((hole) => hole.par)
    .filter((par): par is number => par !== null);
  const totalPar = pars.length === course.holes ? pars.reduce((sum, p) => sum + p, 0) : null;

  return (
    <>
      <Header lang="de" />
      <main className="mx-auto max-w-3xl px-5 py-20 text-center sm:px-8">
        <p className="marginal">Golfplatz</p>
        <h1 className="mt-4 font-display text-[clamp(2.2rem,6vw,3.6rem)] leading-[1.03] tracking-[-0.02em]">
          {course.name}
        </h1>
        {course.location ? <p className="mt-3 text-cream/55">{course.location}</p> : null}

        <p className="mx-auto mt-8 max-w-lg text-lg leading-relaxed text-cream/75">
          {course.welcome || "Schön, dass du da bist! Ab jetzt zählen wir für dich mit – Loch für Loch."}
        </p>

        <dl className="mx-auto mt-10 grid max-w-md gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-2">
          <div className="bg-night/85 p-5">
            <dt className="marginal">Löcher</dt>
            <dd className="mt-1.5 font-mono text-3xl text-brass">{course.holes}</dd>
          </div>
          <div className="bg-night/85 p-5">
            <dt className="marginal">Par</dt>
            <dd className="mt-1.5 font-mono text-3xl text-cream/80">{totalPar ?? "–"}</dd>
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
            Alle Plätze
          </Link>
        </p>
      </main>
      <Footer lang="de" />
    </>
  );
}
