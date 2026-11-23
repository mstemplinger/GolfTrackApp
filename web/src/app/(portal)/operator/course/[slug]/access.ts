import "server-only";
import { notFound, redirect } from "next/navigation";
import { getCourse, type CourseRecord } from "@/lib/courses";
import { currentOperator } from "@/lib/operatorAuth";
import type { Operator } from "@/lib/operators";

/**
 * Konto und Platz für eine Seite unter /course/<kennung>. Ohne Anmeldung zum
 * Login; fremde Plätze gibt es für dieses Konto nicht – auch nicht als
 * „verboten“, sondern als 404.
 */
export async function courseForOperator(slug: string): Promise<{ op: Operator; course: CourseRecord }> {
  const op = await currentOperator();
  if (!op) redirect("/login");
  if (!op.courses.includes(slug)) notFound();
  const course = await getCourse(slug);
  if (!course) notFound();
  return { op, course };
}

/** Lage des Platzes für Umkreis-Werbung: Mittelpunkt, sonst erster Abschlag. */
export function coursePoint(course: CourseRecord): { lat: number; lon: number } | null {
  if (course.latitude != null && course.longitude != null) return { lat: course.latitude, lon: course.longitude };
  if (course.firstTeeLat != null && course.firstTeeLon != null) return { lat: course.firstTeeLat, lon: course.firstTeeLon };
  return null;
}
