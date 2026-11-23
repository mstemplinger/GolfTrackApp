import type { Metadata } from "next";
import { SITE_URL } from "@/i18n/routes";
import { operatorToolsCopy, type AdsCopy } from "@/i18n/operatorTools";
import { listOperatorAds, type AdWithReach } from "@/lib/ads";
import { courseMarkers, getCourse } from "@/lib/courses";
import { distanceMeters } from "@/lib/geometryConsensus";
import { operatorLang, operatorT } from "@/lib/operatorLang";
import { CourseHeader } from "../../../CourseHeader";
import { courseForOperator, coursePoint } from "../access";
import { OperatorAdForm, type NearbyCourse } from "./OperatorAdForm";

export async function generateMetadata(): Promise<Metadata> {
  const tools = operatorToolsCopy(await operatorLang());
  return { title: tools.titleAds, robots: { index: false, follow: false } };
}

/** Weiter als der größte wählbare Umkreis muss die Liste nicht reichen. */
const MAX_RADIUS_KM = 100;

/**
 * Werbung in der Zählkarte: die eigenen Anzeigen des Kontos mit Zählern und
 * darunter die Anfrage einer neuen. Geschaltet wird nichts von hier aus –
 * jede Anfrage ist ein Entwurf im Adminpanel (Quelle `operator`).
 */
export default async function OperatorAdsPage({ params }: PageProps<"/operator/course/[slug]/ads">) {
  const { slug } = await params;
  const { op, course } = await courseForOperator(slug);
  const { lang, t } = await operatorT();
  const tools = operatorToolsCopy(lang);
  const copy = tools.ads;

  const centre = coursePoint(course);
  const [ads, markers, ownCourses] = await Promise.all([
    listOperatorAds(op.id),
    centre ? courseMarkers() : Promise.resolve([]),
    Promise.all(op.courses.map((s) => (s === slug ? Promise.resolve(course) : getCourse(s)))),
  ]);
  const courseNames = new Map(ownCourses.filter((c) => c != null).map((c) => [c.slug, c.name]));

  // Entfernungen rechnet der Server einmal – ins Formular gehen nur die Plätze
  // bis 100 km, nicht der ganze Katalog.
  const nearby: NearbyCourse[] = centre
    ? markers
        .map((m) => ({ slug: m.slug, name: m.name, kind: m.kind, km: distanceMeters(centre, m) / 1000 }))
        .filter((m) => m.km <= MAX_RADIUS_KM)
        .sort((a, b) => a.km - b.km)
    : [];

  return (
    <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8 sm:py-10">
      <CourseHeader course={course} active="ads" showBack={op.courses.length > 1} t={t} tools={tools} />

      <p className="mt-8 max-w-2xl text-sm leading-relaxed text-cream/65">{copy.intro}</p>

      {ads.length ? (
        <section className="mt-8" aria-labelledby="my-ads">
          <h2 id="my-ads" className="text-xs font-medium uppercase tracking-[0.14em] text-cream/45">
            {copy.mine}
          </h2>
          <ul className="mt-3 space-y-3">
            {ads.map((ad) => (
              <AdRow key={ad.id} ad={ad} copy={copy} locale={t.report.locale} courseNames={courseNames} />
            ))}
          </ul>
        </section>
      ) : null}

      <div className="mt-10">
        {course.status === "approved" ? (
          <OperatorAdForm
            slug={course.slug}
            lang={lang}
            course={{ name: course.name, kind: course.kind, hasLocation: centre != null }}
            nearby={nearby}
            contact={{ name: op.name, email: op.email }}
            termsUrl={`${SITE_URL}/werbung/bedingungen`}
          />
        ) : (
          <p className="rounded-xl border border-white/10 bg-white/[0.02] p-5 text-sm text-cream/65 sm:p-6">
            {copy.errNotApproved}
          </p>
        )}
      </div>
    </div>
  );
}

type Phase = "draft" | "active" | "scheduled" | "ended" | "paused";

function phaseOf(ad: AdWithReach, today: string): Phase {
  if (ad.status === "draft") return "draft";
  if (ad.status === "paused") return "paused";
  if (ad.endsOn && ad.endsOn < today) return "ended";
  if (ad.startsOn && ad.startsOn > today) return "scheduled";
  return "active";
}

const PILL: Record<Phase, string> = {
  draft: "bg-white/10 text-cream/80",
  active: "bg-[#28824b]/25 text-[#8fd6a8]",
  scheduled: "bg-brass/15 text-brass",
  ended: "bg-white/5 text-cream/45",
  paused: "bg-white/5 text-cream/45",
};

function AdRow({
  ad,
  copy,
  locale,
  courseNames,
}: {
  ad: AdWithReach;
  copy: AdsCopy;
  locale: string;
  courseNames: Map<string, string>;
}) {
  const today = new Date().toISOString().slice(0, 10);
  const phase = phaseOf(ad, today);
  const day = (d: string) => new Date(`${d}T12:00:00Z`).toLocaleDateString(locale, { day: "numeric", month: "short", year: "numeric" });
  const label =
    phase === "scheduled" && ad.startsOn ? copy.status.scheduled(day(ad.startsOn)) : copy.status[phase === "scheduled" ? "active" : phase];
  const where = ad.courseSlug
    ? copy.onCourse(courseNames.get(ad.courseSlug) ?? ad.courseSlug)
    : ad.radiusKm
      ? copy.around(ad.radiusKm, ad.placeName)
      : ad.placeName;
  const showNumbers = phase !== "draft";

  return (
    <li className="rounded-xl border border-white/10 bg-white/[0.03] p-4 sm:p-5">
      <div className="flex flex-wrap items-start justify-between gap-x-4 gap-y-2">
        <div className="min-w-0 flex-1">
          <p className="font-medium text-cream [overflow-wrap:anywhere]">{ad.title}</p>
          {ad.subtitle ? <p className="mt-0.5 text-sm text-cream/60 [overflow-wrap:anywhere]">{ad.subtitle}</p> : null}
          <p className="mt-1.5 text-xs text-cream/45">
            {where}
            {ad.endsOn && phase !== "draft" ? ` · ${ad.startsOn ? `${day(ad.startsOn)} – ` : "– "}${day(ad.endsOn)}` : ""}
          </p>
        </div>
        <span className={`shrink-0 rounded-full px-2.5 py-1 text-xs font-medium ${PILL[phase]}`}>{label}</span>
      </div>
      {showNumbers ? (
        <dl className="mt-3 flex flex-wrap gap-x-6 gap-y-1 border-t border-white/5 pt-3 text-sm">
          <div className="flex items-baseline gap-1.5">
            <dt className="text-cream/50">{copy.views}</dt>
            <dd className="font-mono text-cream">{ad.impressions.toLocaleString(locale)}</dd>
          </div>
          <div className="flex items-baseline gap-1.5">
            <dt className="text-cream/50">{copy.taps}</dt>
            <dd className="font-mono text-cream">{ad.clicks.toLocaleString(locale)}</dd>
          </div>
          <p className="text-xs text-cream/35 sm:ml-auto sm:self-center">{copy.last30}</p>
        </dl>
      ) : null}
    </li>
  );
}
