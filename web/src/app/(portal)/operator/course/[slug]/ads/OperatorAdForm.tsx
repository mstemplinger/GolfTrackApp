"use client";

import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import type { OperatorLang } from "@/i18n/operator";
import { operatorToolsCopy } from "@/i18n/operatorTools";
import { formatEuro, GOLF_COURSE_MONTHLY_CENTS, MINIGOLF_COURSE_MONTHLY_CENTS, quoteAd } from "@/lib/adPricing";
import { requestOperatorAd } from "../actions";
import { Field, PORTAL_FIELD, Section } from "../formParts";

export interface NearbyCourse {
  slug: string;
  name: string;
  kind: "golf" | "minigolf";
  km: number;
}

const RADII = [5, 10, 25, 50, 100];
const DURATIONS = [1, 3, 6, 12];

const EMPTY = {
  title: "",
  subtitle: "",
  linkURL: "",
  imageURL: "",
  advertiser: "",
  submitterPhone: "",
  requestNote: "",
};

/** „www.beispiel.de“ → „https://www.beispiel.de“ – der Server will die volle Adresse. */
function withScheme(url: string): string {
  const v = url.trim();
  if (!v || /^https?:\/\//i.test(v)) return v;
  return `https://${v}`;
}

/**
 * Werbeanfrage im Portal. Der Platz steht fest; gewählt wird nur, ob die
 * Anzeige auf ihm allein läuft oder im Umkreis um ihn. Reichweite und
 * Richtpreis stehen sofort daneben – dieselbe Rechnung wie auf dem Server.
 */
export function OperatorAdForm({
  slug,
  lang,
  course,
  nearby,
  contact,
  termsUrl,
}: {
  slug: string;
  lang: OperatorLang;
  course: { name: string; kind: "golf" | "minigolf"; hasLocation: boolean };
  /** Freigegebene Plätze bis 100 km, nach Entfernung sortiert (inkl. dem eigenen). */
  nearby: NearbyCourse[];
  contact: { name: string; email: string };
  termsUrl: string;
}) {
  const tools = operatorToolsCopy(lang);
  const t = tools.ads;
  const f = tools.form;
  const router = useRouter();

  const [target, setTarget] = useState<"course" | "radius">("course");
  const [radiusKm, setRadiusKm] = useState(25);
  const [months, setMonths] = useState(3);
  const [values, setValues] = useState({ ...EMPTY, submitterName: contact.name, submitterEmail: contact.email });
  const [state, setState] = useState<"idle" | "sending" | "done">("idle");
  const [error, setError] = useState<string | null>(null);
  const [invalid, setInvalid] = useState<Set<string>>(new Set());

  const set = (key: keyof typeof values, value: string) => setValues((v) => ({ ...v, [key]: value }));

  const reached = useMemo(() => nearby.filter((c) => c.km <= radiusKm), [nearby, radiusKm]);

  const quote = useMemo(() => {
    if (target === "course") {
      const golf = course.kind === "golf";
      return quoteAd(golf ? 1 : 0, golf ? 0 : 1, months);
    }
    if (!reached.length) return null;
    const golf = reached.filter((c) => c.kind === "golf").length;
    return quoteAd(golf, reached.length - golf, months);
  }, [target, course.kind, reached, months]);

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    setState("sending");
    setError(null);
    setInvalid(new Set());
    const payload = {
      ...values,
      linkURL: withScheme(values.linkURL),
      imageURL: withScheme(values.imageURL),
      target,
      radiusKm,
      requestedMonths: months,
    };
    try {
      const result = await requestOperatorAd(slug, payload);
      if (result.ok) {
        setState("done");
        setValues((v) => ({ ...v, ...EMPTY }));
        router.refresh();
        return;
      }
      const messages: Record<string, string> = {
        invalid: f.invalid,
        no_courses: t.errNoCourses,
        too_many: t.errTooMany,
        no_location: t.errNoLocation,
        not_approved: t.errNotApproved,
      };
      setError(messages[result.error] ?? f.failed);
      if (result.fields) setInvalid(new Set(result.fields));
    } catch {
      setError(f.failed);
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

  const preview = <AdPreview title={values.title} subtitle={values.subtitle} image={withScheme(values.imageURL)} t={t} />;
  const golfReached = reached.filter((c) => c.kind === "golf").length;

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_18rem] lg:gap-8">
      <form onSubmit={submit} noValidate className="rounded-xl border border-white/10 bg-white/[0.03] p-5 sm:p-7">
        <h2 className="font-display text-2xl tracking-tight">{t.newTitle}</h2>
        <p className="mt-2 max-w-xl text-sm leading-relaxed text-cream/60">{t.newIntro}</p>

        <Section title={t.where}>
          <fieldset className="grid gap-3 sm:grid-cols-2">
            <legend className="sr-only">{t.where}</legend>
            <TargetOption
              value="course"
              checked={target === "course"}
              onChange={() => setTarget("course")}
              title={t.targetCourse(course.name)}
              hint={t.targetCourseHint}
            />
            <TargetOption
              value="radius"
              checked={target === "radius"}
              onChange={() => setTarget("radius")}
              disabled={!course.hasLocation}
              title={t.targetRadius(course.name)}
              hint={course.hasLocation ? t.targetRadiusHint : t.noCoordinates}
            />
          </fieldset>

          {target === "radius" ? (
            <div className="space-y-4">
              <div>
                <label htmlFor="radius" className="text-sm text-cream/75">
                  {t.radiusLabel(radiusKm)}
                </label>
                <input
                  id="radius"
                  type="range"
                  min={5}
                  max={100}
                  step={1}
                  value={radiusKm}
                  onChange={(e) => setRadiusKm(Number(e.target.value))}
                  aria-label={t.radiusAria}
                  className="mt-2 h-11 w-full accent-[#c9a035]"
                />
                <div className="mt-1 flex flex-wrap gap-2">
                  {RADII.map((km) => (
                    <Chip key={km} active={radiusKm === km} onClick={() => setRadiusKm(km)}>
                      {km} km
                    </Chip>
                  ))}
                </div>
              </div>
              <div
                className={`rounded-lg border p-4 text-sm ${reached.length ? "border-white/10 bg-white/[0.02]" : "border-[#e07a63]/40 bg-[#e07a63]/5"}`}
                aria-live="polite"
              >
                {reached.length ? (
                  <>
                    <p className="font-medium text-cream/90">
                      {t.reach(reached.length, radiusKm)}
                      {golfReached > 0 && golfReached < reached.length
                        ? ` · ${t.split(golfReached, reached.length - golfReached)}`
                        : ""}
                    </p>
                    <ul className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-cream/55">
                      {reached.slice(0, 8).map((c) => (
                        <li key={c.slug}>
                          {c.slug === slug ? `${c.name} (${t.ownCourse})` : `${c.name} · ${c.km < 1 ? "<1" : Math.round(c.km)} km`}
                        </li>
                      ))}
                      {reached.length > 8 ? <li>{t.andMore(reached.length - 8)}</li> : null}
                    </ul>
                  </>
                ) : (
                  <p className="text-cream/75">{t.reachNone(radiusKm)}</p>
                )}
              </div>
            </div>
          ) : null}

          <div>
            <p className="text-sm text-cream/75">{t.duration}</p>
            <div className="mt-2 flex flex-wrap gap-2">
              {DURATIONS.map((m) => (
                <Chip key={m} active={months === m} onClick={() => setMonths(m)}>
                  {t.months(m)}
                </Chip>
              ))}
            </div>
          </div>

          <PriceBox quote={quote} t={t} />
        </Section>

        <Section title={t.content}>
          <Field label={t.headline} htmlFor="title" required hint={t.chars(values.title.length, 40)} error={invalid.has("title") ? t.errTitle : undefined}>
            <input
              id="title"
              className={PORTAL_FIELD}
              value={values.title}
              maxLength={40}
              onChange={(e) => set("title", e.target.value)}
              aria-invalid={invalid.has("title")}
              required
            />
          </Field>
          <Field label={t.subline} htmlFor="subtitle" hint={t.chars(values.subtitle.length, 80)}>
            <input id="subtitle" className={PORTAL_FIELD} value={values.subtitle} maxLength={80} onChange={(e) => set("subtitle", e.target.value)} />
          </Field>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label={t.link} htmlFor="linkURL" hint={t.linkHint} error={invalid.has("linkURL") ? t.errUrl : undefined}>
              <input
                id="linkURL"
                className={PORTAL_FIELD}
                value={values.linkURL}
                onChange={(e) => set("linkURL", e.target.value)}
                placeholder="https://…"
                inputMode="url"
                autoCapitalize="none"
                aria-invalid={invalid.has("linkURL")}
              />
            </Field>
            <Field label={t.image} htmlFor="imageURL" hint={t.imageHint} error={invalid.has("imageURL") ? t.errUrl : undefined}>
              <input
                id="imageURL"
                className={PORTAL_FIELD}
                value={values.imageURL}
                onChange={(e) => set("imageURL", e.target.value)}
                placeholder="https://…"
                inputMode="url"
                autoCapitalize="none"
                aria-invalid={invalid.has("imageURL")}
              />
            </Field>
          </div>
          <Field label={t.advertiser} htmlFor="advertiser" hint={t.advertiserHint}>
            <input
              id="advertiser"
              className={PORTAL_FIELD}
              value={values.advertiser}
              maxLength={120}
              onChange={(e) => set("advertiser", e.target.value)}
              placeholder={course.name}
              autoComplete="organization"
            />
          </Field>
          {/* Am Handy steht die Vorschau gleich unter dem Text, auf breiten Schirmen daneben. */}
          <div className="lg:hidden">{preview}</div>
        </Section>

        <Section title={f.contact}>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label={f.name} htmlFor="submitterName" required error={invalid.has("submitterName") ? f.nameError : undefined}>
              <input
                id="submitterName"
                className={PORTAL_FIELD}
                value={values.submitterName}
                onChange={(e) => set("submitterName", e.target.value)}
                autoComplete="name"
                aria-invalid={invalid.has("submitterName")}
                required
              />
            </Field>
            <Field label={f.email} htmlFor="submitterEmail" required error={invalid.has("submitterEmail") ? f.emailError : undefined}>
              <input
                id="submitterEmail"
                type="email"
                className={PORTAL_FIELD}
                value={values.submitterEmail}
                onChange={(e) => set("submitterEmail", e.target.value)}
                autoComplete="email"
                aria-invalid={invalid.has("submitterEmail")}
                required
              />
            </Field>
          </div>
          <Field label={f.phone} htmlFor="submitterPhone" hint={f.phoneHint}>
            <input
              id="submitterPhone"
              className={PORTAL_FIELD}
              value={values.submitterPhone}
              onChange={(e) => set("submitterPhone", e.target.value)}
              inputMode="tel"
              autoComplete="tel"
            />
          </Field>
          <Field label={t.note} htmlFor="requestNote" hint={t.noteHint}>
            <textarea
              id="requestNote"
              className={PORTAL_FIELD}
              rows={3}
              value={values.requestNote}
              onChange={(e) => set("requestNote", e.target.value)}
            />
          </Field>
        </Section>

        <p className="mt-8 text-xs leading-relaxed text-cream/50">
          {t.terms}{" "}
          <a href={termsUrl} target="_blank" rel="noopener" className="underline decoration-brass/60 underline-offset-4 hover:text-cream">
            {t.termsLink}
          </a>
          .
        </p>
        <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:gap-4">
          <button
            type="submit"
            disabled={state === "sending" || (target === "radius" && !reached.length)}
            className="inline-flex min-h-12 w-full items-center justify-center rounded-lg bg-brass px-6 font-semibold text-night transition-colors hover:bg-brass-soft disabled:opacity-60 sm:w-auto"
          >
            {state === "sending" ? f.sending : t.submit}
          </button>
          {error ? (
            <p role="alert" className="text-sm text-[#e07a63]">
              {error}
            </p>
          ) : null}
        </div>
      </form>

      <aside className="hidden lg:sticky lg:top-24 lg:block lg:self-start">{preview}</aside>
    </div>
  );
}

