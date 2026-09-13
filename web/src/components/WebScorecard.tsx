"use client";

import { useEffect, useState, useSyncExternalStore } from "react";
import type { CourseKind } from "@/lib/schema";
import { CHALLENGES, results as challengeResults, type ChallengeResult } from "@/lib/minigolfChallenges";

/**
 * Mitzählen im Browser – für alle, die weder App noch App Clip bekommen:
 * Android, Rechner, und iPhones, deren Besitzer die Clip-Karte weggewischt
 * haben.
 *
 * Die laufende Runde nimmt den ganzen Bildschirm ein und sieht aus wie die
 * Zählkarte in der App: dieselben Farben, dieselbe Anordnung, dieselben
 * Knöpfe. Wer den Code am Abschlag scannt, soll nicht merken, auf welchem
 * der drei Wege er gerade zählt.
 *
 * Der Stand liegt im `localStorage` des Geräts, damit eine unterbrochene
 * Runde nicht verloren ist. Was hier fehlt – Laufspur, Statistik über alle
 * Runden, Uhr – ist genau das, wofür es die App gibt.
 */

const MAX_PLAYERS = 8;
const MAX_STROKES = 20;

/** Die Farben aus `GolfTrackShared/AppTheme.swift`, damit es wirkt wie die App. */
const APP = {
  bg: "#0E2718",
  card: "#163421",
  cardAlt: "#1C4129",
  gold: "#C9A035",
  ink: "#17251c",
};

interface SavedRound {
  players: string[];
  scores: number[][];
  hole: number;
  finished: boolean;
  /** Eingeschaltete Wettkämpfe. Fehlt bei Runden von vor der Einführung. */
  challenges?: string[];
}

/** Wie viele Namensfelder am Anfang dastehen. */
function emptyNames(kind: CourseKind): string[] {
  return kind === "golf" ? [""] : ["", ""];
}

/**
 * Gespeicherte Runde lesen. Läuft auch beim ersten Rendern im Browser, nicht
 * erst in einem Effekt – sonst blitzt die leere Aufstellung auf, bevor der
 * Stand zurückkommt.
 */
function loadSaved(key: string, holes: number): SavedRound | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(key);
    if (!raw) return null;
    const saved = JSON.parse(raw) as SavedRound;
    if (
      !Array.isArray(saved.players) ||
      !Array.isArray(saved.scores) ||
      !saved.scores.every((row) => Array.isArray(row) && row.length === holes)
    ) {
      return null;
    }
    return saved;
  } catch {
    // Privater Modus oder beschädigter Eintrag: dann eben ohne Fortsetzen.
    return null;
  }
}

/**
 * Erst nach dem Anhängen an das serverseitig gelieferte Markup darf
 * abweichen, was der Browser aus seinem Speicher kennt. Bis dahin zeigen
 * Server und Browser dasselbe, sonst beschwert sich React über den
 * Unterschied.
 */
function useHydrated(): boolean {
  return useSyncExternalStore(
    () => () => {},
    () => true,
    () => false,
  );
}

