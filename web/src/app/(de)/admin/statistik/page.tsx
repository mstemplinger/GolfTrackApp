import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import { MIN_ROUNDS_FOR_DISPLAY } from "@/lib/roundStats";
import { PageHeader, Panel, StatCard } from "../ui";
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
    <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8 lg:py-10">
      <PageHeader
        crumbs={[{ label: "Statistik" }]}
        eyebrow="Rundenstatistik"
        title="Statistik"
        subtitle={`Anonym gemeldete Runden aus App, App Clip und Browser – nur von Spielern, die zugestimmt haben. Betreiber sollen später nur Summen ab ${MIN_ROUNDS_FOR_DISPLAY} Runden sehen; hier siehst du alles.`}
      />

      <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Runden gesamt" value={total.toLocaleString("de-DE")} icon="chart" />
        <StatCard label="Letzte 30 Tage" value={total30.toLocaleString("de-DE")} icon="chart" />
        <StatCard label="Plätze mit Runden" value={courses.length} icon="flag" />
        <StatCard
          label={`Ab ${MIN_ROUNDS_FOR_DISPLAY} Runden`}
          value={ready}
          note="in 30 Tagen – zeigbar"
          icon="check"
          highlight={ready > 0}
        />
      </div>

      <Group title="Golfplätze" courses={golf} />
      <Group title="Minigolfanlagen" courses={minigolf} />
    </div>
  );
}

function Group({ title, courses }: { title: string; courses: CourseOverviewRow[] }) {
  return (
    <div className="mt-6">
      <Panel title={title}>
        {courses.length === 0 ? (
          <p className="px-5 py-6 text-sm text-cream/55">Noch keine Runden gemeldet.</p>
        ) : (
          <ul className="divide-y divide-white/[0.07]">
            {courses.map((c) => (
              <li key={c.slug}>
                <Link
                  href={`/admin/statistik/${c.slug}`}
                  className="flex flex-wrap items-center justify-between gap-3 px-5 py-3.5 transition-colors hover:bg-white/[0.03]"
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
      </Panel>
    </div>
  );
}

function formatDay(day: string | null): string {
  if (!day) return "–";
  const [y, m, d] = day.split("-");
  return `${d}.${m}.${y}`;
}
