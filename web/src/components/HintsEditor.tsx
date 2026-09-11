"use client";

import { useCallback, useState } from "react";
import type { CourseHint, HintKind } from "@/lib/schema";

/**
 * Die Hinweise einer Anlage – Toiletten, Unterstellhaus bei Gewitter und
 * Ähnliches. Sie stehen im App Clip an der Stelle, an der die volle App
 * Werbung zeigt; dort ist Werbung untersagt.
 *
 * Dieselbe Eingabe dient dem öffentlichen Formular (über `onChange`) und dem
 * Adminpanel (über das versteckte Feld `name`, das Server Actions auslesen).
 */

/** Reihenfolge im Auswahlfeld: das Häufigste zuerst. */
export const HINT_KINDS: HintKind[] = [
  "toilet",
  "shelter",
  "drinks",
  "food",
  "rental",
  "parking",
  "water",
  "firstAid",
  "info",
];

/** Nur fürs Auge im Browser – im Gerät zeichnet `CourseHintKind` SF Symbols. */
export const HINT_EMOJI: Record<HintKind, string> = {
  toilet: "🚻",
  shelter: "⛱️",
  drinks: "🥤",
  food: "🍽️",
  rental: "🏌️",
  parking: "🅿️",
  water: "🚰",
  firstAid: "⛑️",
  info: "ℹ️",
};

export interface HintLabels {
  add: string;
  remove: string;
  placeholder: string;
  kinds: Record<HintKind, string>;
}

export function HintsEditor({
  initial = [],
  labels,
  name,
  onChange,
  max = 12,
}: {
  initial?: CourseHint[];
  labels: HintLabels;
  /** Gesetzt im Adminpanel: schreibt den Stand als JSON in ein verstecktes Feld. */
  name?: string;
  onChange?: (hints: CourseHint[]) => void;
  max?: number;
}) {
  const [hints, setHints] = useState<CourseHint[]>(initial);

  const apply = useCallback(
    (next: CourseHint[]) => {
      setHints(next);
      onChange?.(next);
    },
    [onChange],
  );

  return (
    <div className="space-y-2">
      {hints.map((hint, index) => (
        <div key={index} className="flex items-center gap-2">
          <select
            className="field !w-auto shrink-0"
            value={hint.kind}
            aria-label={labels.kinds[hint.kind]}
            onChange={(event) =>
              apply(
                hints.map((entry, i) =>
                  i === index ? { ...entry, kind: event.target.value as HintKind } : entry,
                ),
              )
            }
          >
            {HINT_KINDS.map((kind) => (
              <option key={kind} value={kind}>
                {HINT_EMOJI[kind]} {labels.kinds[kind]}
              </option>
            ))}
          </select>
          <input
            className="field"
            value={hint.text}
            maxLength={140}
            placeholder={labels.placeholder}
            aria-label={labels.kinds[hint.kind]}
            onChange={(event) =>
              apply(
                hints.map((entry, i) => (i === index ? { ...entry, text: event.target.value } : entry)),
              )
            }
          />
          <button
            type="button"
            onClick={() => apply(hints.filter((_, i) => i !== index))}
            aria-label={labels.remove}
            title={labels.remove}
            className="tap grid h-11 w-11 shrink-0 place-items-center rounded-[3px] border border-current/25 opacity-60 transition-opacity hover:opacity-100"
          >
            <svg viewBox="0 0 24 24" aria-hidden className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M6 6l12 12M18 6L6 18" strokeLinecap="round" />
            </svg>
          </button>
        </div>
      ))}

      {hints.length < max ? (
        <button
          type="button"
          onClick={() => apply([...hints, { kind: "toilet", text: "" }])}
          className="tap min-h-11 rounded-full border border-current/25 px-4 text-xs opacity-75 transition-opacity hover:opacity-100"
        >
          + {labels.add}
        </button>
      ) : null}

      {name ? (
        // Server Actions lesen FormData – ein Feld, ein JSON-Wert.
        <input type="hidden" name={name} value={JSON.stringify(hints.filter((h) => h.text.trim()))} readOnly />
      ) : null}
    </div>
  );
}
