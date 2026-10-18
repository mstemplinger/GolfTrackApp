import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import { courseMarkers, listCourses } from "@/lib/courses";
import { AdForm } from "../AdForm";

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
    <div className="mx-auto max-w-5xl px-5 py-12 sm:px-8">
      <Link href="/admin/werbung" className="marginal transition-colors hover:text-brass-soft">
        ← Werbung
      </Link>
      <h1 className="mt-4 border-b rule pb-6 font-display text-3xl tracking-tight">Neue Anzeige</h1>
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
