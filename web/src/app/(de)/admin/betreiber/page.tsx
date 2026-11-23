import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import { listOperators } from "@/lib/operators";
import { operatorPortalUrl } from "@/lib/operatorPortal";
import { ALL_SECTIONS } from "@/lib/sections";
import { Icon, PageHeader, Panel, PrimaryLink, StatCard } from "../ui";

export const metadata: Metadata = {
  title: "Betreiber · GolfTrack",
  robots: { index: false, follow: false },
};

/** Betreiberkonten: wer sich auf operator.golftrack.app anmelden darf und was er sieht. */
export default async function OperatorsPage() {
  if (!(await isAuthenticated())) redirect("/admin");
  const operators = await listOperators();
  const active = operators.filter((o) => o.active);
  const assigned = new Set(operators.flatMap((o) => o.courses)).size;
  const portal = operatorPortalUrl();

  return (
    <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8 lg:py-10">
      <PageHeader
        crumbs={[{ label: "Betreiber" }]}
        eyebrow="Zugänge"
        title="Betreiber"
        subtitle={
          <>
            Konten für die Platz-Statistik unter{" "}
            <a href={`${portal}/login`} target="_blank" rel="noreferrer" className="text-brass hover:underline">
              {portal.replace(/^https?:\/\//, "")}
            </a>
            . Jedes Konto sieht nur seine Plätze und nur die freigegebenen Bausteine.
          </>
        }
        action={<PrimaryLink href="/admin/betreiber/neu">Neuer Betreiber</PrimaryLink>}
      />

      <div className="mt-10 grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-3">
        <StatCard label="Konten" value={operators.length} note={`${active.length} aktiv`} icon="users" />
        <StatCard label="Plätze zugewiesen" value={assigned} note="mit mindestens einem Konto" icon="flag" />
        <StatCard
          label="Angemeldet"
          value={operators.filter((o) => o.lastLoginAt).length}
          note="schon mindestens einmal"
          icon="check"
        />
      </div>

      <div className="mt-6">
        <Panel title="Alle Konten">
          {operators.length === 0 ? (
            <p className="px-5 py-6 text-sm text-cream/55">
              Noch kein Betreiberkonto. Lege eines an und weise ihm Plätze zu.
            </p>
          ) : (
            <ul className="divide-y divide-white/[0.07]">
              {operators.map((o) => (
                <li key={o.id}>
                  <Link
                    href={`/admin/betreiber/${o.id}`}
                    className="group flex items-center gap-4 px-5 py-3.5 transition-colors hover:bg-white/[0.03]"
                  >
                    <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full border border-brass/40 text-sm font-semibold text-brass">
                      {o.name.slice(0, 1).toUpperCase()}
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate font-medium">{o.name}</span>
                      <span className="block truncate text-sm text-cream/55">
                        {o.email} · {o.courses.length} {o.courses.length === 1 ? "Platz" : "Plätze"} ·{" "}
                        {o.permissions.length === ALL_SECTIONS.length
                          ? "alle Bausteine"
                          : `${o.permissions.length} von ${ALL_SECTIONS.length} Bausteinen`}
                      </span>
                    </span>
                    <span className="hidden text-right text-xs text-cream/45 sm:block">
                      {o.lastLoginAt
                        ? `zuletzt ${new Date(o.lastLoginAt).toLocaleDateString("de-DE")}`
                        : "noch nie angemeldet"}
                    </span>
                    <span
                      className={`rounded-full border px-2.5 py-0.5 text-[11px] uppercase tracking-wider ${
                        o.active ? "border-fairway/60 text-[#7fd19b]" : "border-white/15 text-cream/45"
                      }`}
                    >
                      {o.active ? "aktiv" : "gesperrt"}
                    </span>
                    <Icon
                      name="chevron"
                      className="h-4 w-4 shrink-0 text-cream/25 transition-colors group-hover:text-brass"
                    />
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </Panel>
      </div>
    </div>
  );
}
