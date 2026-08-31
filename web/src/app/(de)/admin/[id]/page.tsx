import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import { getCourse } from "@/lib/courses";
import { toFeedCourse } from "@/lib/feed";
import { StatusPill } from "../StatusPill";
import { EditForm } from "./EditForm";
import { approve, moveBackToPending, reject, remove } from "../actions";

export const metadata: Metadata = {
  title: "Anlage prüfen · GolfTrack",
  robots: { index: false, follow: false },
};

export default async function AdminDetailPage({ params }: PageProps<"/admin/[id]">) {
  if (!(await isAuthenticated())) redirect("/admin");

  const { id } = await params;
  const course = await getCourse(id);
  if (!course) notFound();

  const feed = toFeedCourse(course);

  return (
    <div className="mx-auto max-w-4xl px-5 py-12 sm:px-8">
      <Link href="/admin" className="marginal transition-colors hover:text-brass-soft">
        ← Übersicht
      </Link>

      <header className="mt-4 flex flex-wrap items-start justify-between gap-4 border-b rule pb-6">
        <div>
          <h1 className="font-display text-3xl tracking-tight">{course.name}</h1>
          <p className="mt-1.5 text-sm text-cream/70">
            {course.location || "ohne Ortsangabe"} · eingegangen am{" "}
            {new Date(course.createdAt).toLocaleDateString("de-DE", {
              day: "2-digit",
              month: "long",
              year: "numeric",
            })}
          </p>
        </div>
        <StatusPill status={course.status} kind={course.kind} />
      </header>

      {/* Wer hat eingereicht */}
      <section className="mt-8 rounded-sm border rule bg-moss/30 p-5">
        <h2 className="marginal">Einsender</h2>
        <dl className="mt-3 grid gap-x-8 gap-y-2 text-sm sm:grid-cols-3">
          <Detail label="Name" value={course.submitterName || "–"} />
          <Detail
            label="E-Mail"
            value={
              course.submitterEmail ? (
                <a
                  href={`mailto:${course.submitterEmail}?subject=${encodeURIComponent(`GolfTrack: ${course.name}`)}`}
                  className="text-brass underline underline-offset-4"
                >
                  {course.submitterEmail}
                </a>
              ) : (
                "–"
              )
            }
          />
          <Detail label="Funktion" value={course.submitterRole || "–"} />
        </dl>
      </section>

      {/* Entscheidung */}
      <section className="mt-6 flex flex-wrap items-center gap-3">
        {course.status !== "approved" ? (
          <form action={approve}>
            <input type="hidden" name="id" value={course.id} />
            <button type="submit" className="btn-brass !py-2.5 text-sm">
              Freigeben
            </button>
          </form>
        ) : null}
        {course.status !== "rejected" ? (
          <form action={reject}>
            <input type="hidden" name="id" value={course.id} />
            <button type="submit" className="btn-ghost !py-2.5 text-sm">
              Ablehnen
            </button>
          </form>
        ) : null}
        {course.status !== "pending" ? (
          <form action={moveBackToPending}>
            <input type="hidden" name="id" value={course.id} />
            <button type="submit" className="btn-ghost !py-2.5 text-sm">
              Zurück auf offen
            </button>
          </form>
        ) : null}
        <form action={remove} className="ml-auto">
          <input type="hidden" name="id" value={course.id} />
          <button
            type="submit"
            className="text-sm text-cream/65 underline underline-offset-4 transition-colors hover:text-[#e07a63]"
          >
            Endgültig löschen
          </button>
        </form>
      </section>

      {course.status === "approved" ? (
        <p className="mt-4 text-sm text-cream/70">
          In der App sichtbar unter der Kennung{" "}
          <code className="font-mono text-brass">{course.slug}</code>
          {course.kind === "minigolf" ? (
            <>
              {" · "}
              <Link href={`/minigolf/${course.slug}`} className="text-brass underline underline-offset-4">
                QR-Landeseite
              </Link>
            </>
          ) : null}
        </p>
      ) : null}

      <EditForm course={course} />

      {/* Kontrolle: was die App bekommt */}
      <section className="mt-12">
        <h2 className="marginal">So sieht es die App</h2>
        <pre className="mt-3 overflow-x-auto rounded-sm border rule bg-night/85 p-5 font-mono text-xs leading-relaxed text-cream/65">
          {JSON.stringify(feed, null, 2)}
        </pre>
      </section>
    </div>
  );
}

function Detail({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div>
      <dt className="text-xs uppercase tracking-[0.1em] text-cream/60">{label}</dt>
      <dd className="mt-0.5 text-cream/80">{value}</dd>
    </div>
  );
}
