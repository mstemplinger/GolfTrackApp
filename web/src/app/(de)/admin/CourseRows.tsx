import Link from "next/link";
import type { CourseRecord } from "@/lib/courses";
import { StatusPill } from "./StatusPill";
import { Icon } from "./ui";

/** Zeilen der Anlagenliste – auf der Übersicht und unter „Anlagen“. */
export function CourseRows({ courses, empty }: { courses: CourseRecord[]; empty: string }) {
  if (!courses.length) return <p className="px-5 py-6 text-sm text-cream/55">{empty}</p>;
  return (
    <ul className="divide-y divide-white/[0.07]">
      {courses.map((course) => (
        <li key={course.id}>
          <Link
            href={`/admin/${course.id}`}
            className="group flex items-center gap-4 px-5 py-3.5 transition-colors hover:bg-white/[0.03]"
          >
            <span className="min-w-0 flex-1">
              <span className="block truncate font-medium">{course.name}</span>
              <span className="mt-0.5 block truncate text-sm text-cream/55">
                {[
                  course.location,
                  `${course.holes} ${course.kind === "golf" ? "Löcher" : "Bahnen"}`,
                  course.submitterEmail,
                ]
                  .filter(Boolean)
                  .join(" · ")}
              </span>
            </span>
            <span className="hidden font-mono text-xs text-cream/45 sm:block">
              {new Date(course.createdAt).toLocaleDateString("de-DE")}
            </span>
            <StatusPill status={course.status} kind={course.kind} />
            <Icon name="chevron" className="h-4 w-4 shrink-0 text-cream/25 transition-colors group-hover:text-brass" />
          </Link>
        </li>
      ))}
    </ul>
  );
}
