import Link from "next/link";
import { Footer, Header, PageHeader } from "@/components/Chrome";
import { listCourses } from "@/lib/courses";
import { t } from "@/i18n/content";
import { path, type Lang } from "@/i18n/routes";
import { AushangPicker } from "@/components/AushangPicker";
import { DirectoryList, type DirectoryEntry } from "@/components/DirectoryList";

export async function Directory({ lang }: { lang: Lang }) {
  const copy = t(lang).directory;
  const courses = await listCourses({ status: "approved", limit: 1000 });
  // Nur was die Liste anzeigt – die Suche läuft im Browser.
  const entries: DirectoryEntry[] = courses.map((course) => ({
    id: course.id,
    slug: course.slug,
    kind: course.kind,
    name: course.name,
    location: course.location ?? null,
    holes: course.holes,
    parTotal: course.holeData.reduce((sum, hole) => sum + (hole.par ?? 0), 0),
    courseRating: course.courseRating ?? null,
    slopeRating: course.slopeRating ?? null,
    picker: <AushangPicker slug={course.slug} country={course.country} copy={copy} />,
  }));

  return (
    <>
      <Header lang={lang} current="directory" />
      <PageHeader index="10 — Katalog" title={copy.title} lead={copy.lead} />
      <main className="mx-auto max-w-6xl px-5 py-14 sm:px-8 sm:py-16">
        {courses.length === 0 ? (
          <div className="rounded-sm border rule bg-black/20 p-10 text-center">
            <p className="text-cream/70">{copy.empty}</p>
            <Link href={path("submit", lang)} className="btn-brass mt-6">
              {copy.submitCta}
            </Link>
          </div>
        ) : (
          <>
            <DirectoryList entries={entries} copy={copy} />
            <div className="mt-14 flex flex-wrap items-center gap-x-6 gap-y-3 border-t rule pt-8">
              <Link href={path("submit", lang)} className="btn-brass">
                {copy.submitCta}
              </Link>
              <p className="text-sm text-cream/65">
                {copy.apiHint}{" "}
                {/* Schnittstelle, keine Seite – deshalb ein echter Verweis. */}
                <a
                  href="/api/v1/courses"
                  target="_blank"
                  rel="noreferrer"
                  className="tap font-mono text-brass underline underline-offset-4"
                >
                  /api/v1/courses
                </a>
              </p>
            </div>
            {/* Absprache mit handicap.report: Quellenhinweis direkt an der Liste, nicht nur im Impressum. */}
            <p className="mt-6 text-xs leading-relaxed text-cream/55">
              {copy.creditRatings}{" "}
              <a
                href="https://handicap.report"
                target="_blank"
                rel="noreferrer"
                className="tap text-brass underline underline-offset-4"
              >
                handicap.report
              </a>
              . {copy.creditCoords}{" "}
              <a
                href="https://www.openstreetmap.org/copyright"
                target="_blank"
                rel="noreferrer"
                className="tap underline underline-offset-4"
              >
                {copy.creditOsm}
              </a>{" "}
              {copy.creditLicense}.
            </p>
          </>
        )}
      </main>
      <Footer lang={lang} />
    </>
  );
}
