/**
 * Zusatzwertungen für eine Minigolfrunde – dieselben sechs wie in der App.
 *
 * Sie laufen neben der Schlagwertung: Die Runde gewinnt weiterhin, wer die
 * wenigsten Schläge braucht; pro eingeschaltetem Wettkampf gibt es zusätzlich
 * einen eigenen Sieger. Gewertet wird immer die komplette Karte, egal wann
 * jemand den Wettkampf dazugenommen hat.
 *
 * Eins zu eins übersetzt aus `GolfTrackShared/MinigolfChallenge.swift`. Wer
 * dort etwas an der Auswertung ändert, muss es hier nachziehen – sonst zählt
 * die Zählkarte im Browser anders als die in der App.
 */

export type ChallengeId = "streak" | "aces" | "holeWins" | "steady" | "comeback" | "finish";

/** Ab wie vielen Schlägen eine Bahn nicht mehr zur Serie zählt. */
const STREAK_LIMIT = 2;
/** Ab wie vielen Schlägen eine Bahn als Patzer gilt. */
const BLOW_UP_LIMIT = 4;
/** Wie viele Bahnen der Schlussspurt umfasst. */
const FINISH_HOLES = 3;

export interface Challenge {
  id: ChallengeId;
  name: string;
  /** Die Regel in einem Satz – steht in der Auswahl unter dem Namen. */
  rule: string;
  /** Einheit hinter dem Zahlenwert. */
  unit: string;
  trophy: string;
}

export const CHALLENGES: Challenge[] = [
  {
    id: "streak",
    name: "Serie",
    rule: "Wer schafft die längste Serie an Bahnen hintereinander mit höchstens 2 Schlägen?",
    unit: "in Folge",
    trophy: "🔥",
  },
  {
    id: "aces",
    name: "Ass-Jäger",
    rule: "Wer locht am häufigsten mit dem ersten Schlag ein?",
    unit: "Asse",
    trophy: "🎯",
  },
  {
    id: "holeWins",
    name: "Bahnenduell",
    rule: "Wer gewinnt die meisten Bahnen allein? Bei Gleichstand auf einer Bahn bekommt sie niemand.",
    unit: "Bahnen",
    trophy: "🏁",
  },
  {
    id: "steady",
    name: "Nervenstark",
    rule: "Wer leistet sich die wenigsten Patzer mit 4 Schlägen oder mehr?",
    unit: "Patzer",
    trophy: "🛡️",
  },
  {
    id: "comeback",
    name: "Aufholjagd",
    rule: "Wer spielt die zweite Hälfte am deutlichsten besser als die erste?",
    unit: "Schläge besser",
    trophy: "📈",
  },
  {
    id: "finish",
    name: "Schlussspurt",
    rule: "Wer braucht auf den letzten 3 Bahnen die wenigsten Schläge?",
    unit: "Schläge",
    trophy: "🚀",
  },
];

export function challengeById(id: string): Challenge | undefined {
  return CHALLENGES.find((c) => c.id === id);
}

export interface Standing {
  playerIndex: number;
  name: string;
  /** Sortierwert – größer ist immer besser, auch wo weniger besser ist (dann negativ). */
  rank: number;
  /** Der erreichte Wert, schon in Anzeigerichtung. */
  value: number;
  /** Zählt der Spieler überhaupt für die Wertung? */
  qualifies: boolean;
}

export interface ChallengeResult {
  challenge: Challenge;
  /** Alle Spieler, bester zuerst. */
  standings: Standing[];
  /** Führende (mehrere bei Gleichstand), leer solange niemand die Bedingung erfüllt. */
  leaders: Standing[];
  leaderNames: string;
  /** Wert der Führenden inklusive Einheit, z. B. „4 in Folge". */
  leaderValueText: string | null;
}

type Raw = { rank: number; value: number; qualifies: boolean };

/** Kleinster Sortierwert – steht für „zählt nicht". */
const NIE = Number.MIN_SAFE_INTEGER;

function streak(scores: number[][]): Raw[] {
  return scores.map((row) => {
    let best = 0;
    let current = 0;
    for (const s of row) {
      if (s > 0 && s <= STREAK_LIMIT) {
        current += 1;
        best = Math.max(best, current);
      } else {
        current = 0;
      }
    }
    return { rank: best, value: best, qualifies: best >= 2 };
  });
}

