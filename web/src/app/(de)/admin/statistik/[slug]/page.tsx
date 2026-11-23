import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import { getCourse } from "@/lib/courses";
import { MIN_ROUNDS_FOR_DISPLAY } from "@/lib/roundStats";
import { courseReport, type CourseReport, type HoleStat } from "@/lib/roundStatsReport";
import { TEE_META, isTeeColor } from "@/lib/tees";
import { PageHeader } from "../../ui";

export const metadata: Metadata = {
  title: "Rundenstatistik · GolfTrack",
  robots: { index: false, follow: false },
};

const PERIODS = [30, 90, 365] as const;
const WEEKDAYS = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];
const SLOT_LABELS = ["vormittags", "mittags", "nachmittags", "abends"];
const SOURCE_LABELS: Record<string, string> = {
  app: "App",
  clip: "App Clip",
  web: "Browser",
};

/**
 * Auswertung eines Platzes – so, wie sie später der Betreiber sehen soll,
 * nur ohne Mindestmengen-Sperre. Golf zeigt zusätzlich Par-Abweichung, Putts
 * und Abschläge; Minigolf die Hole-in-one-Quote.
 */
export default async function CourseRoundStatsPage({ params, searchParams }: PageProps<"/admin/statistik/[slug]">) {
  if (!(await isAuthenticated())) redirect("/admin");
  const { slug } = await params;
  const requested = Number((await searchParams).tage);
  const days = (PERIODS as readonly number[]).includes(requested) ? requested : 90;

  const course = await getCourse(slug);
  const sortedHoles = (course?.holeData ?? []).slice().sort((a, b) => a.number - b.number);
  const pars = sortedHoles.map((h) => h.par ?? null);
  const hcps = sortedHoles.map((h) => h.hcp ?? null);
  const report = await courseReport(slug, days, pars);
  if (!course && !report) notFound();

  const unit = (course?.kind ?? report?.kind) === "golf" ? "Loch" : "Bahn";

  return (
    <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8 lg:py-10">
      <PageHeader
        crumbs={[{ label: "Statistik", href: "/admin/statistik" }, { label: course?.name ?? slug }]}
        eyebrow={`Rundenstatistik · ${(course?.kind ?? report?.kind) === "golf" ? "Golf" : "Minigolf"}`}
        title={course?.name ?? slug}
        subtitle={course?.location || undefined}
        action={
          <nav className="flex gap-1 rounded-lg border border-white/10 p-1 text-sm" aria-label="Zeitraum">
            {PERIODS.map((p) => (
              <Link
                key={p}
                href={`/admin/statistik/${slug}?tage=${p}`}
                className={`rounded-sm px-3 py-1.5 transition-colors ${p === days ? "bg-brass text-night" : "text-cream/70 hover:text-brass"}`}
              >
                {p === 365 ? "1 Jahr" : `${p} Tage`}
              </Link>
            ))}
          </nav>
        }
      />

      {!report ? (
        <p className="mt-8 text-sm text-cream/65">In den letzten {days} Tagen wurden keine Runden gemeldet.</p>
      ) : (
        <Report report={report} unit={unit} hcps={hcps} />
      )}
    </div>
  );
}

