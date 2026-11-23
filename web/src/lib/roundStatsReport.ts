import "server-only";
import { query } from "./db";
import { ensureSchema } from "./migrations";
import { MIN_ROUNDS_FOR_DISPLAY, SLOTS } from "./roundStats";

/**
 * Auswertung der anonymen Rundenstatistik (`round_stats`) – zuerst nur für das
 * Adminpanel, später Grundlage für die Betreiber-Seite. Golf und Minigolf
 * teilen dieselbe Auswertung; Putts und Abschlagfarben gibt es nur bei Golf.
 *
 * Gerechnet wird in JS über die Zeilen eines Platzes und Zeitraums – bei ein
 * paar tausend Runden je Platz und Jahr ist das schneller geschrieben als SQL
 * und schnell genug.
 */

export type Kind = "golf" | "minigolf";
export type Slot = (typeof SLOTS)[number];

export interface CourseOverviewRow {
  slug: string;
  name: string;
  location: string;
  kind: Kind;
  rounds: number;
  rounds30: number;
  lastPlayed: string | null;
}

/** Alle Plätze, für die schon Runden gemeldet wurden – meiste zuerst. */
export async function listCoursesWithStats(): Promise<CourseOverviewRow[]> {
  await ensureSchema();
  const rows = await query<{
    course_slug: string;
    kind: string;
    rounds: string;
    rounds30: string;
    last_played: string | Date | null;
    name: string | null;
    location: string | null;
  }>(
    `SELECT r.course_slug, r.kind,
            count(*)                                                   AS rounds,
            count(*) FILTER (WHERE r.played_on >= current_date - 30)   AS rounds30,
            max(r.played_on)                                           AS last_played,
            c.name, c.location
       FROM round_stats r
       LEFT JOIN courses c ON c.slug = r.course_slug
      GROUP BY r.course_slug, r.kind, c.name, c.location
      ORDER BY count(*) DESC`,
  );
  return rows.map((r) => ({
    slug: r.course_slug,
    name: r.name ?? r.course_slug,
    location: r.location ?? "",
    kind: r.kind as Kind,
    rounds: Number(r.rounds),
    rounds30: Number(r.rounds30),
    lastPlayed: toDay(r.last_played),
  }));
}

/** Runden der letzten `days` Tage je Platz – für die Platzauswahl der Betreiber. */
export async function roundCounts(slugs: string[], days: number): Promise<Map<string, number>> {
  const result = new Map(slugs.map((s) => [s, 0]));
  if (!slugs.length) return result;
  await ensureSchema();
  const rows = await query<{ course_slug: string; total: string }>(
    `SELECT course_slug, COUNT(*) AS total FROM round_stats
      WHERE course_slug = ANY($1) AND played_on >= current_date - $2::int
      GROUP BY course_slug`,
    [slugs, days],
  );
  for (const r of rows) result.set(r.course_slug, Number(r.total));
  return result;
}

export interface HoleStat {
  hole: number;
  par: number | null;
  /** Ø Schläge je Spieler, nur gespielte (>0). */
  avgStrokes: number | null;
  /** Ø Schläge über Par (Golf mit Par-Angabe). */
  overPar: number | null;
  /** Ø Putts (nur Golf mit Putt-Angabe). */
  avgPutts: number | null;
  /** Anteil Hole-in-one (Minigolf). */
  aceRate: number | null;
  samples: number;
  /** Auffällig schwerer als zuvor – Hinweis auf eine beschädigte Bahn. */
  anomaly: { recent: number; before: number } | null;
}

export interface CourseReport {
  kind: Kind;
  days: number;
  rounds: number;
  players: number;
  avgGroup: number | null;
  medianDuration: number | null;
  durationSamples: number;
  /** Runden je Woche (Montag als Wochenbeginn), älteste zuerst. */
  weeks: { start: string; rounds: number }[];
  /** heatmap[slot][weekday-1] */
  heatmap: number[][];
  sources: Record<string, number>;
  holesPlayed: Record<string, number>;
  teeColors: Record<string, number>;
  holes: HoleStat[];
  /** Unter der Schwelle sähe ein Betreiber nichts. */
  belowThreshold: boolean;
}

interface Row {
  played_on: string | Date;
  slot: string;
  weekday: number;
  holes_played: number;
  duration_min: number | null;
  tee_color: string;
  players: number;
  strokes: number[][] | string;
  putts: number[][] | string | null;
  source: string;
}

const ANOMALY_RECENT_DAYS = 14;
const ANOMALY_MIN_SAMPLES = 10;
const ANOMALY_DELTA = 0.8;

