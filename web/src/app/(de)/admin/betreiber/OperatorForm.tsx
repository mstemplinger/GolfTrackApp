"use client";

import Link from "next/link";
import { useActionState, useMemo, useState } from "react";
import { ALL_SECTIONS, OPERATOR_SECTIONS, type OperatorSection } from "@/lib/sections";
import { saveOperator, type SaveState } from "./actions";
import { PasswordNotice } from "./PasswordNotice";

export interface CourseOption {
  slug: string;
  name: string;
  location: string;
  kind: "golf" | "minigolf";
}

interface Initial {
  id?: string;
  name: string;
  email: string;
  notes: string;
  active: boolean;
  lang: "de" | "en";
  permissions: OperatorSection[];
  courses: string[];
}

const EMPTY: Initial = {
  name: "",
  email: "",
  notes: "",
  active: true,
  lang: "de",
  permissions: ALL_SECTIONS,
  courses: [],
};

const field =
  "w-full rounded-lg border border-white/10 bg-white/[0.03] px-4 py-2.5 text-sm text-cream placeholder:text-cream/35 focus:border-brass/60 focus:outline-none";

/**
 * Anlegen und Bearbeiten eines Betreiberkontos: Stammdaten, zugewiesene Plätze
 * (Suche über alle freigegebenen Plätze) und freigegebene Statistik-Bausteine.
 */
