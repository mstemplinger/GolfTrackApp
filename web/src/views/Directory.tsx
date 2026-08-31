import Link from "next/link";
import { Footer, Header, PageHeader } from "@/components/Chrome";
import { listCourses, type CourseRecord } from "@/lib/courses";
import { t } from "@/i18n/content";
import { path, type Lang } from "@/i18n/routes";

export async function Directory({ lang }: { lang: Lang }) {
  const copy = t(lang).directory;
  const courses = await listCourses({ status: "approved", limit: 1000 });
  const golf = courses.filter((course) => course.kind === "golf");
  const minigolf = courses.filter((course) => course.kind === "minigolf");

  return (
    <>
      <Header lang={lang} current="directory" />
      <PageHeader index="10 — Katalog" title={copy.title} lead={copy.lead} />
      <main className="mx-auto max-w-6xl px-5 py-14 sm:px-8 sm:py-16">
        {courses.length === 0 ? (
          <div className="rounded-sm border rule bg-moss/30 p-10 text-center">
            <p className="text-cream/70">{copy.empty}</p>
            <Link href={path("submit", lang)} className="btn-brass mt-6">
              {copy.submitCta}
            </Link>
          </div>
        ) : (
          <>
            {golf.length ? <CourseGroup title={copy.golf} courses={golf} lang={lang} /> : null}
            {minigolf.length ? <CourseGroup title={copy.minigolf} courses={minigolf} lang={lang} /> : null}
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
          </>
        )}
      </main>
      <Footer lang={lang} />
    </>
  );
}

function CourseGroup({
  title,
  courses,
  lang,
}: {
  title: string;
  courses: CourseRecord[];
  lang: Lang;
}) {
  const copy = t(lang).directory;
  return (
    <section className="mt-14 first:mt-0">
      <h2 className="marginal flex items-baseline gap-2">
        {title}
        <span className="text-cream/45">{courses.length}</span>
      </h2>
      <ul className="mt-4 grid gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-2 lg:grid-cols-3">
        {courses.map((course) => {
          const pars = course.holeData.map((hole) => hole.par ?? 0);
          const parTotal = pars.reduce((sum, value) => sum + value, 0);
          const body = (
            <>
              <h3 className="font-display text-xl leading-snug tracking-tight">{course.name}</h3>
              {course.location ? <p className="mt-1 text-sm text-cream/65">{course.location}</p> : null}
              <dl className="mt-4 flex flex-wrap gap-x-5 gap-y-1.5 font-mono text-xs text-cream/60">
                <span>
                  {course.holes} {course.kind === "golf" ? copy.holes : copy.lanes}
                </span>
                {parTotal ? (
                  <span>
                    {copy.par} {parTotal}
                  </span>
                ) : null}
                {course.courseRating && course.slopeRating ? (
                  <span>
                    {course.courseRating.toFixed(1)} / {course.slopeRating}
                  </span>
                ) : null}
              </dl>
            </>
          );

          return (
            <li key={course.id} className="bg-night/85 p-6 transition-colors hover:bg-moss-2/60">
              {course.kind === "minigolf" ? (
                <>
                  <Link href={`/minigolf/${course.slug}`} className="block">
                    {body}
                  </Link>
                  {/* Aushang für die Anlage. Der Code zeigt auf die Seite oben:
                      mit App startet die Runde, ohne App führt sie zum Store. */}
                  <a
                    href={`/qr/${course.slug}`}
                    title={copy.qrTitle}
                    className="tap mt-4 inline-block font-mono text-xs text-brass underline underline-offset-4"
                  >
                    ↓ {copy.qrDownload}
                  </a>
                </>
              ) : (
                body
              )}
            </li>
          );
        })}
      </ul>
    </section>
  );
}
