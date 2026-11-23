/**
 * Druckwerbung, die ein Golfplatz auf `/werbung/golfplatz` anfragen kann.
 * Eigene Datei, weil Formular (Client) und Mail (Server) dieselbe Liste
 * brauchen und `printRequests.ts` nur auf dem Server läuft.
 */
export const PRINT_ITEMS = [
  "saeule-golf",
  "saeule-minigolf",
  "saeule-lernen",
  "plane-abschlag",
  "plane-range",
  "plakate",
] as const;
export type PrintItem = (typeof PRINT_ITEMS)[number];

export const PRINT_ITEM_LABEL: Record<PrintItem, string> = {
  "saeule-golf": "Werbesäule Golf · 60 × 200 cm",
  "saeule-minigolf": "Werbesäule Minigolf · 60 × 180 cm",
  "saeule-lernen": "Werbesäule Golf lernen · 50 × 155 cm",
  "plane-abschlag": "Bauzaunplane Abschlag · 340 × 173 cm",
  "plane-range": "Bauzaunplane Driving Range · 340 × 173 cm",
  plakate: "Plakate und Flyer fürs Clubhaus",
};
