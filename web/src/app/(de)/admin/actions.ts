"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { attemptLogin, createSession, destroySession, isAuthenticated } from "@/lib/auth";
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
  const result = await attemptLogin(password);
  if (result === "locked") return "Zu viele Fehlversuche. Bitte in 15 Minuten erneut versuchen.";
  if (result === "wrong") return "Passwort stimmt nicht.";
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

  // Abschläge kommen wie die Hinweise als JSON-Felder aus dem Tee-Editor.
  let tees: unknown = [];
  let holeTees: unknown = [];
  try {
    tees = JSON.parse(String(formData.get("tees") ?? "[]"));
    holeTees = JSON.parse(String(formData.get("holeTees") ?? "[]"));
  } catch {
    return "tees: konnte nicht gelesen werden";
  }
  type HoleTeeInput = { length?: number | null; lat?: number | null; lon?: number | null };
  const teesAt = (index: number): HoleTeeInput[] =>
    Array.isArray(holeTees) && Array.isArray(holeTees[index]) ? holeTees[index] : [];

  const holeData: z.input<typeof holeSchema>[] = [];
  for (let index = 0; index < holes; index += 1) {
    const perTee = teesAt(index);
    // Leere Standardwerte übernimmt der erste Abschlag – ältere App-Versionen
    // kennen nur diese.
    const first = perTee[0];
    const length = numberOrNull(formData.get(`length-${index}`)) ?? first?.length ?? null;
    let teeLat = numberOrNull(formData.get(`teeLat-${index}`));
    let teeLon = numberOrNull(formData.get(`teeLon-${index}`));
    if ((teeLat === null || teeLon === null) && first?.lat != null && first?.lon != null) {
      teeLat = first.lat;
      teeLon = first.lon;
    }
    holeData.push({
      number: index + 1,
      par: numberOrNull(formData.get(`par-${index}`)),
      hcp: numberOrNull(formData.get(`hcp-${index}`)),
      length,
      teeLat,
      teeLon,
      flagLat: numberOrNull(formData.get(`flagLat-${index}`)),
      flagLon: numberOrNull(formData.get(`flagLon-${index}`)),
      tees: perTee as z.input<typeof holeSchema>["tees"],
    });
  }

  const hasHoleValues = holeData.some(
    (hole) =>
      [hole.par, hole.hcp, hole.length, hole.teeLat, hole.flagLat].some((value) => value !== null) ||
      Boolean(hole.tees?.length),
  );

  // Die Hinweise kommen als ein JSON-Feld aus `HintsEditor`. Unlesbares
  // verwerfen wir nicht stillschweigend – zod meldet es als Fehler zurück.
  let facilityHints: unknown = [];
  try {
    facilityHints = JSON.parse(String(formData.get("facilityHints") ?? "[]"));
  } catch {
    return "facilityHints: konnte nicht gelesen werden";
  }

  const parsed = adminUpdateSchema.safeParse({
    name: String(formData.get("name") ?? ""),
    location: String(formData.get("location") ?? ""),
    country: String(formData.get("country") ?? "DE").toUpperCase().slice(0, 2),
    slug: String(formData.get("slug") ?? ""),
    holes,
    latitude: numberOrNull(formData.get("latitude")),
    longitude: numberOrNull(formData.get("longitude")),
    firstTeeLat: numberOrNull(formData.get("firstTeeLat")),
    firstTeeLon: numberOrNull(formData.get("firstTeeLon")),
    courseRating: numberOrNull(formData.get("courseRating")),
    slopeRating: numberOrNull(formData.get("slopeRating")),
    holeData: hasHoleValues ? holeData : [],
    tees,
    facilityNotes: String(formData.get("facilityNotes") ?? ""),
    facilityHints,
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
