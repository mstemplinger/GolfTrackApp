"use client";

import { useState } from "react";

export const MAX_HOLES = 36;

/**
 * Anzahl der Löcher bzw. Bahnen: Regler, Plus/Minus und ein Feld, das sich
 * auch leeren lässt, ohne sofort auf 1 zu springen. Mit `name` geht der Wert
 * als verstecktes Feld mit dem Formular mit.
 */
export function HoleCountInput({
  value,
  onChange,
  label,
  name,
}: {
  value: number;
  onChange: (count: number) => void;
  label: string;
  name?: string;
}) {
  const [draft, setDraft] = useState(String(value));
  const [last, setLast] = useState(value);
  // Wert von außen geändert (Regler, Knöpfe, Art der Anlage): Feld nachziehen.
  if (last !== value) {
    setLast(value);
    setDraft(String(value));
  }

  const commit = (count: number) => {
    const safe = Math.min(MAX_HOLES, Math.max(1, Math.round(count) || 1));
    setDraft(String(safe));
    onChange(safe);
  };

  const button =
    "tap grid h-11 w-11 shrink-0 place-items-center rounded-[3px] border border-ink/25 text-lg transition-colors hover:border-ink/50 hover:bg-ink/5 disabled:opacity-40";

  return (
    <div>
      {name ? <input type="hidden" name={name} value={value} /> : null}
      <div className="flex items-center gap-3">
        <button type="button" onClick={() => commit(value - 1)} disabled={value <= 1} aria-label="−1" className={button}>
          −
        </button>
        <input
          className="field w-20 text-center font-mono"
          type="number"
          inputMode="numeric"
          min={1}
          max={MAX_HOLES}
          value={draft}
          aria-label={label}
          onChange={(e) => {
            const raw = e.target.value;
            setDraft(raw);
            const parsed = Number(raw);
            if (raw.trim() && Number.isInteger(parsed) && parsed >= 1 && parsed <= MAX_HOLES) onChange(parsed);
          }}
          onBlur={() => commit(Number(draft))}
          required
        />
        <button
          type="button"
          onClick={() => commit(value + 1)}
          disabled={value >= MAX_HOLES}
          aria-label="+1"
          className={button}
        >
          +
        </button>
      </div>
      <input
        type="range"
        min={1}
        max={MAX_HOLES}
        step={1}
        value={value}
        onChange={(e) => commit(Number(e.target.value))}
        aria-label={label}
        className="mt-3 w-full max-w-md accent-[#28824b]"
      />
    </div>
  );
}
