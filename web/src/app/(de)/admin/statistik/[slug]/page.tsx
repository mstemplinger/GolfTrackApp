import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import { getCourse } from "@/lib/courses";
import { courseReport } from "@/lib/roundStatsReport";
import { PeriodSwitch, RoundStatsReport, periodFrom } from "@/components/RoundStatsReport";
import { PageHeader } from "../../ui";

export const metadata: Metadata = {
  title: "Rundenstatistik · GolfTrack",
  robots: { index: false, follow: false },
};

/**
 * Auswertung eines Platzes – so, wie sie später der Betreiber sehen soll,
 * nur ohne Mindestmengen-Sperre. Golf zeigt zusätzlich Par-Abweichung, Putts
 * und Abschläge; Minigolf die Hole-in-one-Quote.
 */
export default async function CourseRoundStatsPage({ params, searchParams }: PageProps<"/admin/statistik/[slug]">) {
  if (!(await isAuthenticated())) redirect("/admin");
  const { slug } = await params;
  const days = periodFrom((await searchParams).tage);

  const course = await getCourse(slug);
  const sortedHoles = (course?.holeData ?? []).slice().sort((a, b) => a.number - b.number);
  const pars = sortedHoles.map((h) => h.par ?? null);
  const hcps = sortedHoles.map((h) => h.hcp ?? null);
  const report = await courseReport(slug, days, pars);
  if (!course && !report) notFound();

  return (
    <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8 lg:py-10">
      <PageHeader
        crumbs={[{ label: "Statistik", href: "/admin/statistik" }, { label: course?.name ?? slug }]}
        eyebrow={`Rundenstatistik · ${(course?.kind ?? report?.kind) === "golf" ? "Golf" : "Minigolf"}`}
        title={course?.name ?? slug}
        subtitle={course?.location || undefined}
        action={<PeriodSwitch days={days} href={(p) => `/admin/statistik/${slug}?tage=${p}`} />}
      />

      {!report ? (
        <p className="mt-8 text-sm text-cream/65">In den letzten {days} Tagen wurden keine Runden gemeldet.</p>
      ) : (
        <RoundStatsReport report={report} hcps={hcps} />
      )}
    </div>
  );
}
