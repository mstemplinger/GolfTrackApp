import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { listAds, type AdWithReach } from "@/lib/ads";
import { isAuthenticated } from "@/lib/auth";
import { AdStatusPill } from "./AdStatusPill";

export const metadata: Metadata = {
  title: "Werbung · GolfTrack",
  robots: { index: false, follow: false },
};

export default async function AdsPage() {
  if (!(await isAuthenticated())) redirect("/admin");

  const ads = await listAds();
  const active = ads.filter((ad) => ad.status === "active");
  // Was über /werbung hereinkommt, liegt als Entwurf da und will zuerst
  // angeschaut werden – deshalb eine eigene Gruppe ganz oben.
  const requests = ads.filter((ad) => ad.status === "draft" && ad.source === "form");
  const rest = ads.filter((ad) => ad.status !== "active" && !requests.includes(ad));
  const reach = active.reduce((sum, ad) => sum + ad.impressions, 0);

  return (
    <div className="mx-auto max-w-5xl px-5 py-12 sm:px-8">
      <Link href="/admin" className="marginal transition-colors hover:text-brass-soft">
        ← Übersicht
      </Link>

      <header className="mt-4 flex flex-wrap items-end justify-between gap-4 border-b rule pb-6">
        <div>
          <p className="marginal">Adminpanel</p>
          <h1 className="mt-2 font-display text-3xl tracking-tight">Werbung</h1>
          <p className="mt-2 max-w-xl text-sm leading-relaxed text-cream/65">
            Der freie Platz unter den Spielernamen in der Minigolfkarte. Eine Anzeige gilt entweder
            für eine Anlage oder für alle – die Anlage geht vor.
          </p>
        </div>
        <Link href="/admin/werbung/neu" className="btn-brass !py-2.5 text-sm">
          Neue Anzeige
        </Link>
      </header>

      <dl className="mt-8 grid gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-3">
        <Stat label="Offene Anfragen" value={requests.length} highlight />
        <Stat label="Aktiv" value={active.length} />
        <Stat label="Sichtkontakte (30 Tage)" value={reach} />
      </dl>

      {requests.length ? <Group title="Anfragen von Betreibern" ads={requests} empty="" /> : null}
      <Group title="Aktiv" ads={active} empty="Noch keine Anzeige geschaltet." />
      <Group title="Entwürfe und pausierte" ads={rest} empty="Nichts abgelegt." />
    </div>
  );
}

function Stat({ label, value, highlight }: { label: string; value: number; highlight?: boolean }) {
  return (
    <div className="bg-night/85 p-5">
      <dt className="marginal">{label}</dt>
      <dd className={`mt-1.5 font-mono text-3xl ${highlight && value > 0 ? "text-brass" : "text-cream/80"}`}>
        {value.toLocaleString("de-DE")}
      </dd>
    </div>
  );
}

function Group({ title, ads, empty }: { title: string; ads: AdWithReach[]; empty: string }) {
  return (
    <section className="mt-12">
      <h2 className="marginal">{title}</h2>
      {ads.length === 0 ? (
        <p className="mt-3 text-sm text-cream/65">{empty}</p>
      ) : (
        <ul className="mt-4 divide-y rule overflow-hidden rounded-sm border rule">
          {ads.map((ad) => (
            <li key={ad.id}>
              <Link
                href={`/admin/werbung/${ad.id}`}
                className="flex flex-wrap items-center justify-between gap-3 bg-night/85 p-4 transition-colors hover:bg-moss-2/60"
              >
                <span className="min-w-0">
                  <span className="block truncate font-display text-lg tracking-tight">{ad.title}</span>
                  <span className="mt-0.5 block text-sm text-cream/70">
                    {[
                      ad.courseSlug || "alle Anlagen",
                      ad.advertiser || (ad.source === "form" ? ad.submitterName : ""),
                      ad.endsOn ? `bis ${new Date(ad.endsOn).toLocaleDateString("de-DE")}` : null,
                    ]
                      .filter(Boolean)
                      .join(" · ")}
                  </span>
                </span>
                <span className="flex items-center gap-3">
                  <span className="font-mono text-xs text-cream/60">
                    {ad.impressions.toLocaleString("de-DE")} × gesehen · {ad.clicks.toLocaleString("de-DE")} × getippt
                  </span>
                  <AdStatusPill status={ad.status} />
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
