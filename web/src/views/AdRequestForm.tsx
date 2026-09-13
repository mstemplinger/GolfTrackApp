"use client";

import { useMemo, useState } from "react";

export interface CourseMarker {
  slug: string;
  name: string;
  kind: "golf" | "minigolf";
  lat: number;
  lon: number;
}

/** Wählbare Umkreise. Mehr Stufen helfen niemandem beim Entscheiden. */
const RADII = [5, 10, 25, 50, 100];
/** Wählbare Laufzeiten in Monaten. */
const DURATIONS = [1, 3, 6, 12];

/** Entfernung zweier Punkte in Kilometern (Haversine). */
function distanceKm(aLat: number, aLon: number, bLat: number, bLon: number): number {
  const toRad = (v: number) => (v * Math.PI) / 180;
  const dLat = toRad(bLat - aLat);
  const dLon = toRad(bLon - aLon);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.min(1, Math.sqrt(h)));
}

/**
 * Buchungsanfrage für den Werbeplatz.
 *
 * Gebucht wird **kein einzelner Platz**, sondern ein Umkreis: Wer wirbt, sitzt
 * an einem Ort und will die Gäste der Anlagen ringsum erreichen. Wie viele das
 * sind, steht sofort daneben – das ist die Zahl, die über die Buchung
 * entscheidet, und sie soll nicht erst in einer Mail auftauchen.
 */
