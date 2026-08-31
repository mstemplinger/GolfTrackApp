import { Footer, Header, PageHeader } from "@/components/Chrome";
import { t } from "@/i18n/content";
import { SITE_URL, type Lang } from "@/i18n/routes";

const FIELDS: { name: string; type: string; de: string; en: string }[] = [
  { name: "id", type: "string", de: "Kennung des Platzes (slug)", en: "Course identifier (slug)" },
  { name: "kind", type: '"golf" | "minigolf"', de: "Art der Anlage", en: "Kind of venue" },
  { name: "name", type: "string", de: "Name der Anlage", en: "Name of the venue" },
  { name: "location", type: "string", de: "Ort", en: "Town" },
  { name: "holes", type: "number", de: "Anzahl Löcher bzw. Bahnen", en: "Number of holes or lanes" },
  { name: "lat / lon", type: "number | null", de: "Mittelpunkt der Anlage", en: "Centre of the venue" },
  { name: "parValues", type: "number[]", de: "Par je Loch – leer, wenn unvollständig", en: "Par per hole – empty if incomplete" },
  { name: "hcpValues", type: "number[]", de: "Stroke Index je Loch", en: "Stroke index per hole" },
  { name: "holeLengths", type: "number[]", de: "Länge je Loch in Metern", en: "Length per hole in metres" },
  { name: "courseRating", type: "number | null", de: "Course Rating", en: "Course rating" },
  { name: "slopeRating", type: "number | null", de: "Slope Rating", en: "Slope rating" },
  { name: "facilityNotes", type: "string", de: "Platzinfos", en: "Facilities" },
  { name: "welcome", type: "string", de: "Begrüßung für den QR-Start", en: "Welcome text for the QR start" },
  {
    name: "teeLatitudes …",
    type: "number[]",
    de: "Abschlag- und Fahnenkoordinaten je Loch",
    en: "Tee and pin coordinates per hole",
  },
  { name: "updatedAt", type: "string", de: "Letzte Änderung (ISO 8601)", en: "Last change (ISO 8601)" },
];

const EXAMPLE = `{
  "version": 1,
  "generatedAt": "2026-08-30T09:12:44.000Z",
  "count": 1,
  "courses": [
    {
      "id": "golf-und-landclub-bayerwald",
      "kind": "golf",
      "name": "Golf- und Landclub Bayerwald",
      "location": "Sankt Englmar",
      "holes": 18,
      "lat": 48.9906,
      "lon": 12.8114,
      "parValues": [4, 3, 5, "…"],
      "hcpValues": [5, 11, 1, "…"],
      "holeLengths": [320, 150, 480, "…"],
      "courseRating": 71.4,
      "slopeRating": 130,
      "updatedAt": "2026-08-30T09:10:00.000Z"
    }
  ]
}`;

export function ApiDocs({ lang }: { lang: Lang }) {
  const copy = t(lang).api;
  const de = lang === "de";

  return (
    <>
      <Header lang={lang} current="api" />
      <PageHeader index="13 — API" title={copy.title} lead={copy.lead} />
      <main className="mx-auto max-w-6xl px-5 py-14 sm:px-8 sm:py-16">
        <section className="max-w-4xl">
          <h2 className="marginal">{copy.endpointsTitle}</h2>
          <ul className="mt-4 divide-y rule border-y rule font-mono text-sm">
            <Endpoint
              method="GET"
              url="/api/v1/courses"
              note={de ? "Alle freigegebenen Anlagen" : "All approved venues"}
            />
            <Endpoint
              method="GET"
              url="/api/v1/courses?kind=minigolf"
              note={de ? "Nur Minigolfanlagen" : "Minigolf venues only"}
            />
            <Endpoint
              method="GET"
              url="/api/v1/courses/{id}"
              note={de ? "Eine einzelne Anlage" : "A single venue"}
            />
          </ul>
          <p className="mt-4 text-sm text-cream/65">
            {de
              ? "Antworten werden fünf Minuten zwischengespeichert und dürfen von jeder Herkunft abgefragt werden."
              : "Responses are cached for five minutes and may be requested from any origin."}
          </p>
        </section>

        <section className="mt-14 max-w-4xl">
          <h2 className="marginal">{copy.fieldsTitle}</h2>
          <dl className="mt-4 divide-y rule border-y rule">
            {FIELDS.map((field) => (
              <div key={field.name} className="grid gap-1 py-3 sm:grid-cols-[14rem_1fr] sm:gap-4">
                <dt className="font-mono text-sm text-brass-soft">{field.name}</dt>
                <dd className="text-sm text-cream/60">
                  <span className="font-mono text-xs text-cream/60">{field.type}</span>
                  <span className="mx-2 text-cream/20">·</span>
                  {de ? field.de : field.en}
                </dd>
              </div>
            ))}
          </dl>
        </section>

        <section className="mt-14 max-w-4xl">
          <h2 className="marginal">{copy.exampleTitle}</h2>
          <pre className="mt-4 overflow-x-auto rounded-sm border rule bg-moss/30 p-6 font-mono text-xs leading-relaxed text-cream/70">
            {EXAMPLE}
          </pre>
          <p className="mt-4">
            <a
              href="/api/v1/courses"
              className="tap break-all font-mono text-sm text-brass underline underline-offset-4"
              target="_blank"
              rel="noreferrer"
            >
              {SITE_URL}/api/v1/courses
            </a>
          </p>
        </section>
      </main>
      <Footer lang={lang} />
    </>
  );
}

function Endpoint({ method, url, note }: { method: string; url: string; note: string }) {
  return (
    <li className="flex flex-wrap items-baseline gap-x-4 gap-y-1 py-3.5">
      <span className="rounded-sm border border-fairway/40 px-2 py-0.5 text-[0.7rem] text-[#5fbe86]">{method}</span>
      <code className="text-cream/85">{url}</code>
      <span className="font-sans text-sm text-cream/65">{note}</span>
    </li>
  );
}
