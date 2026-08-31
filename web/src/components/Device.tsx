import Image from "next/image";
import type { Lang } from "@/i18n/routes";

/**
 * Bildschirmfotos aus der App, in einem Rahmen.
 *
 * Die Dateien liegen unter `public/app/<sprache>/` und stammen aus
 * `marketing/screenshots` (iPhone 17 Pro und Apple Watch Series 11, Simulator).
 * Auf 750 px Breite gerechnet – das reicht für die doppelte Auflösung der
 * größten Darstellung auf der Seite.
 *
 * Englisch gibt es nur für einen Teil der Aufnahmen; für alles andere greift
 * die deutsche Fassung. Die Watch-App hat keine Übersetzung, ihre Bilder sind
 * deshalb grundsätzlich deutsch.
 */

/** Aufnahmen, die es auch auf Englisch gibt. Rest fällt auf Deutsch zurück. */
const EN_SHOTS = new Set([
  "00-splash",
  "01-home",
  "06-statistiken-chart",
  "09-schlagkarte",
  "11-regel-diagramm",
  "12-training",
  "14-caddy-ki",
  "18-neue-runde",
  "19-live-scorecard",
]);

function source(shot: string, lang: Lang): string {
  const folder = lang === "en" && EN_SHOTS.has(shot) ? "en" : "de";
  return `/app/${folder}/${shot}.png`;
}

export function PhoneShot({
  shot,
  alt,
  lang,
  width = 300,
  priority = false,
  className = "",
}: {
  shot: string;
  alt: string;
  lang: Lang;
  /** Darstellungsbreite in Pixeln – bestimmt, welche Größe geliefert wird. */
  width?: number;
  priority?: boolean;
  className?: string;
}) {
  return (
    <span className={`phone ${className}`} style={{ width: `min(100%, ${width}px)` }}>
      <Image
        src={source(shot, lang)}
        alt={alt}
        width={750}
        height={1630}
        sizes={`(max-width: 47.99rem) 70vw, ${width}px`}
        priority={priority}
        quality={82}
      />
    </span>
  );
}

export function WatchShot({
  shot,
  alt,
  width = 220,
  className = "",
}: {
  shot: string;
  alt: string;
  width?: number;
  className?: string;
}) {
  return (
    <span className={`watch ${className}`} style={{ width: `min(100%, ${width}px)` }}>
      <Image src={`/app/de/${shot}.png`} alt={alt} width={416} height={496} sizes={`${width}px`} quality={88} />
    </span>
  );
}
