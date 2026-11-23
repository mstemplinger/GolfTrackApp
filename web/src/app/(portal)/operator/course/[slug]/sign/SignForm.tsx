"use client";

import { useEffect, useState } from "react";

/**
 * Sprachen wählen, Aushang als PDF laden – ein schlichtes GET-Formular auf
 * `/qr/<kennung>/aushang` (liegt außerhalb des Proxys, geht also auch auf der
 * Portal-Subdomain). Das PDF baut der Server mit Headless-Chrome, das dauert
 * ein paar Sekunden; solange steht am Knopf, dass etwas passiert.
 */
export function SignForm({
  slug,
  languages,
  preselected,
  names,
  copy,
}: {
  slug: string;
  languages: readonly string[];
  preselected: string[];
  names: Record<string, string>;
  copy: { languages: string; languagesHint: string; download: string; preparing: string };
}) {
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!busy) return;
    // Der Download beendet die Seite nicht – nach einer Weile wieder freigeben.
    const timer = setTimeout(() => setBusy(false), 8000);
    return () => clearTimeout(timer);
  }, [busy]);

  return (
    <form action={`/qr/${slug}/aushang`} method="get" onSubmit={() => setBusy(true)}>
      <fieldset>
        <legend className="text-sm font-medium text-cream/80">{copy.languages}</legend>
        <div className="mt-3 flex flex-wrap gap-2">
          {languages.map((code) => (
            <label
              key={code}
              className="inline-flex min-h-11 cursor-pointer items-center gap-2 rounded-full border border-white/15 px-3.5 text-sm text-cream/75 transition-colors hover:border-white/30 has-[:checked]:border-brass has-[:checked]:bg-brass has-[:checked]:text-night has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-brass/60"
            >
              <input
                type="checkbox"
                name="sprache"
                value={code}
                defaultChecked={preselected.includes(code)}
                className="sr-only"
              />
              <span className="font-mono text-xs font-semibold">{code.toUpperCase()}</span>
              <span>{names[code] ?? code}</span>
            </label>
          ))}
        </div>
      </fieldset>
      <p className="mt-3 text-xs leading-relaxed text-cream/50">{copy.languagesHint}</p>
      <button
        type="submit"
        disabled={busy}
        className="mt-5 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-lg bg-brass px-5 font-semibold text-night transition-colors hover:bg-brass-soft disabled:opacity-70 sm:w-auto"
      >
        <svg aria-hidden viewBox="0 0 20 20" className="size-4" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M10 3v10m0 0-4-4m4 4 4-4M4 16h12" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
        {busy ? copy.preparing : copy.download}
      </button>
    </form>
  );
}
