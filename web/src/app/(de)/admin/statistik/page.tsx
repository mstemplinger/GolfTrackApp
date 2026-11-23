import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import { MIN_ROUNDS_FOR_DISPLAY } from "@/lib/roundStats";
import { listCoursesWithStats, type CourseOverviewRow } from "@/lib/roundStatsReport";

export const metadata: Metadata = {
  title: "Rundenstatistik · GolfTrack",
  robots: { index: false, follow: false },
};

/**
 * Anonyme Rundenstatistik aller Plätze – Golf und Minigolf. Nur für das
 * Adminpanel; Betreiber bekommen später ihre eigene Seite (Konzept:
 * docs/betreiber-dashboard-konzept.md).
 */
export default async function RoundStatsOverviewPage() {
  if (!(await isAuthenticated())) redirect("/admin");

  const courses = await listCoursesWithStats();
  const golf = courses.filter((c) => c.kind === "golf");
  const minigolf = courses.filter((c) => c.kind === "minigolf");
  const total = courses.reduce((sum, c) => sum + c.rounds, 0);
  const total30 = courses.reduce((sum, c) => sum + c.rounds30, 0);
  const ready = courses.filter((c) => c.rounds30 >= MIN_ROUNDS_FOR_DISPLAY).length;

  return (
    <div className="mx-auto max-w-5xl px-5 py-12 sm:px-8">
      <Link href="/admin" className="marginal transition-colors hover:text-brass-soft">
        ← Übersicht
      </Link>

      <header className="mt-4 border-b rule pb-6">
        <p className="marginal">Adminpanel</p>
        <h1 className="mt-2 font-display text-3xl tracking-tight">Rundenstatistik</h1>
        <p className="mt-2 max-w-2xl text-sm leading-relaxed text-cream/65">
          Anonym gemeldete Runden aus App, App Clip und Browser – nur von Spielern, die zugestimmt
          haben. Betreiber sollen später nur Summen ab {MIN_ROUNDS_FOR_DISPLAY} Runden sehen; hier
          siehst du alles.
        </p>
      </header>

      <dl className="mt-8 grid gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-4">
        <Stat label="Runden gesamt" value={total} />
        <Stat label="Letzte 30 Tage" value={total30} />
        <Stat label="Plätze mit Runden" value={courses.length} />
        <Stat label={`Plätze ab ${MIN_ROUNDS_FOR_DISPLAY} Runden (30 T.)`} value={ready} highlight />
      </dl>

      <Group title="Golfplätze" courses={golf} />
      <Group title="Minigolfanlagen" courses={minigolf} />
    </div>
  );
}

function Stat({ label, value, highlight }: { label: string; value: number; highlight?: boolean }) {
  return (
    <div className="bg-night/85 p-5">
      <dt className="marginal">{label}</dt>
      <dd className={`mt-1.5 font-mono text-3xl ${highlight && value > 0 ? "text-brass" : "text-cream/80"}`}>
        {value.toLocaleString("de-DE")}
      </dd>
    </div>
  );
}

function Group({ title, courses }: { title: string; courses: CourseOverviewRow[] }) {
  return (
    <section className="mt-12">
      <h2 className="marginal">{title}</h2>
      {courses.length === 0 ? (
        <p className="mt-3 text-sm text-cream/65">Noch keine Runden gemeldet.</p>
      ) : (
        <ul className="mt-4 divide-y rule overflow-hidden rounded-sm border rule">
          {courses.map((c) => (
            <li key={c.slug}>
              <Link
                href={`/admin/statistik/${c.slug}`}
                className="flex flex-wrap items-center justify-between gap-3 bg-night/85 p-4 transition-colors hover:bg-moss-2/60"
              >
                <span className="min-w-0">
                  <span className="block truncate font-medium">{c.name}</span>
                  <span className="block text-xs text-cream/55">
                    {c.location ? `${c.location} · ` : ""}zuletzt gespielt {formatDay(c.lastPlayed)}
                  </span>
                </span>
                <span className="flex items-center gap-5 font-mono text-sm">
                  <span className={c.rounds30 >= MIN_ROUNDS_FOR_DISPLAY ? "text-brass" : "text-cream/55"}>
                    {c.rounds30} <span className="text-xs text-cream/45">/ 30 T.</span>
                  </span>
                  <span className="text-cream/80">
                    {c.rounds} <span className="text-xs text-cream/45">gesamt</span>
                  </span>
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

function formatDay(day: string | null): string {
  if (!day) return "–";
  const [y, m, d] = day.split("-");
  return `${d}.${m}.${y}`;
}
