"use client";

import { usePathname, useRouter } from "next/navigation";
import { useTransition } from "react";
import { choosePlayLang } from "@/app/(de)/p/actions";
import { PLAY_LANGS, PLAY_LANG_NAMES, type PlayLang } from "@/i18n/play";

/**
 * Sprachleiste des Spielbereichs: alle sieben Sprachen als Kürzel in einer
 * Reihe, gleich oben auf der Seite. Ein Menü wäre schmaler, aber wer die
 * Seite nicht lesen kann, findet „DE EN FR …" schneller als ein Symbol.
 *
 * Die Wahl landet im Cookie und gilt dann für alle Plätze. Danach wird die
 * Seite vom Server neu geholt – eine angefangene Zählkarte behält ihren
 * Stand, weil der im Browser liegt.
 */
export function PlayLangPicker({ lang, label }: { lang: PlayLang; label: string }) {
  const router = useRouter();
  const pathname = usePathname();
  const [pending, startTransition] = useTransition();

  function choose(next: PlayLang) {
    if (next === lang) return;
    startTransition(async () => {
      await choosePlayLang(next);
      // Ein `?lang=` in der Adresse würde die Wahl sonst gleich wieder überstimmen.
      router.replace(pathname, { scroll: false });
      router.refresh();
    });
  }

  return (
    <nav aria-label={label} className={`flex flex-wrap justify-center gap-1 ${pending ? "opacity-60" : ""}`}>
      {PLAY_LANGS.map((code) => {
        const active = code === lang;
        return (
          <button
            key={code}
            type="button"
            lang={code}
            title={PLAY_LANG_NAMES[code]}
            aria-label={PLAY_LANG_NAMES[code]}
            aria-pressed={active}
            onClick={() => choose(code)}
            className={`min-h-9 min-w-10 rounded-full px-2.5 font-mono text-xs uppercase tracking-[0.12em] transition-colors ${
              active ? "bg-brass/90 text-night" : "text-cream/55 hover:text-brass"
            }`}
          >
            {code}
          </button>
        );
      })}
    </nav>
  );
}