function TargetOption({
  value,
  checked,
  onChange,
  disabled,
  title,
  hint,
}: {
  value: string;
  checked: boolean;
  onChange: () => void;
  disabled?: boolean;
  title: string;
  hint: string;
}) {
  return (
    <label
      className={`flex cursor-pointer gap-3 rounded-lg border p-4 transition-colors has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-brass/60 ${
        checked ? "border-brass bg-brass/[0.08]" : "border-white/12 hover:border-white/25"
      } ${disabled ? "cursor-not-allowed opacity-50" : ""}`}
    >
      <input type="radio" name="target" value={value} checked={checked} onChange={onChange} disabled={disabled} className="mt-1 size-4 shrink-0 accent-[#c9a035]" />
      <span className="min-w-0">
        <span className="block text-sm font-medium text-cream [overflow-wrap:anywhere]">{title}</span>
        <span className="mt-1 block text-xs leading-relaxed text-cream/55">{hint}</span>
      </span>
    </label>
  );
}

function Chip({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={active}
      className={`min-h-11 rounded-full border px-4 text-sm transition-colors ${
        active ? "border-brass bg-brass text-night" : "border-white/15 text-cream/75 hover:border-white/35"
      }`}
    >
      {children}
    </button>
  );
}

function PriceBox({ quote, t }: { quote: ReturnType<typeof quoteAd> | null; t: ReturnType<typeof operatorToolsCopy>["ads"] }) {
  if (!quote) return null;
  const minimum = quote.monthlyCents > quote.golf * GOLF_COURSE_MONTHLY_CENTS + quote.minigolf * MINIGOLF_COURSE_MONTHLY_CENTS;
  return (
    <div className="rounded-lg border border-white/10 bg-night/60 p-4" aria-live="polite">
      <p className="flex flex-wrap items-baseline justify-between gap-2">
        <span className="text-sm text-cream/60">{t.price}</span>
        <span className="font-display text-2xl tracking-tight">
          {formatEuro(quote.monthlyDiscountedCents)}
          <span className="text-sm font-normal text-cream/55"> {t.perMonth}</span>
        </span>
      </p>
      <p className="mt-1 text-sm text-cream/70 sm:text-right">
        {t.total(t.months(quote.months), formatEuro(quote.totalCents))}
        {quote.discountPercent ? <span className="text-cream/50"> ({t.discount(quote.discountPercent)})</span> : null}
      </p>
      <p className="mt-2 text-xs leading-relaxed text-cream/45">
        {minimum ? `${t.minimum} · ` : ""}
        {t.priceNote}
      </p>
    </div>
  );
}

