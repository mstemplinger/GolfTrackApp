"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useState } from "react";
import { Icon } from "../ui";

const SORTS = [
  { value: "neu", label: "Neueste zuerst" },
  { value: "alt", label: "Älteste zuerst" },
  { value: "name", label: "Name A–Z" },
];

/** Suchfeld und Sortierung – schreiben in die Adresse, die Seite filtert auf dem Server. */
export function SearchBar() {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const [q, setQ] = useState(params.get("q") ?? "");

  function go(changes: Record<string, string>) {
    const next = new URLSearchParams(params.toString());
    for (const [k, v] of Object.entries(changes)) {
      if (v) next.set(k, v);
      else next.delete(k);
    }
    next.delete("seite");
    router.push(`${pathname}${next.size ? `?${next}` : ""}`);
  }

  return (
    <form
      className="flex flex-col gap-3 sm:flex-row"
      onSubmit={(e) => {
        e.preventDefault();
        go({ q: q.trim() });
      }}
    >
      <label className="relative flex-1">
        <span className="sr-only">Anlagen durchsuchen</span>
        <Icon
          name="search"
          className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-cream/40"
        />
        <input
          type="search"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Name, Ort, Kennung oder E-Mail suchen …"
          className="w-full rounded-lg border border-white/10 bg-white/[0.03] py-3 pl-11 pr-4 text-sm text-cream placeholder:text-cream/40 focus:border-brass/60 focus:outline-none"
        />
      </label>
      <select
        aria-label="Sortierung"
        value={params.get("sort") ?? "neu"}
        onChange={(e) => go({ sort: e.target.value === "neu" ? "" : e.target.value })}
        className="rounded-lg border border-white/10 bg-white/[0.03] px-4 py-3 text-sm text-cream focus:border-brass/60 focus:outline-none sm:w-52"
      >
        {SORTS.map((s) => (
          <option key={s.value} value={s.value} className="bg-night">
            {s.label}
          </option>
        ))}
      </select>
    </form>
  );
}
