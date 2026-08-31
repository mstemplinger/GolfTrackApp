import { DM_Mono, Fraunces, Instrument_Sans } from "next/font/google";

/** Display: eine warme, leicht eigenwillige Serif – wie ein graviertes Clubschild. */
export const fraunces = Fraunces({
  subsets: ["latin"],
  variable: "--font-fraunces",
  axes: ["SOFT", "WONK", "opsz"],
  display: "swap",
});

export const instrument = Instrument_Sans({
  subsets: ["latin"],
  variable: "--font-instrument",
  display: "swap",
});

/** Zahlen auf der Scorekarte laufen tabellarisch. */
export const dmMono = DM_Mono({
  subsets: ["latin"],
  weight: ["400", "500"],
  variable: "--font-dm-mono",
  display: "swap",
});

export const fontVariables = `${fraunces.variable} ${instrument.variable} ${dmMono.variable}`;
