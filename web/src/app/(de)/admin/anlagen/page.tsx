import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { isAuthenticated } from "@/lib/auth";
import { courseFacets, searchCourses, type CourseSort } from "@/lib/courses";
import type { CourseKind, CourseStatus } from "@/lib/schema";
import { CourseRows } from "../CourseRows";
import { Chip, PageHeader, Panel, PrimaryLink } from "../ui";
import { SearchBar } from "./SearchBar";

export const metadata: Metadata = {
  title: "Anlagen · GolfTrack",
  robots: { index: false, follow: false },
};

const PAGE_SIZE = 50;

/** Statuswerte in der Adresse auf Deutsch, damit Links lesbar bleiben. */
const STATUS_PARAM: Record<string, CourseStatus> = {
  offen: "pending",
  frei: "approved",
  abgelehnt: "rejected",
};
const KIND_PARAM: Record<string, CourseKind> = {
  golf: "golf",
  minigolf: "minigolf",
};
const SORT_PARAM: Record<string, CourseSort> = { alt: "old", name: "name" };

/**
 * Alle Anlagen – Golfplätze aus dem Import wie eingereichte Minigolfanlagen –
 * mit Suche, Filter-Chips und seitenweiser Liste statt einer endlosen Seite.
 */
export default async function CoursesAdminPage({ searchParams }: PageProps<"/admin/anlagen">) {
  if (!(await isAuthenticated())) redirect("/admin");
  const sp = await searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? "";
  const q = one(sp.q);
  const statusKey = one(sp.status);
  const kindKey = one(sp.art);
  const sortKey = one(sp.sort);
  const status = STATUS_PARAM[statusKey];
  const kind = KIND_PARAM[kindKey];
  const page = Math.max(1, Number(one(sp.seite)) || 1);

  const [{ courses, total }, facets] = await Promise.all([
    searchCourses({
      q,
      status,
      kind,
      sort: SORT_PARAM[sortKey],
      limit: PAGE_SIZE,
      offset: (page - 1) * PAGE_SIZE,
    }),
    courseFacets({ q, status, kind }),
  ]);
  const pages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  /** Adresse mit geänderten Filtern; Seite springt dabei auf 1 zurück. */
  const href = (changes: Record<string, string>) => {
    const p = new URLSearchParams();
    const merged = {
      q,
      status: statusKey,
      art: kindKey,
      sort: sortKey,
      ...changes,
    };
    for (const [k, v] of Object.entries(merged)) if (v) p.set(k, v);
    return `/admin/anlagen${p.size ? `?${p}` : ""}`;
  };

  return (
    <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8 lg:py-10">
      <PageHeader
        crumbs={[{ label: "Anlagen" }]}
        eyebrow="Verzeichnis"
        title="Anlagen"
        subtitle="Alle Golfplätze und Minigolfanlagen – eingereicht, freigegeben oder abgelehnt."
        action={
          <PrimaryLink href="/platz-melden" icon="plus">
            Anlage eintragen
          </PrimaryLink>
        }
      />

      <div className="mt-10 space-y-4">
        <Suspense>
          <SearchBar />
        </Suspense>
        <div className="flex flex-wrap gap-2">
          <Chip href={href({ status: "" })} active={!status} label="Alle" count={facets.status.all} />
          <Chip
            href={href({ status: "offen" })}
            active={status === "pending"}
            label="Zu prüfen"
            count={facets.status.pending}
          />
          <Chip
            href={href({ status: "frei" })}
            active={status === "approved"}
            label="Freigegeben"
            count={facets.status.approved}
          />
          <Chip
            href={href({ status: "abgelehnt" })}
            active={status === "rejected"}
            label="Abgelehnt"
            count={facets.status.rejected}
          />
          <span className="mx-1 hidden w-px self-stretch bg-white/10 sm:block" />
          <Chip href={href({ art: "" })} active={!kind} label="Golf + Minigolf" count={facets.kind.all} />
          <Chip href={href({ art: "golf" })} active={kind === "golf"} label="Golf" count={facets.kind.golf} />
          <Chip
            href={href({ art: "minigolf" })}
            active={kind === "minigolf"}
            label="Minigolf"
            count={facets.kind.minigolf}
          />
        </div>
      </div>

      <div className="mt-6">
        <Panel
          title={`${total.toLocaleString("de-DE")} ${total === 1 ? "Anlage" : "Anlagen"}${q ? ` für „${q}“` : ""}`}
        >
          <CourseRows courses={courses} empty="Keine Anlage passt zu Suche und Filter." />
        </Panel>
      </div>

      {pages > 1 ? (
        <nav className="mt-6 flex items-center justify-between gap-4 text-sm" aria-label="Seiten">
          <PageLink
            href={page > 1 ? `${href({})}${href({}).includes("?") ? "&" : "?"}seite=${page - 1}` : null}
            label="← Zurück"
          />
          <span className="text-cream/55">
            Seite {page} von {pages}
          </span>
          <PageLink
            href={page < pages ? `${href({})}${href({}).includes("?") ? "&" : "?"}seite=${page + 1}` : null}
            label="Weiter →"
          />
        </nav>
      ) : null}
    </div>
  );
}

function PageLink({ href, label }: { href: string | null; label: string }) {
  return href ? (
    <Link
      href={href}
      className="rounded-lg border border-white/10 px-4 py-2 transition-colors hover:border-brass/60 hover:text-brass"
    >
      {label}
    </Link>
  ) : (
    <span className="rounded-lg border border-white/5 px-4 py-2 text-cream/25">{label}</span>
  );
}
