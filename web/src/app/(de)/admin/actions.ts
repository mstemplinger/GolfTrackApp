"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createSession, destroySession, isAuthenticated, passwordMatches } from "@/lib/auth";
import { deleteCourse, setStatus, updateCourse } from "@/lib/courses";
import { adminUpdateSchema, holeSchema } from "@/lib/schema";
import { z } from "zod";

/** Nach einer Statusaenderung: die Seiten erneuern, auf denen der Platz auftaucht. */
function revalidatePublicPages(slug?: string): void {
  revalidatePath("/plaetze");
  revalidatePath("/en/courses");
  revalidatePath("/sitemap.xml");
  if (slug) revalidatePath(`/minigolf/${slug}`);
}

async function requireAdmin(): Promise<void> {
  if (!(await isAuthenticated())) redirect("/admin");
}

export async function login(_state: string | null, formData: FormData): Promise<string | null> {
  const password = String(formData.get("password") ?? "");
  if (!passwordMatches(password)) return "Passwort stimmt nicht.";
  await createSession();
  redirect("/admin");
}

export async function logout(): Promise<void> {
  await destroySession();
  redirect("/admin");
}

export async function approve(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = String(formData.get("id"));
  const record = await setStatus(id, "approved");
  revalidatePath("/admin");
  revalidatePath(`/admin/${id}`);
  revalidatePublicPages(record?.slug);
}

export async function reject(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = String(formData.get("id"));
  const record = await setStatus(id, "rejected");
  revalidatePath("/admin");
  revalidatePath(`/admin/${id}`);
  revalidatePublicPages(record?.slug);
}

export async function moveBackToPending(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = String(formData.get("id"));
  const record = await setStatus(id, "pending");
  revalidatePath("/admin");
  revalidatePath(`/admin/${id}`);
  revalidatePublicPages(record?.slug);
}

export async function remove(formData: FormData): Promise<void> {
  await requireAdmin();
  await deleteCourse(String(formData.get("id")));
  revalidatePath("/admin");
  revalidatePublicPages();
  redirect("/admin");
}

const numberOrNull = (value: FormDataEntryValue | null): number | null => {
  const text = String(value ?? "").trim().replace(",", ".");
  if (!text) return null;
  const parsed = Number(text);
  return Number.isFinite(parsed) ? parsed : null;
};

export async function save(_state: string | null, formData: FormData): Promise<string | null> {
  await requireAdmin();
  const id = String(formData.get("id"));
  const holes = Number(formData.get("holes") ?? 0);

  const holeData: z.input<typeof holeSchema>[] = [];
  for (let index = 0; index < holes; index += 1) {
    holeData.push({
      number: index + 1,
      par: numberOrNull(formData.get(`par-${index}`)),
      hcp: numberOrNull(formData.get(`hcp-${index}`)),
      length: numberOrNull(formData.get(`length-${index}`)),
      teeLat: numberOrNull(formData.get(`teeLat-${index}`)),
      teeLon: numberOrNull(formData.get(`teeLon-${index}`)),
      flagLat: numberOrNull(formData.get(`flagLat-${index}`)),
      flagLon: numberOrNull(formData.get(`flagLon-${index}`)),
    });
  }

  const hasHoleValues = holeData.some((hole) => hole.par !== null || hole.hcp !== null || hole.length !== null);

  const parsed = adminUpdateSchema.safeParse({
    name: String(formData.get("name") ?? ""),
    location: String(formData.get("location") ?? ""),
    country: String(formData.get("country") ?? "DE").toUpperCase().slice(0, 2),
    slug: String(formData.get("slug") ?? ""),
    holes,
    latitude: numberOrNull(formData.get("latitude")),
    longitude: numberOrNull(formData.get("longitude")),
    courseRating: numberOrNull(formData.get("courseRating")),
    slopeRating: numberOrNull(formData.get("slopeRating")),
    holeData: hasHoleValues ? holeData : [],
    facilityNotes: String(formData.get("facilityNotes") ?? ""),
    welcome: String(formData.get("welcome") ?? ""),
    website: String(formData.get("website") ?? ""),
    phone: String(formData.get("phone") ?? ""),
    publicEmail: String(formData.get("publicEmail") ?? ""),
    adminNotes: String(formData.get("adminNotes") ?? ""),
  });

  if (!parsed.success) {
    const first = parsed.error.issues[0];
    return `${first.path.join(".")}: ${first.message}`;
  }

  const record = await updateCourse(id, parsed.data);
  revalidatePath("/admin");
  revalidatePath(`/admin/${id}`);
  revalidatePublicPages(record?.slug);
  return "Gespeichert.";
}
