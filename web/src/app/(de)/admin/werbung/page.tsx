import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { isAdRequest, listAds, type AdWithReach } from "@/lib/ads";
import { isAuthenticated } from "@/lib/auth";
import { AdStatusPill } from "./AdStatusPill";
import { PageHeader, Panel, PrimaryLink, StatCard } from "../ui";

export const metadata: Metadata = {
  title: "Werbung · GolfTrack",
  robots: { index: false, follow: false },
};

export default async function AdsPage() {
  if (!(await isAuthenticated())) redirect("/admin");

  const ads = await listAds();
  const active = ads.filter((ad) => ad.status === "active");
  // Was über /werbung oder das Betreiber-Portal hereinkommt, liegt als Entwurf
  // da und will zuerst angeschaut werden – deshalb eine eigene Gruppe ganz oben.
  const requests = ads.filter(isAdRequest);
  const rest = ads.filter((ad) => ad.status !== "active" && !requests.includes(ad));
  const reach = active.reduce((sum, ad) => sum + ad.impressions, 0);

  return (
    <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8 lg:py-10">
      <PageHeader
        crumbs={[{ label: "Werbung" }]}
        eyebrow="Werbeplatz"
        title="Werbung"
        subtitle="Der freie Platz unter den Spielernamen in der Minigolfkarte. Eine Anzeige gilt für einen Umkreis, eine Anlage oder alle – die Anlage geht vor."
        action={<PrimaryLink href="/admin/werbung/neu">Neue Anzeige</PrimaryLink>}
      />

      <div className="mt-10 grid gap-4 sm:grid-cols-3">
        <StatCard
          label="Offene Anfragen"
          value={requests.length}
          note="über /werbung eingegangen"
          icon="inbox"
          highlight={requests.length > 0}
        />
        <StatCard label="Aktiv" value={active.length} note="gerade geschaltet" icon="megaphone" />
        <StatCard
          label="Sichtkontakte"
          value={reach.toLocaleString("de-DE")}
          note="aktive Anzeigen, 30 Tage"
          icon="chart"
        />
      </div>

      {requests.length ? <Group title="Anfragen von Betreibern" ads={requests} empty="" /> : null}
      <Group title="Aktiv" ads={active} empty="Noch keine Anzeige geschaltet." />
      <Group title="Entwürfe und pausierte" ads={rest} empty="Nichts abgelegt." />
    </div>
  );
}

function Group({ title, ads, empty }: { title: string; ads: AdWithReach[]; empty: string }) {
  return (
    <div className="mt-6">
      <Panel title={title}>
        {ads.length === 0 ? (
          <p className="px-5 py-6 text-sm text-cream/55">{empty}</p>
        ) : (
          <ul className="divide-y divide-white/[0.07]">
            {ads.map((ad) => (
              <li key={ad.id}>
                <Link
                  href={`/admin/werbung/${ad.id}`}
                  className="flex flex-wrap items-center justify-between gap-3 px-5 py-3.5 transition-colors hover:bg-white/[0.03]"
                >
                  <span className="min-w-0">
                    <span className="block truncate font-medium">{ad.title}</span>
                    <span className="mt-0.5 block text-sm text-cream/70">
                      {[
                        ad.courseSlug || "alle Anlagen",
                        ad.advertiser || (ad.source !== "admin" ? ad.submitterName : ""),
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
      </Panel>
    </div>
  );
}
