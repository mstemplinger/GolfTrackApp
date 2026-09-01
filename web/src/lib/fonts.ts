import { DM_Mono, Instrument_Sans, Manrope } from "next/font/google";

/**
 * Display: Manrope, geometrischer Grotesk mit kräftigem Fettschnitt.
 *
 * Vorher stand hier Fraunces, eine warme Old-Style-Serife. Die passte weder
 * zur App – deren Oberfläche ist durchgehend serifenlos – noch zum eigenen
 * Logo, dessen Wortmarke ebenfalls ein geometrischer Grotesk ist. Große
 * Überschriften laufen deshalb jetzt in derselben Formensprache wie das
 * Zeichen darüber.
 */
export const manrope = Manrope({
  subsets: ["latin"],
  variable: "--font-manrope",
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

export const fontVariables = `${manrope.variable} ${instrument.variable} ${dmMono.variable}`;
