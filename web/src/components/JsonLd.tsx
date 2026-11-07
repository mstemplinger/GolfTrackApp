import { t } from "@/i18n/content";
import { APP_STORE_URL, SITE_URL, path, type Lang } from "@/i18n/routes";
import type { CourseRecord } from "@/lib/courses";
import { isPlaceholder, site } from "@/lib/site";

/**
 * Strukturierte Daten (schema.org als JSON-LD) für Suchmaschinen und KI-Suche.
 * Sie beschreiben, was auf der Seite steht – App, Betreiber, Platz, häufige
 * Fragen –, damit Google & Co. das nicht aus dem Fließtext erraten müssen.
 *
 * `<` wird maskiert, wie es die Next.js-Anleitung verlangt: Namen und
 * Begrüßungstexte der Plätze kommen von Betreibern und dürfen das
 * Skript-Tag nicht schließen können.
 */
export function JsonLd({ data }: { data: object | object[] }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data).replace(/</g, "\\u003c") }}
    />
  );
}

const ORG_ID = `${SITE_URL}/#organization`;
const APP_ID = `${SITE_URL}/#app`;

export function organizationSchema() {
  return {
    "@context": "https://schema.org",
    "@type": "Organization",
    "@id": ORG_ID,
    name: "GolfTrack",
    url: SITE_URL,
    logo: `${SITE_URL}/logo.png`,
    founder: { "@type": "Person", name: site.operator },
    ...(isPlaceholder(site.email) ? {} : { email: site.email }),
    sameAs: [APP_STORE_URL],
  };
}

export function appSchema(lang: Lang) {
  const copy = t(lang).meta;
  return {
    "@context": "https://schema.org",
    "@type": "MobileApplication",
    "@id": APP_ID,
    name: "GolfTrack",
    description: copy.description,
    url: `${SITE_URL}${path("home", lang)}`,
    image: `${SITE_URL}/og.png`,
    applicationCategory: "SportsApplication",
    operatingSystem: "iOS, watchOS, Android",
    inLanguage: ["de", "en", "fr", "it", "es", "pl", "cs"],
    downloadUrl: [APP_STORE_URL, `${SITE_URL}${path("android", lang)}`],
    publisher: { "@id": ORG_ID },
    // Grundfunktionen kostenlos, Pro als Abo oder Einmalkauf.
    offers: [
      { "@type": "Offer", name: lang === "de" ? "Kostenlos" : "Free", price: "0", priceCurrency: "EUR" },
      { "@type": "Offer", name: lang === "de" ? "Pro monatlich" : "Pro monthly", price: "5", priceCurrency: "EUR" },
      { "@type": "Offer", name: lang === "de" ? "Pro jährlich" : "Pro yearly", price: "50", priceCurrency: "EUR" },
      { "@type": "Offer", name: lang === "de" ? "Pro einmalig" : "Pro one-time", price: "80", priceCurrency: "EUR" },
    ],
  };
}

export function faqSchema(lang: Lang) {
  return {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    inLanguage: lang,
    mainEntity: t(lang).support.faq.map((entry) => ({
      "@type": "Question",
      name: entry.q,
      acceptedAnswer: { "@type": "Answer", text: entry.a },
    })),
  };
}

/** Summe der Pars, wenn für jedes Loch eins hinterlegt ist. */
export function totalPar(course: CourseRecord): number | null {
  const pars = course.holeData.map((hole) => hole.par).filter((par): par is number => par !== null);
  return pars.length === course.holes && pars.length > 0 ? pars.reduce((sum, p) => sum + p, 0) : null;
}

/**
 * Beschreibung für Suchergebnis und Linkvorschau. Ohne Begrüßungstext des
 * Betreibers wird sie aus den Platzdaten gebaut, damit nicht alle Plätze
 * denselben Satz tragen.
 */
export function courseDescription(course: CourseRecord): string {
  if (course.welcome) return course.welcome;
  const where = course.location ? ` in ${course.location}` : "";
  if (course.kind === "minigolf") {
    return `Minigolfanlage ${course.name}${where} mit ${course.holes} Bahnen. Zähle deine Runde mit GolfTrack – Bahn für Bahn, für die ganze Gruppe, mit App, App Clip oder im Browser.`;
  }
  const par = totalPar(course);
  const facts = [`${course.holes} Löcher`, par ? `Par ${par}` : null].filter(Boolean).join(", ");
  return `Golfplatz ${course.name}${where} (${facts}): Scorekarte, Abschläge und Bahnlängen in GolfTrack. Zähle deine Runde Loch für Loch, gegen Par und mit Handicap.`;
}

export function courseSchema(course: CourseRecord) {
  const url = `${SITE_URL}/${course.kind === "minigolf" ? "minigolf" : "golf"}/${course.slug}`;
  const hasGeo = course.latitude !== null && course.longitude !== null;
  return {
    "@context": "https://schema.org",
    "@type": course.kind === "minigolf" ? "SportsActivityLocation" : "GolfCourse",
    "@id": `${url}#place`,
    name: course.name,
    url,
    description: courseDescription(course),
    ...(course.kind === "minigolf" ? { sport: "Minigolf" } : {}),
    // Nur der Ort: `country` ist bei importierten Plätzen nicht verlässlich
    // (tschechische Plätze tragen dort „DE“), ein falsches Land schadet mehr
    // als ein fehlendes.
    ...(course.location
      ? { address: { "@type": "PostalAddress", addressLocality: course.location } }
      : {}),
    ...(hasGeo
      ? { geo: { "@type": "GeoCoordinates", latitude: course.latitude, longitude: course.longitude } }
      : {}),
    ...(course.website ? { sameAs: [course.website] } : {}),
    ...(course.phone ? { telephone: course.phone } : {}),
    ...(course.publicEmail ? { email: course.publicEmail } : {}),
    additionalProperty: [
      { "@type": "PropertyValue", name: course.kind === "minigolf" ? "Bahnen" : "Löcher", value: course.holes },
      ...(totalPar(course) ? [{ "@type": "PropertyValue", name: "Par", value: totalPar(course) }] : []),
      ...(course.courseRating ? [{ "@type": "PropertyValue", name: "Course Rating", value: course.courseRating }] : []),
      ...(course.slopeRating ? [{ "@type": "PropertyValue", name: "Slope Rating", value: course.slopeRating }] : []),
    ],
  };
}
