import { SPRACHEN, vorauswahl } from "@/lib/aushang";

/**
 * Sprachen wählen, Aushang als PDF laden. Ein schlichtes GET-Formular auf
 * `/qr/<kennung>/aushang` – geht auch ohne JavaScript. Vorausgewählt sind
 * Landessprache, Deutsch und Englisch.
 */
export function AushangPicker({
  slug,
  country,
  copy,
  open = false,
}: {
  slug: string;
  country: string;
  copy: { sheet: string; sheetHint: string; sheetButton: string; sheetCodeOnly: string; qrTitle: string };
  open?: boolean;
}) {
  const vorgewaehlt = vorauswahl(country);
  return (
    <details className="group" open={open}>
      <summary className="tap inline-block cursor-pointer list-none font-mono text-xs text-brass underline underline-offset-4">
        ↓ {copy.sheet}
      </summary>
      <form action={`/qr/${slug}/aushang`} method="get" className="mt-3">
        <div className="flex flex-wrap gap-1.5">
          {SPRACHEN.map((sprache) => (
            <label
              key={sprache}
              className="cursor-pointer rounded-full border rule px-2.5 py-1 font-mono text-xs text-cream/70 has-[:checked]:border-brass has-[:checked]:bg-brass has-[:checked]:text-[#1c1400]"
            >
              <input
                type="checkbox"
                name="sprache"
                value={sprache}
                defaultChecked={vorgewaehlt.includes(sprache)}
                className="sr-only"
              />
              {sprache.toUpperCase()}
            </label>
          ))}
        </div>
        <p className="mt-2 text-xs leading-relaxed text-cream/50">{copy.sheetHint}</p>
        <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-2">
          <button type="submit" className="btn-brass !min-h-9 !px-4 !py-2 !text-sm">
            {copy.sheetButton}
          </button>
          <a
            href={`/qr/${slug}?format=code`}
            title={copy.qrTitle}
            className="tap font-mono text-xs text-cream/55 underline underline-offset-4"
          >
            {copy.sheetCodeOnly}
          </a>
        </div>
      </form>
    </details>
  );
}
