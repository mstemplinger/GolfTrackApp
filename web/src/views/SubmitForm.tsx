"use client";

import { useCallback, useMemo, useState } from "react";
import { t } from "@/i18n/content";
import type { Lang } from "@/i18n/routes";

type Kind = "golf" | "minigolf";

interface HoleRow {
  par: string;
  hcp: string;
  length: string;
}

const emptyRow = (): HoleRow => ({ par: "", hcp: "", length: "" });

/** Übliche Par-Folge einer 18-Loch-Anlage – nur als Startpunkt zum Überschreiben. */
const PAR_72 = [4, 3, 5, 4, 4, 3, 4, 5, 4, 4, 4, 3, 5, 4, 3, 4, 5, 4];

const numberOrNull = (value: string): number | null => {
  const trimmed = value.trim().replace(",", ".");
  if (!trimmed) return null;
  const parsed = Number(trimmed);
  return Number.isFinite(parsed) ? parsed : null;
};

export function SubmitForm({ lang }: { lang: Lang }) {
  const copy = t(lang).submit;

  const [kind, setKind] = useState<Kind>("golf");
  const [holes, setHoles] = useState(18);
  const [rows, setRows] = useState<HoleRow[]>(() => Array.from({ length: 18 }, emptyRow));
  const [values, setValues] = useState({
    name: "",
    location: "",
    country: "DE",
    latitude: "",
    longitude: "",
    courseRating: "",
    slopeRating: "",
    facilityNotes: "",
    welcome: "",
    website: "",
    phone: "",
    publicEmail: "",
    submitterName: "",
    submitterEmail: "",
    submitterRole: "",
    company: "",
  });
  const [consent, setConsent] = useState(false);
  const [state, setState] = useState<"idle" | "sending" | "done">("idle");
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [geoError, setGeoError] = useState(false);

  const set = useCallback((key: keyof typeof values, value: string) => {
    setValues((previous) => ({ ...previous, [key]: value }));
  }, []);

  const changeHoles = useCallback((count: number) => {
    const safe = Math.min(36, Math.max(1, count || 1));
    setHoles(safe);
    setRows((previous) => {
      const next = previous.slice(0, safe);
      while (next.length < safe) next.push(emptyRow());
      return next;
    });
  }, []);

  const setCell = useCallback((index: number, key: keyof HoleRow, value: string) => {
    setRows((previous) => previous.map((row, i) => (i === index ? { ...row, [key]: value } : row)));
  }, []);

  const fillPar = useCallback(() => {
    setRows((previous) =>
      previous.map((row, index) => ({ ...row, par: String(PAR_72[index % PAR_72.length]) })),
    );
  }, []);

  const fillHcp = useCallback(() => {
    setRows((previous) => previous.map((row, index) => ({ ...row, hcp: String(index + 1) })));
  }, []);

  const clearRows = useCallback(() => {
    setRows((previous) => previous.map(emptyRow));
  }, []);

  const useCurrentLocation = useCallback(() => {
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
  }, [set]);

  const parSum = useMemo(
    () => rows.reduce((sum, row) => sum + (Number(row.par) || 0), 0),
    [rows],
  );

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    setState("sending");
    setError(null);
    setFieldErrors({});

    const holeData = rows
      .map((row, index) => ({
        number: index + 1,
        par: row.par ? Number(row.par) : null,
        hcp: row.hcp ? Number(row.hcp) : null,
        length: row.length ? Number(row.length) : null,
        teeLat: null,
        teeLon: null,
        flagLat: null,
        flagLon: null,
      }))
      .filter((hole) => hole.par !== null || hole.hcp !== null || hole.length !== null);

    const payload = {
      kind,
      name: values.name,
      location: values.location,
      country: values.country || "DE",
      holes,
      latitude: numberOrNull(values.latitude),
      longitude: numberOrNull(values.longitude),
      courseRating: kind === "golf" ? numberOrNull(values.courseRating) : null,
      slopeRating: kind === "golf" ? numberOrNull(values.slopeRating) : null,
      holeData: holeData.length === holes ? holeData : [],
      facilityNotes: values.facilityNotes,
      welcome: values.welcome,
      website: values.website,
      phone: values.phone,
      publicEmail: values.publicEmail,
      submitterName: values.submitterName,
      submitterEmail: values.submitterEmail,
      submitterRole: values.submitterRole,
      consent,
      company: values.company,
    };

    try {
      const response = await fetch("/api/submissions", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        setState("done");
        window.scrollTo({ top: 0, behavior: "smooth" });
        return;
      }

      const body = await response.json().catch(() => null);
      if (response.status === 429) setError(copy.errorRateLimit);
      else if (response.status === 422) {
        setError(copy.errorValidation);
        const map: Record<string, string> = {};
        for (const issue of body?.issues ?? []) map[issue.path] = issue.message;
        setFieldErrors(map);
      } else setError(copy.errorGeneric);
      setState("idle");
    } catch {
      setError(copy.errorGeneric);
      setState("idle");
    }
  }

  if (state === "done") {
    return (
      <div className="paper reveal mx-auto max-w-2xl rounded-[4px] p-10 text-center">
        <span aria-hidden className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-fairway/15">
          <svg viewBox="0 0 24 24" className="h-7 w-7" fill="none" stroke="#28824b" strokeWidth="2">
            <path d="M4 12.5 9.5 18 20 6.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </span>
        <h2 className="mt-5 font-display text-3xl tracking-tight">{copy.successTitle}</h2>
        <p className="mx-auto mt-3 max-w-md leading-relaxed text-ink/70">{copy.successBody}</p>
        <button
          type="button"
          onClick={() => {
            setState("idle");
            setValues((previous) => ({ ...previous, name: "", location: "", welcome: "", facilityNotes: "" }));
            setRows(Array.from({ length: holes }, emptyRow));
            setConsent(false);
          }}
          className="tap mt-5 text-sm font-medium text-[#1c6a3c] underline underline-offset-4 hover:text-ink"
        >
          {copy.successAgain}
        </button>
      </div>
    );
  }

  const isGolf = kind === "golf";

  return (
    <form onSubmit={submit} className="paper mx-auto max-w-3xl rounded-[4px] p-6 sm:p-10" noValidate>
      {/* Art der Anlage */}
      <fieldset>
        <legend className="label">{copy.kindLabel}</legend>
        <div className="grid gap-3 sm:grid-cols-2">
          {(
            [
              { value: "golf" as const, title: copy.kindGolf, hint: copy.kindGolfHint },
              { value: "minigolf" as const, title: copy.kindMinigolf, hint: copy.kindMinigolfHint },
            ]
          ).map((option) => (
            <label
              key={option.value}
              className={`cursor-pointer rounded-[3px] border p-4 transition-all ${
                kind === option.value
                  ? "border-fairway bg-fairway/8 shadow-[0_0_0_3px_rgba(40,130,75,0.12)]"
                  : "border-ink/20 hover:border-ink/40"
              }`}
            >
              <input
                type="radio"
                name="kind"
                value={option.value}
                checked={kind === option.value}
                onChange={() => {
                  setKind(option.value);
                  if (option.value === "minigolf") changeHoles(18);
                }}
                className="sr-only"
              />
              <span className="block font-display text-lg tracking-tight">{option.title}</span>
              <span className="mt-0.5 block text-sm text-ink/70">{option.hint}</span>
            </label>
          ))}
        </div>
      </fieldset>

      <Section title={copy.sectionBasics}>
        <Field label={copy.name} required error={fieldErrors.name}>
          <input
            className="field"
            value={values.name}
            onChange={(e) => set("name", e.target.value)}
            placeholder={copy.namePlaceholder}
            required
            aria-invalid={Boolean(fieldErrors.name)}
          />
        </Field>
        <div className="grid gap-4 sm:grid-cols-[2fr_1fr]">
          <Field label={copy.location} error={fieldErrors.location}>
            <input
              className="field"
              value={values.location}
              onChange={(e) => set("location", e.target.value)}
              placeholder={copy.locationPlaceholder}
            />
          </Field>
          <Field label={copy.country}>
            <input
              className="field uppercase"
              value={values.country}
              onChange={(e) => set("country", e.target.value.toUpperCase().slice(0, 2))}
              maxLength={2}
              placeholder="DE"
            />
          </Field>
        </div>
        <Field label={isGolf ? copy.holes : copy.holesMinigolf} required>
          <input
            className="field max-w-32"
            type="number"
            min={1}
            max={36}
            value={holes}
            onChange={(e) => changeHoles(Number(e.target.value))}
            required
          />
        </Field>
        <Field label={copy.coordinates} hint={copy.coordinatesHint}>
          <div className="grid gap-3 sm:grid-cols-[1fr_1fr_auto]">
            <input
              className="field"
              value={values.latitude}
              onChange={(e) => set("latitude", e.target.value)}
              placeholder={copy.latitude}
              inputMode="decimal"
              aria-label={copy.latitude}
            />
            <input
              className="field"
              value={values.longitude}
              onChange={(e) => set("longitude", e.target.value)}
              placeholder={copy.longitude}
              inputMode="decimal"
              aria-label={copy.longitude}
            />
            <button
              type="button"
              onClick={useCurrentLocation}
              className="tap min-h-11 whitespace-nowrap rounded-[3px] border border-ink/25 px-4 text-sm transition-colors hover:border-ink/50 hover:bg-ink/5"
            >
              {copy.useLocation}
            </button>
          </div>
          {geoError ? <p className="mt-2 text-sm text-[#a6321f]">{copy.locationDenied}</p> : null}
        </Field>
      </Section>

      {isGolf ? (
        <Section title={copy.sectionRating}>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label={copy.courseRating} hint={copy.courseRatingHint} error={fieldErrors.courseRating}>
              <input
                className="field"
                value={values.courseRating}
                onChange={(e) => set("courseRating", e.target.value)}
                placeholder="71,4"
                inputMode="decimal"
              />
            </Field>
            <Field label={copy.slopeRating} hint={copy.slopeRatingHint} error={fieldErrors.slopeRating}>
              <input
                className="field"
                value={values.slopeRating}
                onChange={(e) => set("slopeRating", e.target.value)}
                placeholder="113"
                inputMode="numeric"
              />
            </Field>
          </div>
        </Section>
      ) : null}

      {/* Lochtabelle */}
      <Section title={isGolf ? copy.sectionHoles : copy.sectionHolesMinigolf}>
        <p className="-mt-1 text-sm leading-relaxed text-ink/70">
          {isGolf ? copy.holeTableHint : copy.holeTableHintMinigolf}
        </p>
        <div className="mt-3 flex flex-wrap gap-2">
          <TableButton onClick={fillPar}>{copy.autofillPar}</TableButton>
          {isGolf ? <TableButton onClick={fillHcp}>{copy.autofillHcp}</TableButton> : null}
          <TableButton onClick={clearRows}>{copy.clearHoles}</TableButton>
        </div>

        <div className="mt-4 overflow-x-auto">
          <table className="w-full min-w-[26rem] border-collapse">
            <thead>
              <tr className="font-mono text-[0.6rem] uppercase tracking-[0.16em] text-ink/65">
                <th scope="col" className="w-14 pb-2 text-left font-normal">
                  {isGolf ? copy.colHole : copy.colLane}
                </th>
                <th scope="col" className="pb-2 text-left font-normal">
                  {copy.colPar}
                </th>
                {isGolf ? (
                  <>
                    <th scope="col" className="pb-2 text-left font-normal">
                      {copy.colHcp}
                    </th>
                    <th scope="col" className="pb-2 text-left font-normal">
                      {copy.colLength}
                    </th>
                  </>
                ) : null}
              </tr>
            </thead>
            <tbody>
              {rows.map((row, index) => (
                <tr key={index} className="border-t border-ink/10">
                  <th
                    scope="row"
                    className="py-1.5 pr-3 text-left font-mono text-sm font-normal text-ink/70"
                  >
                    {index + 1}
                  </th>
                  <td className="py-1.5 pr-2">
                    <input
                      className="field field--tight !py-1.5 font-mono"
                      value={row.par}
                      onChange={(e) => setCell(index, "par", e.target.value)}
                      inputMode="numeric"
                      aria-label={`${copy.colPar} ${index + 1}`}
                    />
                  </td>
                  {isGolf ? (
                    <>
                      <td className="py-1.5 pr-2">
                        <input
                          className="field field--tight !py-1.5 font-mono"
                          value={row.hcp}
                          onChange={(e) => setCell(index, "hcp", e.target.value)}
                          inputMode="numeric"
                          aria-label={`${copy.colHcp} ${index + 1}`}
                        />
                      </td>
                      <td className="py-1.5">
                        <input
                          className="field field--tight !py-1.5 font-mono"
                          value={row.length}
                          onChange={(e) => setCell(index, "length", e.target.value)}
                          inputMode="numeric"
                          aria-label={`${copy.colLength} ${index + 1}`}
                        />
                      </td>
                    </>
                  ) : null}
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr className="border-t border-ink/25 font-mono text-sm">
                <th scope="row" className="pt-2 text-left text-[0.6rem] uppercase tracking-[0.16em] font-normal text-ink/65">
                  Σ
                </th>
                <td className="pt-2 pl-2 text-ink/70">{parSum || "–"}</td>
              </tr>
            </tfoot>
          </table>
        </div>
        {fieldErrors.holeData ? (
          <p className="mt-2 text-sm text-[#a6321f]">{copy.errorValidation}</p>
        ) : null}
      </Section>

      <Section title={copy.sectionExtras}>
        <Field label={copy.facilityNotes} hint={copy.facilityNotesHint}>
          <textarea
            className="field min-h-24"
            value={values.facilityNotes}
            onChange={(e) => set("facilityNotes", e.target.value)}
            rows={3}
          />
        </Field>
        <Field label={copy.welcome} hint={copy.welcomeHint}>
          <textarea
            className="field min-h-20"
            value={values.welcome}
            onChange={(e) => set("welcome", e.target.value)}
            rows={2}
            maxLength={400}
          />
        </Field>
        <div className="grid gap-4 sm:grid-cols-3">
          <Field label={copy.website} error={fieldErrors.website}>
            <input
              className="field"
              value={values.website}
              onChange={(e) => set("website", e.target.value)}
              placeholder="https://"
              inputMode="url"
            />
          </Field>
          <Field label={copy.phone}>
            <input
              className="field"
              value={values.phone}
              onChange={(e) => set("phone", e.target.value)}
              inputMode="tel"
            />
          </Field>
          <Field label={copy.publicEmail} error={fieldErrors.publicEmail}>
            <input
              className="field"
              value={values.publicEmail}
              onChange={(e) => set("publicEmail", e.target.value)}
              inputMode="email"
            />
          </Field>
        </div>
        <p className="text-xs text-ink/65">{copy.publicContactHint}</p>
      </Section>

      <Section title={copy.sectionContact}>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label={copy.submitterName} required error={fieldErrors.submitterName}>
            <input
              className="field"
              value={values.submitterName}
              onChange={(e) => set("submitterName", e.target.value)}
              required
              autoComplete="name"
              aria-invalid={Boolean(fieldErrors.submitterName)}
            />
          </Field>
          <Field label={copy.submitterEmail} required hint={copy.submitterEmailHint} error={fieldErrors.submitterEmail}>
            <input
              className="field"
              type="email"
              value={values.submitterEmail}
              onChange={(e) => set("submitterEmail", e.target.value)}
              required
              autoComplete="email"
              aria-invalid={Boolean(fieldErrors.submitterEmail)}
            />
          </Field>
        </div>
        <Field label={copy.submitterRole}>
          <input
            className="field"
            value={values.submitterRole}
            onChange={(e) => set("submitterRole", e.target.value)}
            placeholder={copy.submitterRolePlaceholder}
          />
        </Field>

        {/* Honigtopf */}
        <div aria-hidden className="absolute left-[-9999px] h-0 w-0 overflow-hidden">
          <label>
            Firma
            <input
              tabIndex={-1}
              autoComplete="off"
              value={values.company}
              onChange={(e) => set("company", e.target.value)}
            />
          </label>
        </div>

        <label className="mt-2 flex min-h-11 cursor-pointer items-start gap-3 py-1 text-sm leading-relaxed text-ink/70">
          <input
            type="checkbox"
            checked={consent}
            onChange={(e) => setConsent(e.target.checked)}
            required
            className="mt-0.5 h-6 w-6 shrink-0 accent-[#28824b]"
          />
          {copy.consent}
        </label>
      </Section>

      {error ? (
        <div role="alert" className="mt-6 rounded-[3px] border border-[#a6321f]/40 bg-[#a6321f]/8 p-4">
          <p className="font-medium text-[#a6321f]">{copy.errorTitle}</p>
          <p className="mt-1 text-sm text-ink/70">{error}</p>
        </div>
      ) : null}

      <button type="submit" disabled={state === "sending" || !consent} className="btn-brass mt-8 w-full sm:w-auto">
        {state === "sending" ? copy.submitting : copy.submit}
      </button>
    </form>
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
  hint,
  required,
  error,
  children,
}: {
  label: string;
  hint?: string;
  required?: boolean;
  error?: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label className="label">
        {label}
        {required ? <span className="ml-1 text-[#a6321f]">*</span> : null}
      </label>
      {children}
      {hint ? <p className="mt-1.5 text-xs leading-relaxed text-ink/65">{hint}</p> : null}
      {error ? <p className="mt-1.5 text-xs text-[#a6321f]">{error}</p> : null}
    </div>
  );
}

function TableButton({ onClick, children }: { onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="tap min-h-11 rounded-full border border-ink/25 px-4 text-xs transition-colors hover:border-ink/50 hover:bg-ink/5"
    >
      {children}
    </button>
  );
}
