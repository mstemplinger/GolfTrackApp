"use client";

import { useEffect, useState, useSyncExternalStore } from "react";
import type { CourseKind } from "@/lib/schema";

/**
 * Mitzählen im Browser – für alle, die weder App noch App Clip bekommen:
 * Android heute, Rechner, und iPhones, deren Besitzer die Clip-Karte
 * weggewischt haben.
 *
 * Bewusst schlank gehalten und ohne Konto: Der Stand liegt im Browser des
 * Geräts (`localStorage`), damit eine unterbrochene Runde nicht verloren ist.
 * Was hier fehlt – Laufspur, Statistik über alle Runden, Uhr – ist genau das,
 * wofür es die App gibt.
 */

const MAX_PLAYERS = 8;
const MAX_STROKES = 20;

interface SavedRound {
  players: string[];
  scores: number[][];
  hole: number;
  finished: boolean;
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

  // Stand sichern. Der Effekt schreibt nur nach außen und rührt keinen
  // Zustand an – genau wofür Effekte da sind.
  useEffect(() => {
    try {
      if (!scores) {
        window.localStorage.removeItem(storageKey);
        return;
      }
      const payload: SavedRound = { players: names, scores, hole, finished };
      window.localStorage.setItem(storageKey, JSON.stringify(payload));
    } catch {
      // Nicht speichern können ist ärgerlich, aber kein Grund abzubrechen.
    }
  }, [storageKey, names, scores, hole, finished]);

  function start() {
    const filled = names.map((name, index) => name.trim() || `Spieler ${index + 1}`);
    setNames(filled);
    setScores(filled.map(() => Array.from({ length: holes }, () => 0)));
    setHole(0);
    setFinished(false);
  }

  function change(player: number, delta: number) {
    setScores((current) => {
      if (!current) return current;
      const next = current.map((row) => [...row]);
      const value = next[player][hole] + delta;
      next[player][hole] = Math.min(Math.max(value, 0), MAX_STROKES);
      return next;
    });
  }

  function reset() {
    setScores(null);
    setFinished(false);
    setHole(0);
    setNames(emptyNames(kind));
  }

  // Der Server kennt den Speicher des Geräts nicht. Solange sein Markup noch
  // nicht übernommen ist, zeigen beide Seiten dasselbe: die leere Aufstellung.
  // Erst danach darf ein gespeicherter Stand einspringen – sonst weicht der
  // erste Durchgang im Browser vom gelieferten Markup ab.
  if (!hydrated) {
    return (
      <Setup
        kind={kind}
        names={emptyNames(kind)}
        setNames={() => {}}
        onStart={() => {}}
        holes={holes}
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
      />
    );
  }

  if (finished) {
    return (
      <Result
        names={names}
        scores={scores}
        pars={hasPar ? pars : []}
        onBack={() => setFinished(false)}
        onReset={reset}
      />
    );
  }

  return (
    <Scoring
      names={names}
      scores={scores}
      hole={hole}
      holes={holes}
      par={hasPar ? pars[hole] : null}
      kind={kind}
      onChange={change}
      onHole={setHole}
      onFinish={() => setFinished(true)}
    />
  );
}

// MARK: – Aufstellung

