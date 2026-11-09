"use client";

import Link from "next/link";
import { useDeferredValue, useState, type ReactNode } from "react";

export type DirectoryEntry = {
  id: string;
  slug: string;
  kind: "golf" | "minigolf";
  name: string;
  location: string | null;
  holes: number;
  parTotal: number;
  courseRating: number | null;
  slopeRating: number | null;
  /** Aushang-Auswahl, auf dem Server gerendert – `aushang.ts` ist server-only. */
  picker: ReactNode;
};

type Copy = {
  golf: string;
  minigolf: string;
  holes: string;
  lanes: string;
  par: string;
  search: string;
  noMatch: string;
};

/** Umlaute und Akzente weg, damit „munchen“ auch „München“ findet. */
function fold(text: string) {
  return text.normalize("NFD").replace(/\p{Diacritic}/gu, "").toLowerCase();
}

export function DirectoryList({ entries, copy }: { entries: DirectoryEntry[]; copy: Copy }) {
  const [query, setQuery] = useState("");
  const deferred = useDeferredValue(query);
  const words = fold(deferred).split(/\s+/).filter(Boolean);
  const matches = words.length
    ? entries.filter((entry) => {
        const haystack = fold(`${entry.name} ${entry.location ?? ""}`);
        return words.every((word) => haystack.includes(word));
      })
    : entries;
  const golf = matches.filter((entry) => entry.kind === "golf");
  const minigolf = matches.filter((entry) => entry.kind === "minigolf");

  return (
    <>
      <input
        type="search"
        value={query}
        onChange={(event) => setQuery(event.target.value)}
        placeholder={copy.search}
        aria-label={copy.search}
        className="min-h-[44px] w-full rounded-full border border-cream/25 bg-white/5 px-5 text-cream placeholder:text-muted/70 focus:border-brass focus:outline-none sm:max-w-md"
      />
      {matches.length === 0 ? <p className="mt-10 text-cream/70">{copy.noMatch}</p> : null}
      {golf.length ? <CourseGroup title={copy.golf} entries={golf} copy={copy} /> : null}
      {minigolf.length ? <CourseGroup title={copy.minigolf} entries={minigolf} copy={copy} /> : null}
    </>
  );
}

function CourseGroup({ title, entries, copy }: { title: string; entries: DirectoryEntry[]; copy: Copy }) {
  return (
    <section className="mt-14">
      <h2 className="marginal flex items-baseline gap-2">
        {title}
        <span className="text-cream/45">{entries.length}</span>
      </h2>
      <ul className="mt-4 grid gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-2 lg:grid-cols-3">
        {entries.map((course) => (
          <li key={course.id} className="bg-black/25 p-6 transition-colors hover:bg-white/[0.04]">
            {/* Golf und Minigolf gleichberechtigt: beide haben eine Landeseite
                und beide brauchen ihren Aushang. */}
            <Link href={`/${course.kind}/${course.slug}`} className="block">
              <h3 className="font-display text-xl leading-snug tracking-tight">{course.name}</h3>
              {course.location ? <p className="mt-1 text-sm text-cream/65">{course.location}</p> : null}
              <dl className="mt-4 flex flex-wrap gap-x-5 gap-y-1.5 font-mono text-xs text-cream/60">
                <span>
                  {course.holes} {course.kind === "golf" ? copy.holes : copy.lanes}
                </span>
                {course.parTotal ? (
                  <span>
                    {copy.par} {course.parTotal}
                  </span>
                ) : null}
                {course.courseRating && course.slopeRating ? (
                  <span>
                    {course.courseRating.toFixed(1)} / {course.slopeRating}
                  </span>
                ) : null}
              </dl>
            </Link>
            {/* Aushang für die Anlage: Sprachen wählen, PDF laden. */}
            <div className="mt-4">{course.picker}</div>
          </li>
        ))}
      </ul>
    </section>
  );
}
