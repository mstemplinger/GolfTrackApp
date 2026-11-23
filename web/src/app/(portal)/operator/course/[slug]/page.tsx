import type { Metadata } from "next";
import Link from "next/link";
import { PeriodSwitch, RoundStatsReport, periodFrom } from "@/components/RoundStatsReport";
import { operatorToolsCopy } from "@/i18n/operatorTools";
import { operatorT } from "@/lib/operatorLang";
import { MIN_ROUNDS_FOR_DISPLAY } from "@/lib/roundStats";
import { courseReport } from "@/lib/roundStatsReport";
import { CourseHeader } from "../../CourseHeader";
import { courseForOperator } from "./access";

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
  const { slug } = await params;
  const { op, course } = await courseForOperator(slug);
  const days = periodFrom((await searchParams).tage);
  const { lang, t } = await operatorT();
  const tools = operatorToolsCopy(lang);

  const holes = course.holeData.slice().sort((a, b) => a.number - b.number);
  const report = await courseReport(
    slug,
    days,
    holes.map((h) => h.par ?? null),
  );

  return (
    <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8 sm:py-10">
      <CourseHeader
        course={course}
        active="stats"
        showBack={op.courses.length > 1}
        t={t}
        tools={tools}
        aside={<PeriodSwitch days={days} href={(p) => `/course/${slug}?tage=${p}`} t={t.report} />}
      />

      {report == null || report.rounds < MIN_ROUNDS_FOR_DISPLAY ? (
        <div className="mt-8 rounded-xl border border-white/10 bg-white/[0.02] p-5 sm:p-6">
          <p className="font-medium">{t.tooFew}</p>
          <p className="mt-2 text-sm leading-relaxed text-cream/60">{t.tooFewText(MIN_ROUNDS_FOR_DISPLAY)}</p>
          {course.status === "approved" ? (
            <Link
              href={`/course/${slug}/sign`}
              className="mt-4 inline-flex min-h-11 items-center rounded-lg border border-brass/50 px-4 text-sm text-brass transition-colors hover:bg-brass/10"
            >
              {tools.toSign} →
            </Link>
          ) : null}
        </div>
      ) : op.permissions.length === 0 ? (
        <p className="mt-8 rounded-xl border border-white/10 bg-white/[0.02] p-5 text-sm text-cream/60 sm:p-6">
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