export async function courseReport(slug: string, days: number, pars: (number | null)[]): Promise<CourseReport | null> {
  await ensureSchema();
  const rows = await query<Row & Record<string, unknown>>(
    `SELECT played_on, slot, weekday, holes_played, duration_min, tee_color, players, strokes, putts, source, kind
       FROM round_stats
      WHERE course_slug = $1 AND played_on >= current_date - $2::int
      ORDER BY played_on`,
    [slug, days],
  );
  if (!rows.length) return null;
  const kind = (rows[0] as unknown as { kind: Kind }).kind;

  const parse = <T,>(v: T | string | null): T | null => (typeof v === "string" ? (JSON.parse(v) as T) : v);
  const today = new Date();
  const recentFrom = dayString(new Date(today.getTime() - ANOMALY_RECENT_DAYS * 86_400_000));

  let players = 0;
  const durations: number[] = [];
  const heatmap = SLOTS.map(() => Array.from({ length: 7 }, () => 0));
  const sources: Record<string, number> = {};
  const holesPlayed: Record<string, number> = {};
  const teeColors: Record<string, number> = {};
  const weekMap = new Map<string, number>();

  type Acc = { sum: number; n: number; puttSum: number; puttN: number; aces: number; overSum: number; overN: number;
               recentSum: number; recentN: number; beforeSum: number; beforeN: number };
  const acc: Acc[] = [];
  const holeAcc = (i: number) =>
    (acc[i] ??= { sum: 0, n: 0, puttSum: 0, puttN: 0, aces: 0, overSum: 0, overN: 0, recentSum: 0, recentN: 0, beforeSum: 0, beforeN: 0 });

  for (const r of rows) {
    const day = toDay(r.played_on)!;
    players += r.players;
    if (r.duration_min) durations.push(r.duration_min);
    const slotIndex = SLOTS.indexOf(r.slot as Slot);
    if (slotIndex >= 0 && r.weekday >= 1 && r.weekday <= 7) heatmap[slotIndex][r.weekday - 1] += 1;
    sources[r.source] = (sources[r.source] ?? 0) + 1;
    const bucket = r.holes_played >= 18 ? "18" : r.holes_played >= 9 ? "9–17" : "unter 9";
    holesPlayed[bucket] = (holesPlayed[bucket] ?? 0) + 1;
    if (kind === "golf") {
      const color = r.tee_color || "unbekannt";
      teeColors[color] = (teeColors[color] ?? 0) + 1;
    }
    const week = weekStart(day);
    weekMap.set(week, (weekMap.get(week) ?? 0) + 1);

    const strokes = parse<number[][]>(r.strokes) ?? [];
    const putts = parse<number[][]>(r.putts);
    const recent = day >= recentFrom;
    strokes.forEach((row, p) => {
      row.forEach((s, i) => {
        if (s <= 0) return;
        const a = holeAcc(i);
        a.sum += s;
        a.n += 1;
        if (s === 1) a.aces += 1;
        const par = pars[i];
        if (par) {
          a.overSum += s - par;
          a.overN += 1;
        }
        const pt = putts?.[p]?.[i];
        if (pt && pt > 0) {
          a.puttSum += pt;
          a.puttN += 1;
        }
        if (recent) {
          a.recentSum += s;
          a.recentN += 1;
        } else {
          a.beforeSum += s;
          a.beforeN += 1;
        }
      });
    });
  }

  const holes: HoleStat[] = acc.map((a, i) => {
    const recent = a.recentN >= ANOMALY_MIN_SAMPLES ? a.recentSum / a.recentN : null;
    const before = a.beforeN >= ANOMALY_MIN_SAMPLES ? a.beforeSum / a.beforeN : null;
    return {
      hole: i + 1,
      par: pars[i] ?? null,
      avgStrokes: a.n ? a.sum / a.n : null,
      overPar: a.overN ? a.overSum / a.overN : null,
      avgPutts: a.puttN ? a.puttSum / a.puttN : null,
      aceRate: kind === "minigolf" && a.n ? a.aces / a.n : null,
      samples: a.n,
      anomaly: recent != null && before != null && recent - before >= ANOMALY_DELTA ? { recent, before } : null,
    };
  });

  // Lückenlose Wochenreihe vom ersten bis zum aktuellen Montag.
  const weeks: { start: string; rounds: number }[] = [];
  const firstWeek = weekStart(toDay(rows[0].played_on)!);
  for (let w = firstWeek; w <= weekStart(dayString(today)); w = addDays(w, 7)) {
    weeks.push({ start: w, rounds: weekMap.get(w) ?? 0 });
  }

  return {
    kind,
    days,
    rounds: rows.length,
    players,
    avgGroup: rows.length ? players / rows.length : null,
    medianDuration: median(durations),
    durationSamples: durations.length,
    weeks,
    heatmap,
    sources,
    holesPlayed,
    teeColors,
    holes,
    belowThreshold: rows.length < MIN_ROUNDS_FOR_DISPLAY,
  };
}

// MARK: – Hilfen

function toDay(v: string | Date | null): string | null {
  if (v == null) return null;
  if (v instanceof Date) return dayString(v);
  return String(v).slice(0, 10);
}

function dayString(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

function addDays(day: string, n: number): string {
  const d = new Date(`${day}T12:00:00`);
  d.setDate(d.getDate() + n);
  return dayString(d);
}

/** Montag der Woche, in der `day` liegt. */
function weekStart(day: string): string {
  const d = new Date(`${day}T12:00:00`);
  const offset = (d.getDay() + 6) % 7;
  return addDays(day, -offset);
}

function median(values: number[]): number | null {
  if (!values.length) return null;
  const s = [...values].sort((a, b) => a - b);
  const mid = Math.floor(s.length / 2);
  return s.length % 2 ? s[mid] : (s[mid - 1] + s[mid]) / 2;
}
