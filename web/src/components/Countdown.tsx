"use client";

import { useEffect, useState } from "react";

/**
 * Zähler bis zur Freischaltung. Der Server gibt seine Uhrzeit mit, gerechnet
 * wird gegen sie – eine falsch gehende Uhr am Gerät zeigt sonst einen anderen
 * Rest. Bei null lädt die Seite neu; der Proxy liefert dann die echte Seite.
 */

const WORDS = {
  de: [
    ["Tag", "Tage"],
    ["Stunde", "Stunden"],
    ["Minute", "Minuten"],
    ["Sekunde", "Sekunden"],
  ],
  en: [
    ["Day", "Days"],
    ["Hour", "Hours"],
    ["Minute", "Minutes"],
    ["Second", "Seconds"],
  ],
} as const;

function parts(rest: number): number[] {
  const s = Math.max(0, Math.floor(rest / 1000));
  return [Math.floor(s / 86400), Math.floor((s % 86400) / 3600), Math.floor((s % 3600) / 60), s % 60];
}

export function Countdown({ target, serverNow, lang }: { target: number; serverNow: number; lang: "de" | "en" }) {
  const [rest, setRest] = useState(target - serverNow);

  useEffect(() => {
    const offset = serverNow - Date.now();
    let timer: ReturnType<typeof setTimeout>;
    let done = false;
    const tick = () => {
      const now = Date.now() + offset;
      const left = target - now;
      setRest(left);
      if (left <= 0) {
        if (!done) {
          done = true;
          timer = setTimeout(() => location.reload(), 1500);
        }
        return;
      }
      // Auf die volle Sekunde ausrichten, sonst springt die Anzeige ungleichmäßig.
      timer = setTimeout(tick, 1000 - (now % 1000) + 20);
    };
    tick();
    return () => clearTimeout(timer);
  }, [target, serverNow]);

  const values = parts(rest);
  return (
    <div
      role="timer"
      aria-label={lang === "de" ? "Zeit bis zur Freischaltung" : "Time until launch"}
      className="paper mx-auto grid w-full max-w-[34rem] grid-cols-4 overflow-hidden rounded-md"
    >
      {values.map((v, i) => (
        <div key={i} className={`flex flex-col items-center py-4 sm:py-5 ${i > 0 ? "border-l border-ink/15" : ""}`}>
          <span className="font-mono text-[2.1rem] font-medium leading-none tabular-nums text-ink sm:text-5xl">
            {String(v).padStart(2, "0")}
          </span>
          <span className="mt-2 text-[0.68rem] font-semibold uppercase tracking-[0.14em] text-ink/60 sm:text-xs">
            {WORDS[lang][i][v === 1 ? 0 : 1]}
          </span>
        </div>
      ))}
    </div>
  );
}
