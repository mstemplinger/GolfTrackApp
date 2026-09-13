import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Footer, Header } from "@/components/Chrome";
import { CourseHintList } from "@/components/CourseHintList";
import { WebScorecard } from "@/components/WebScorecard";
import { getCourse } from "@/lib/courses";
import { APP_STORE_URL, PLAY_URL } from "@/i18n/routes";

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
 */

const APP_STORE_ID = "6767996957";
const APP_CLIP_BUNDLE_ID = "com.TobiasAufschlaeger.GolfTrackandwatch.Clip";

export async function generateMetadata({ params }: PageProps<"/p/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const course = await getCourse(slug);
  if (!course) return { title: "Platz nicht gefunden · GolfTrack" };

  return {
    title: `${course.name} · Runde mitzählen`,
    description:
      course.welcome ||
      `Zähle deine Runde auf ${course.name} mit – mit der App, ohne Installation oder direkt im Browser.`,
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

export default async function PlayPage({ params }: PageProps<"/p/[slug]">) {
  const { slug } = await params;
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
      <Header lang="de" />
      <main className="mx-auto max-w-3xl px-5 py-16 text-center sm:px-8 sm:py-20">
        <p className="marginal">{isGolf ? "Golfplatz" : "Minigolf"}</p>
        <h1 className="mt-4 font-display text-[clamp(2rem,5.5vw,3.2rem)] leading-[1.05] tracking-[-0.02em]">
          {course.name}
        </h1>
        {course.location ? <p className="mt-3 text-cream/55">{course.location}</p> : null}

        <p className="mx-auto mt-7 max-w-lg text-lg leading-relaxed text-cream/75">
          {course.welcome ||
            (isGolf
              ? "Schön, dass du da bist! Ab jetzt zählen wir für dich mit – Loch für Loch."
              : "Schön, dass du da bist! Ab jetzt zählen wir für dich mit – Bahn für Bahn.")}
        </p>

        {/*
          Der Knopf hilft nur, wenn die App schon installiert ist. Sie fängt
          diese Adresse dann ohnehin selbst ab – dieser Weg bleibt für den
          Fall, dass jemand den Link weitergeschickt hat.
        */}
        <div className="mt-9 flex flex-wrap justify-center gap-3">
          <a href={deepLink} className="btn-brass">
            In der App öffnen
          </a>
          <a href={APP_STORE_URL} target="_blank" rel="noreferrer" className="btn-ghost">
            GolfTrack laden
          </a>
        </div>

        <CourseHintList hints={course.facilityHints} />

        <WebScorecard
          slug={course.slug}
          kind={course.kind}
          holes={course.holes}
          pars={pars}
        />

        <p className="mx-auto mt-8 max-w-lg text-sm leading-relaxed text-cream/45">
          Die Zählkarte hier reicht für die Runde. Laufspur, Schlagweiten,
          Handicap und die Auswertung über alle Runden gibt es in der App.
        </p>

        <p className="mt-10 text-sm">
          <Link href={detailPath} className="text-brass underline underline-offset-4">
            Mehr zu {course.name}
          </Link>
        </p>
      </main>
      <Footer lang="de" />
    </>
  );
}