export function WebScorecard({
  slug,
  kind,
  holes,
  pars,
}: {
  slug: string;
  kind: CourseKind;
  holes: number;
  /** Leer, wenn das Verzeichnis für diesen Platz keine vollständigen Par-Werte hat. */
  pars: number[];
}) {
  const storageKey = `golftrack.play.${slug}`;
  const hasPar = kind === "golf" && pars.length === holes;
  const hydrated = useHydrated();

  const [saved] = useState(() => loadSaved(storageKey, holes));
  const [names, setNames] = useState<string[]>(() => saved?.players ?? emptyNames(kind));
  const [scores, setScores] = useState<number[][] | null>(() => saved?.scores ?? null);
  const [hole, setHole] = useState(() =>
    saved ? Math.min(Math.max(saved.hole, 0), holes - 1) : 0,
  );
  const [finished, setFinished] = useState(() => Boolean(saved?.finished));
  /** Eingeschaltete Wettkämpfe – nur bei Minigolf, wie in der App. */
  const [challenges, setChallenges] = useState<string[]>(() => saved?.challenges ?? []);
  /** Runde läuft, aber der Gast hat den Zähler zugeklappt. */
  const [minimized, setMinimized] = useState(false);

  const running = Boolean(scores) && hydrated && !minimized;

  // Stand sichern. Der Effekt schreibt nur nach außen und rührt keinen
  // Zustand an – genau wofür Effekte da sind.
  useEffect(() => {
    try {
      if (!scores) {
        window.localStorage.removeItem(storageKey);
        return;
      }
      const payload: SavedRound = { players: names, scores, hole, finished, challenges };
      window.localStorage.setItem(storageKey, JSON.stringify(payload));
    } catch {
      // Nicht speichern können ist ärgerlich, aber kein Grund abzubrechen.
    }
  }, [storageKey, names, scores, hole, finished, challenges]);

  // Solange der Zähler den Bildschirm füllt, soll die Seite darunter nicht
  // mitscrollen.
  useEffect(() => {
    if (!running) return;
    const vorher = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = vorher;
    };
  }, [running]);

  function start() {
    const gefuellt = names.map((name, index) => name.trim() || `Spieler ${index + 1}`);
    setNames(gefuellt);
    setScores(gefuellt.map(() => Array.from({ length: holes }, () => 0)));
    setHole(0);
    setFinished(false);
    setMinimized(false);
  }

  function change(player: number, delta: number) {
    setScores((current) => {
      if (!current) return current;
      const next = current.map((row) => [...row]);
      next[player][hole] = Math.min(Math.max(next[player][hole] + delta, 0), MAX_STROKES);
      return next;
    });
  }

  function reset() {
    setScores(null);
    setFinished(false);
    setMinimized(false);
    setHole(0);
    setNames(emptyNames(kind));
  }

  // Der Server kennt den Speicher des Geräts nicht. Solange sein Markup noch
  // nicht übernommen ist, zeigen beide Seiten dasselbe: die leere Aufstellung.
  if (!hydrated) {
    return (
      <Setup
        kind={kind}
        names={emptyNames(kind)}
        setNames={() => {}}
        onStart={() => {}}
        holes={holes}
        challenges={[]}
        setChallenges={() => {}}
      />
    );
  }

  if (!scores) {
    return (
      <Setup
        kind={kind}
        names={names}
        setNames={setNames}
        onStart={start}
        holes={holes}
        challenges={challenges}
        setChallenges={setChallenges}
      />
    );
  }

  if (minimized) {
    return (
      <Resume
        kind={kind}
        hole={hole}
        holes={holes}
        onResume={() => setMinimized(false)}
        onDiscard={reset}
      />
    );
  }

  return (
    <FullScreen>
      {finished ? (
        <Result
          names={names}
          scores={scores}
          pars={hasPar ? pars : []}
          awards={challengeResults(challenges, scores, names)}
          onBack={() => setFinished(false)}
          onReset={reset}
          onClose={() => setMinimized(true)}
        />
      ) : (
        <Scoring
          names={names}
          scores={scores}
          hole={hole}
          holes={holes}
          par={hasPar ? pars[hole] : null}
          kind={kind}
          challenges={challenges}
          setChallenges={setChallenges}
          onChange={change}
          onHole={setHole}
          onFinish={() => setFinished(true)}
          onClose={() => setMinimized(true)}
        />
      )}
    </FullScreen>
  );
}

/** Nimmt den ganzen Bildschirm ein – wie die Zählkarte in der App. */
function FullScreen({ children }: { children: React.ReactNode }) {
  return (
    <div
      className="fixed inset-0 z-50 flex flex-col text-left"
      style={{ backgroundColor: APP.bg, color: "#fff" }}
    >
      {children}
    </div>
  );
}

