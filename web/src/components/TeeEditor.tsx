"use client";

import { TEE_COLORS, TEE_META, type TeeColor } from "@/lib/tees";

/** Ein gewählter Abschlag im Formular – Wertungen als Text, wie die übrigen Felder. */
export interface TeeRow {
  color: TeeColor;
  courseRating: string;
  slopeRating: string;
}

/** Farbpunkt eines Abschlags. Weiß bekommt einen Rand, sonst verschwindet er auf Papier. */
export function TeeDot({ color, className = "h-3 w-3" }: { color: TeeColor; className?: string }) {
  return (
    <span
      aria-hidden
      className={`inline-block shrink-0 rounded-full border border-black/25 ${className}`}
      style={{ background: TEE_META[color].swatch }}
    />
  );
}

interface Labels {
  colors: Record<TeeColor, string>;
  courseRating: string;
  slopeRating: string;
}

/**
 * Abschlagfarben wählen (Chips) und je Farbe optional CR/Slope eintragen.
 * Neue Farben reihen sich in die feste Anzeigereihenfolge ein.
 */
export function TeeEditor({
  value,
  onChange,
  labels,
}: {
  value: TeeRow[];
  onChange: (next: TeeRow[]) => void;
  labels: Labels;
}) {
  const selected = new Set(value.map((tee) => tee.color));

  const toggle = (color: TeeColor) => {
    if (selected.has(color)) {
      onChange(value.filter((tee) => tee.color !== color));
      return;
    }
    const next = [...value, { color, courseRating: "", slopeRating: "" }];
    next.sort((a, b) => TEE_COLORS.indexOf(a.color) - TEE_COLORS.indexOf(b.color));
    onChange(next);
  };

  const setValue = (color: TeeColor, key: "courseRating" | "slopeRating", text: string) =>
    onChange(value.map((tee) => (tee.color === color ? { ...tee, [key]: text } : tee)));

  return (
    <div>
      <div className="flex flex-wrap gap-2" role="group">
        {TEE_COLORS.map((color) => {
          const on = selected.has(color);
          return (
            <button
              key={color}
              type="button"
              onClick={() => toggle(color)}
              aria-pressed={on}
              className={`tap flex min-h-11 items-center gap-2 rounded-full border px-4 text-sm transition-colors ${
                on ? "border-fairway bg-fairway/10 font-medium" : "border-ink/20 text-ink/75 hover:border-ink/40"
              }`}
            >
              <TeeDot color={color} />
              {labels.colors[color]}
            </button>
          );
        })}
      </div>

      {value.length ? (
        <div className="mt-4 space-y-2">
          {value.map((tee) => (
            <div key={tee.color} className="grid grid-cols-[7rem_1fr_1fr] items-center gap-2 sm:grid-cols-[9rem_10rem_10rem]">
              <span className="flex items-center gap-2 text-sm">
                <TeeDot color={tee.color} />
                {labels.colors[tee.color]}
              </span>
              <input
                className="field field--tight !py-1.5 font-mono"
                value={tee.courseRating}
                onChange={(e) => setValue(tee.color, "courseRating", e.target.value)}
                placeholder="CR 71,4"
                inputMode="decimal"
                aria-label={`${labels.courseRating} ${labels.colors[tee.color]}`}
              />
              <input
                className="field field--tight !py-1.5 font-mono"
                value={tee.slopeRating}
                onChange={(e) => setValue(tee.color, "slopeRating", e.target.value)}
                placeholder="Slope 130"
                inputMode="numeric"
                aria-label={`${labels.slopeRating} ${labels.colors[tee.color]}`}
              />
            </div>
          ))}
        </div>
      ) : null}
    </div>
  );
}

/** Text → Zahl oder `null`; Komma als Dezimaltrenner erlaubt. */
export function teeNumber(value: string): number | null {
  const trimmed = value.trim().replace(",", ".");
  if (!trimmed) return null;
  const parsed = Number(trimmed);
  return Number.isFinite(parsed) ? parsed : null;
}
