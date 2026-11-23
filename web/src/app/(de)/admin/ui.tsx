import Link from "next/link";

/**
 * Bausteine des Adminpanels – Seitenkopf mit Pfad, Kennzahlkarten,
 * Filter-Chips und eine kleine Icon-Sammlung (Strichzeichnungen, 24er Raster).
 * Vorbild für die Anordnung war das toob360-Adminpanel: Seitenleiste, Pfad,
 * Kicker + großer Titel + Hauptknopf, Kennzahlen, darunter Suche und Filter.
 */

const ICONS = {
  home: "M3 10.5 12 3l9 7.5M5 9v11h5v-6h4v6h5V9",
  flag: "M5 21V4m0 0h11l-2 4 2 4H5",
  megaphone: "M3 11v2a1 1 0 0 0 1 1h2l5 4V6L6 10H4a1 1 0 0 0-1 1Zm13-3a5 5 0 0 1 0 8m2.5-10.5a8.5 8.5 0 0 1 0 13",
  chart: "M4 20V10m6 10V4m6 16v-7m4 7H2",
  external: "M14 4h6v6m0-6L10 14M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5",
  logout: "M15 4h4a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-4M10 17l5-5-5-5m5 5H3",
  search: "M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14Zm9 2-4.3-4.3",
  menu: "M4 6h16M4 12h16M4 18h16",
  close: "M6 6l12 12M18 6 6 18",
  plus: "M12 5v14M5 12h14",
  inbox: "M3 13h5l1.5 3h5L16 13h5M5 5h14l2 8v6a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-6l2-8Z",
  alert: "M12 9v4m0 4h.01M10.3 3.9 2.4 17.6A2 2 0 0 0 4.1 20.6h15.8a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z",
  phone: "M8 3h8a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1Zm3 15h2",
  check: "M4 12.5 9 17.5 20 6.5",
  chevron: "M9 6l6 6-6 6",
  users: "M16 20v-1a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v1m7-9a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm13 9v-1a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8",
} as const;

export type IconName = keyof typeof ICONS;

export function Icon({ name, className = "h-5 w-5" }: { name: IconName; className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.6}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden
    >
      <path d={ICONS[name]} />
    </svg>
  );
}

export interface Crumb {
  label: string;
  href?: string;
}

/** Kopf jeder Adminseite: Pfad, Kicker, Titel, Untertitel, Aktion rechts. */
export function PageHeader({
  crumbs,
  eyebrow,
  title,
  subtitle,
  action,
}: {
  crumbs: Crumb[];
  eyebrow?: string;
  title: React.ReactNode;
  subtitle?: React.ReactNode;
  action?: React.ReactNode;
}) {
  return (
    <header>
      <nav aria-label="Pfad" className="flex flex-wrap items-center gap-1.5 text-sm text-cream/55">
        <Link href="/admin" className="transition-colors hover:text-brass">
          Admin
        </Link>
        {crumbs.map((c, i) => (
          <span key={i} className="flex items-center gap-1.5">
            <Icon name="chevron" className="h-3.5 w-3.5 text-cream/30" />
            {c.href ? (
              <Link href={c.href} className="transition-colors hover:text-brass">
                {c.label}
              </Link>
            ) : (
              <span className="text-cream/90">{c.label}</span>
            )}
          </span>
        ))}
      </nav>
      <div className="mt-8 flex flex-wrap items-end justify-between gap-5">
        <div className="min-w-0">
          {eyebrow ? (
            <p className="flex items-center gap-2 text-xs font-medium uppercase tracking-[0.18em] text-brass">
              <span className="h-1.5 w-1.5 rounded-full bg-brass" />
              {eyebrow}
            </p>
          ) : null}
          <h1 className="mt-2 font-display text-3xl tracking-tight sm:text-4xl">{title}</h1>
          {subtitle ? <p className="mt-2 max-w-2xl text-sm leading-relaxed text-cream/60">{subtitle}</p> : null}
        </div>
        {action ? <div className="shrink-0">{action}</div> : null}
      </div>
    </header>
  );
}

/** Goldener Hauptknopf im Seitenkopf. */
export function PrimaryLink({
  href,
  children,
  icon = "plus",
}: {
  href: string;
  children: React.ReactNode;
  icon?: IconName;
}) {
  return (
    <Link
      href={href}
      className="inline-flex items-center gap-2 rounded-lg bg-brass px-5 py-3 text-sm font-semibold text-night transition-colors hover:bg-brass-soft"
    >
      <Icon name={icon} className="h-4 w-4" />
      {children}
    </Link>
  );
}

/** Kennzahl mit Icon oben rechts – auf Wunsch anklickbar. */
export function StatCard({
  label,
  value,
  note,
  icon,
  href,
  highlight,
}: {
  label: string;
  value: React.ReactNode;
  note?: React.ReactNode;
  icon: IconName;
  href?: string;
  highlight?: boolean;
}) {
  const body = (
    <>
      <div className="flex items-start justify-between gap-3">
        <span
          lang="de"
          className="min-w-0 hyphens-auto text-[11px] font-medium uppercase tracking-[0.08em] text-cream/55 sm:text-xs sm:tracking-[0.14em]"
        >
          {label}
        </span>
        <Icon name={icon} className={`h-[18px] w-[18px] shrink-0 ${highlight ? "text-brass" : "text-brass/70"}`} />
      </div>
      <div
        className={`mt-3 font-display text-3xl font-semibold tabular-nums ${highlight ? "text-brass" : "text-cream"}`}
      >
        {value}
      </div>
      {note ? <div className="mt-1 text-sm text-cream/55">{note}</div> : null}
    </>
  );
  const cls = `block rounded-xl border p-4 sm:p-5 transition-colors ${
    highlight ? "border-brass/50 bg-brass/[0.07]" : "border-white/10 bg-white/[0.03]"
  }`;
  return href ? (
    <Link href={href} className={`${cls} hover:border-brass/60`}>
      {body}
    </Link>
  ) : (
    <div className={cls}>{body}</div>
  );
}

/** Filter-Chip mit Zähler, wie die Ordner bei toob360. */
export function Chip({ href, active, label, count }: { href: string; active: boolean; label: string; count?: number }) {
  return (
    <Link
      href={href}
      className={`inline-flex items-center gap-2.5 rounded-lg border px-4 py-2 text-sm transition-colors ${
        active
          ? "border-brass/70 bg-brass/[0.08] text-brass"
          : "border-white/10 bg-white/[0.03] text-cream/80 hover:border-white/25"
      }`}
    >
      {label}
      {count != null ? (
        <span className={`font-mono text-xs ${active ? "text-brass/80" : "text-cream/40"}`}>
          {count.toLocaleString("de-DE")}
        </span>
      ) : null}
    </Link>
  );
}

/** Abschnitt mit kleiner Überschrift und optionalem Link rechts. */
export function Panel({
  title,
  action,
  children,
}: {
  title: string;
  action?: { href: string; label: string };
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-xl border border-white/10 bg-white/[0.02]">
      <div className="flex items-center justify-between gap-3 border-b border-white/10 px-5 py-3.5">
        <h2 className="text-xs font-medium uppercase tracking-[0.14em] text-cream/60">{title}</h2>
        {action ? (
          <Link href={action.href} className="text-sm text-brass transition-colors hover:text-brass-soft">
            {action.label}
          </Link>
        ) : null}
      </div>
      {children}
    </section>
  );
}
