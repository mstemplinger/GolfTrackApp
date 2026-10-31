import type { CourseRecord } from "@/lib/courses";
import { TEE_META } from "@/lib/tees";

/**
 * Abschläge eines Golfplatzes auf der öffentlichen Platzseite: Farbpunkt,
 * Wertung und Gesamtlänge, darunter – falls bekannt – die Längen je Loch.
 * Bewusst knapp; die eigentliche Scorekarte führt die App.
 */
export function CourseTees({ course }: { course: CourseRecord }) {
  if (course.kind !== "golf" || !course.tees.length) return null;

  const holes = [...course.holeData].sort((a, b) => a.number - b.number);
  const rows = course.tees.map((tee) => {
    const lengths = holes.map((hole) => hole.tees.find((t) => t.color === tee.color)?.length ?? null);
    const known = lengths.filter((value): value is number => value !== null);
    return { tee, lengths, total: known.length === course.holes ? known.reduce((a, b) => a + b, 0) : null };
  });
  const anyLengths = rows.some((row) => row.lengths.some((value) => value !== null));

  return (
    <section className="mx-auto mt-10 max-w-2xl text-left">
      <h2 className="marginal text-center">Abschläge</h2>
      <ul className="mt-4 divide-y rule border-y rule text-sm">
        {rows.map(({ tee, total }) => (
          <li key={tee.color} className="flex flex-wrap items-center gap-x-4 gap-y-1 py-2.5">
            <span className="flex min-w-24 items-center gap-2 text-cream/80">
              <Dot color={tee.color} />
              {TEE_META[tee.color].label}
            </span>
            <span className="font-mono text-cream/60">
              {tee.courseRating !== null || tee.slopeRating !== null
                ? `CR ${tee.courseRating?.toFixed(1).replace(".", ",") ?? "–"} / ${tee.slopeRating ?? "–"}`
                : ""}
            </span>
            {total !== null ? <span className="ml-auto font-mono text-cream/60">{total} m</span> : null}
          </li>
        ))}
      </ul>

      {anyLengths ? (
        <div className="mt-4 overflow-x-auto">
          <table className="w-full border-collapse text-center font-mono text-xs">
            <thead>
              <tr className="text-cream/45">
                <th scope="col" className="pb-1.5 pr-3 text-left font-normal">
                  Loch
                </th>
                {holes.map((hole) => (
                  <th key={hole.number} scope="col" className="px-1 pb-1.5 font-normal">
                    {hole.number}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map(({ tee, lengths }) => (
                <tr key={tee.color} className="border-t rule text-cream/70">
                  <th scope="row" className="py-1.5 pr-3 text-left font-normal">
                    <span className="flex items-center gap-1.5">
                      <Dot color={tee.color} />
                      <span className="sr-only">{TEE_META[tee.color].label}</span>
                    </span>
                  </th>
                  {lengths.map((value, index) => (
                    <td key={index} className="px-1 py-1.5">
                      {value ?? "–"}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </section>
  );
}

function Dot({ color }: { color: keyof typeof TEE_META }) {
  return (
    <span
      aria-hidden
      className="inline-block h-2.5 w-2.5 shrink-0 rounded-full border border-white/30"
      style={{ background: TEE_META[color].swatch }}
    />
  );
}
