"use client";

import { useMemo, useState } from "react";
import Link from "next/link";

/** Farben wie in der App, damit der Spielbereich zusammengehört. */
const APP = {
  card: "#163421",
  cardAlt: "#1C4129",
  gold: "#C9A035",
};

export interface PickerCourse {
  slug: string;
  name: string;
  location: string;
  kind: "golf" | "minigolf";
  holes: number;
}

/**
 * Platzauswahl für den Fall, dass niemand einen Code scannen kann.
 *
 * Die Liste kommt vollständig vom Server – bei rund hundert Plätzen lohnt
 * kein Nachladen, und so funktioniert das Suchen auch bei wackligem Empfang
 * auf dem Platz.
 */
export function CoursePicker({ courses }: { courses: PickerCourse[] }) {
  const [suche, setSuche] = useState("");

  const treffer = useMemo(() => {
    const frage = suche.trim().toLowerCase();
    if (!frage) return courses;
    return courses.filter(
      (c) =>
        c.name.toLowerCase().includes(frage) ||
        c.location.toLowerCase().includes(frage),
    );
  }, [courses, suche]);

  return (
    <div className="mx-auto mt-8 max-w-lg text-left">
      <label className="sr-only" htmlFor="platzsuche">
        Platz suchen
      </label>
      <input
        id="platzsuche"
        type="search"
        autoComplete="off"
        value={suche}
        onChange={(event) => setSuche(event.target.value)}
        placeholder="Platz oder Ort suchen"
        className="min-h-12 w-full rounded-xl px-4 text-[0.95rem] text-cream outline-none placeholder:text-cream/35"
        style={{ backgroundColor: APP.cardAlt }}
      />

      <p className="mt-3 font-mono text-xs text-cream/40">
        {treffer.length === courses.length
          ? `${courses.length} Plätze`
          : `${treffer.length} von ${courses.length}`}
      </p>

      {treffer.length === 0 ? (
        <p className="mt-6 rounded-xl p-5 text-sm text-cream/60" style={{ backgroundColor: APP.card }}>
          Kein Platz gefunden. Steht deiner noch nicht im Verzeichnis, kann ihn der
          Betreiber unter{" "}
          <Link href="/platz-melden" className="underline underline-offset-4" style={{ color: APP.gold }}>
            golftrack.app/platz-melden
          </Link>{" "}
          eintragen.
        </p>
      ) : (
        <ul className="mt-3 flex flex-col gap-2">
          {treffer.map((course) => (
            <li key={course.slug}>
              <Link
                href={`/p/${course.slug}`}
                className="flex items-center gap-3 rounded-xl p-4 transition-colors"
                style={{ backgroundColor: APP.card }}
              >
                <span className="min-w-0 flex-1">
                  <span className="block truncate font-semibold text-cream">{course.name}</span>
                  <span className="block truncate text-xs text-cream/50">
                    {course.location} · {course.holes}{" "}
                    {course.kind === "golf" ? "Löcher" : "Bahnen"}
                  </span>
                </span>
                <span aria-hidden className="text-lg" style={{ color: APP.gold }}>
                  ›
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
