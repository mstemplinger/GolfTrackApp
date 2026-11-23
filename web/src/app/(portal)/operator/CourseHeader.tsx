import Link from "next/link";
import type { OperatorCopy } from "@/i18n/operator";
import type { CourseTab, OperatorToolsCopy } from "@/i18n/operatorTools";
import type { CourseRecord } from "@/lib/courses";

const TABS: { id: CourseTab; path: string }[] = [
  { id: "stats", path: "" },
  { id: "sign", path: "/sign" },
  { id: "ads", path: "/ads" },
  { id: "print", path: "/print" },
];

/**
 * Kopf jeder Platzseite im Portal: Zurück-Link (nur bei mehreren Plätzen),
 * Name, Ort und die Reiter Statistik · Aushang · Werbung · Werbemittel.
 *
 * Der aktive Reiter kommt von der Seite, nicht aus `usePathname()`: Auf der
 * Subdomain schreibt der Proxy die Adresse um, und Server und Browser sähen
 * sonst verschiedene Pfade.
 */
export function CourseHeader({
  course,
  active,
  showBack,
  t,
  tools,
  aside,
}: {
  course: Pick<CourseRecord, "slug" | "name" | "location" | "kind">;
  active: CourseTab;
  showBack: boolean;
  t: Pick<OperatorCopy, "back" | "golfCourse" | "minigolfFacility">;
  tools: Pick<OperatorToolsCopy, "tabs" | "tabsLabel">;
  /** Rechts neben dem Namen, z. B. die Zeitraumwahl der Statistik. */
  aside?: React.ReactNode;
}) {
  return (
    <>
      {showBack ? (
        <Link href="/" className="inline-flex min-h-11 items-center text-sm text-cream/55 transition-colors hover:text-brass">
          {t.back}
        </Link>
      ) : null}
      <div className="mt-2 flex flex-wrap items-end justify-between gap-5">
        <div className="min-w-0">
          <p className="flex items-center gap-2 text-xs font-medium uppercase tracking-[0.18em] text-brass">
            <span className="h-1.5 w-1.5 rounded-full bg-brass" />
            {course.kind === "golf" ? t.golfCourse : t.minigolfFacility}
          </p>
          <h1 className="mt-2 font-display text-3xl tracking-tight [overflow-wrap:anywhere] sm:text-4xl">
            {course.name}
          </h1>
          {course.location ? <p className="mt-1 text-sm text-cream/60">{course.location}</p> : null}
        </div>
        {aside}
      </div>

      {/* Am Handy seitlich wischbar statt umgebrochen – vier Reiter passen nicht immer in eine Zeile. */}
      <nav aria-label={tools.tabsLabel} className="-mx-5 mt-8 overflow-x-auto px-5 [scrollbar-width:none] sm:mx-0 sm:px-0">
        <ul className="flex min-w-max gap-1 border-b border-white/10">
          {TABS.map((tab) => {
            const current = tab.id === active;
            return (
              <li key={tab.id}>
                <Link
                  href={`/course/${course.slug}${tab.path}`}
                  aria-current={current ? "page" : undefined}
                  className={`-mb-px inline-flex min-h-11 items-center whitespace-nowrap border-b-2 px-3 text-sm transition-colors sm:px-4 ${
                    current
                      ? "border-brass font-medium text-cream"
                      : "border-transparent text-cream/55 hover:border-white/25 hover:text-cream"
                  }`}
                >
                  {tools.tabs[tab.id]}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
    </>
  );
}
