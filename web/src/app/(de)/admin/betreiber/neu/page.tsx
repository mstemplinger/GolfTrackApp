import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import { listCourses } from "@/lib/courses";
import { operatorPortalUrl } from "@/lib/operatorPortal";
import { OperatorForm } from "../OperatorForm";
import { PageHeader } from "../../ui";

export const metadata: Metadata = {
  title: "Neuer Betreiber · GolfTrack",
  robots: { index: false, follow: false },
};

export default async function NewOperatorPage() {
  if (!(await isAuthenticated())) redirect("/admin");
  const courses = await listCourses({ status: "approved", limit: 5000 });

  return (
    <div className="mx-auto max-w-4xl px-5 py-8 sm:px-8 lg:py-10">
      <PageHeader
        crumbs={[{ label: "Betreiber", href: "/admin/betreiber" }, { label: "Neu" }]}
        eyebrow="Zugänge"
        title="Neuer Betreiber"
        subtitle="Das Passwort erzeugt das Adminpanel beim Anlegen – es wird genau einmal angezeigt."
      />
      <div className="mt-8 border-t border-white/10 pt-8">
        <OperatorForm
          portalUrl={operatorPortalUrl()}
          courses={courses
            .map((c) => ({ slug: c.slug, name: c.name, location: c.location, kind: c.kind }))
            .sort((a, b) => a.name.localeCompare(b.name, "de"))}
        />
      </div>
    </div>
  );
}
