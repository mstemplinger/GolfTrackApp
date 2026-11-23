import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { pendingNameRequests } from "@/lib/courseNameRequests";
import { getCourse } from "@/lib/courses";
import { currentOperator } from "@/lib/operatorAuth";
import { operatorT } from "@/lib/operatorLang";
import { CourseNameForm, PasswordForm, ProfileForm } from "./AccountForms";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await operatorT();
  return { title: `${t.account.title} · GolfTrack`, robots: { index: false, follow: false } };
}

/** Mein Konto: Name, Anmelde-E-Mail, Passwort und Namen der eigenen Plätze. */
export default async function OperatorAccountPage() {
  const op = await currentOperator();
  if (!op) redirect("/login");
  const { lang, t } = await operatorT();
  const a = t.account;

  const [courses, pending] = await Promise.all([
    Promise.all(op.courses.map((slug) => getCourse(slug))),
    pendingNameRequests(op.courses),
  ]);
  const list = courses
    .filter((c): c is NonNullable<typeof c> => Boolean(c))
    .sort((x, y) => x.name.localeCompare(y.name, t.report.locale));
  const fmtDate = (iso: string) => new Date(iso).toLocaleDateString(t.report.locale);

  return (
    <div className="mx-auto max-w-3xl px-5 py-10 sm:px-8">
      <p className="flex items-center gap-2 text-xs font-medium uppercase tracking-[0.18em] text-brass">
        <span className="h-1.5 w-1.5 rounded-full bg-brass" />
        {t.portal}
      </p>
      <h1 className="mt-2 font-display text-3xl tracking-tight sm:text-4xl">{a.title}</h1>
      <p className="mt-2 text-sm leading-relaxed text-cream/60">{a.intro}</p>

      <Section title={a.profile}>
        <ProfileForm lang={lang} name={op.name} email={op.email} />
      </Section>

      <Section title={a.passwordTitle}>
        <PasswordForm lang={lang} />
      </Section>

      {list.length ? (
        <Section title={a.coursesTitle} intro={a.coursesIntro}>
          <div className="space-y-3">
            {list.map((c) => {
              const p = pending.find((r) => r.courseSlug === c.slug);
              return (
                <CourseNameForm
                  key={c.slug}
                  lang={lang}
                  slug={c.slug}
                  name={c.name}
                  kindLabel={c.kind === "golf" ? t.golfCourse : t.minigolfFacility}
                  pending={p ? { id: p.id, requestedName: p.requestedName, since: fmtDate(p.createdAt) } : null}
                />
              );
            })}
          </div>
        </Section>
      ) : null}
    </div>
  );
}

function Section({ title, intro, children }: { title: string; intro?: string; children: React.ReactNode }) {
  return (
    <section className="mt-10 rounded-xl border border-white/10 bg-white/[0.02] p-5 sm:p-6">
      <h2 className="text-xs font-medium uppercase tracking-[0.14em] text-cream/60">{title}</h2>
      {intro ? <p className="mt-1.5 text-sm leading-relaxed text-cream/55">{intro}</p> : null}
      <div className="mt-5">{children}</div>
    </section>
  );
}
