import Link from "next/link";
import { MIN_ROUNDS_FOR_DISPLAY } from "@/lib/roundStats";
import type { CourseReport, HoleStat } from "@/lib/roundStatsReport";
import { TEE_META, isTeeColor } from "@/lib/tees";
import { ALL_SECTIONS, type OperatorSection } from "@/lib/sections";
import { operatorCopy, type ReportCopy } from "@/i18n/operator";

/**
 * Darstellung der Rundenstatistik eines Platzes – im Adminpanel vollständig
 * und deutsch, auf operator.golftrack.app nur mit den freigegebenen
 * Bausteinen und in der Sprache des Betreibers (`t`).
 */

const DE = operatorCopy("de").report;

export const PERIODS = [30, 90, 365] as const;

/** Zeitraum aus der Adresse, sonst 90 Tage. */
export function periodFrom(value: unknown): number {
  const n = Number(value);
  return (PERIODS as readonly number[]).includes(n) ? n : 90;
}

/** Umschalter 30 Tage / 90 Tage / 1 Jahr. */
export function PeriodSwitch({ days, href, t = DE }: { days: number; href: (days: number) => string; t?: ReportCopy }) {
  return (
    <nav className="flex gap-1 rounded-lg border border-white/10 p-1 text-sm" aria-label={t.periodLabel}>
      {PERIODS.map((p) => (
        <Link
          key={p}
          href={href(p)}
          className={`rounded-sm px-3 py-1.5 transition-colors ${p === days ? "bg-brass text-night" : "text-cream/70 hover:text-brass"}`}
        >
          {t.period(p)}
        </Link>
      ))}
    </nav>
  );
}

export function RoundStatsReport({
  report,
  hcps,
  sections = ALL_SECTIONS,
  audience = "admin",
  t = DE,
}: {
  report: CourseReport;
  hcps: (number | null)[];
  /** Welche Bausteine gezeigt werden – Betreiber sehen nur ihre freigegebenen. */
  sections?: readonly OperatorSection[];
  audience?: "admin" | "operator";
  t?: ReportCopy;
}) {
  const show = (s: OperatorSection) => sections.includes(s);
  const golf = report.kind === "golf";
  const unit = golf ? t.unitHole : t.unitLane;
  const fmt = (n: number, digits: number) =>
    n.toLocaleString(t.locale, { minimumFractionDigits: digits, maximumFractionDigits: digits });
  // Golf: Länge des Balkens = Schläge über Par (sonst bestimmt der Par allein
  // das Bild). Minigolf: Ø Schläge.
  const metric = (h: HoleStat) => (golf ? h.overPar : h.avgStrokes);
  const maxMetric = Math.max(...report.holes.map((h) => metric(h) ?? 0), 0.1);
  // Tatsächlicher Schwierigkeitsrang (1 = schwerstes Loch) – zum Vergleich mit
  // dem HCP-Index der Scorecard.
  const ranked = report.holes.filter((h) => metric(h) != null).sort((a, b) => (metric(b) ?? 0) - (metric(a) ?? 0));
  const rank = new Map(ranked.map((h, i) => [h.hole, i + 1]));
  const showHcp = golf && hcps.some((x) => x != null);
  const anomalies = report.holes.filter((h) => h.anomaly);
  const topSource = Object.entries(report.sources).sort((a, b) => b[1] - a[1])[0];

  return (
    <>
      {audience === "admin" && report.belowThreshold ? (
        <p className="mt-8 rounded-sm border border-brass/40 bg-brass/10 p-4 text-sm text-cream/80">
          Erst {report.rounds} {report.rounds === 1 ? "Runde" : "Runden"} in diesem Zeitraum. Ein Betreiber sähe hier
          noch nichts (Schwelle: {MIN_ROUNDS_FOR_DISPLAY} Runden).
        </p>
      ) : null}

      {show("kennzahlen") ? (
        <dl className="mt-8 grid gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-4">
          <Stat label={t.rounds} value={report.rounds.toLocaleString(t.locale)} />
          <Stat
            label={t.duration}
            value={report.medianDuration != null ? formatDuration(report.medianDuration) : "–"}
            note={t.durationNote(report.durationSamples)}
          />
          <Stat
            label={t.group}
            value={report.avgGroup != null ? fmt(report.avgGroup, 1) : "–"}
            note={t.players(report.players)}
          />
          <Stat
            label={t.source}
            value={topSource ? (t.sources[topSource[0]] ?? topSource[0]) : "–"}
            note={Object.entries(report.sources)
              .sort((a, b) => b[1] - a[1])
              .map(([k, v]) => `${t.sources[k] ?? k} ${v}`)
              .join(" · ")}
          />
        </dl>
      ) : null}

      {show("warnungen") && anomalies.length ? (
        <div className="mt-6 space-y-2">
          {anomalies.map((h) => (
            <p
              key={h.hole}
              className="rounded-sm border border-amber-400/40 bg-amber-400/10 p-3 text-sm text-amber-100"
            >
              ⚠{" "}
              {t.anomaly(
                unit,
                h.hole,
                fmt(h.anomaly!.recent - h.anomaly!.before, 1),
                fmt(h.anomaly!.before, 1),
                fmt(h.anomaly!.recent, 1),
                !golf,
              )}
            </p>
          ))}
        </div>
      ) : null}

      {show("verlauf") ? (
        <Section title={t.perWeek}>
          <WeekBars weeks={report.weeks} t={t} />
        </Section>
      ) : null}

      {show("stosszeiten") ? (
        <Section title={t.busy}>
          <Heatmap data={report.heatmap} t={t} />
        </Section>
      ) : null}

      {show("schwierigkeit") ? (
        <Section title={t.difficulty(unit)}>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[520px] text-sm">
              <thead>
                <tr className="text-left text-xs text-cream/55">
                  <th className="py-2 pr-3 font-normal">{unit}</th>
                  {golf ? <th className="py-2 pr-3 font-normal">{t.par}</th> : null}
                  {showHcp ? (
                    <th className="py-2 pr-3 font-normal" title={t.hcpRealHint}>
                      {t.hcpReal}
                    </th>
                  ) : null}
                  <th className="py-2 pr-3 font-normal">{t.avgStrokes}</th>
                  <th className="w-1/3 py-2 pr-3 font-normal" aria-hidden />
                  {golf ? <th className="py-2 pr-3 font-normal">{t.overPar}</th> : null}
                  <th className="py-2 pr-3 font-normal">{golf ? t.avgPutts : t.ace}</th>
                  <th className="py-2 font-normal text-right">{t.samples}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-cream/10">
                {report.holes.map((h) => (
                  <HoleRow
                    key={h.hole}
                    h={h}
                    golf={golf}
                    fmt={fmt}
                    width={Math.max(0, Math.round(((metric(h) ?? 0) / maxMetric) * 100))}
                    hcp={showHcp ? (hcps[h.hole - 1] ?? null) : undefined}
                    rank={rank.get(h.hole) ?? null}
                  />
                ))}
              </tbody>
            </table>
          </div>
        </Section>
      ) : null}

      {show("abschlaege") ? (
        <div className="mt-12 grid gap-8 sm:grid-cols-2">
          <Section title={t.length} flush>
            <Breakdown
              data={report.holesPlayed}
              empty={t.noData}
              label={(k) => `${k} ${golf ? t.unitHoles : t.unitLanes}`}
            />
          </Section>
          {golf ? (
            <Section title={t.tees} flush>
              <Breakdown
                data={report.teeColors}
                empty={t.noData}
                label={(k) => t.teeNames[k] ?? (isTeeColor(k) ? TEE_META[k].label : k)}
                swatch={(k) => (isTeeColor(k) ? TEE_META[k].swatch : undefined)}
              />
            </Section>
          ) : null}
        </div>
      ) : null}
    </>
  );
}

