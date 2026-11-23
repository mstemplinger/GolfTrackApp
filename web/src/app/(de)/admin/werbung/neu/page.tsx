import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import { courseMarkers, listCourses } from "@/lib/courses";
import { AdForm } from "../AdForm";
import { PageHeader } from "../../ui";

export const metadata: Metadata = {
  title: "Neue Anzeige · GolfTrack",
  robots: { index: false, follow: false },
};

export default async function NewAdPage() {
  if (!(await isAuthenticated())) redirect("/admin");

  const [courses, markers] = await Promise.all([
    listCourses({ status: "approved", kind: "minigolf", limit: 500 }),
    courseMarkers(),
  ]);

  return (
    <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8 lg:py-10">
      <PageHeader
        crumbs={[{ label: "Werbung", href: "/admin/werbung" }, { label: "Neue Anzeige" }]}
        eyebrow="Werbung"
        title="Neue Anzeige"
      />
      <div className="mt-8 border-t border-white/10" />
      <AdForm
        markers={markers}
        courses={courses.map((course) => ({
          slug: course.slug,
          name: course.name,
          location: course.location,
        }))}
      />
    </div>
  );
}