// MARK: – Aufstellung

function Setup({
  kind,
  names,
  setNames,
  onStart,
  holes,
  challenges,
  setChallenges,
}: {
  kind: CourseKind;
  names: string[];
  setNames: (next: string[]) => void;
  onStart: () => void;
  holes: number;
  challenges: string[];
  setChallenges: (next: string[]) => void;
}) {
  const einheit = kind === "golf" ? "Löcher" : "Bahnen";

  return (
    <section
      className="mx-auto mt-12 max-w-lg rounded-2xl p-6 text-left sm:p-7"
      style={{ backgroundColor: APP.card }}
    >
      <h2 className="font-display text-xl">Ohne App mitzählen</h2>
      <p className="mt-2 text-sm leading-relaxed text-cream/55">
        Direkt im Browser, ohne Anmeldung. Der Stand bleibt auf diesem Gerät –
        auch wenn du das Fenster schließt.
      </p>

      <div className="mt-6 space-y-2">
        {names.map((name, index) => (
          <div
            key={index}
            className="flex items-center gap-3 rounded-xl px-3 py-2"
            style={{ backgroundColor: APP.cardAlt }}
          >
            <span
              className="grid h-6 w-6 shrink-0 place-items-center rounded-full text-xs font-semibold text-white"
              style={{ backgroundColor: `${APP.gold}bf` }}
            >
              {index + 1}
            </span>
            <input
              className="min-h-11 w-full bg-transparent text-[0.95rem] text-cream outline-none placeholder:text-cream/35"
              value={name}
              maxLength={24}
              placeholder={`Spieler ${index + 1}`}
              aria-label={`Name von Spieler ${index + 1}`}
              onChange={(event) => {
                const next = [...names];
                next[index] = event.target.value;
                setNames(next);
              }}
            />
          </div>
        ))}
      </div>

      <div className="mt-3 flex gap-2">
        {names.length < MAX_PLAYERS ? (
          <button
            type="button"
            className="tap flex-1 justify-center rounded-xl py-2.5 text-sm font-semibold"
            style={{ backgroundColor: `${APP.gold}1f`, color: APP.gold }}
            onClick={() => setNames([...names, ""])}
          >
            + Hinzufügen
          </button>
        ) : null}
        {names.length > 1 ? (
          <button
            type="button"
            className="tap flex-1 justify-center rounded-xl bg-red-500/10 py-2.5 text-sm font-semibold text-red-400"
            onClick={() => setNames(names.slice(0, -1))}
          >
            − Entfernen
          </button>
        ) : null}
      </div>

      {/* Wettkämpfe gibt es nur beim Minigolf – wie in der App. */}
      {kind === "minigolf" ? (
        <ChallengePicker challenges={challenges} setChallenges={setChallenges} />
      ) : null}

      <button
        type="button"
        className="mt-6 w-full rounded-2xl py-4 text-center font-display font-semibold"
        style={{ backgroundColor: APP.gold, color: APP.ink }}
        onClick={onStart}
      >
        Runde starten · {holes} {einheit}
      </button>
    </section>
  );
}

/** Zugeklappte Runde: der Weg zurück in den Zähler. */
function Resume({
  kind,
  hole,
  holes,
  onResume,
  onDiscard,
}: {
  kind: CourseKind;
  hole: number;
  holes: number;
  onResume: () => void;
  onDiscard: () => void;
}) {
  const einheit = kind === "golf" ? "Loch" : "Bahn";
  return (
    <section
      className="mx-auto mt-12 max-w-lg rounded-2xl p-6 text-left"
      style={{ backgroundColor: APP.card }}
    >
      <h2 className="font-display text-xl">Angefangene Runde</h2>
      <p className="mt-1.5 text-sm text-cream/55">
        {einheit} {hole + 1} von {holes}
      </p>
      <div className="mt-5 flex gap-3">
        <button
          type="button"
          className="flex-1 rounded-xl py-3 text-center font-semibold"
          style={{ backgroundColor: APP.gold, color: APP.ink }}
          onClick={onResume}
        >
          Weiterzählen
        </button>
        <button
          type="button"
          className="flex-1 rounded-xl bg-red-500/10 py-3 text-center font-semibold text-red-400"
          onClick={onDiscard}
        >
          Verwerfen
        </button>
      </div>
    </section>
  );
}