function HoleRow({
  h,
  golf,
  width,
  hcp,
  rank,
  fmt,
}: {
  h: HoleStat;
  golf: boolean;
  width: number;
  /** `undefined` = Spalte nicht zeigen. */
  hcp?: number | null;
  rank: number | null;
  fmt: (n: number, digits: number) => string;
}) {
  // Weicht der echte Rang deutlich vom HCP-Index ab, lohnt ein Blick.
  const off = hcp != null && rank != null && Math.abs(hcp - rank) >= 6;
  const signed = (n: number) => `${n > 0 ? "+" : n < 0 ? "−" : "±"}${fmt(Math.abs(n), 2)}`;
  return (
    <tr className={h.anomaly ? "bg-amber-400/5" : undefined}>
      <td className="py-2 pr-3 font-mono">{h.hole}</td>
      {golf ? <td className="py-2 pr-3 font-mono text-cream/65">{h.par ?? "–"}</td> : null}
      {hcp !== undefined ? (
        <td className={`py-2 pr-3 font-mono ${off ? "text-brass" : "text-cream/65"}`}>
          {hcp ?? "–"} · {rank ?? "–"}
        </td>
      ) : null}
      <td className="py-2 pr-3 font-mono">{h.avgStrokes != null ? fmt(h.avgStrokes, 2) : "–"}</td>
      <td className="py-2 pr-3">
        <span
          className={`block h-2 rounded-r-sm ${h.anomaly ? "bg-amber-400" : "bg-brass/80"}`}
          style={{ width: `${width}%` }}
        />
      </td>
      {golf ? (
        <td className="py-2 pr-3 font-mono text-cream/80">{h.overPar != null ? signed(h.overPar) : "–"}</td>
      ) : null}
      {golf ? (
        <td className="py-2 pr-3 font-mono text-cream/80">{h.avgPutts != null ? fmt(h.avgPutts, 1) : "–"}</td>
      ) : (
        <td className="py-2 pr-3 font-mono text-cream/80">
          {h.aceRate != null ? `${Math.round(h.aceRate * 100)} %` : "–"}
        </td>
      )}
      <td className="py-2 text-right font-mono text-xs text-cream/45">{h.samples}</td>
    </tr>
  );
}

