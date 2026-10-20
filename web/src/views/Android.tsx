import Link from "next/link";
import { Footer, Header, PageHeader } from "@/components/Chrome";
import { t } from "@/i18n/content";
import { APP_STORE_URL, path, type Lang } from "@/i18n/routes";
import { ANDROID_RELEASE } from "@/lib/android";
import { AndroidCta } from "@/components/AndroidCta";
import { AndroidCta as AndroidCtaPlayOnly } from "@/components/AndroidCta";

/**
 * Download der Android-APK. Bewusst ohne Play Store: die erste Fassung geht
 * direkt von hier aus. Caddy und Training fehlen noch und stehen deshalb
 * ausdrücklich als „kommt später" auf der Seite.
 */
export function Android({ lang }: { lang: Lang }) {
  const copy = t(lang).android;
  const nav = t(lang).nav;
  const rel = ANDROID_RELEASE;
  const mb = (rel.sizeBytes / 1_000_000).toLocaleString(lang === "de" ? "de-DE" : "en-GB", {
    maximumFractionDigits: 1,
  });
  const date = rel.releasedAt
    ? new Date(rel.releasedAt).toLocaleDateString(lang === "de" ? "de-DE" : "en-GB", {
        day: "numeric",
        month: "long",
        year: "numeric",
      })
    : "";

  return (
    <>
      <Header lang={lang} current="android" />
      <PageHeader index="Android" title={copy.title} lead={copy.lead} />

      <main className="mx-auto max-w-6xl px-5 py-14 sm:px-8 sm:py-16">
        <div className="grid gap-12 lg:grid-cols-[1fr_22rem] lg:gap-16">
          <div className="space-y-12">
            <section>
              <h2 className="marginal">{copy.includedTitle}</h2>
              <ul className="mt-4 divide-y rule border-y rule">
                {copy.included.map((item) => (
                  <li key={item} className="flex gap-3 py-3 leading-relaxed text-cream/80">
                    <span aria-hidden className="text-brass">✓</span>
                    {item}
                  </li>
                ))}
              </ul>
            </section>

            <section>
              <h2 className="marginal">{copy.laterTitle}</h2>
              <ul className="mt-4 divide-y rule border-y rule">
                {copy.later.map((item) => (
                  <li key={item} className="flex items-center justify-between gap-3 py-3 text-cream/60">
                    {item}
                    <span className="shrink-0 rounded-full border border-brass/50 px-2.5 py-0.5 text-xs text-brass">
                      {lang === "de" ? "später" : "later"}
                    </span>
                  </li>
                ))}
              </ul>
              <p className="mt-4 max-w-2xl text-sm leading-relaxed text-cream/60">{copy.laterNote}</p>
            </section>

            <section>
              <h2 className="marginal">{copy.installTitle}</h2>
              <ol className="mt-4 space-y-4">
                {copy.install.map((step, i) => (
                  <li key={step} className="flex gap-4 leading-relaxed text-cream/80">
                    <span className="font-display text-2xl leading-none text-brass">{i + 1}</span>
                    {step}
                  </li>
                ))}
              </ol>
              <p className="mt-6 max-w-2xl text-sm leading-relaxed text-cream/60">{copy.updateNote}</p>
            </section>
          </div>

          <aside className="lg:pt-1">
            <div className="rounded-sm border rule bg-black/20 p-6">
              {rel.file ? (
                <>
                  <a href={`/downloads/${rel.file}`} download className="btn-brass w-full">
                    {copy.download}
                  </a>
                  <dl className="mt-6 space-y-2 text-sm">
                    <Row label={copy.versionLabel} value={rel.versionName} />
                    <Row label={copy.sizeLabel} value={`${mb} MB`} />
                    {date ? <Row label={copy.dateLabel} value={date} /> : null}
                  </dl>
                  <p className="mt-4 text-xs text-cream/50">{copy.requirement}</p>
                  <p className="mt-4 break-all font-mono text-[0.65rem] leading-relaxed text-cream/40">
                    {copy.checksumLabel}: {rel.sha256}
                  </p>
                </>
              ) : (
                <p className="leading-relaxed text-cream/70">{copy.notYet}</p>
              )}
            </div>

            <div className="mt-6">
              <AndroidCtaPlayOnly lang={lang} />
            </div>

            <div className="mt-6">
              <AndroidCta lang={lang} showApk={false} />
            </div>

            <p className="mt-8 text-sm text-cream/60">
              {copy.iphone}{" "}
              <a href={APP_STORE_URL} target="_blank" rel="noreferrer" className="text-brass underline underline-offset-4">
                {nav.appStore}
              </a>
            </p>
            <p className="mt-2 text-sm text-cream/60">
              <Link href={path("support", lang)} className="underline underline-offset-4 hover:text-brass">
                {nav.support}
              </Link>
            </p>
          </aside>
        </div>
      </main>

      <Footer lang={lang} />
    </>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between gap-4">
      <dt className="text-cream/50">{label}</dt>
      <dd className="text-cream/85">{value}</dd>
    </div>
  );
}
