"use client";

import { useState } from "react";
import type { OperatorLang } from "@/i18n/operator";
import { operatorToolsCopy } from "@/i18n/operatorTools";
import type { PrintItem } from "@/lib/printItems";
import { requestOperatorPrint } from "../actions";
import { Field, PORTAL_FIELD, Section } from "../formParts";

/**
 * Werbemittel anfragen. Platzname und Ort kommen auf dem Server aus dem
 * Verzeichnis; hier nur, was es sein soll und wer zurückgerufen wird.
 * Scheitert der Mailversand, steht die Adresse da, an die man selbst schreibt.
 */
export function OperatorPrintForm({
  slug,
  lang,
  items,
  contact,
  fallbackEmail,
}: {
  slug: string;
  lang: OperatorLang;
  items: PrintItem[];
  contact: { name: string; email: string };
  fallbackEmail: string | null;
}) {
  const tools = operatorToolsCopy(lang);
  const t = tools.print;
  const f = tools.form;

  const [chosen, setChosen] = useState<PrintItem[]>([]);
  const [values, setValues] = useState({ name: contact.name, email: contact.email, phone: "", message: "" });
  const [state, setState] = useState<"idle" | "sending" | "done">("idle");
  const [error, setError] = useState<string | null>(null);
  const [mailFallback, setMailFallback] = useState(false);
  const [invalid, setInvalid] = useState<Set<string>>(new Set());

  const set = (key: keyof typeof values, value: string) => setValues((v) => ({ ...v, [key]: value }));
  const toggle = (item: PrintItem) =>
    setChosen((current) => (current.includes(item) ? current.filter((i) => i !== item) : [...current, item]));

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    setState("sending");
    setError(null);
    setMailFallback(false);
    setInvalid(new Set());
    try {
      const result = await requestOperatorPrint(slug, { ...values, items: chosen });
      if (result.ok) {
        setState("done");
        setChosen([]);
        setValues((v) => ({ ...v, message: "" }));
        return;
      }
      if (result.error === "invalid") {
        setError(f.invalid);
        setInvalid(new Set(result.fields ?? []));
      } else {
        setError(f.failed);
        setMailFallback(result.error === "unavailable");
      }
    } catch {
      setError(f.failed);
      setMailFallback(true);
    }
    setState("idle");
  }

  if (state === "done") {
    return (
      <div className="rounded-xl border border-brass/40 bg-brass/[0.06] p-6 text-center sm:p-10" role="status">
        <span aria-hidden className="mx-auto grid size-12 place-items-center rounded-full bg-brass/15 text-brass">
          <svg viewBox="0 0 24 24" className="size-6" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M4 12.5 9.5 18 20 6.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </span>
        <h3 className="mt-4 font-display text-2xl tracking-tight">{t.done}</h3>
        <p className="mx-auto mt-2 max-w-md text-sm leading-relaxed text-cream/65">{t.doneText}</p>
        <button
          type="button"
          onClick={() => setState("idle")}
          className="mt-6 inline-flex min-h-11 items-center rounded-lg border border-white/15 px-4 text-sm text-cream/80 transition-colors hover:border-brass/60"
        >
          {t.another}
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={submit} noValidate className="rounded-xl border border-white/10 bg-white/[0.03] p-5 sm:p-7">
      <h2 className="font-display text-2xl tracking-tight">{t.submit}</h2>
      <p className="mt-2 max-w-xl text-sm leading-relaxed text-cream/60">{t.nonBinding}</p>

      <Section title={t.what}>
        <fieldset aria-describedby={invalid.has("items") ? "items-error" : undefined}>
          <legend className="sr-only">{t.what}</legend>
          <div className="grid gap-2 sm:grid-cols-2">
            {items.map((item) => (
              <label
                key={item}
                className="flex min-h-12 cursor-pointer items-center gap-3 rounded-lg border border-white/12 px-4 py-3 text-sm text-cream/80 transition-colors hover:border-white/25 has-[:checked]:border-brass has-[:checked]:bg-brass/[0.08] has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-brass/60"
              >
                <input
                  type="checkbox"
                  checked={chosen.includes(item)}
                  onChange={() => toggle(item)}
                  className="size-4 shrink-0 accent-[#c9a035]"
                />
                <ItemLabel text={t.items[item]} />
              </label>
            ))}
          </div>
          {invalid.has("items") ? (
            <p id="items-error" className="mt-2 text-xs text-[#e07a63]">
              {t.pickOne}
            </p>
          ) : null}
        </fieldset>
        <Field label={t.message} htmlFor="message" hint={t.messageHint}>
          <textarea id="message" className={PORTAL_FIELD} rows={3} value={values.message} onChange={(e) => set("message", e.target.value)} />
        </Field>
      </Section>

      <Section title={f.contact}>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label={f.name} htmlFor="name" required error={invalid.has("name") ? f.nameError : undefined}>
            <input
              id="name"
              className={PORTAL_FIELD}
              value={values.name}
              onChange={(e) => set("name", e.target.value)}
              autoComplete="name"
              aria-invalid={invalid.has("name")}
              required
            />
          </Field>
          <Field label={f.email} htmlFor="email" required error={invalid.has("email") ? f.emailError : undefined}>
            <input
              id="email"
              type="email"
              className={PORTAL_FIELD}
              value={values.email}
              onChange={(e) => set("email", e.target.value)}
              autoComplete="email"
              aria-invalid={invalid.has("email")}
              required
            />
          </Field>
        </div>
        <Field label={f.phone} htmlFor="phone" hint={f.phoneHint}>
          <input
            id="phone"
            className={PORTAL_FIELD}
            value={values.phone}
            onChange={(e) => set("phone", e.target.value)}
            inputMode="tel"
            autoComplete="tel"
          />
        </Field>
      </Section>

      <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center sm:gap-4">
        <button
          type="submit"
          disabled={state === "sending"}
          className="inline-flex min-h-12 w-full items-center justify-center rounded-lg bg-brass px-6 font-semibold text-night transition-colors hover:bg-brass-soft disabled:opacity-60 sm:w-auto"
        >
          {state === "sending" ? f.sending : t.submit}
        </button>
        {error ? (
          <p role="alert" className="text-sm text-[#e07a63]">
            {error}
            {mailFallback && fallbackEmail ? (
              <>
                {" "}
                <a href={`mailto:${fallbackEmail}`} className="underline underline-offset-4">
                  {t.writeDirectly(fallbackEmail)}
                </a>
              </>
            ) : null}
          </p>
        ) : null}
      </div>
    </form>
  );
}

/** „Werbesäule Golf · 60 × 200 cm“ → Name, darunter das Maß – ohne Umbruch mitten in der Zahl. */
function ItemLabel({ text }: { text: string }) {
  const [name, size] = text.split(" · ");
  return (
    <span className="min-w-0">
      <span className="block">{name}</span>
      {size ? <span className="block text-xs text-cream/50">{size.replace(/ /g, "\u00a0")}</span> : null}
    </span>
  );
}