// MARK: – Zählen

function Scoring({
  names,
  scores,
  hole,
  holes,
  par,
  kind,
  challenges,
  setChallenges,
  onChange,
  onHole,
  onFinish,
  onClose,
}: {
  names: string[];
  scores: number[][];
  hole: number;
  holes: number;
  par: number | null;
  kind: CourseKind;
  challenges: string[];
  setChallenges: (next: string[]) => void;
  onChange: (player: number, delta: number) => void;
  onHole: (hole: number) => void;
  onFinish: () => void;
  onClose: () => void;
}) {
  const [zeigeAuswahl, setZeigeAuswahl] = useState(false);
  const einheit = kind === "golf" ? "Loch" : "Bahn";
  const letzte = hole === holes - 1;
  // Rang wie in der App: wenige Schläge zuerst.
  const gesamt = names.map((_, i) => scores[i].reduce((sum, value) => sum + value, 0));
  const reihenfolge = names.map((_, i) => i).sort((a, b) => gesamt[a] - gesamt[b]);

  return (
    <>
      <TitleBar
        title={`${einheit} ${hole + 1} / ${holes}`}
        subtitle={par ? `Par ${par}` : null}
        onClose={onClose}
        right={
          <button
            type="button"
            className="text-sm font-semibold"
            style={{ color: APP.gold }}
            onClick={onFinish}
          >
            Ergebnis
          </button>
        }
      />

      {/* Fortschritt wie in der App: ein dünner goldener Streifen. */}
      <div className="h-[3px] w-full bg-white/10">
        <div
          className="h-full transition-[width] duration-200"
          style={{ width: `${((hole + 1) / holes) * 100}%`, backgroundColor: APP.gold }}
        />
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-4">
        <ul className="mx-auto flex max-w-lg flex-col gap-2.5">
          {names.map((name, player) => (
            <li
              key={player}
              className="flex items-center gap-3 rounded-2xl p-4"
              style={{ backgroundColor: APP.card }}
            >
              <span
                className="grid h-6 w-6 shrink-0 place-items-center rounded-full text-xs font-semibold text-white"
                style={{ backgroundColor: rangFarbe(reihenfolge.indexOf(player)) }}
              >
                {reihenfolge.indexOf(player) + 1}
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate font-semibold">{name}</p>
                <p className="text-xs text-cream/50">Gesamt: {gesamt[player]}</p>
              </div>
              <Stepper
                value={scores[player][hole]}
                name={name}
                onLess={() => onChange(player, -1)}
                onMore={() => onChange(player, +1)}
              />
            </li>
          ))}
        </ul>

        {/* Wettkämpfe laufen neben der Schlagwertung mit – wie in der App. */}
        {kind === "minigolf" ? (
          <div className="mx-auto mt-2.5 max-w-lg">
            {zeigeAuswahl ? (
              <div className="rounded-2xl p-4" style={{ backgroundColor: APP.card }}>
                <ChallengePicker
                  challenges={challenges}
                  setChallenges={setChallenges}
                  offen
                />
                <button
                  type="button"
                  className="mt-4 w-full rounded-xl py-3 text-center text-sm font-semibold"
                  style={{ backgroundColor: APP.cardAlt }}
                  onClick={() => setZeigeAuswahl(false)}
                >
                  Fertig
                </button>
              </div>
            ) : (
              <ChallengeLiveCard
                results={challengeResults(challenges, scores, names)}
                onEdit={() => setZeigeAuswahl(true)}
              />
            )}
          </div>
        ) : null}
      </div>

      <nav className="flex gap-3 px-4 pb-[max(1rem,env(safe-area-inset-bottom))] pt-2">
        <button
          type="button"
          className="flex-1 rounded-xl py-3.5 text-center text-sm font-semibold disabled:opacity-30"
          style={{ backgroundColor: APP.card }}
          disabled={hole === 0}
          onClick={() => onHole(hole - 1)}
        >
          ‹ Zurück
        </button>
        <button
          type="button"
          className="flex-1 rounded-xl py-3.5 text-center text-sm font-semibold"
          style={{ backgroundColor: APP.gold, color: APP.ink }}
          onClick={() => (letzte ? onFinish() : onHole(hole + 1))}
        >
          {letzte ? "Ergebnis" : "Weiter ›"}
        </button>
      </nav>
    </>
  );
}

