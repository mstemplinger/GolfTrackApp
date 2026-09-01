import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { adReach, getAd } from "@/lib/ads";
import { isAuthenticated } from "@/lib/auth";
import { listCourses } from "@/lib/courses";
import { AdForm } from "../AdForm";
import { AdStatusPill } from "../AdStatusPill";
import { removeAd, switchAdStatus } from "../actions";

export const metadata: Metadata = {
  title: "Anzeige · GolfTrack",
  robots: { index: false, follow: false },
};

export default async function AdDetailPage({ params }: PageProps<"/admin/werbung/[id]">) {
  if (!(await isAuthenticated())) redirect("/admin");

  const { id } = await params;
  const ad = await getAd(id);
  if (!ad) notFound();

  const [reach, courses] = await Promise.all([
    adReach(ad.id),
    listCourses({ status: "approved", kind: "minigolf", limit: 500 }),
  ]);

  const rate = reach.total.impressions
    ? (reach.total.clicks / reach.total.impressions) * 100
    : 0;

  return (
    <div className="mx-auto max-w-5xl px-5 py-12 sm:px-8">
      <Link href="/admin/werbung" className="marginal transition-colors hover:text-brass-soft">
        ← Werbung
      </Link>

      <header className="mt-4 flex flex-wrap items-start justify-between gap-4 border-b rule pb-6">
        <div>
          <h1 className="font-display text-3xl tracking-tight">{ad.title}</h1>
          <p className="mt-1.5 text-sm text-cream/70">
            {ad.advertiser || "ohne Auftraggeber"} · {ad.courseSlug || "alle Anlagen"} · angelegt am{" "}
            {new Date(ad.createdAt).toLocaleDateString("de-DE")}
          </p>
        </div>
        <AdStatusPill status={ad.status} />
      </header>

      <section className="mt-6 flex flex-wrap items-center gap-3">
        {ad.status !== "active" ? (
          <StatusButton id={ad.id} status="active" label="Schalten" primary />
        ) : (
          <StatusButton id={ad.id} status="paused" label="Pausieren" />
        )}
        {ad.status !== "draft" ? <StatusButton id={ad.id} status="draft" label="Zurück in den Entwurf" /> : null}
        <form action={removeAd} className="ml-auto">
          <input type="hidden" name="id" value={ad.id} />
          <button
            type="submit"
            className="text-sm text-cream/65 underline underline-offset-4 transition-colors hover:text-[#e07a63]"
          >
            Endgültig löschen
          </button>
        </form>
      </section>

      {ad.source === "form" ? (
        <section className="mt-8 rounded-sm border rule bg-moss/30 p-5">
          <h2 className="marginal">Anfrage über /werbung</h2>
          <dl className="mt-3 grid gap-x-8 gap-y-2 text-sm sm:grid-cols-3">
            <Detail label="Name" value={ad.submitterName || "–"} />
            <Detail
              label="E-Mail"
              value={ad.submitterEmail || "–"}
              href={
                ad.submitterEmail
                  ? `mailto:${ad.submitterEmail}?subject=${encodeURIComponent(`GolfTrack: Werbeplatz ${ad.courseSlug}`)}`
                  : undefined
              }
            />
            <Detail label="Telefon" value={ad.submitterPhone || "–"} />
          </dl>
          {ad.requestNote ? (
            <p className="mt-4 max-w-2xl whitespace-pre-line text-sm leading-relaxed text-cream/75">
              {ad.requestNote}
            </p>
          ) : null}
        </section>
      ) : null}

      <section className="mt-8 rounded-sm border rule bg-moss/30 p-5">
        <h2 className="marginal">Reichweite, letzte 30 Tage</h2>
        <dl className="mt-3 grid gap-x-8 gap-y-2 text-sm sm:grid-cols-3">
          <Detail label="Gesehen" value={reach.total.impressions.toLocaleString("de-DE")} />
          <Detail label="Getippt" value={reach.total.clicks.toLocaleString("de-DE")} />
          <Detail label="Anteil" value={`${rate.toFixed(1).replace(".", ",")} %`} />
        </dl>
        {reach.daily.length ? (
          <div className="mt-5 overflow-x-auto">
            <table className="w-full min-w-[20rem] border-collapse text-sm">
              <thead>
                <tr className="font-mono text-[0.6rem] uppercase tracking-[0.16em] text-cream/60">
                  <th scope="col" className="pb-2 text-left font-normal">Tag</th>
                  <th scope="col" className="pb-2 text-right font-normal">Gesehen</th>
                  <th scope="col" className="pb-2 text-right font-normal">Getippt</th>
                </tr>
              </thead>
              <tbody className="font-mono text-cream/80">
                {reach.daily.map((entry) => (
                  <tr key={entry.day}>
                    <td className="py-0.5">{new Date(entry.day).toLocaleDateString("de-DE")}</td>
                    <td className="py-0.5 text-right">{entry.impressions.toLocaleString("de-DE")}</td>
                    <td className="py-0.5 text-right">{entry.clicks.toLocaleString("de-DE")}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="mt-3 text-sm text-cream/65">Noch nichts gezählt.</p>
        )}
      </section>

      <AdForm
        ad={ad}
        courses={courses.map((course) => ({
          slug: course.slug,
          name: course.name,
          location: course.location,
        }))}
      />
    </div>
  );
}

function StatusButton({
  id,
  status,
  label,
  primary,
}: {
  id: string;
  status: string;
  label: string;
  primary?: boolean;
}) {
  return (
    <form action={switchAdStatus}>
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="status" value={status} />
      <button type="submit" className={`${primary ? "btn-brass" : "btn-ghost"} !py-2.5 text-sm`}>
        {label}
      </button>
    </form>
  );
}

function Detail({ label, value, href }: { label: string; value: string; href?: string }) {
  return (
    <div>
      <dt className="marginal">{label}</dt>
      <dd className="mt-0.5 font-mono text-cream/85">
        {href ? (
          <a href={href} className="text-brass underline underline-offset-4">
            {value}
          </a>
        ) : (
          value
        )}
      </dd>
    </div>
  );
}
