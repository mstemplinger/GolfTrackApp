/**
 * Freischaltung der Website. Bis dahin zeigt jede Marketingseite den Zähler
 * (`/bald`, englisch `/en/soon`); danach lässt der Proxy alles durch, ohne
 * dass jemand etwas umstellen muss.
 *
 * Verlängert am 2026-10-31 (ursprünglich 1. November 2026, wie toob360.com):
 * Mittwoch, 1. Dezember 2027, 00:00 Uhr
 * deutscher Zeit (dann noch Winterzeit, also UTC+1).
 */
export const LAUNCH_AT = Date.parse("2027-12-01T00:00:00+01:00");

export function launched(now: number = Date.now()): boolean {
  return now >= LAUNCH_AT;
}
