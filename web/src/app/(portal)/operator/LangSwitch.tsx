"use client";

import { useTransition } from "react";
import type { OperatorLang } from "@/i18n/operator";
import { setOperatorLang } from "./actions";

/** DE | EN – merkt die Wahl im Cookie und lädt die Seite neu. */
export function LangSwitch({ lang }: { lang: OperatorLang }) {
  const [pending, start] = useTransition();
  return (
    <div className="flex rounded-lg border border-white/10 p-0.5 text-xs" role="group" aria-label="Sprache / Language">
      {(["de", "en"] as const).map((l) => (
        <button
          key={l}
          type="button"
          disabled={pending || l === lang}
          aria-pressed={l === lang}
          onClick={() =>
            start(async () => {
              await setOperatorLang(l);
              window.location.reload();
            })
          }
          className={`rounded-md px-2.5 py-1 uppercase tracking-wider transition-colors ${
            l === lang ? "bg-brass text-night" : "text-cream/60 hover:text-brass"
          }`}
        >
          {l}
        </button>
      ))}
    </div>
  );
}
