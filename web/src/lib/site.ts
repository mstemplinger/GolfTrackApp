/**
 * Betreiberangaben für Impressum, Datenschutz und Kontakt.
 *
 * Die Werte lassen sich über Umgebungsvariablen setzen, damit hier keine
 * privaten Daten im Repository liegen. Ohne gesetzte Variablen erscheinen
 * sichtbare Platzhalter – die Seite bleibt benutzbar, weist aber deutlich
 * darauf hin, dass noch etwas fehlt.
 */
export const PLACEHOLDER = "[bitte eintragen]";

export const site = {
  operator: process.env.NEXT_PUBLIC_OPERATOR_NAME ?? "Tobias Aufschläger",
  street: process.env.NEXT_PUBLIC_OPERATOR_STREET ?? PLACEHOLDER,
  city: process.env.NEXT_PUBLIC_OPERATOR_CITY ?? PLACEHOLDER,
  country: process.env.NEXT_PUBLIC_OPERATOR_COUNTRY ?? "Deutschland",
  email: process.env.NEXT_PUBLIC_CONTACT_EMAIL ?? PLACEHOLDER,
  phone: process.env.NEXT_PUBLIC_CONTACT_PHONE ?? "",
  vatId: process.env.NEXT_PUBLIC_VAT_ID ?? "",
  /** Datum der letzten inhaltlichen Änderung der Rechtstexte. */
  legalUpdated: "2026-08-30",
};

export function isPlaceholder(value: string): boolean {
  return value === PLACEHOLDER;
}
