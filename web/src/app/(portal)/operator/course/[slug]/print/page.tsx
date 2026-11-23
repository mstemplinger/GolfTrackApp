import type { Metadata } from "next";
import Image from "next/image";
import { operatorToolsCopy } from "@/i18n/operatorTools";
import { operatorLang, operatorT } from "@/lib/operatorLang";
import type { PrintItem } from "@/lib/printItems";
import { isPlaceholder, site } from "@/lib/site";
import { CourseHeader } from "../../../CourseHeader";
import { courseForOperator } from "../access";
import { OperatorPrintForm } from "./OperatorPrintForm";

export async function generateMetadata(): Promise<Metadata> {
  const tools = operatorToolsCopy(await operatorLang());
  return { title: tools.titlePrint, robots: { index: false, follow: false } };
}

/** Was zu welcher Art Platz passt – Bauzaunplanen und „Golf lernen“ nur für Golf. */
const ITEMS: Record<"golf" | "minigolf", PrintItem[]> = {
  golf: ["saeule-golf", "saeule-lernen", "plane-abschlag", "plane-range", "plakate"],
  minigolf: ["saeule-minigolf", "plakate"],
};

/**
 * Druckwerbung für den eigenen Platz: Werbesäulen, Bauzaunplanen, Plakate.
 * Dieselben Motive wie auf golftrack.app/werbung/golfplatz; die Anfrage geht
 * per Mail an uns, mit Konto und Platzkennung.
 */
export default async function OperatorPrintPage({ params }: PageProps<"/operator/course/[slug]/print">) {
  const { slug } = await params;
  const { op, course } = await courseForOperator(slug);
  const { lang, t } = await operatorT();
  const tools = operatorToolsCopy(lang);
  const copy = tools.print;
  const golf = course.kind === "golf";

  const gallery = [
    { src: "/werbemittel/saeulen-trio.jpg", w: 1600, h: 1200, title: copy.columns, text: copy.columnsText },
    ...(golf
      ? [
          { src: "/werbemittel/plane-abschlag-3d.jpg", w: 1600, h: 900, title: copy.fenceTee, text: copy.fenceText },
          { src: "/werbemittel/plane-range-3d.jpg", w: 1600, h: 900, title: copy.fenceRange, text: copy.fenceText },
        ]
      : []),
  ];

  return (
    <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8 sm:py-10">
      <CourseHeader course={course} active="print" showBack={op.courses.length > 1} t={t} tools={tools} />

      <h2 className="sr-only">{copy.title}</h2>
      <p className="mt-8 max-w-2xl text-sm leading-relaxed text-cream/65">{golf ? copy.introGolf : copy.introMinigolf}</p>

      {/* Am Handy seitlich wischbar, damit das Formular nicht drei Bildschirme tiefer liegt. */}
      <ul
        className={`-mx-5 mt-6 flex snap-x snap-mandatory scroll-px-5 gap-3 overflow-x-auto px-5 pb-2 [scrollbar-width:none] sm:mx-0 sm:grid sm:gap-4 sm:overflow-visible sm:px-0 sm:pb-0 ${
          gallery.length > 1 ? "sm:grid-cols-2 lg:grid-cols-3" : "sm:grid-cols-2"
        }`}
      >
        {gallery.map((g, i) => (
          <li
            key={g.src}
            className={`shrink-0 snap-start overflow-hidden rounded-xl border border-white/10 bg-white/[0.03] sm:w-auto ${
              gallery.length > 1 ? "w-[82%]" : "w-full"
            }`}
          >
            <div className="bg-[#0E2718]">
              <Image
                src={g.src}
                alt={g.title}
                width={g.w}
                height={g.h}
                sizes="(min-width: 64rem) 24rem, (min-width: 40rem) 50vw, 100vw"
                className="aspect-[3/2] h-auto w-full object-cover"
                priority={i === 0}
              />
            </div>
            <div className="p-4">
              <p className="font-medium text-cream">{g.title}</p>
              <p className="mt-1 text-xs leading-relaxed text-cream/55">{g.text}</p>
            </div>
          </li>
        ))}
      </ul>

      <div className="mt-10">
        <OperatorPrintForm
          slug={course.slug}
          lang={lang}
          items={ITEMS[golf ? "golf" : "minigolf"]}
          contact={{ name: op.name, email: op.email }}
          fallbackEmail={isPlaceholder(site.email) ? null : site.email}
        />
      </div>
    </div>
  );
}
