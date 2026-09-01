import type { Metadata } from "next";
import Link from "next/link";
import { isAuthenticated, adminConfigured } from "@/lib/auth";
import { countByStatus, listCourses, type CourseRecord } from "@/lib/courses";
import { LoginForm } from "./LoginForm";
import { logout } from "./actions";
import { StatusPill } from "./StatusPill";

export const metadata: Metadata = {
  title: "Adminpanel · GolfTrack",
  robots: { index: false, follow: false },
};

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

  const [pending, approved, rejected, counts] = await Promise.all([
    listCourses({ status: "pending" }),
    listCourses({ status: "approved" }),
    listCourses({ status: "rejected" }),
    countByStatus(),
  ]);

  return (
    <div className="mx-auto max-w-5xl px-5 py-12 sm:px-8">
      <header className="flex flex-wrap items-end justify-between gap-4 border-b rule pb-6">
        <div>
          <p className="marginal">Adminpanel</p>
          <h1 className="mt-2 font-display text-3xl tracking-tight">Eingegangene Anlagen</h1>
        </div>
        <div className="flex items-center gap-5 text-sm">
          <Link href="/admin/werbung" className="tap text-cream/70 transition-colors hover:text-brass">
            Werbung
          </Link>
          <Link href="/" className="tap text-cream/70 transition-colors hover:text-brass">
            Zur Website
          </Link>
          <form action={logout}>
            <button type="submit" className="tap text-cream/70 transition-colors hover:text-brass">
              Abmelden
            </button>
          </form>
        </div>
      </header>

      <dl className="mt-8 grid gap-px overflow-hidden rounded-sm border rule bg-brass/15 sm:grid-cols-3">
        <Stat label="Offen" value={counts.pending} highlight />
        <Stat label="Freigegeben" value={counts.approved} />
        <Stat label="Abgelehnt" value={counts.rejected} />
      </dl>

      <Group title="Zu prüfen" courses={pending} empty="Nichts offen." />
      <Group title="Freigegeben" courses={approved} empty="Noch nichts freigegeben." />
      {rejected.length ? <Group title="Abgelehnt" courses={rejected} empty="" /> : null}
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

function Stat({ label, value, highlight }: { label: string; value: number; highlight?: boolean }) {
  return (
    <div className="bg-black/25 p-5">
      <dt className="marginal">{label}</dt>
      <dd className={`mt-1.5 font-mono text-3xl ${highlight && value > 0 ? "text-brass" : "text-cream/80"}`}>
        {value}
      </dd>
    </div>
  );
}

function Group({ title, courses, empty }: { title: string; courses: CourseRecord[]; empty: string }) {
  return (
    <section className="mt-12">
      <h2 className="marginal">{title}</h2>
      {courses.length === 0 ? (
        <p className="mt-3 text-sm text-cream/65">{empty}</p>
      ) : (
        <ul className="mt-4 divide-y rule overflow-hidden rounded-sm border rule">
          {courses.map((course) => (
            <li key={course.id}>
              <Link
                href={`/admin/${course.id}`}
                className="flex flex-wrap items-center justify-between gap-3 bg-black/25 p-4 transition-colors hover:bg-white/[0.04]"
              >
                <span className="min-w-0">
                  <span className="block truncate font-display text-lg tracking-tight">{course.name}</span>
                  <span className="mt-0.5 block text-sm text-cream/70">
                    {[course.location, `${course.holes} ${course.kind === "golf" ? "Löcher" : "Bahnen"}`]
                      .filter(Boolean)
                      .join(" · ")}
                  </span>
                </span>
                <span className="flex items-center gap-3">
                  <span className="font-mono text-xs text-cream/60">
                    {new Date(course.createdAt).toLocaleDateString("de-DE")}
                  </span>
                  <StatusPill status={course.status} kind={course.kind} />
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
