import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import { listCourses } from "@/lib/courses";
import { getOperator } from "@/lib/operators";
import { operatorPortalUrl } from "@/lib/operatorPortal";
import { OperatorForm } from "../OperatorForm";
import { ResetPasswordForm } from "../ResetPasswordForm";
import { DeleteOperatorButton } from "../DeleteOperatorButton";
import { PageHeader, Panel } from "../../ui";

export const metadata: Metadata = {
  title: "Betreiber · GolfTrack",
  robots: { index: false, follow: false },
};

export default async function OperatorDetailPage({ params }: PageProps<"/admin/betreiber/[id]">) {
  if (!(await isAuthenticated())) redirect("/admin");
  const { id } = await params;
  const [op, courses] = await Promise.all([getOperator(id), listCourses({ status: "approved", limit: 5000 })]);
  if (!op) notFound();
  const portal = operatorPortalUrl();
  const fmtDate = (v: string | null) =>
    v ? new Date(v).toLocaleString("de-DE", { dateStyle: "medium", timeStyle: "short" }) : "noch nie";

  return (
    <div className="mx-auto max-w-4xl px-5 py-8 sm:px-8 lg:py-10">
      <PageHeader
        crumbs={[{ label: "Betreiber", href: "/admin/betreiber" }, { label: op.name }]}
        eyebrow={op.active ? "Konto aktiv" : "Konto gesperrt"}
        title={op.name}
        subtitle={`${op.email} · angelegt am ${new Date(op.createdAt).toLocaleDateString("de-DE")} · letzte Anmeldung ${fmtDate(op.lastLoginAt)}`}
      />

      <div className="mt-8 border-t border-white/10 pt-8">
        <OperatorForm
          portalUrl={portal}
          initial={{
            id: op.id,
            name: op.name,
            email: op.email,
            notes: op.notes,
            active: op.active,
            permissions: op.permissions,
            courses: op.courses,
          }}
          courses={courses
            .map((c) => ({ slug: c.slug, name: c.name, location: c.location, kind: c.kind }))
            .sort((a, b) => a.name.localeCompare(b.name, "de"))}
        />
      </div>

      <div className="mt-10 grid gap-6 sm:grid-cols-2">
        <Panel title="Passwort">
          <div className="space-y-3 px-5 py-4">
            <p className="text-sm text-cream/60">
              Zuletzt geändert am {new Date(op.passwordChangedAt).toLocaleDateString("de-DE")}. Ein neues Passwort
              beendet alle laufenden Anmeldungen.
            </p>
            <ResetPasswordForm id={op.id} email={op.email} portalUrl={portal} />
          </div>
        </Panel>
        <Panel title="Konto löschen">
          <div className="space-y-3 px-5 py-4">
            <p className="text-sm text-cream/60">
              Entfernt das Konto und alle Zuweisungen. Die Statistik der Plätze bleibt erhalten.
            </p>
            <DeleteOperatorButton id={op.id} name={op.name} />
          </div>
        </Panel>
      </div>
    </div>
  );
}