function aces(scores: number[][]): Raw[] {
  return scores.map((row) => {
    const count = row.filter((s) => s === 1).length;
    return { rank: count, value: count, qualifies: count > 0 };
  });
}

function holeWins(scores: number[][]): Raw[] {
  const holeCount = scores[0]?.length ?? 0;
  const wins = scores.map(() => 0);

  for (let hole = 0; hole < holeCount; hole += 1) {
    const strokes = scores.map((row) => row[hole]);
    // Nur vollständig gespielte Bahnen werden gewertet.
    if (!strokes.every((s) => s > 0)) continue;
    const best = Math.min(...strokes);
    const winners = strokes.flatMap((s, i) => (s === best ? [i] : []));
    // Geteilte Bahnen zählen für niemanden.
    if (winners.length === 1) wins[winners[0]] += 1;
  }

  return wins.map((w) => ({ rank: w, value: w, qualifies: w > 0 }));
}

function steady(scores: number[][]): Raw[] {
  return scores.map((row) => {
    const played = row.filter((s) => s > 0);
    const blowUps = played.filter((s) => s >= BLOW_UP_LIMIT).length;
    // Weniger ist besser → negativer Sortierwert.
    return { rank: -blowUps, value: blowUps, qualifies: played.length > 0 };
  });
}

function comeback(scores: number[][]): Raw[] {
  const holeCount = scores[0]?.length ?? 0;
  const half = Math.floor(holeCount / 2);
  if (half <= 0) return scores.map(() => ({ rank: 0, value: 0, qualifies: false }));

  return scores.map((row) => {
    const first = row.slice(0, half);
    const second = row.slice(row.length - half);
    // Nur vergleichbar, wenn beide Hälften komplett gespielt sind.
    if (!first.every((s) => s > 0) || !second.every((s) => s > 0)) {
      return { rank: NIE, value: 0, qualifies: false };
    }
    const summe = (xs: number[]) => xs.reduce((a, b) => a + b, 0);
    const gain = summe(first) - summe(second);
    return { rank: gain, value: gain, qualifies: gain > 0 };
  });
}

function finish(scores: number[][]): Raw[] {
  const holeCount = scores[0]?.length ?? 0;
  const count = Math.min(FINISH_HOLES, holeCount);
  if (count <= 0) return scores.map(() => ({ rank: 0, value: 0, qualifies: false }));

  return scores.map((row) => {
    const last = row.slice(row.length - count);
    if (!last.every((s) => s > 0)) return { rank: NIE, value: 0, qualifies: false };
    const total = last.reduce((a, b) => a + b, 0);
    // Weniger ist besser.
    return { rank: -total, value: total, qualifies: true };
  });
}

const RECHNER: Record<ChallengeId, (scores: number[][]) => Raw[]> = {
  streak,
  aces,
  holeWins,
  steady,
  comeback,
  finish,
};

/** Wertet einen Wettkampf über die bisherige Karte aus. `scores[spieler][bahn]`, 0 = offen. */
export function evaluate(
  challenge: Challenge,
  scores: number[][],
  names: string[],
): ChallengeResult {
  const roh = RECHNER[challenge.id](scores);

  const standings: Standing[] = roh
    .map((r, i) => ({
      playerIndex: i,
      name: names[i] ?? String(i + 1),
      rank: r.rank,
      value: r.value,
      qualifies: r.qualifies,
    }))
    .sort((a, b) => {
      if (a.qualifies !== b.qualifies) return a.qualifies ? -1 : 1;
      if (a.rank !== b.rank) return b.rank - a.rank;
      return a.playerIndex - b.playerIndex;
    });

  const best = standings.find((s) => s.qualifies);
  const leaders = best ? standings.filter((s) => s.qualifies && s.rank === best.rank) : [];

  return {
    challenge,
    standings,
    leaders,
    leaderNames: leaders.map((s) => s.name).join(", "),
    leaderValueText: leaders[0] ? `${leaders[0].value} ${challenge.unit}` : null,
  };
}

export function results(ids: string[], scores: number[][], names: string[]): ChallengeResult[] {
  return ids
    .map(challengeById)
    .filter((c): c is Challenge => Boolean(c))
    .map((c) => evaluate(c, scores, names));
}