export function AdRequestForm({ markers }: { markers: CourseMarker[] }) {
  const [values, setValues] = useState({
    placeName: "",
    latitude: "",
    longitude: "",
    title: "",
    subtitle: "",
    linkURL: "",
    imageURL: "",
    advertiser: "",
    submitterName: "",
    submitterEmail: "",
    submitterPhone: "",
    requestNote: "",
    company: "",
  });
  const [radiusKm, setRadiusKm] = useState(25);
  const [months, setMonths] = useState(3);
  const [geoError, setGeoError] = useState(false);
  const [consent, setConsent] = useState(false);
  const [state, setState] = useState<"idle" | "sending" | "done">("idle");
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  const set = (key: keyof typeof values, value: string) =>
    setValues((previous) => ({ ...previous, [key]: value }));

  const centre = useMemo(() => {
    const lat = Number(values.latitude.replace(",", "."));
    const lon = Number(values.longitude.replace(",", "."));
    if (!values.latitude || !values.longitude || !Number.isFinite(lat) || !Number.isFinite(lon)) {
      return null;
    }
    return { lat, lon };
  }, [values.latitude, values.longitude]);

  /** Welche Plätze der gewählte Umkreis trifft – dieselbe Rechnung wie im Gerät. */
  const reached = useMemo(() => {
    if (!centre) return [];
    return markers
      .map((m) => ({ ...m, km: distanceKm(centre.lat, centre.lon, m.lat, m.lon) }))
      .filter((m) => m.km <= radiusKm)
      .sort((a, b) => a.km - b.km);
  }, [centre, markers, radiusKm]);

  function applyCurrentLocation() {
    if (!navigator.geolocation) {
      setGeoError(true);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setGeoError(false);
        set("latitude", position.coords.latitude.toFixed(6));
        set("longitude", position.coords.longitude.toFixed(6));
      },
      () => setGeoError(true),
      { enableHighAccuracy: true, timeout: 10_000 },
    );
  }

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    setState("sending");
    setError(null);
    setFieldErrors({});

    try {
      const response = await fetch("/api/ads/request", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...values,
          latitude: Number(values.latitude.replace(",", ".")),
          longitude: Number(values.longitude.replace(",", ".")),
          radiusKm,
          requestedMonths: months,
          consent,
        }),
      });

      if (response.ok) {
        setState("done");
        window.scrollTo({ top: 0, behavior: "smooth" });
        return;
      }

      const body = await response.json().catch(() => null);
      if (response.status === 429) {
        setError("Zu viele Anfragen von hier. Bitte später noch einmal versuchen.");
      } else if (response.status === 422 && body?.error === "no_courses_in_radius") {
        setError("In diesem Umkreis liegt noch kein eingetragener Platz. Größeren Umkreis wählen oder die Anlage zuerst eintragen lassen.");
      } else if (response.status === 422) {
        setError("Bitte die markierten Felder prüfen.");
        const map: Record<string, string> = {};
        for (const issue of body?.issues ?? []) map[issue.path] = issue.message;
        setFieldErrors(map);
      } else {
        setError("Das hat nicht geklappt. Bitte später noch einmal versuchen.");
      }
      setState("idle");
    } catch {
      setError("Das hat nicht geklappt. Bitte später noch einmal versuchen.");
      setState("idle");
    }
  }

  if (!markers.length) {
    return (
      <div className="paper rounded-[4px] p-8">
        <h2 className="font-display text-xl tracking-tight">Noch kein Platz mit Koordinaten</h2>
        <p className="mt-3 max-w-md leading-relaxed text-ink/70">
          Umkreis-Werbung braucht Plätze, die auf der Karte liegen. Sobald der erste eingetragen und
          freigegeben ist, steht hier das Formular.
        </p>
      </div>
    );
  }

  if (state === "done") {
    return (
      <div className="paper reveal rounded-[4px] p-10 text-center">
        <span aria-hidden className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-fairway/15">
          <svg viewBox="0 0 24 24" className="h-7 w-7" fill="none" stroke="#28824b" strokeWidth="2">
            <path d="M4 12.5 9.5 18 20 6.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </span>
        <h2 className="mt-5 font-display text-3xl tracking-tight">Anfrage ist da</h2>
        <p className="mx-auto mt-3 max-w-md leading-relaxed text-ink/70">
          Wir melden uns per Mail – meist innerhalb von zwei Tagen. Geschaltet wird erst, wenn
          Text, Laufzeit und Preis stehen.
        </p>
      </div>
    );
  }

  return (
    <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_18rem] lg:gap-12">
      <form onSubmit={submit} className="paper rounded-[4px] p-6 sm:p-10" noValidate>
        <h2 className="font-display text-2xl tracking-tight">Werbeplatz anfragen</h2>
        <p className="mt-2 max-w-lg text-sm leading-relaxed text-ink/70">
          Unverbindlich. Wir schreiben zurück, bevor irgendetwas läuft.
        </p>

        <Section title="Wo und wie weit">
          <Field
            label="Ihr Standort"
            htmlFor="placeName"
            hint="Nur zur Orientierung für uns – etwa „Kiosk am Seeufer, Musterdorf“."
            error={fieldErrors.placeName}
          >
            <input
              id="placeName"
              className="field"
              value={values.placeName}
              maxLength={120}
              onChange={(event) => set("placeName", event.target.value)}
              placeholder="Seebad Musterdorf"
            />
          </Field>

          <div className="grid gap-4 sm:grid-cols-[1fr_1fr_auto] sm:items-end">
            <Field label="Breite" htmlFor="latitude" required error={fieldErrors.latitude}>
              <input
                id="latitude"
                className="field font-mono"
                value={values.latitude}
                onChange={(event) => set("latitude", event.target.value)}
                placeholder="48.9906"
                inputMode="decimal"
                required
              />
            </Field>
            <Field label="Länge" htmlFor="longitude" required error={fieldErrors.longitude}>
              <input
                id="longitude"
                className="field font-mono"
                value={values.longitude}
                onChange={(event) => set("longitude", event.target.value)}
                placeholder="12.8114"
                inputMode="decimal"
                required
              />
            </Field>
            <button type="button" onClick={applyCurrentLocation} className="btn-ghost !py-2.5 text-sm">
              Standort verwenden
            </button>
          </div>
          {geoError ? (
            <p className="text-xs text-[#a6321f]">
              Der Standort ließ sich nicht ermitteln – bitte die Werte von Hand eintragen.
            </p>
          ) : null}

          <Field label="Umkreis" htmlFor="radius">
            <div className="flex flex-wrap gap-2" id="radius">
              {RADII.map((km) => (
                <button
                  key={km}
                  type="button"
                  onClick={() => setRadiusKm(km)}
                  aria-pressed={radiusKm === km}
                  className={`tap min-h-11 rounded-full border px-4 text-sm transition-colors ${
                    radiusKm === km
                      ? "border-fairway bg-fairway/10 text-ink"
                      : "border-ink/25 text-ink/70 hover:border-ink/50"
                  }`}
                >
                  {km} km
                </button>
              ))}
            </div>
          </Field>

          <ReachNote centre={Boolean(centre)} reached={reached} radiusKm={radiusKm} />

          <Field label="Laufzeit" htmlFor="months">
            <div className="flex flex-wrap gap-2" id="months">
              {DURATIONS.map((m) => (
                <button
                  key={m}
                  type="button"
                  onClick={() => setMonths(m)}
                  aria-pressed={months === m}
                  className={`tap min-h-11 rounded-full border px-4 text-sm transition-colors ${
                    months === m
                      ? "border-fairway bg-fairway/10 text-ink"
                      : "border-ink/25 text-ink/70 hover:border-ink/50"
                  }`}
                >
                  {m === 1 ? "1 Monat" : `${m} Monate`}
                </button>
              ))}
            </div>
          </Field>
        </Section>

        <Section title="Was auf der Karte steht">

          <Field
            label="Überschrift"
            htmlFor="title"
            required
            hint={`${values.title.length}/40 Zeichen`}
            error={fieldErrors.title}
          >
            <input
              id="title"
              className="field"
              value={values.title}
              maxLength={40}
              onChange={(event) => set("title", event.target.value)}
              placeholder="Kiosk am Platz"
              required
              aria-invalid={Boolean(fieldErrors.title)}
            />
          </Field>

          <Field label="Zeile darunter" htmlFor="subtitle" hint={`${values.subtitle.length}/80 Zeichen`} error={fieldErrors.subtitle}>
            <input
              id="subtitle"
              className="field"
              value={values.subtitle}
              maxLength={80}
              onChange={(event) => set("subtitle", event.target.value)}
              placeholder="Eis, Getränke, Snacks – gleich neben Bahn 1"
            />
          </Field>

          <div className="grid gap-4 sm:grid-cols-2">
            <Field
              label="Ziel beim Antippen"
              htmlFor="linkURL"
              hint="Ihre Website oder Speisekarte. Leer lassen, wenn es nichts zu öffnen gibt."
              error={fieldErrors.linkURL}
            >
              <input
                id="linkURL"
                className="field"
                value={values.linkURL}
                onChange={(event) => set("linkURL", event.target.value)}
                placeholder="https://…"
                inputMode="url"
              />
            </Field>
            <Field
              label="Bild"
              htmlFor="imageURL"
              hint="Adresse eines quadratischen Bildes. Haben Sie keines, schicken wir Ihnen einen Platz dafür."
              error={fieldErrors.imageURL}
            >
              <input
                id="imageURL"
                className="field"
                value={values.imageURL}
                onChange={(event) => set("imageURL", event.target.value)}
                placeholder="https://…"
                inputMode="url"
              />
            </Field>
          </div>

          <Field label="Wer wirbt" htmlFor="advertiser" hint="Der Name, der auf der Rechnung steht." error={fieldErrors.advertiser}>
            <input
              id="advertiser"
              className="field"
              value={values.advertiser}
              onChange={(event) => set("advertiser", event.target.value)}
              placeholder="Minigolf Sankt Englmar"
            />
          </Field>
        </Section>

        <Section title="Kontakt">
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Name" required htmlFor="submitterName" error={fieldErrors.submitterName}>
              <input
                id="submitterName"
                className="field"
                value={values.submitterName}
                onChange={(event) => set("submitterName", event.target.value)}
                required
                aria-invalid={Boolean(fieldErrors.submitterName)}
              />
            </Field>
            <Field label="E-Mail" required htmlFor="submitterEmail" error={fieldErrors.submitterEmail}>
              <input
                id="submitterEmail"
                className="field"
                type="email"
                value={values.submitterEmail}
                onChange={(event) => set("submitterEmail", event.target.value)}
                required
                aria-invalid={Boolean(fieldErrors.submitterEmail)}
              />
            </Field>
          </div>
          <Field label="Telefon" htmlFor="submitterPhone" hint="Freiwillig – manches klärt ein Anruf schneller.">
            <input
              id="submitterPhone"
              className="field"
              value={values.submitterPhone}
              onChange={(event) => set("submitterPhone", event.target.value)}
              inputMode="tel"
            />
          </Field>
          <Field label="Anmerkung" htmlFor="requestNote" hint="Wunschzeitraum, Fragen, alles was sonst noch dazugehört.">
            <textarea
              id="requestNote"
              className="field"
              rows={4}
              value={values.requestNote}
              onChange={(event) => set("requestNote", event.target.value)}
            />
          </Field>
        </Section>

        {/* Honigtopf – für Menschen unsichtbar. */}
        <div aria-hidden className="absolute left-[-9999px] h-0 w-0 overflow-hidden">
          <label htmlFor="company">Firma</label>
          <input
            id="company"
            name="company"
            tabIndex={-1}
            autoComplete="off"
            value={values.company}
            onChange={(event) => set("company", event.target.value)}
          />
        </div>

        <label className="mt-8 flex items-start gap-3 text-sm leading-relaxed text-ink/75">
          <input
            type="checkbox"
            checked={consent}
            onChange={(event) => setConsent(event.target.checked)}
            className="mt-1 size-4 shrink-0"
            required
          />
          <span>
            Die Angaben dürfen zur Bearbeitung dieser Anfrage gespeichert und per Mail beantwortet
            werden.
          </span>
        </label>

        <div className="mt-6 flex flex-wrap items-center gap-4">
          <button type="submit" disabled={state === "sending" || !consent} className="btn-brass">
            {state === "sending" ? "Wird geschickt …" : "Anfrage schicken"}
          </button>
          {error ? <p className="text-sm text-[#a6321f]">{error}</p> : null}
        </div>
      </form>

      <aside className="lg:sticky lg:top-8 lg:self-start">
        <h2 className="marginal">So sieht es aus</h2>
        <div className="mt-3 rounded-[4px] bg-[#0E2718] p-4">
          <div className="flex items-center gap-3 rounded-xl bg-[#163421] p-3">
            {values.imageURL ? (
              // eslint-disable-next-line @next/next/no-img-element -- fremde Adresse, absichtlich ohne Optimierung
              <img
                src={values.imageURL}
                alt=""
                className="size-11 shrink-0 rounded-lg object-cover"
                onError={(event) => {
                  event.currentTarget.style.visibility = "hidden";
                }}
              />
            ) : (
              <span className="grid size-11 shrink-0 place-items-center rounded-lg bg-[#1C4129] text-[#C9A035]">
                ★
              </span>
            )}
            <span className="min-w-0 flex-1">
              <span className="rounded-[3px] bg-white/10 px-1.5 py-px font-mono text-[0.55rem] uppercase tracking-[0.12em] text-white/55">
                Anzeige
              </span>
              <span className="mt-0.5 block truncate text-sm font-semibold text-white">
                {values.title || "Überschrift"}
              </span>
              <span className="block truncate text-xs text-white/60">
                {values.subtitle || "Zeile darunter"}
              </span>
            </span>
            <span className="text-white/30">›</span>
          </div>
        </div>
        <p className="mt-3 text-xs leading-relaxed text-cream/60">
          So steht die Anzeige während der ganzen Runde unter den Spielernamen – auf jedem Gerät,
          das den QR-Code Ihrer Anlage gescannt hat.
        </p>
      </aside>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="mt-10 border-t border-ink/15 pt-7">
      <h2 className="mb-5 font-display text-xl tracking-tight">{title}</h2>
      <div className="space-y-4">{children}</div>
    </section>
  );
}

