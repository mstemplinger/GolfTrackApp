/**
 * Bausteine der Portal-Formulare (Werbung, Werbemittel): dunkle Felder wie
 * beim Login, 44 px hoch, damit sie sich am Handy bedienen lassen. `text-base`
 * verhindert, dass iOS beim Antippen hineinzoomt.
 */
export const PORTAL_FIELD =
  "block min-h-11 w-full rounded-lg border border-white/12 bg-white/[0.04] px-3.5 py-2.5 text-base text-cream placeholder:text-cream/30 focus:border-brass/70 focus:outline-none focus:ring-2 focus:ring-brass/25 aria-[invalid=true]:border-[#e07a63]/80 sm:text-sm";

export function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="mt-8 border-t border-white/10 pt-6">
      <h3 className="mb-4 text-base font-semibold tracking-tight text-cream">{title}</h3>
      <div className="space-y-5">{children}</div>
    </section>
  );
}

export function Field({
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
      <label htmlFor={htmlFor} className="mb-1.5 block text-sm text-cream/75">
        {label}
        {required ? (
          <span aria-hidden className="ml-1 text-brass">
            *
          </span>
        ) : null}
      </label>
      {children}
      {hint ? <p className="mt-1.5 text-xs leading-relaxed text-cream/45">{hint}</p> : null}
      {error ? <p className="mt-1.5 text-xs text-[#e07a63]">{error}</p> : null}
    </div>
  );
}