function Setup({
  kind,
  names,
  setNames,
  onStart,
  holes,
}: {
  kind: CourseKind;
  names: string[];
  setNames: (next: string[]) => void;
  onStart: () => void;
  holes: number;
}) {
  const unit = kind === "golf" ? "Löcher" : "Bahnen";

  return (
    <section className="paper mx-auto mt-12 max-w-lg rounded-sm p-6 text-left sm:p-8">
      <h2 className="font-display text-2xl tracking-tight">Ohne App mitzählen</h2>
      <p className="mt-2 text-sm leading-relaxed text-ink/70">
        Direkt im Browser, ohne Anmeldung. Der Stand bleibt auf diesem Gerät –
        auch wenn du das Fenster schließt.
      </p>

      <div className="mt-6 space-y-2.5">
        {names.map((name, index) => (
          <div key={index} className="flex items-center gap-3">
            <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-ink/10 font-mono text-xs">
              {index + 1}
            </span>
            <input
              className="field"
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

      <div className="mt-4 flex gap-3">
        {names.length < MAX_PLAYERS ? (
          <button
            type="button"
            className="tap font-mono text-xs text-ink/70 underline underline-offset-4"
            onClick={() => setNames([...names, ""])}
          >
            + Spieler
          </button>
        ) : null}
        {names.length > 1 ? (
          <button
            type="button"
            className="tap font-mono text-xs text-ink/70 underline underline-offset-4"
            onClick={() => setNames(names.slice(0, -1))}
          >
            − Spieler
          </button>
        ) : null}
      </div>

      <button type="button" className="btn-brass mt-7 w-full justify-center" onClick={onStart}>
        Runde starten · {holes} {unit}
      </button>
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
  onChange,
  onHole,
  onFinish,
}: {
  names: string[];
  scores: number[][];
  hole: number;
  holes: number;
  par: number | null;
  kind: CourseKind;
  onChange: (player: number, delta: number) => void;
  onHole: (hole: number) => void;
  onFinish: () => void;
}) {
  const unit = kind === "golf" ? "Loch" : "Bahn";
  const isLast = hole === holes - 1;

  return (
    <section className="paper mx-auto mt-12 max-w-lg rounded-sm p-6 text-left sm:p-8">
      <header className="flex items-baseline justify-between">
        <h2 className="font-display text-2xl tracking-tight">
          {unit} {hole + 1}
          <span className="text-ink/40"> / {holes}</span>
        </h2>
        {par ? <span className="font-mono text-sm text-ink/60">Par {par}</span> : null}
      </header>

      {/* Fortschritt – ein Strich je Bahn, angetippt springt man hin. */}
      <div className="mt-4 flex gap-[3px]">
        {Array.from({ length: holes }, (_, index) => (
          <button
            key={index}
            type="button"
            aria-label={`${unit} ${index + 1}`}
            aria-current={index === hole ? "step" : undefined}
            className={`h-1.5 flex-1 rounded-full ${
              index === hole ? "bg-ink/70" : index < hole ? "bg-ink/30" : "bg-ink/10"
            }`}
            onClick={() => onHole(index)}
          />
        ))}
      </div>

      <ul className="mt-6 space-y-2.5">
        {names.map((name, player) => {
          const total = scores[player].reduce((sum, value) => sum + value, 0);
          return (
            <li
              key={player}
              className="flex items-center gap-3 rounded-sm border border-ink/12 bg-white/45 px-3 py-2.5"
            >
              <div className="min-w-0 flex-1">
                <p className="truncate text-[0.95rem] font-semibold">{name}</p>
                <p className="font-mono text-xs text-ink/55">Gesamt {total}</p>
              </div>
              <StrokeStepper
                value={scores[player][hole]}
                name={name}
                onLess={() => onChange(player, -1)}
                onMore={() => onChange(player, +1)}
              />
            </li>
          );
        })}
      </ul>

      <div className="mt-6 flex gap-3">
        <SecondaryButton disabled={hole === 0} onClick={() => onHole(hole - 1)}>
          Zurück
        </SecondaryButton>
        {isLast ? (
          <button type="button" className="btn-brass flex-1 justify-center" onClick={onFinish}>
            Ergebnis
          </button>
        ) : (
          <button
            type="button"
            className="btn-brass flex-1 justify-center"
            onClick={() => onHole(hole + 1)}
          >
            Weiter
          </button>
        )}
      </div>
    </section>
  );
}

function StrokeStepper({
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
      <StepperButton label={`Ein Schlag weniger für ${name}`} disabled={value === 0} onClick={onLess}>
        −
      </StepperButton>
      <output className="w-10 text-center font-mono text-2xl tabular-nums">{value}</output>
      <StepperButton label={`Ein Schlag mehr für ${name}`} disabled={value >= MAX_STROKES} onClick={onMore}>
        +
      </StepperButton>
    </div>
  );
}

function StepperButton({
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
      className="grid h-11 w-11 place-items-center rounded-sm border border-ink/20 bg-white/70 text-xl leading-none transition-colors hover:bg-white disabled:opacity-35 disabled:hover:bg-white/70"
    >
      {children}
    </button>
  );
}

/**
 * Zweitknopf auf dem Papier. `btn-ghost` scheidet hier aus: der ist für den
 * dunklen Seitengrund gemacht und schreibt in Creme – auf dem Papier wäre er
 * nicht zu lesen.
 */
function SecondaryButton({
  disabled = false,
  onClick,
  children,
}: {
  disabled?: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className="inline-flex min-h-12 flex-1 items-center justify-center rounded-[0.85rem] border border-ink/25 px-5 font-display text-[0.95rem] font-semibold text-ink/80 transition-colors hover:bg-ink/5 disabled:opacity-35 disabled:hover:bg-transparent"
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
  onBack,
  onReset,
}: {
  names: string[];
  scores: number[][];
  /** Leer bei Minigolf und bei Plätzen ohne vollständige Par-Werte. */
  pars: number[];
  onBack: () => void;
  onReset: () => void;
}) {
  const totalPar = pars.reduce((sum, par) => sum + par, 0);
  const totals = scores.map((row) => row.reduce((sum, value) => sum + value, 0));
  const ranking = totals
    .map((total, player) => ({ player, total }))
    .sort((a, b) => a.total - b.total);

  return (
    <section className="paper mx-auto mt-12 max-w-lg rounded-sm p-6 text-left sm:p-8">
      <h2 className="font-display text-2xl tracking-tight">Ergebnis</h2>

      <ol className="mt-5 space-y-px overflow-hidden rounded-sm border border-ink/12">
        {ranking.map((row, place) => (
          <li
            key={row.player}
            className="flex items-center gap-3 bg-white/45 px-4 py-3"
          >
            <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-ink/10 font-mono text-xs">
              {place + 1}
            </span>
            <span className="min-w-0 flex-1 truncate">{names[row.player]}</span>
            <span className="font-mono text-lg tabular-nums">{row.total}</span>
            {totalPar ? (
              <span className="w-14 text-right font-mono text-xs text-ink/55">
                {toPar(row.total - totalPar)}
              </span>
            ) : null}
          </li>
        ))}
      </ol>

      {totalPar ? (
        <p className="mt-3 font-mono text-xs text-ink/55">Par {totalPar}</p>
      ) : null}

      <div className="mt-7 flex gap-3">
        <SecondaryButton onClick={onBack}>Weiterzählen</SecondaryButton>
        <button type="button" className="btn-brass flex-1 justify-center" onClick={onReset}>
          Neue Runde
        </button>
      </div>
    </section>
  );
}

/** Golfnotation: ±0 heißt „Par", sonst mit Vorzeichen. */
function toPar(delta: number): string {
  if (delta === 0) return "Par";
  return delta > 0 ? `+${delta}` : `${delta}`;
}
