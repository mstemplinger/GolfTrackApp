import type { Metadata } from "next";
import Link from "next/link";
import { isAuthenticated, adminConfigured } from "@/lib/auth";
import { adminOverview } from "@/lib/adminOverview";
import { listCourses } from "@/lib/courses";
import { CourseRows } from "./CourseRows";
import { LoginForm } from "./LoginForm";
import { PageHeader, Panel, PrimaryLink, StatCard } from "./ui";

export const metadata: Metadata = {
  title: "Adminpanel · GolfTrack",
  robots: { index: false, follow: false },
};

const REPORT_LABELS: Record<string, string> = {
  name: "Name",
  holes: "Löcher/Par",
  rating: "Course/Slope Rating",
  location: "Lage",
  closed: "Geschlossen",
  other: "Sonstiges",
};

/**
 * Startseite des Adminpanels: was zu tun ist (offene Anlagen, Werbeanfragen,
 * Fehlermeldungen) und wie es läuft (Plätze online, Runden, Warteliste).
 * Die vollständige Anlagenliste liegt unter /admin/anlagen.
 */
export default async function AdminPage() {
  if (!adminConfigured()) {
    return (
      <Center>
        <h1 className="font-display text-2xl">Adminpanel nicht eingerichtet</h1>
        <p className="mt-3 text-sm leading-relaxed text-cream/60">
          Setze die Umgebungsvariablen <code className="font-mono text-brass">ADMIN_PASSWORD</code> und{" "}
          <code className="font-mono text-brass">ADMIN_SECRET</code>, dann ist dieser Bereich erreichbar.
        </p>
      </Center>
    );
  }

  if (!(await isAuthenticated())) {
    return (
      <Center>
        <LoginForm />
      </Center>
    );
  }

  const [o, pending] = await Promise.all([adminOverview(), listCourses({ status: "pending", limit: 8 })]);
  const fmt = (n: number | null) => (n == null ? "–" : n.toLocaleString("de-DE"));

  return (
    <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8 lg:py-10">
      <PageHeader
        crumbs={[{ label: "Übersicht" }]}
        eyebrow="Adminpanel"
        title="Übersicht"
        subtitle="Was gerade zu tun ist und wie es auf golftrack.app läuft – auf einen Blick."
        action={<PrimaryLink href="/admin/werbung/neu">Neue Anzeige</PrimaryLink>}
      />

      <h2 className="mt-10 text-xs font-medium uppercase tracking-[0.14em] text-cream/50">Zu erledigen</h2>
      <div className="mt-3 grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-3">
        <StatCard
          label="Anlagen prüfen"
          value={fmt(o.pending)}
          note="eingereicht, noch nicht freigegeben"
          icon="inbox"
          href="/admin/anlagen?status=offen"
          highlight={(o.pending ?? 0) > 0}
        />
        <StatCard
          label="Werbeanfragen"
          value={fmt(o.adRequests)}
          note="über /werbung eingegangen"
          icon="megaphone"
          href="/admin/werbung"
          highlight={(o.adRequests ?? 0) > 0}
        />
        <StatCard
          label="Fehlermeldungen"
          value={fmt(o.reports30)}
          note="letzte 30 Tage"
          icon="alert"
          href="#meldungen"
        />
      </div>

      <h2 className="mt-10 text-xs font-medium uppercase tracking-[0.14em] text-cream/50">Wie es läuft</h2>
      <div className="mt-3 grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
        <StatCard
          label="Plätze online"
          value={fmt((o.approvedGolf ?? 0) + (o.approvedMinigolf ?? 0))}
          note={`${fmt(o.approvedGolf)} Golf · ${fmt(o.approvedMinigolf)} Minigolf`}
          icon="flag"
          href="/admin/anlagen?status=frei"
        />
        <StatCard
          label="Anzeigen aktiv"
          value={fmt(o.adsActive)}
          note="im Minigolf-Zähler"
          icon="megaphone"
          href="/admin/werbung"
        />
        <StatCard
          label="Gemeldete Runden"
          value={fmt(o.rounds30)}
          note="letzte 30 Tage, anonym"
          icon="chart"
          href="/admin/statistik"
        />
        <StatCard label="Android-Warteliste" value={fmt(o.waitlist)} note="bestätigte Adressen" icon="phone" />
      </div>

      <div className="mt-10 grid gap-6 lg:grid-cols-2">
        <Panel
          title="Zu prüfen"
          action={{
            href: "/admin/anlagen?status=offen",
            label: "Alle anzeigen",
          }}
        >
          <CourseRows courses={pending} empty="Nichts offen – alles geprüft." />
        </Panel>

        <div id="meldungen">
          <Panel title="Neueste Fehlermeldungen">
            {o.latestReports.length === 0 ? (
              <p className="px-5 py-6 text-sm text-cream/55">Keine Meldungen.</p>
            ) : (
              <ul className="divide-y divide-white/[0.07]">
                {o.latestReports.map((r) => (
                  <li key={r.id}>
                    <Link
                      href={`/admin/${r.courseSlug}`}
                      className="block px-5 py-3.5 transition-colors hover:bg-white/[0.03]"
                    >
                      <span className="flex items-center justify-between gap-3">
                        <span className="truncate font-medium">{r.courseName}</span>
                        <span className="shrink-0 font-mono text-xs text-cream/45">
                          {new Date(r.createdAt).toLocaleDateString("de-DE")}
                        </span>
                      </span>
                      <span className="mt-1 flex items-start gap-2 text-sm text-cream/60">
                        <span className="shrink-0 rounded border border-brass/40 px-1.5 py-px text-[11px] text-brass">
                          {REPORT_LABELS[r.category] ?? r.category}
                        </span>
                        <span className="line-clamp-2">{r.message}</span>
                      </span>
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </Panel>
        </div>
      </div>
    </div>
  );
}

function Center({ children }: { children: React.ReactNode }) {
  return (
    <div className="grid min-h-screen place-items-center px-5">
      <div className="w-full max-w-sm text-center">{children}</div>
    </div>
  );
}
