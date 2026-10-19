import Link from "next/link";
import type { AdRecord } from "@/lib/ads";

/**
 * „Aktuelle Werbepartner" auf /werbung: wer gerade in den Zählkarten läuft.
 *
 * Eine Umkreisbuchung legt je Platzart (Golf, Minigolf) eine eigene Anzeige
 * an – hier zählt aber der Werbende, nicht der Werbeplatz. Deshalb wird nach
 * Werbendem und Ziel zusammengefasst. Jede Karte führt auf die Zwischenseite
 * `/werbung/<id>`, wie ein Tipp in der App.
 */
export function AdPartners({
  ads,
  courseNames,
}: {
  ads: AdRecord[];
  courseNames: Map<string, string>;
}) {
  const partners = dedupe(ads);
  if (partners.length === 0) return null;

  return (
    <section className="mt-16 border-t rule pt-14">
      <h2 className="marginal">Aktuelle Werbepartner</h2>
      <p className="mt-4 max-w-2xl leading-relaxed text-cream/75">
        Diese Betriebe stehen gerade in den Zählkarten der App – jeweils bei den Plätzen in ihrer
        Nähe.
      </p>
      <ul className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {partners.map((ad) => (
          <li key={ad.id}>
            <Link
              href={`/werbung/${ad.id}`}
              className="flex h-full items-center gap-4 rounded-[4px] bg-[#0E2718] p-4 transition-colors hover:bg-[#123020]"
            >
              {ad.imageURL ? (
                // eslint-disable-next-line @next/next/no-img-element -- fremde Adresse, absichtlich ohne Optimierung
                <img src={ad.imageURL} alt="" className="size-14 shrink-0 rounded-lg object-cover" />
              ) : (
                <span className="grid size-14 shrink-0 place-items-center rounded-lg bg-[#1C4129] text-xl text-[#C9A035]">
                  ★
                </span>
              )}
              <span className="min-w-0 flex-1">
                <span className="block truncate font-semibold text-white">
                  {ad.advertiser || ad.title}
                </span>
                <span className="block truncate text-sm text-white/65">
                  {ad.advertiser ? ad.title : ad.subtitle}
                </span>
                <span className="mt-1 block truncate font-mono text-[0.65rem] uppercase tracking-[0.1em] text-white/45">
                  {region(ad, courseNames)}
                </span>
              </span>
              <span className="text-white/30">›</span>
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}

function dedupe(ads: AdRecord[]): AdRecord[] {
  const seen = new Set<string>();
  const result: AdRecord[] = [];
  for (const ad of ads) {
    const key = `${(ad.advertiser || ad.title).trim().toLowerCase()}|${ad.linkURL.trim().toLowerCase()}`;
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(ad);
  }
  return result.sort((a, b) =>
    (a.advertiser || a.title).localeCompare(b.advertiser || b.title, "de"),
  );
}

function region(ad: AdRecord, courseNames: Map<string, string>): string {
  if (ad.courseSlug) return courseNames.get(ad.courseSlug) ?? ad.courseSlug;
  if (ad.radiusKm != null && ad.latitude != null && ad.longitude != null) {
    return ad.placeName ? `${ad.radiusKm} km um ${ad.placeName}` : `Umkreis ${ad.radiusKm} km`;
  }
  return "Alle Plätze";
}
