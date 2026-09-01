import type { Metadata } from "next";
import Link from "next/link";
import { Footer, Header, PageHeader } from "@/components/Chrome";
import { SITE_URL } from "@/i18n/routes";
import { listCourses } from "@/lib/courses";
import { isPlaceholder, site } from "@/lib/site";
import { AdRequestForm } from "@/views/AdRequestForm";

/**
 * Angebotsseite für Anlagenbetreiber. Erreichbar aus der App: im freien Feld
 * unter den Spielernamen steht „Hier könnte Ihre Anlage stehen" – wer darauf
 * tippt, landet hier. Bewusst nicht in der Hauptnavigation; die Seite richtet
 * sich an eine Handvoll Betreiber, nicht an Besucher.
 */
export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: "Werbung auf der Anlage · GolfTrack",
  description:
    "Der Werbeplatz in der Minigolf-Zählkarte: sichtbar bei jeder Runde auf Ihrer Anlage, direkt in der Hand Ihrer Gäste.",
  alternates: { canonical: "/werbung" },
};

const STEPS = [
  {
    index: "01",
    title: "QR-Code aufhängen",
    text: "Am Kassenhäuschen oder an Bahn 1. Wer ihn scannt, startet die Runde direkt auf Ihrer Anlage – ohne Suchen, ohne Anmeldung.",
  },
  {
    index: "02",
    title: "Ihre Anzeige läuft mit",
    text: "Unter den Spielernamen steht während der ganzen Runde ein Feld: Bild, eine Zeile Text, ein Ziel beim Antippen. Der Kiosk, der Verleih, das Restaurant nebenan.",
  },
  {
    index: "03",
    title: "Sie sehen, was ankommt",
    text: "Wie oft die Anzeige zu sehen war und wie oft jemand darauf getippt hat – Tag für Tag. Ohne Nachverfolgung einzelner Gäste.",
  },
];

/** Neue Anlagen kommen laufend dazu – täglich neu bauen reicht. */
export const revalidate = 86400;

export default async function Page() {
  const courses = await listCourses({ status: "approved", kind: "minigolf", limit: 500 });

  return (
    <>
      <Header lang="de" />
      <PageHeader
        index="14 — Für Betreiber"
        title="Ihre Anlage im Blick der Gäste"
        lead="Eine Minigolfrunde dauert eine Dreiviertelstunde. So lange liegt die Zählkarte in der Hand – und darunter ist Platz für Sie."
      />

      <main className="mx-auto max-w-6xl px-5 py-14 sm:px-8 sm:py-16">
        <ol className="grid gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-3">
          {STEPS.map((step) => (
            <li key={step.index} className="bg-night/85 p-6">
              <p className="marginal">{step.index}</p>
              <h2 className="mt-3 font-display text-xl tracking-tight">{step.title}</h2>
              <p className="mt-2 text-sm leading-relaxed text-cream/70">{step.text}</p>
            </li>
          ))}
        </ol>

        <p className="mt-8">
          <Link href="#anfragen" className="btn-brass">
            Werbeplatz anfragen
          </Link>
        </p>

        <section className="mt-16 grid gap-12 lg:grid-cols-[1fr_20rem] lg:gap-16">
          <div>
            <h2 className="marginal">Was auf dem Platz steht</h2>
            <p className="mt-4 max-w-2xl leading-relaxed text-cream/75">
              Eine Überschrift mit höchstens 40 Zeichen, eine Zeile darunter mit höchstens 80, ein
              quadratisches Bild und die Adresse, die sich beim Antippen öffnet. Mehr passt nicht
              hin, ohne dass die Schrift unlesbar klein wird – und mehr braucht es auch nicht.
            </p>

            <div className="mt-6 max-w-md rounded-[4px] bg-[#0E2718] p-4">
              <div className="flex items-center gap-3 rounded-xl bg-[#163421] p-3">
                <span className="grid size-11 shrink-0 place-items-center rounded-lg bg-[#1C4129] text-[#C9A035]">
                  ★
                </span>
                <span className="min-w-0 flex-1">
                  <span className="rounded-[3px] bg-white/10 px-1.5 py-px font-mono text-[0.55rem] uppercase tracking-[0.12em] text-white/55">
                    Anzeige
                  </span>
                  <span className="mt-0.5 block truncate text-sm font-semibold text-white">
                    Kiosk am Platz
                  </span>
                  <span className="block truncate text-xs text-white/60">
                    Eis, Getränke, Snacks – gleich neben Bahn 1
                  </span>
                </span>
                <span className="text-white/30">›</span>
              </div>
            </div>

            <h2 className="marginal mt-12">Wie gebucht wird</h2>
            <p className="mt-4 max-w-2xl leading-relaxed text-cream/75">
              Über das Formular weiter unten: Anlage wählen, die zwei Zeilen tippen, abschicken.
              Die Anfrage landet als Entwurf bei uns – nichts geht ungesehen in die App. Laufzeit
              und Preis klären wir per Mail, danach wird geschaltet. Keine Auktion, kein
              Werbenetzwerk. Eine Anzeige für Ihre eigene Anlage hat dort immer Vorrang vor
              allgemeiner Werbung.
            </p>

            <h2 className="marginal mt-12">Was nicht passiert</h2>
            <ul className="mt-4 max-w-2xl space-y-2 leading-relaxed text-cream/75">
              <li>Kein Werbenetzwerk, keine fremden Skripte, keine Profilbildung.</li>
              <li>Gezählt wird nur, wie oft eine Anzeige zu sehen war und wie oft jemand tippte.</li>
              <li>Keine Gerätekennung, kein Standort, nichts, was auf einen Gast zurückführt.</li>
              <li>Wer ein Abo hat, sieht die Fläche gar nicht.</li>
            </ul>
          </div>

          <aside className="lg:pt-1">
            <h2 className="marginal">Lieber direkt schreiben?</h2>
            <p className="mt-4 text-sm leading-relaxed text-cream/70">
              Geht auch – mit dem Namen der Anlage im Betreff.
            </p>
            {isPlaceholder(site.email) ? (
              <p className="mt-4 text-sm text-cream/50">{site.email}</p>
            ) : (
              <a
                href={`mailto:${site.email}?subject=${encodeURIComponent("Werbeplatz in der GolfTrack-App")}`}
                className="btn-ghost mt-4 w-full"
              >
                Mail schreiben
              </a>
            )}
            <Link href="/platz-melden" className="btn-ghost mt-3 w-full">
              Anlage zuerst eintragen
            </Link>
            <p className="mt-4 text-xs leading-relaxed text-cream/55">
              Ihre Anlage muss auf golftrack.app eingetragen und freigegeben sein – erst dann gibt
              es einen QR-Code und damit einen Werbeplatz.
            </p>
          </aside>
        </section>

        <section id="anfragen" className="mt-16 scroll-mt-8 border-t rule pt-14">
          <AdRequestForm
            courses={courses.map((course) => ({
              slug: course.slug,
              name: course.name,
              location: course.location,
            }))}
          />
        </section>
      </main>

      <Footer lang="de" />
    </>
  );
}
