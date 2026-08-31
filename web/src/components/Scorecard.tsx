/**
 * Eine Scorekarte aus Papier – das Bildzeichen der Seite.
 * Die Zahlen sind echte Golfnotation: Kreis = unter Par, Quadrat = über Par.
 */
const HOLES = [
  { hole: 1, par: 4, score: 4 },
  { hole: 2, par: 3, score: 2 },
  { hole: 3, par: 5, score: 6 },
  { hole: 4, par: 4, score: 4 },
  { hole: 5, par: 4, score: 5 },
  { hole: 6, par: 3, score: 3 },
  { hole: 7, par: 5, score: 5 },
  { hole: 8, par: 4, score: 3 },
  { hole: 9, par: 4, score: 4 },
];

function ScoreMark({ par, score }: { par: number; score: number }) {
  const delta = score - par;
  const shape =
    delta < 0
      ? "rounded-full border-[1.5px] border-ink/70"
      : delta > 0
        ? "border-[1.5px] border-ink/45"
        : "border border-transparent";
  return (
    <span className={`grid h-7 w-7 place-items-center font-mono text-[0.95rem] ${shape}`}>{score}</span>
  );
}

export interface ScorecardLabels {
  title: string;
  hole: string;
  par: string;
  me: string;
  out: string;
}

export function Scorecard({
  caption,
  labels,
  className = "",
}: {
  caption: string;
  labels: ScorecardLabels;
  className?: string;
}) {
  const outPar = HOLES.reduce((sum, h) => sum + h.par, 0);
  const outScore = HOLES.reduce((sum, h) => sum + h.score, 0);

  return (
    <figure className={`paper rounded-[4px] p-5 sm:p-7 ${className}`}>
      <div className="flex items-baseline justify-between border-b border-ink/15 pb-3">
        <div>
          <p className="font-mono text-[0.62rem] uppercase tracking-[0.24em] text-ink/65">{labels.title}</p>
          <p className="mt-1 font-display text-lg leading-tight">Bayerwald · Gelb</p>
        </div>
        <p className="font-mono text-[0.7rem] text-ink/65">CR 71,4 / 130</p>
      </div>

      <table className="mt-4 w-full border-collapse text-center">
        <thead>
          <tr className="font-mono text-[0.6rem] uppercase tracking-[0.18em] text-ink/65">
            <th scope="col" className="pb-2 text-left font-normal">
              {labels.hole}
            </th>
            {HOLES.map((h) => (
              <th key={h.hole} scope="col" className="pb-2 font-normal">
                {h.hole}
              </th>
            ))}
            <th scope="col" className="pb-2 font-normal text-ink/70">
              {labels.out}
            </th>
          </tr>
        </thead>
        <tbody className="font-mono text-[0.82rem]">
          <tr className="border-t border-ink/10 text-ink/70">
            <th scope="row" className="py-2 text-left text-[0.6rem] uppercase tracking-[0.18em] font-normal">
              {labels.par}
            </th>
            {HOLES.map((h) => (
              <td key={h.hole} className="py-2">
                {h.par}
              </td>
            ))}
            <td className="py-2 text-ink/75">{outPar}</td>
          </tr>
          <tr className="border-t border-ink/10">
            <th scope="row" className="py-1.5 text-left text-[0.6rem] uppercase tracking-[0.18em] font-normal text-ink/70">
              {labels.me}
            </th>
            {HOLES.map((h) => (
              <td key={h.hole} className="py-1.5">
                <span className="inline-grid place-items-center">
                  <ScoreMark par={h.par} score={h.score} />
                </span>
              </td>
            ))}
            <td className="py-1.5 font-medium">{outScore}</td>
          </tr>
        </tbody>
      </table>

      <figcaption className="mt-4 border-t border-ink/15 pt-3 font-mono text-[0.62rem] uppercase tracking-[0.16em] text-ink/65">
        {caption}
      </figcaption>
    </figure>
  );
}