/** Gold, Silber, Bronze – wie die Ränge in der App. */
function rangFarbe(rang: number): string {
  if (rang === 0) return "#D9A61A";
  if (rang === 1) return "#9CA3AF";
  if (rang === 2) return "#B87333";
  return "#4B5563";
}

function Stepper({
  value,
  name,
  onLess,
  onMore,
}: {
  value: number;
  name: string;
  onLess: () => void;
  onMore: () => void;
}) {
  return (
    <div className="flex shrink-0 items-center gap-1">
      <RoundButton label={`Ein Schlag weniger für ${name}`} disabled={value === 0} onClick={onLess}>
        −
      </RoundButton>
      <output className="w-10 text-center font-mono text-2xl font-bold tabular-nums">{value}</output>
      <RoundButton label={`Ein Schlag mehr für ${name}`} disabled={value >= MAX_STROKES} onClick={onMore}>
        +
      </RoundButton>
    </div>
  );
}

function RoundButton({
  label,
  disabled,
  onClick,
  children,
}: {
  label: string;
  disabled: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      aria-label={label}
      disabled={disabled}
      onClick={onClick}
      className="grid h-11 w-11 place-items-center rounded-full text-2xl leading-none"
      style={{
        backgroundColor: disabled ? "#ffffff1a" : APP.gold,
        color: disabled ? "#ffffff80" : APP.ink,
      }}
    >
      {children}
    </button>
  );
}

// MARK: – Ergebnis

