/**
 * Abschlagfarben – ohne zod, damit Client-Komponenten sie einbinden können.
 * Reihenfolge = Anzeigereihenfolge. Die Werte stehen genauso in der iOS-App;
 * wer hier etwas ergänzt, muss es dort ebenfalls tun.
 */
export const TEE_COLORS = ["black", "white", "gold", "blue", "yellow", "red", "orange", "green"] as const;

export type TeeColor = (typeof TEE_COLORS)[number];

/** Deutsche Bezeichnung und Farbpunkt je Abschlagfarbe. */
export const TEE_META: Record<TeeColor, { label: string; swatch: string }> = {
  black: { label: "Schwarz", swatch: "#1c1c1c" },
  white: { label: "Weiß", swatch: "#f5f5f5" },
  gold: { label: "Gold", swatch: "#d4af37" },
  blue: { label: "Blau", swatch: "#2f6fde" },
  yellow: { label: "Gelb", swatch: "#f2c230" },
  red: { label: "Rot", swatch: "#d93a3a" },
  orange: { label: "Orange", swatch: "#f08a24" },
  green: { label: "Grün", swatch: "#2e9e4f" },
};

export const isTeeColor = (value: unknown): value is TeeColor =>
  typeof value === "string" && (TEE_COLORS as readonly string[]).includes(value);
