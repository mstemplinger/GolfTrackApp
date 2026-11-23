import type { Metadata } from "next";
import { PLAY_URL } from "@/i18n/routes";
import { operatorToolsCopy } from "@/i18n/operatorTools";
import { SPRACHEN, vorauswahl } from "@/lib/aushang";
import { operatorLang, operatorT } from "@/lib/operatorLang";
import { CourseHeader } from "../../../CourseHeader";
import { courseForOperator } from "../access";
import { SignForm } from "./SignForm";

export async function generateMetadata(): Promise<Metadata> {
  const tools = operatorToolsCopy(await operatorLang());
  return { title: tools.titleSign, robots: { index: false, follow: false } };
}

/**
 * Gäste-Aushang und QR-Code des Platzes. Dieselben Dateien wie im
 * Verzeichnis auf golftrack.app (`/qr/<kennung>…`), hier nur ohne Suchen –
 * und mit dem Hinweis, dass mehr Aushänge mehr Statistik bedeuten.
 */
export default async function OperatorSignPage({ params }: PageProps<"/operator/course/[slug]/sign">) {
  const { slug } = await params;
  const { op, course } = await courseForOperator(slug);
  const { lang, t } = await operatorT();
  const tools = operatorToolsCopy(lang);
  const copy = tools.sign;
  const link = `${PLAY_URL}/p/${course.slug}`;

  return (
    <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8 sm:py-10">
      <CourseHeader course={course} active="sign" showBack={op.courses.length > 1} t={t} tools={tools} />

      {course.status !== "approved" ? (
        <p className="mt-8 rounded-xl border border-white/10 bg-white/[0.02] p-5 text-sm leading-relaxed text-cream/65 sm:p-6">
          {copy.notApproved}
        </p>
      ) : (
        // Am Handy: Aushang, QR-Code, Tipps untereinander. Breit: QR-Code als Spalte rechts.
        <div className="mt-8 grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_20rem] lg:gap-x-8">
          <section className="rounded-xl border border-white/10 bg-white/[0.03] p-5 sm:p-7">
            <h2 className="font-display text-2xl tracking-tight">{copy.title}</h2>
            <p className="mt-2 max-w-2xl text-sm leading-relaxed text-cream/65">{copy.intro}</p>
            <div className="mt-6">
              <SignForm
                slug={course.slug}
                languages={SPRACHEN}
                preselected={vorauswahl(course.country)}
                names={copy.langNames}
                copy={copy}
              />
            </div>
          </section>

          <aside className="rounded-xl border border-white/10 bg-white/[0.03] p-5 sm:p-6 lg:col-start-2 lg:row-span-2 lg:row-start-1">
            <h2 className="text-sm font-medium text-cream/80">{copy.codeTitle}</h2>
            <div className="mx-auto mt-4 max-w-[15rem] rounded-lg bg-white p-3 lg:max-w-none">
              {/* eslint-disable-next-line @next/next/no-img-element -- SVG aus der eigenen Route, keine Optimierung nötig */}
              <img
                src={`/qr/${course.slug}?format=code`}
                alt={`${copy.codeTitle}: ${link}`}
                width={240}
                height={240}
                className="block aspect-square h-auto w-full"
              />
            </div>
            <p className="mt-4 text-xs text-cream/50">{copy.codeLeadsTo}</p>
            <p className="mt-1 break-all font-mono text-sm text-cream/85">{link.replace(/^https:\/\//, "")}</p>
            <a
              href={link}
              target="_blank"
              rel="noopener"
              className="mt-1 inline-flex min-h-11 items-center text-sm text-brass underline-offset-4 hover:underline"
            >
              {copy.tryIt} ↗
            </a>
            <div className="mt-3 grid grid-cols-2 gap-2">
              <a
                href={`/qr/${course.slug}?format=code`}
                className="inline-flex min-h-11 items-center justify-center rounded-lg border border-white/15 px-3 text-center text-xs text-cream/80 transition-colors hover:border-brass/60 hover:text-cream"
              >
                {copy.codeSvg}
              </a>
              <a
                href={`/qr/${course.slug}?format=png`}
                className="inline-flex min-h-11 items-center justify-center rounded-lg border border-white/15 px-3 text-center text-xs text-cream/80 transition-colors hover:border-brass/60 hover:text-cream"
              >
                {copy.codePng}
              </a>
            </div>
            <p className="mt-3 text-xs leading-relaxed text-cream/45">{copy.codeHint}</p>
          </aside>

          <section className="rounded-xl border border-white/10 bg-white/[0.02] p-5 sm:p-7">
            <h2 className="text-sm font-medium text-cream/80">{copy.tipsTitle}</h2>
            <ol className="mt-3 space-y-2.5 text-sm leading-relaxed text-cream/65">
              {copy.tips.map((tip, i) => (
                <li key={tip} className="flex gap-3">
                  <span className="mt-px font-mono text-xs text-brass">{String(i + 1).padStart(2, "0")}</span>
                  <span>{tip}</span>
                </li>
              ))}
            </ol>
          </section>
        </div>
      )}
    </div>
  );
}