function Result({
  names,
  scores,
  pars,
  awards,
  onBack,
  onReset,
  onClose,
}: {
  names: string[];
  scores: number[][];
  /** Leer bei Minigolf und bei Plätzen ohne vollständige Par-Werte. */
  pars: number[];
  /** Wettkämpfe der Runde – leer, wenn keiner eingeschaltet war. */
  awards: ChallengeResult[];
  onBack: () => void;
  onReset: () => void;
  onClose: () => void;
}) {
  const parGesamt = pars.reduce((sum, par) => sum + par, 0);
  const gesamt = scores.map((row) => row.reduce((sum, value) => sum + value, 0));
  const reihenfolge = gesamt
    .map((total, player) => ({ player, total }))
    .sort((a, b) => a.total - b.total);

  return (
    <>
      <TitleBar title="Ergebnis" subtitle={parGesamt ? `Par ${parGesamt}` : null} onClose={onClose} />

      <div className="flex-1 overflow-y-auto px-4 py-6">
        <ol className="mx-auto flex max-w-lg flex-col gap-2.5">
          {reihenfolge.map((row, platz) => (
            <li
              key={row.player}
              className="flex items-center gap-3 rounded-2xl p-4"
              style={{ backgroundColor: APP.card }}
            >
              <span
                className="grid h-7 w-7 shrink-0 place-items-center rounded-full text-xs font-semibold text-white"
                style={{ backgroundColor: rangFarbe(platz) }}
              >
                {platz + 1}
              </span>
              <span className="min-w-0 flex-1 truncate font-semibold">{names[row.player]}</span>
              {parGesamt ? (
                <span className="font-mono text-xs text-cream/50">{zuPar(row.total - parGesamt)}</span>
              ) : null}
              <span className="font-mono text-2xl font-bold tabular-nums" style={{ color: APP.gold }}>
                {row.total}
              </span>
            </li>
          ))}
        </ol>

        {awards.length ? (
          <section className="mx-auto mt-8 max-w-lg">
            <h2 className="mb-2.5 font-display text-lg">Pokale</h2>
            <ul className="flex flex-col gap-2">
              {awards.map((result) => (
                <li
                  key={result.challenge.id}
                  className="flex items-center gap-3 rounded-2xl p-4"
                  style={{ backgroundColor: APP.card }}
                >
                  <span aria-hidden className="text-xl">
                    {result.challenge.trophy}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-xs text-cream/50">{result.challenge.name}</span>
                    <span className="block truncate font-semibold">
                      {result.leaders.length ? result.leaderNames : "niemand"}
                    </span>
                  </span>
                  {result.leaderValueText ? (
                    <span className="font-mono text-xs" style={{ color: APP.gold }}>
                      {result.leaderValueText}
                    </span>
                  ) : null}
                </li>
              ))}
            </ul>
          </section>
        ) : null}
      </div>

      <nav className="flex gap-3 px-4 pb-[max(1rem,env(safe-area-inset-bottom))] pt-2">
        <button
          type="button"
          className="flex-1 rounded-xl py-3.5 text-center text-sm font-semibold"
          style={{ backgroundColor: APP.card }}
          onClick={onBack}
        >
          Weiterzählen
        </button>
        <button
          type="button"
          className="flex-1 rounded-xl py-3.5 text-center text-sm font-semibold"
          style={{ backgroundColor: APP.gold, color: APP.ink }}
          onClick={onReset}
        >
          Neue Runde
        </button>
      </nav>
    </>
  );
}

/** Kopfzeile wie die Navigationsleiste der App. */
function TitleBar({
  title,
  subtitle,
  onClose,
  right,
}: {
  title: string;
  subtitle?: string | null;
  onClose: () => void;
  right?: React.ReactNode;
}) {
  return (
    <header className="flex items-center gap-3 px-3 pb-2 pt-[max(0.75rem,env(safe-area-inset-top))]">
      <button
        type="button"
        aria-label="Zähler schließen"
        className="grid h-11 w-11 shrink-0 place-items-center rounded-full text-2xl leading-none"
        style={{ color: APP.gold }}
        onClick={onClose}
      >
        ‹
      </button>
      <div className="min-w-0 flex-1 text-center">
        <p className="truncate font-semibold">{title}</p>
        {subtitle ? <p className="text-xs text-cream/50">{subtitle}</p> : null}
      </div>
      <div className="flex h-11 w-20 shrink-0 items-center justify-end pr-1">{right}</div>
    </header>
  );
}

/** Golfnotation: ±0 heißt „Par", sonst mit Vorzeichen. */
function zuPar(delta: number): string {
  if (delta === 0) return "Par";
  return delta > 0 ? `+${delta}` : `${delta}`;
}

// MARK: – Wettkämpfe

