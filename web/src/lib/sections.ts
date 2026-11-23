/**
 * Bausteine der Rundenstatistik, die einem Betreiberkonto einzeln
 * freigegeben werden können. Ohne Server-Abhängigkeiten, weil auch das
 * Formular im Adminpanel (Client) und die Darstellung sie brauchen.
 */
export const OPERATOR_SECTIONS = [
  { id: "kennzahlen", label: "Kennzahlen", hint: "Runden, Spieldauer, Gruppengröße" },
  { id: "verlauf", label: "Runden pro Woche", hint: "Verlauf über den gewählten Zeitraum" },
  { id: "stosszeiten", label: "Stoßzeiten", hint: "Wochentag × Tageszeit" },
  { id: "schwierigkeit", label: "Schwierigkeit je Loch/Bahn", hint: "Ø Schläge, über Par, Putts, Hole-in-one" },
  { id: "warnungen", label: "Warnhinweise", hint: "Bahn plötzlich schwerer – vielleicht beschädigt" },
  { id: "abschlaege", label: "Abschläge und Länge", hint: "Abschlagfarben (Golf), gespielte Länge" },
] as const;

export type OperatorSection = (typeof OPERATOR_SECTIONS)[number]["id"];
export const ALL_SECTIONS: OperatorSection[] = OPERATOR_SECTIONS.map((s) => s.id);

export function isSection(v: unknown): v is OperatorSection {
  return typeof v === "string" && (ALL_SECTIONS as string[]).includes(v);
}