export function OperatorForm({
  courses,
  initial = EMPTY,
  portalUrl,
}: {
  courses: CourseOption[];
  initial?: Initial;
  portalUrl: string;
}) {
  const [state, action, pending] = useActionState<SaveState, FormData>(saveOperator, { status: "idle" });
  const [selected, setSelected] = useState<string[]>(initial.courses);
  const [query, setQuery] = useState("");
  const bySlug = useMemo(() => new Map(courses.map((c) => [c.slug, c])), [courses]);

  const matches = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (q.length < 2) return [];
    return courses
      .filter((c) => !selected.includes(c.slug))
      .filter((c) => `${c.name} ${c.location} ${c.slug}`.toLowerCase().includes(q))
      .slice(0, 12);
  }, [courses, query, selected]);

  // Neu angelegt: Passwort einmal zeigen, Formular nicht mehr.
  if (!initial.id && state.status === "ok" && state.password) {
    return (
      <div className="space-y-5">
        <PasswordNotice
          email={state.email ?? ""}
          password={state.password}
          portalUrl={portalUrl}
          mail={state.mail}
          created
        />
        <Link
          href={`/admin/betreiber/${state.id}`}
          className="inline-flex rounded-lg border border-white/10 px-4 py-2 text-sm transition-colors hover:border-brass/60 hover:text-brass"
        >
          Zum Konto
        </Link>
      </div>
    );
  }

  return (
    <form action={action} className="space-y-8">
      {initial.id ? <input type="hidden" name="id" value={initial.id} /> : null}

      <section className="grid gap-5 sm:grid-cols-2">
        <label className="block">
          <span className="mb-1.5 block text-sm text-cream/70">Name</span>
          <input
            name="name"
            required
            defaultValue={initial.name}
            placeholder="Minigolf Sankt Englmar"
            className={field}
          />
        </label>
        <label className="block">
          <span className="mb-1.5 block text-sm text-cream/70">E-Mail (Anmeldename)</span>
          <input
            name="email"
            type="email"
            required
            defaultValue={initial.email}
            placeholder="betrieb@beispiel.de"
            className={field}
          />
        </label>
        <label className="block sm:col-span-2">
          <span className="mb-1.5 block text-sm text-cream/70">Notiz (nur intern)</span>
          <textarea
            name="notes"
            rows={2}
            defaultValue={initial.notes}
            placeholder="z. B. Ansprechpartner, Paket, bezahlt bis …"
            className={field}
          />
        </label>
        <label className="block">
          <span className="mb-1.5 block text-sm text-cream/70">Sprache (E-Mails und Portal)</span>
          <select name="lang" defaultValue={initial.lang} className={field}>
            <option value="de" className="bg-night">
              Deutsch
            </option>
            <option value="en" className="bg-night">
              Englisch
            </option>
          </select>
        </label>
        <div className="flex flex-col justify-end gap-3 pb-1 text-sm">
          <label className="flex items-center gap-3">
            <input type="checkbox" name="active" defaultChecked={initial.active} className="h-4 w-4 accent-[#c9a035]" />
            Konto aktiv – darf sich anmelden
          </label>
          {!initial.id ? (
            <label className="flex items-center gap-3">
              <input type="checkbox" name="sendMail" defaultChecked className="h-4 w-4 accent-[#c9a035]" />
              Zugangsdaten per E-Mail senden (zwei getrennte Mails)
            </label>
          ) : null}
        </div>
      </section>

      <section>
        <h2 className="text-xs font-medium uppercase tracking-[0.14em] text-cream/55">Plätze</h2>
        <p className="mt-1 text-sm text-cream/50">Der Betreiber sieht nur die Statistik dieser Plätze.</p>
        {selected.map((slug) => (
          <input key={slug} type="hidden" name="courses" value={slug} />
        ))}
        <div className="mt-3 flex flex-wrap gap-2">
          {selected.length === 0 ? <span className="text-sm text-cream/45">Noch kein Platz zugewiesen.</span> : null}
          {selected.map((slug) => {
            const c = bySlug.get(slug);
            return (
              <span
                key={slug}
                className="inline-flex items-center gap-2 rounded-lg border border-brass/50 bg-brass/[0.08] py-1.5 pl-3 pr-1.5 text-sm text-brass"
              >
                {c?.name ?? slug}
                <button
                  type="button"
                  onClick={() => setSelected((s) => s.filter((x) => x !== slug))}
                  className="rounded px-1.5 text-cream/60 hover:bg-white/10 hover:text-cream"
                  aria-label={`${c?.name ?? slug} entfernen`}
                >
                  ×
                </button>
              </span>
            );
          })}
        </div>
        <div className="relative mt-3">
          <input
            type="search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Platz suchen und hinzufügen …"
            className={field}
            aria-label="Platz suchen"
          />
          {matches.length ? (
            <ul className="absolute z-10 mt-1 max-h-72 w-full overflow-auto rounded-lg border border-white/10 bg-[#0b1d12] shadow-2xl">
              {matches.map((c) => (
                <li key={c.slug}>
                  <button
                    type="button"
                    onClick={() => {
                      setSelected((s) => [...s, c.slug]);
                      setQuery("");
                    }}
                    className="flex w-full items-center justify-between gap-3 px-4 py-2.5 text-left text-sm hover:bg-white/[0.05]"
                  >
                    <span className="min-w-0">
                      <span className="block truncate">{c.name}</span>
                      <span className="block truncate text-xs text-cream/45">{c.location}</span>
                    </span>
                    <span className="shrink-0 text-xs uppercase tracking-wider text-cream/40">
                      {c.kind === "golf" ? "Golf" : "Minigolf"}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          ) : null}
        </div>
      </section>

      <section>
        <h2 className="text-xs font-medium uppercase tracking-[0.14em] text-cream/55">Sichtbare Statistik</h2>
        <p className="mt-1 text-sm text-cream/50">
          Welche Bausteine der Betreiber sieht. Unter zehn Runden im Zeitraum sieht er in keinem Fall Zahlen.
        </p>
        <div className="mt-3 grid gap-2 sm:grid-cols-2">
          {OPERATOR_SECTIONS.map((s) => (
            <label
              key={s.id}
              className="flex cursor-pointer items-start gap-3 rounded-lg border border-white/10 bg-white/[0.02] p-3.5 transition-colors hover:border-white/20"
            >
              <input
                type="checkbox"
                name="permissions"
                value={s.id}
                defaultChecked={initial.permissions.includes(s.id)}
                className="mt-0.5 h-4 w-4 accent-[#c9a035]"
              />
              <span>
                <span className="block text-sm">{s.label}</span>
                <span className="block text-xs text-cream/45">{s.hint}</span>
              </span>
            </label>
          ))}
        </div>
      </section>

      <div className="flex flex-wrap items-center gap-4 border-t border-white/10 pt-6">
        <button
          type="submit"
          disabled={pending}
          className="rounded-lg bg-brass px-5 py-3 text-sm font-semibold text-night transition-colors hover:bg-brass-soft disabled:opacity-60"
        >
          {pending ? "Speichert …" : initial.id ? "Änderungen speichern" : "Konto anlegen"}
        </button>
        {state.status === "error" ? <span className="text-sm text-[#e07a63]">{state.message}</span> : null}
        {state.status === "ok" && initial.id ? <span className="text-sm text-brass">✓ {state.message}</span> : null}
      </div>
    </form>
  );
}
