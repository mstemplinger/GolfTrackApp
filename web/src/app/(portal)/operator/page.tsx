import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { getCourse } from "@/lib/courses";
import { currentOperator } from "@/lib/operatorAuth";
import { operatorT } from "@/lib/operatorLang";
import { MIN_ROUNDS_FOR_DISPLAY } from "@/lib/roundStats";
import { roundCounts } from "@/lib/roundStatsReport";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await operatorT();
  return { title: t.titleHome, robots: { index: false, follow: false } };
}

/** Startseite des Portals: die zugewiesenen Plätze. Bei genau einem direkt dorthin. */
export default async function OperatorHomePage() {
  const op = await currentOperator();
  if (!op) redirect("/login");
  if (op.courses.length === 1) redirect(`/course/${op.courses[0]}`);
  const { t } = await operatorT();

  const [courses, counts] = await Promise.all([
    Promise.all(op.courses.map((slug) => getCourse(slug))),
    roundCounts(op.courses, 30),
  ]);
  const list = courses
    .filter((c): c is NonNullable<typeof c> => Boolean(c))
    .sort((a, b) => a.name.localeCompare(b.name, t.report.locale));

  return (
    <div className="mx-auto max-w-6xl px-5 py-10 sm:px-8">
      <p className="flex items-center gap-2 text-xs font-medium uppercase tracking-[0.18em] text-brass">
        <span className="h-1.5 w-1.5 rounded-full bg-brass" />
        {t.roundStats}
      </p>
      <h1 className="mt-2 font-display text-3xl tracking-tight sm:text-4xl">{t.myCourses}</h1>
      <p className="mt-2 max-w-2xl text-sm leading-relaxed text-cream/60">{t.myCoursesIntro(MIN_ROUNDS_FOR_DISPLAY)}</p>

      {list.length === 0 ? (
        <p className="mt-10 rounded-xl border border-white/10 bg-white/[0.02] p-6 text-sm text-cream/60">
          {t.noCourses}
        </p>
      ) : (
        <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {list.map((c) => {
            const n = counts.get(c.slug) ?? 0;
            return (
              <Link
                key={c.slug}
                href={`/course/${c.slug}`}
                className="group rounded-xl border border-white/10 bg-white/[0.03] p-5 transition-colors hover:border-brass/60"
              >
                <span className="text-xs uppercase tracking-[0.14em] text-cream/45">
                  {c.kind === "golf" ? t.golfCourse : t.minigolf}
                </span>
                <span className="mt-2 block font-display text-xl font-semibold tracking-tight group-hover:text-brass">
                  {c.name}
                </span>
                <span className="block text-sm text-cream/55">{c.location}</span>
                <span className="mt-4 block text-sm">
                  <span className="font-mono text-lg text-cream">{n.toLocaleString(t.report.locale)}</span>{" "}
                  <span className="text-cream/55">{t.roundsIn30}</span>
                </span>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
