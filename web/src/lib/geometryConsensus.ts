/**
 * Reine Rechenlogik für die Crowd-Positionen (Abschlag/Grün je Loch) – ohne
 * Datenbank, damit sie sich mit `node` allein prüfen lässt
 * (`node deploy/check-geometry-consensus.mjs`).
 *
 * Aus vielen Einzelbeiträgen wird erst dann ein Wert, wenn genug unabhängige
 * Beiträge eng beieinander liegen. Ein einzelner Spieler – oder jemand, der
 * Unsinn schickt – verschiebt damit nichts.
 */

export interface GeoPoint {
  lat: number;
  lon: number;
}

export type GeometryKind = "tee" | "green";

/** Ab so vielen übereinstimmenden Beiträgen gilt ein Punkt als gesichert. */
export const MIN_CONTRIBUTORS = 5;

/** Beiträge, die weiter als das vom vorläufigen Median liegen, zählen nicht. */
export const OUTLIER_METERS: Record<GeometryKind, number> = { tee: 25, green: 35 };

/**
 * Höchstens so weit dürfen die verbleibenden Beiträge im Mittel (Median der
 * Abstände) vom Ergebnis entfernt liegen. Grüns streuen mehr, weil die Fahne
 * täglich woanders steckt und die Spieler um sie herum stehen.
 */
export const MAX_SPREAD_METERS: Record<GeometryKind, number> = { tee: 10, green: 15 };

/** Nur die jüngsten Beiträge je Punkt fließen ein (und bleiben gespeichert). */
export const MAX_CONTRIBUTIONS_PER_POINT = 30;

/** Beiträge, die weiter als das vom Platzmittelpunkt liegen, werden abgelehnt. */
export const MAX_DISTANCE_FROM_COURSE_METERS = 4000;

/**
 * Weicht der Crowd-Wert so weit von einer Angabe des Betreibers ab, wird das
 * als Widerspruch vermerkt – überschrieben wird die Angabe nicht.
 */
export const CONFLICT_METERS = 15;

/** Kleinere Verschiebungen schreibt der Server nicht zurück (kein Flattern). */
export const MIN_MOVE_METERS = 2;

/** Gleichheit zweier gespeicherter Werte (Rundung auf 5 Nachkommastellen ≈ 1 m). */
export const SAME_POINT_METERS = 1.5;

const EARTH_RADIUS = 6_371_000;
const rad = (deg: number) => (deg * Math.PI) / 180;

export function distanceMeters(a: GeoPoint, b: GeoPoint): number {
  const dLat = rad(b.lat - a.lat);
  const dLon = rad(b.lon - a.lon);
  const h =
    Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLon / 2) ** 2;
  return 2 * EARTH_RADIUS * Math.asin(Math.min(1, Math.sqrt(h)));
}

function median(values: number[]): number {
  const sorted = [...values].sort((x, y) => x - y);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

/** Komponentenweiser Median – robust gegen einzelne Ausreißer. */
export function medianPoint(points: GeoPoint[]): GeoPoint {
  return { lat: median(points.map((p) => p.lat)), lon: median(points.map((p) => p.lon)) };
}

/** Auf 5 Nachkommastellen (≈ 1 m) – genauer misst ein Handy-GPS ohnehin nicht. */
export function roundPoint(point: GeoPoint): GeoPoint {
  return { lat: Math.round(point.lat * 1e5) / 1e5, lon: Math.round(point.lon * 1e5) / 1e5 };
}

export interface Consensus {
  point: GeoPoint;
  /** Anzahl der Beiträge, die das Ergebnis tragen (ohne Ausreißer). */
  contributors: number;
  /** Median der Abstände der tragenden Beiträge zum Ergebnis, in Metern. */
  spreadMeters: number;
}

/**
 * Gemeinsamer Punkt aus den Beiträgen – oder `null`, solange es zu wenige
 * sind oder sie sich nicht einig sind.
 */
export function consensus(points: GeoPoint[], kind: GeometryKind): Consensus | null {
  if (points.length < MIN_CONTRIBUTORS) return null;
  const rough = medianPoint(points);
  const inliers = points.filter((p) => distanceMeters(p, rough) <= OUTLIER_METERS[kind]);
  if (inliers.length < MIN_CONTRIBUTORS) return null;
  const center = medianPoint(inliers);
  const spread = median(inliers.map((p) => distanceMeters(p, center)));
  if (spread > MAX_SPREAD_METERS[kind]) return null;
  return { point: roundPoint(center), contributors: inliers.length, spreadMeters: Math.round(spread * 10) / 10 };
}

/**
 * Was mit einem gesicherten Crowd-Wert geschieht, je nachdem, was am Loch
 * schon steht:
 *
 * - `apply`    – eintragen (Feld leer, vom Crowd-Verfahren selbst gesetzt, oder
 *                ein ungeprüfter Importwert, den die Crowd noch nie angefasst hat)
 * - `unchanged`– steht praktisch schon so da
 * - `conflict` – der Betreiber (oder der Admin) hat etwas anderes eingetragen,
 *                und es liegt deutlich daneben → nur vermerken
 * - `kept`     – Angabe des Betreibers, Crowd stimmt grob zu → nichts tun
 */
export type Decision = "apply" | "unchanged" | "conflict" | "kept";

export interface DecisionInput {
  consensus: GeoPoint;
  /** Was jetzt in `hole_data` steht. */
  current: GeoPoint | null;
  /** Was das Crowd-Verfahren zuletzt selbst eingetragen hat (falls je). */
  lastApplied: GeoPoint | null;
  /** Ob die Crowd an diesem Punkt schon einmal etwas entschieden hat. */
  seenBefore: boolean;
  /**
   * Stammen die Positionen des Platzes aus dem Formular des Betreibers
   * (Satellitenkarte)? Dann gelten sie als geprüft. Eingebaute und
   * importierte Plätze haben teils nur geschätzte Werte.
   */
  operatorProvided: boolean;
}

export function decide(input: DecisionInput): Decision {
  const { consensus: next, current, lastApplied, seenBefore, operatorProvided } = input;
  if (!current) return "apply";
  if (distanceMeters(current, next) < MIN_MOVE_METERS) return "unchanged";
  // Seit dem letzten Eintrag der Crowd unverändert → gehört der Crowd.
  if (lastApplied && distanceMeters(current, lastApplied) <= SAME_POINT_METERS) return "apply";
  // Ungeprüfter Importwert, noch nie von der Crowd berührt → ersetzen.
  // Hat ihn seitdem jemand von Hand geändert (lastApplied passt nicht mehr),
  // gilt er als geprüft.
  if (!operatorProvided && !seenBefore) return "apply";
  return distanceMeters(current, next) > CONFLICT_METERS ? "conflict" : "kept";
}
