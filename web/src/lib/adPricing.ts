/**
 * Preis einer Umkreisbuchung. Läuft im Formular (live beim Ziehen des Kreises)
 * und auf dem Server (beim Absenden, als Richtwert für das Adminpanel) – beide
 * rechnen mit genau diesen Zahlen, deshalb ohne `server-only`.
 *
 * Bezahlt wird pro Platz, den der Umkreis trifft: Das ist, was der Werbende
 * bekommt. Plätze außerhalb jedes Umkreises erhalten zwar die Anzeige des
 * nächstgelegenen Umkreises (siehe `AdCatalogService` in der App), kosten aber
 * nichts – das hängt davon ab, wer sonst noch bucht, und lässt sich beim
 * Ausfüllen nicht zusagen.
 *
 * Alle Beträge netto in Cent.
 */

/** Pro Monat je Golfplatz im Umkreis. */
export const GOLF_COURSE_MONTHLY_CENTS = 800;
/** Pro Monat je Minigolfanlage im Umkreis. */
export const MINIGOLF_COURSE_MONTHLY_CENTS = 500;
/** Darunter lohnt die Rückfrage per Mail nicht. */
export const MINIMUM_MONTHLY_CENTS = 1900;

/** Rabatt nach Laufzeit – ab dieser Monatszahl gilt der Satz. */
export const DURATION_DISCOUNTS: { months: number; percent: number }[] = [
  { months: 12, percent: 25 },
  { months: 6, percent: 15 },
  { months: 3, percent: 10 },
];

export interface AdQuote {
  golf: number;
  minigolf: number;
  /** Monatspreis vor Rabatt, mindestens `MINIMUM_MONTHLY_CENTS`. */
  monthlyCents: number;
  discountPercent: number;
  /** Monatspreis nach Rabatt. */
  monthlyDiscountedCents: number;
  months: number;
  totalCents: number;
}

export function discountFor(months: number): number {
  return DURATION_DISCOUNTS.find((step) => months >= step.months)?.percent ?? 0;
}

export function quoteAd(golf: number, minigolf: number, months: number): AdQuote {
  const raw = golf * GOLF_COURSE_MONTHLY_CENTS + minigolf * MINIGOLF_COURSE_MONTHLY_CENTS;
  const monthlyCents = Math.max(MINIMUM_MONTHLY_CENTS, raw);
  const discountPercent = discountFor(months);
  // Auf volle Euro abrunden – krumme Centbeträge wirken wie aus dem Taschenrechner.
  const monthlyDiscountedCents = Math.floor((monthlyCents * (100 - discountPercent)) / 100 / 100) * 100;
  return {
    golf,
    minigolf,
    monthlyCents,
    discountPercent,
    monthlyDiscountedCents,
    months,
    totalCents: monthlyDiscountedCents * months,
  };
}

export function formatEuro(cents: number): string {
  return new Intl.NumberFormat("de-DE", {
    style: "currency",
    currency: "EUR",
    minimumFractionDigits: cents % 100 === 0 ? 0 : 2,
  }).format(cents / 100);
}
