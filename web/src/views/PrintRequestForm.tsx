"use client";

import { useState } from "react";
import { PRINT_ITEM_LABEL, PRINT_ITEMS, type PrintItem } from "@/lib/printItems";

/**
 * Anfrage nach Druckwerbung für einen Golfplatz (`/werbung/golfplatz`).
 * Geht per Mail an uns; scheitert der Versand, steht die Mailadresse da.
 */
export function PrintRequestForm({ email, preselect = [] }: { email: string | null; preselect?: PrintItem[] }) {
  const [values, setValues] = useState({
    club: "",
    location: "",
    name: "",
    email: "",
    phone: "",
    message: "",
    company: "",
  });
  const [items, setItems] = useState<PrintItem[]>(preselect);
  const [consent, setConsent] = useState(false);
  const [state, setState] = useState<"idle" | "sending" | "done">("idle");
  const [error, setError] = useState<string | null>(null);
  const [mailFallback, setMailFallback] = useState(false);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  function set(key: keyof typeof values, value: string) {
    setValues((current) => ({ ...current, [key]: value }));
  }

  function toggle(item: PrintItem) {
    setItems((current) => (current.includes(item) ? current.filter((i) => i !== item) : [...current, item]));
  }

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    setState("sending");
    setError(null);
    setMailFallback(false);
    setFieldErrors({});

    try {
      const response = await fetch("/api/werbemittel", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...values, items, consent }),
      });

      if (response.ok) {
        setState("done");
        document.getElementById("anfragen")?.scrollIntoView({ behavior: "smooth" });
        return;
      }

      const body = await response.json().catch(() => null);
      if (response.status === 429) {
        setError("Zu viele Anfragen von hier. Bitte später noch einmal versuchen.");
      } else if (response.status === 422) {
        setError("Bitte die markierten Felder prüfen.");
        const map: Record<string, string> = {};
        for (const issue of body?.issues ?? []) map[String(issue.path).split(".")[0]] = issue.message;
        setFieldErrors(map);
      } else {
        setError("Die Anfrage ging gerade nicht raus.");
        setMailFallback(true);
      }
      setState("idle");
    } catch {
      setError("Die Anfrage ging gerade nicht raus.");
      setMailFallback(true);
      setState("idle");
    }
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
          Wir melden uns per Mail – meist innerhalb von zwei Tagen – mit einem Vorschlag für Ihren
          Platz.
        </p>
      </div>
    );
  }

  const mailto = email
    ? `mailto:${email}?subject=${encodeURIComponent(`Werbemittel für ${values.club || "unseren Golfplatz"}`)}`
    : null;

  return (
    <form onSubmit={submit} className="paper rounded-[4px] p-6 sm:p-10" noValidate>
      <h2 className="font-display text-2xl tracking-tight">Werbemittel anfragen</h2>
      <p className="mt-2 max-w-lg text-sm leading-relaxed text-ink/70">
        Unverbindlich. Wir schreiben zurück mit Vorschlag, Lieferzeit und Konditionen.
      </p>

      <Section title="Was darf es sein?">
        <fieldset aria-describedby={fieldErrors.items ? "items-error" : undefined}>
          <legend className="sr-only">Werbemittel</legend>
          <div className="grid gap-2 sm:grid-cols-2">
            {PRINT_ITEMS.map((item) => (
              <label
                key={item}
                className="flex cursor-pointer items-start gap-3 rounded-[3px] border border-ink/15 p-3 text-sm leading-snug text-ink/80 has-[:checked]:border-fairway/60 has-[:checked]:bg-fairway/5"
              >
                <input
                  type="checkbox"
                  className="mt-0.5 size-4 shrink-0"
                  checked={items.includes(item)}
                  onChange={() => toggle(item)}
                />
                <span>{PRINT_ITEM_LABEL[item]}</span>
              </label>
            ))}
          </div>
          {fieldErrors.items ? (
            <p id="items-error" className="mt-2 text-xs text-[#a6321f]">
              {fieldErrors.items}
            </p>
          ) : null}
        </fieldset>
      </Section>

      <Section title="Ihr Platz">
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Golfplatz / Club" required htmlFor="club" error={fieldErrors.club}>
            <input
              id="club"
              className="field"
              value={values.club}
              onChange={(event) => set("club", event.target.value)}
              required
              autoComplete="organization"
              aria-invalid={Boolean(fieldErrors.club)}
            />
          </Field>
          <Field label="Ort" htmlFor="location">
            <input
              id="location"
              className="field"
              value={values.location}
              onChange={(event) => set("location", event.target.value)}
              autoComplete="address-level2"
            />
          </Field>
        </div>
      </Section>

      <Section title="Kontakt">
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Name" required htmlFor="name" error={fieldErrors.name}>
            <input
              id="name"
              className="field"
              value={values.name}
              onChange={(event) => set("name", event.target.value)}
              required
              autoComplete="name"
              aria-invalid={Boolean(fieldErrors.name)}
            />
          </Field>
          <Field label="E-Mail" required htmlFor="email" error={fieldErrors.email}>
            <input
              id="email"
              className="field"
              type="email"
              value={values.email}
              onChange={(event) => set("email", event.target.value)}
              required
              autoComplete="email"
              aria-invalid={Boolean(fieldErrors.email)}
            />
          </Field>
        </div>
        <Field label="Telefon" htmlFor="phone" hint="Freiwillig – manches klärt ein Anruf schneller.">
          <input
            id="phone"
            className="field"
            value={values.phone}
            onChange={(event) => set("phone", event.target.value)}
            inputMode="tel"
            autoComplete="tel"
          />
        </Field>
        <Field
          label="Nachricht"
          htmlFor="message"
          hint="Wo soll es stehen oder hängen? Stückzahl, Wunschtermin, Fragen."
        >
          <textarea
            id="message"
            className="field"
            rows={4}
            value={values.message}
            onChange={(event) => set("message", event.target.value)}
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
        <span>Die Angaben dürfen zur Bearbeitung dieser Anfrage per Mail an uns geschickt und beantwortet werden.</span>
      </label>

      <div className="mt-6 flex flex-wrap items-center gap-4">
        <button type="submit" disabled={state === "sending" || !consent} className="btn-brass">
          {state === "sending" ? "Wird geschickt …" : "Anfrage schicken"}
        </button>
        {error ? (
          <p className="text-sm text-[#a6321f]" role="alert">
            {error}
            {mailFallback && mailto ? (
              <>
                {" "}
                Bitte direkt an{" "}
                <a href={mailto} className="underline">
                  {email}
                </a>{" "}
                schreiben.
              </>
            ) : null}
          </p>
        ) : null}
      </div>
    </form>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="mt-10 border-t border-ink/15 pt-7">
      <h3 className="mb-5 font-display text-xl tracking-tight">{title}</h3>
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