function WeekBars({ weeks, t }: { weeks: { start: string; rounds: number }[]; t: ReportCopy }) {
  const shown = weeks.slice(-26);
  const max = Math.max(...shown.map((w) => w.rounds), 1);
  return (
    <div>
      <div className="flex h-36 items-stretch gap-1">
        {shown.map((w) => (
          <div
            key={w.start}
            className="flex h-full min-w-0 flex-1 flex-col items-center justify-end"
            title={`${t.weekOf(formatDay(w.start, t))}: ${w.rounds}`}
          >
            <span className="mb-1 font-mono text-[10px] text-cream/55">{w.rounds || ""}</span>
            {/* Höhe relativ zu einer Fläche mit fester Höhe – sonst greift das Prozent nicht. */}
            <div className="flex w-full flex-1 items-end justify-center">
              <span
                className="block w-full max-w-6 rounded-t-sm bg-brass/80"
                style={{
                  height: `${(w.rounds / max) * 100}%`,
                  minHeight: w.rounds ? 2 : 0,
                }}
              />
            </div>
          </div>
        ))}
      </div>
      <div className="mt-1 flex justify-between font-mono text-[11px] text-cream/45">
        <span>{formatDay(shown[0]?.start ?? null, t)}</span>
        <span>{formatDay(shown.at(-1)?.start ?? null, t)}</span>
      </div>
    </div>
  );
}

function Heatmap({ data, t }: { data: number[][]; t: ReportCopy }) {
  const max = Math.max(...data.flat(), 1);
  return (
    <div className="grid grid-cols-[88px_repeat(7,minmax(0,1fr))] gap-1 text-xs">
      <span />
      {t.weekdays.map((d) => (
        <span key={d} className="text-center text-cream/55">
          {d}
        </span>
      ))}
      {data.map((row, s) => (
        <Row key={s} label={t.slots[s]} row={row} max={max} />
      ))}
    </div>
  );
}

function Row({ label, row, max }: { label: string; row: number[]; max: number }) {
  return (
    <>
      <span className="self-center text-cream/55">{label}</span>
      {row.map((v, i) => (
        <span
          key={i}
          className="flex h-8 items-center justify-center rounded-sm font-mono"
          style={{
            backgroundColor: `rgba(201, 160, 53, ${v ? 0.12 + (v / max) * 0.78 : 0.05})`,
            color: v / max > 0.55 ? "#0e2718" : undefined,
          }}
        >
          {v || ""}
        </span>
      ))}
    </>
  );
}

function Breakdown({
  data,
  empty,
  label = (k) => k,
  swatch,
}: {
  data: Record<string, number>;
  empty: string;
  label?: (k: string) => string;
  swatch?: (k: string) => string | undefined;
}) {
  const entries = Object.entries(data).sort((a, b) => b[1] - a[1]);
  const total = entries.reduce((s, [, v]) => s + v, 0) || 1;
  if (!entries.length) return <p className="text-sm text-cream/55">{empty}</p>;
  return (
    <ul className="space-y-1.5 text-sm">
      {entries.map(([k, v]) => (
        <li key={k} className="flex items-center gap-3">
          {swatch ? (
            <span
              className="h-3 w-3 shrink-0 rounded-full border border-cream/30"
              style={{ backgroundColor: swatch(k) ?? "transparent" }}
            />
          ) : null}
          <span className="flex-1">{label(k)}</span>
          <span className="font-mono text-cream/80">{v}</span>
          <span className="w-12 text-right font-mono text-xs text-cream/45">{Math.round((v / total) * 100)} %</span>
        </li>
      ))}
    </ul>
  );
}

function Section({ title, children, flush }: { title: string; children: React.ReactNode; flush?: boolean }) {
  return (
    <section className={flush ? "" : "mt-12"}>
      <h2 className="marginal mb-4">{title}</h2>
      {children}
    </section>
  );
}

function Stat({ label, value, note }: { label: string; value: string; note?: string }) {
  return (
    <div className="bg-night/85 p-5">
      <dt className="marginal">{label}</dt>
      <dd className="mt-1.5 font-mono text-3xl text-cream/80">{value}</dd>
      {note ? <dd className="mt-1 text-xs text-cream/45">{note}</dd> : null}
    </div>
  );
}

function formatDuration(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = Math.round(minutes % 60);
  return h ? `${h}:${String(m).padStart(2, "0")} h` : `${m} min`;
}

/** Datum `YYYY-MM-DD` in der Schreibweise der Sprache. */
function formatDay(day: string | null, t: ReportCopy): string {
  if (!day) return "–";
  const [y, m, d] = day.split("-");
  return t.locale.startsWith("de") ? `${d}.${m}.${y}` : `${d}/${m}/${y}`;
}