function Field({
  label,
  htmlFor,
  hint,
  required,
  error,
  children,
}: {
  label: string;
  /** Kennung des Bedienelements – ohne die Verknüpfung findet ein
   *  Screenreader die Beschriftung nicht. */
  htmlFor: string;
  hint?: string;
  required?: boolean;
  error?: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label className="label" htmlFor={htmlFor}>
        {label}
        {required ? <span className="ml-1 text-[#a6321f]">*</span> : null}
      </label>
      {children}
      {hint ? <p className="mt-1.5 text-xs leading-relaxed text-ink/65">{hint}</p> : null}
      {error ? <p className="mt-1.5 text-xs text-[#a6321f]">{error}</p> : null}
    </div>
  );
}

/**
 * Wie viele Plätze der gewählte Umkreis trifft. Die Zahl entscheidet über die
 * Buchung – sie gehört neben den Regler und nicht in die Antwortmail.
 */
function ReachNote({
  centre,
  reached,
  radiusKm,
}: {
  centre: boolean;
  reached: { slug: string; name: string; kind: "golf" | "minigolf"; km: number }[];
  radiusKm: number;
}) {
  if (!centre) {
    return (
      <p className="rounded-[3px] border border-ink/15 bg-ink/[0.03] p-4 text-sm leading-relaxed text-ink/65">
        Sobald ein Standort steht, zeigen wir hier, wie viele Plätze im Umkreis liegen.
      </p>
    );
  }

  if (!reached.length) {
    return (
      <p className="rounded-[3px] border border-[#a6321f]/30 bg-[#a6321f]/5 p-4 text-sm leading-relaxed text-ink/75">
        In {radiusKm} km liegt kein eingetragener Platz. Größerer Umkreis oder Anlage zuerst eintragen.
      </p>
    );
  }

  const golf = reached.filter((r) => r.kind === "golf").length;
  const mini = reached.length - golf;
  // Nur ausschreiben, wenn beide Arten dabei sind – sonst steht da „5 Golf,
  // 0 Minigolf". (`golf && mini` hätte hier eine nackte 0 in die Seite
  // geschrieben; in JSX ist 0 ein sichtbarer Wert.)
  const split = golf > 0 && mini > 0 ? ` – ${golf} Golf, ${mini} Minigolf` : "";

  return (
    <div className="rounded-[3px] border border-fairway/30 bg-fairway/5 p-4">
      <p className="text-sm leading-relaxed text-ink/80">
        <strong className="font-semibold">
          {reached.length} {reached.length === 1 ? "Platz" : "Plätze"}
        </strong>{" "}
        im Umkreis von {radiusKm} km{split}.
      </p>
      <p className="mt-1 text-xs leading-relaxed text-ink/60">
        Die Anzeige läuft auf der Zählkarte – bei Golfrunden wie bei Minigolf.
      </p>
      <ul className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-ink/60">
        {reached.slice(0, 6).map((r) => (
          <li key={r.slug}>
            {r.name} · {r.km < 1 ? "<1" : Math.round(r.km)} km
          </li>
        ))}
        {reached.length > 6 ? <li>und {reached.length - 6} weitere</li> : null}
      </ul>
    </div>
  );
}