/** Auswahl der Wettkämpfe – vor dem Start und jederzeit während der Runde. */
function ChallengePicker({
  challenges,
  setChallenges,
  offen = false,
}: {
  challenges: string[];
  setChallenges: (next: string[]) => void;
  /** In der laufenden Runde ist die Liste schon ausgeklappt. */
  offen?: boolean;
}) {
  const [ausgeklappt, setAusgeklappt] = useState(offen);

  function umschalten(id: string) {
    setChallenges(
      challenges.includes(id) ? challenges.filter((c) => c !== id) : [...challenges, id],
    );
  }

  const kopf = (
    <>
      <span className="font-semibold">Wettkämpfe</span>
      <span className="font-mono text-xs text-cream/50">
        {challenges.length ? `${challenges.length} aktiv` : "keine"}
      </span>
    </>
  );

  return (
    <div className={offen ? "" : "mt-6"}>
      {/* In der laufenden Runde ist die Liste fest offen – ein Aufklapper, der
          sie wieder verschwinden lässt, wäre dort nur eine Falle. */}
      {offen ? (
        <div className="flex items-center gap-2">{kopf}</div>
      ) : (
        <button
          type="button"
          className="flex w-full items-center gap-2 text-left"
          onClick={() => setAusgeklappt((a) => !a)}
          aria-expanded={ausgeklappt}
        >
          {kopf}
          <span aria-hidden className="ml-auto text-sm" style={{ color: APP.gold }}>
            {ausgeklappt ? "▾" : "▸"}
          </span>
        </button>
      )}

      {ausgeklappt ? (
        <>
          <p className="mt-1.5 text-xs leading-relaxed text-cream/50">
            Laufen neben der Schlagwertung mit. Gewertet wird immer die ganze Karte,
            egal wann du einen dazunimmst.
          </p>
          <ul className="mt-3 flex flex-col gap-2">
            {CHALLENGES.map((challenge) => {
              const an = challenges.includes(challenge.id);
              return (
                <li key={challenge.id}>
                  <button
                    type="button"
                    aria-pressed={an}
                    onClick={() => umschalten(challenge.id)}
                    className="flex w-full items-start gap-3 rounded-xl p-3 text-left"
                    style={{
                      backgroundColor: APP.cardAlt,
                      outline: an ? `1.5px solid ${APP.gold}` : "none",
                    }}
                  >
                    <span aria-hidden className="text-lg leading-6">
                      {challenge.trophy}
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block text-sm font-semibold">{challenge.name}</span>
                      <span className="block text-xs leading-snug text-cream/50">
                        {challenge.rule}
                      </span>
                    </span>
                    <span
                      aria-hidden
                      className="mt-0.5 text-sm"
                      style={{ color: an ? APP.gold : "#ffffff40" }}
                    >
                      {an ? "✓" : "+"}
                    </span>
                  </button>
                </li>
              );
            })}
          </ul>
        </>
      ) : null}
    </div>
  );
}

/** Der Zwischenstand der Wettkämpfe während der Runde. */
function ChallengeLiveCard({
  results,
  onEdit,
}: {
  results: ChallengeResult[];
  onEdit: () => void;
}) {
  return (
    <div className="rounded-2xl p-4" style={{ backgroundColor: APP.card }}>
      <div className="flex items-baseline gap-2">
        <span className="text-sm font-semibold">Wettkämpfe</span>
        <button
          type="button"
          className="ml-auto text-xs font-semibold"
          style={{ color: APP.gold }}
          onClick={onEdit}
        >
          {results.length ? "Ändern" : "Hinzufügen"}
        </button>
      </div>

      {results.length ? (
        <ul className="mt-2.5 flex flex-col gap-1.5">
          {results.map((result) => (
            <li key={result.challenge.id} className="flex items-center gap-2 text-xs">
              <span aria-hidden>{result.challenge.trophy}</span>
              <span className="text-cream/50">{result.challenge.name}</span>
              {result.leaderValueText ? (
                <>
                  <span className="ml-auto truncate font-semibold">{result.leaderNames}</span>
                  <span className="font-mono tabular-nums" style={{ color: APP.gold }}>
                    {result.leaderValueText}
                  </span>
                </>
              ) : (
                <span className="ml-auto text-cream/40">noch offen</span>
              )}
            </li>
          ))}
        </ul>
      ) : (
        <p className="mt-1.5 text-xs text-cream/40">
          Serie, Asse, Bahnenduell und mehr – laufen nebenher mit.
        </p>
      )}
    </div>
  );
}