function AdPreview({
  title,
  subtitle,
  image,
  t,
}: {
  title: string;
  subtitle: string;
  image: string;
  t: ReturnType<typeof operatorToolsCopy>["ads"];
}) {
  return (
    <div>
      <p className="text-xs font-medium uppercase tracking-[0.14em] text-cream/45">{t.preview}</p>
      <div className="mt-3 rounded-lg bg-[#0E2718] p-3 ring-1 ring-white/10">
        <div className="flex items-center gap-3 rounded-xl bg-[#163421] p-3">
          {image ? (
            // eslint-disable-next-line @next/next/no-img-element -- fremde Adresse, absichtlich ohne Optimierung
            <img
              src={image}
              alt=""
              className="size-11 shrink-0 rounded-lg object-cover"
              onError={(e) => {
                e.currentTarget.style.visibility = "hidden";
              }}
            />
          ) : (
            <span className="grid size-11 shrink-0 place-items-center rounded-lg bg-[#1C4129] text-[#C9A035]">★</span>
          )}
          <span className="min-w-0 flex-1">
            <span className="rounded-[3px] bg-white/10 px-1.5 py-px font-mono text-[0.55rem] uppercase tracking-[0.12em] text-white/55">
              {t.adLabel}
            </span>
            <span className="mt-0.5 block truncate text-sm font-semibold text-white">{title || t.headline}</span>
            <span className="block truncate text-xs text-white/60">{subtitle || t.subline}</span>
          </span>
          <span className="text-white/30">›</span>
        </div>
      </div>
      <p className="mt-3 text-xs leading-relaxed text-cream/50">{t.previewHint}</p>
    </div>
  );
}