function Report({ report, unit, hcps }: { report: CourseReport; unit: string; hcps: (number | null)[] }) {
  const golf = report.kind === "golf";
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

  return (
    <>
      {report.belowThreshold ? (
        <p className="mt-8 rounded-sm border border-brass/40 bg-brass/10 p-4 text-sm text-cream/80">
          Erst {report.rounds} {report.rounds === 1 ? "Runde" : "Runden"} in diesem Zeitraum. Ein Betreiber sähe hier
          noch nichts (Schwelle: {MIN_ROUNDS_FOR_DISPLAY} Runden).
        </p>
      ) : null}

      <dl className="mt-8 grid gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-4">
        <Stat label="Gemeldete Runden" value={report.rounds.toLocaleString("de-DE")} />
        <Stat
          label="Ø Spieldauer (Median)"
          value={report.medianDuration != null ? formatDuration(report.medianDuration) : "–"}
          note={`aus ${report.durationSamples} Runden mit Dauer`}
        />
        <Stat
          label="Ø Gruppengröße"
          value={report.avgGroup != null ? fmt(report.avgGroup, 1) : "–"}
          note={`${report.players} Spieler`}
        />
        <Stat label="Quelle" value={dominant(report.sources)} note={breakdown(report.sources, SOURCE_LABELS)} />
      </dl>

      {anomalies.length ? (
        <div className="mt-6 space-y-2">
          {anomalies.map((h) => (
            <p
              key={h.hole}
              className="rounded-sm border border-amber-400/40 bg-amber-400/10 p-3 text-sm text-amber-100"
            >
              ⚠ {unit} {h.hole} ist in den letzten 14 Tagen im Schnitt {fmt(h.anomaly!.recent - h.anomaly!.before, 1)}{" "}
              Schläge schwerer als davor ({fmt(h.anomaly!.before, 1)} → {fmt(h.anomaly!.recent, 1)}).
              {golf ? "" : " Vielleicht beschädigt?"}
            </p>
          ))}
        </div>
      ) : null}

      <Section title="Runden pro Woche">
        <WeekBars weeks={report.weeks} />
      </Section>

      <Section title="Wann ist viel los?">
        <Heatmap data={report.heatmap} />
      </Section>

      <Section title={`Schwierigkeit je ${unit}`}>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[520px] text-sm">
            <thead>
              <tr className="text-left text-xs text-cream/55">
                <th className="py-2 pr-3 font-normal">{unit}</th>
                {golf ? <th className="py-2 pr-3 font-normal">Par</th> : null}
                {showHcp ? (
                  <th className="py-2 pr-3 font-normal" title="Schwierigkeitsrang laut Scorecard / laut Runden">
                    HCP · real
                  </th>
                ) : null}
                <th className="py-2 pr-3 font-normal">Ø Schläge</th>
                <th className="w-1/3 py-2 pr-3 font-normal" aria-hidden />
                {golf ? <th className="py-2 pr-3 font-normal">über Par</th> : null}
                {golf ? (
                  <th className="py-2 pr-3 font-normal">Ø Putts</th>
                ) : (
                  <th className="py-2 pr-3 font-normal">Hole-in-one</th>
                )}
                <th className="py-2 font-normal text-right">Werte</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-cream/10">
              {report.holes.map((h) => (
                <HoleRow
                  key={h.hole}
                  h={h}
                  golf={golf}
                  width={Math.max(0, Math.round(((metric(h) ?? 0) / maxMetric) * 100))}
                  hcp={showHcp ? (hcps[h.hole - 1] ?? null) : undefined}
                  rank={rank.get(h.hole) ?? null}
                />
              ))}
            </tbody>
          </table>
        </div>
      </Section>

      <div className="mt-12 grid gap-8 sm:grid-cols-2">
        <Section title="Gespielte Länge" flush>
          <Breakdown data={report.holesPlayed} label={(k) => `${k} ${golf ? "Löcher" : "Bahnen"}`} />
        </Section>
        {golf ? (
          <Section title="Abschläge" flush>
            <Breakdown
              data={report.teeColors}
              label={(k) => (isTeeColor(k) ? TEE_META[k].label : k)}
              swatch={(k) => (isTeeColor(k) ? TEE_META[k].swatch : undefined)}
            />
          </Section>
        ) : null}
      </div>
    </>
  );
}

function HoleRow({
  h,
  golf,
  width,
  hcp,
  rank,
}: {
  h: HoleStat;
  golf: boolean;
  width: number;
  /** `undefined` = Spalte nicht zeigen. */
  hcp?: number | null;
  rank: number | null;
}) {
  // Weicht der echte Rang deutlich vom HCP-Index ab, lohnt ein Blick.
  const off = hcp != null && rank != null && Math.abs(hcp - rank) >= 6;
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

function WeekBars({ weeks }: { weeks: { start: string; rounds: number }[] }) {
  const shown = weeks.slice(-26);
  const max = Math.max(...shown.map((w) => w.rounds), 1);
  return (
    <div>
      <div className="flex h-36 items-stretch gap-1">
        {shown.map((w) => (
          <div
            key={w.start}
            className="flex h-full min-w-0 flex-1 flex-col items-center justify-end"
            title={`Woche ab ${formatDay(w.start)}: ${w.rounds}`}
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
        <span>{formatDay(shown[0]?.start ?? null)}</span>
        <span>{formatDay(shown.at(-1)?.start ?? null)}</span>
      </div>
    </div>
  );
}

function Heatmap({ data }: { data: number[][] }) {
  const max = Math.max(...data.flat(), 1);
  return (
    <div className="grid grid-cols-[88px_repeat(7,minmax(0,1fr))] gap-1 text-xs">
      <span />
      {WEEKDAYS.map((d) => (
        <span key={d} className="text-center text-cream/55">
          {d}
        </span>
      ))}
      {data.map((row, s) => (
        <Row key={s} label={SLOT_LABELS[s]} row={row} max={max} />
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
  label = (k) => k,
  swatch,
}: {
  data: Record<string, number>;
  label?: (k: string) => string;
  swatch?: (k: string) => string | undefined;
}) {
  const entries = Object.entries(data).sort((a, b) => b[1] - a[1]);
  const total = entries.reduce((s, [, v]) => s + v, 0) || 1;
  if (!entries.length) return <p className="text-sm text-cream/55">Keine Angaben.</p>;
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

function fmt(n: number, digits: number): string {
  return n.toLocaleString("de-DE", {
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  });
}

function signed(n: number): string {
  return `${n > 0 ? "+" : n < 0 ? "−" : "±"}${fmt(Math.abs(n), 2)}`;
}

function formatDuration(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = Math.round(minutes % 60);
  return h ? `${h}:${String(m).padStart(2, "0")} h` : `${m} min`;
}

function dominant(sources: Record<string, number>): string {
  const top = Object.entries(sources).sort((a, b) => b[1] - a[1])[0];
  return top ? (SOURCE_LABELS[top[0]] ?? top[0]) : "–";
}

function breakdown(data: Record<string, number>, labels: Record<string, string>): string {
  return Object.entries(data)
    .sort((a, b) => b[1] - a[1])
    .map(([k, v]) => `${labels[k] ?? k} ${v}`)
    .join(" · ");
}

function formatDay(day: string | null): string {
  if (!day) return "–";
  const [y, m, d] = day.split("-");
  return `${d}.${m}.${y}`;
}
