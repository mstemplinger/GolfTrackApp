import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { PeriodSwitch, RoundStatsReport, periodFrom } from "@/components/RoundStatsReport";
import { getCourse } from "@/lib/courses";
import { currentOperator } from "@/lib/operatorAuth";
import { operatorT } from "@/lib/operatorLang";
import { MIN_ROUNDS_FOR_DISPLAY } from "@/lib/roundStats";
import { courseReport } from "@/lib/roundStatsReport";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await operatorT();
  return { title: t.titleCourse, robots: { index: false, follow: false } };
}

/**
 * Statistik eines Platzes für seinen Betreiber. Nur zugewiesene Plätze, nur
 * freigegebene Bausteine – und unter MIN_ROUNDS_FOR_DISPLAY Runden im
 * Zeitraum gar keine Zahlen (so steht es in der Datenschutzerklärung).
 */
export default async function OperatorCoursePage({ params, searchParams }: PageProps<"/operator/course/[slug]">) {
  const op = await currentOperator();
  if (!op) redirect("/login");
  const { slug } = await params;
  // Fremde Plätze gibt es für dieses Konto nicht – auch nicht als „verboten“.
  if (!op.courses.includes(slug)) notFound();
  const days = periodFrom((await searchParams).tage);
  const { t } = await operatorT();

  const course = await getCourse(slug);
  if (!course) notFound();
  const holes = course.holeData.slice().sort((a, b) => a.number - b.number);
  const report = await courseReport(
    slug,
    days,
    holes.map((h) => h.par ?? null),
  );

  return (
    <div className="mx-auto max-w-6xl px-5 py-10 sm:px-8">
      {op.courses.length > 1 ? (
        <Link href="/" className="text-sm text-cream/55 transition-colors hover:text-brass">
          {t.back}
        </Link>
      ) : null}
      <div className="mt-4 flex flex-wrap items-end justify-between gap-5">
        <div className="min-w-0">
          <p className="flex items-center gap-2 text-xs font-medium uppercase tracking-[0.18em] text-brass">
            <span className="h-1.5 w-1.5 rounded-full bg-brass" />
            {course.kind === "golf" ? t.golfCourse : t.minigolfFacility}
          </p>
          <h1 className="mt-2 font-display text-3xl tracking-tight sm:text-4xl">{course.name}</h1>
          {course.location ? <p className="mt-1 text-sm text-cream/60">{course.location}</p> : null}
        </div>
        <PeriodSwitch days={days} href={(p) => `/course/${slug}?tage=${p}`} t={t.report} />
      </div>

      {report == null || report.rounds < MIN_ROUNDS_FOR_DISPLAY ? (
        <div className="mt-10 rounded-xl border border-white/10 bg-white/[0.02] p-6">
          <p className="font-medium">{t.tooFew}</p>
          <p className="mt-2 text-sm leading-relaxed text-cream/60">{t.tooFewText(MIN_ROUNDS_FOR_DISPLAY)}</p>
        </div>
      ) : op.permissions.length === 0 ? (
        <p className="mt-10 rounded-xl border border-white/10 bg-white/[0.02] p-6 text-sm text-cream/60">
          {t.nothingShared}
        </p>
      ) : (
        <RoundStatsReport
          report={report}
          hcps={holes.map((h) => h.hcp ?? null)}
          sections={op.permissions}
          audience="operator"
          t={t.report}
        />
      )}

      <p className="mt-16 border-t border-white/10 pt-6 text-xs leading-relaxed text-cream/40">{t.footnote}</p>
    </div>
  );
}
