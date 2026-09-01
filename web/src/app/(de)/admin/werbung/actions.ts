"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createAd, deleteAd, setAdStatus, updateAd } from "@/lib/ads";
import { isAuthenticated } from "@/lib/auth";
import { adSchema, adStatus } from "@/lib/schema";

async function requireAdmin(): Promise<void> {
  if (!(await isAuthenticated())) redirect("/admin");
}

/** Nach jeder Änderung: Übersicht neu und den Feed, aus dem die App liest. */
function revalidateAds(id?: string): void {
  revalidatePath("/admin/werbung");
  if (id) revalidatePath(`/admin/werbung/${id}`);
  revalidatePath("/api/v1/ads");
}

const textOrNull = (value: FormDataEntryValue | null): string | null => {
  const text = String(value ?? "").trim();
  return text ? text : null;
};

function readForm(formData: FormData) {
  return adSchema.safeParse({
    status: String(formData.get("status") ?? "draft"),
    placement: String(formData.get("placement") ?? "minigolf_scoring"),
    courseSlug: String(formData.get("courseSlug") ?? ""),
    title: String(formData.get("title") ?? ""),
    subtitle: String(formData.get("subtitle") ?? ""),
    imageURL: String(formData.get("imageURL") ?? ""),
    linkURL: String(formData.get("linkURL") ?? ""),
    advertiser: String(formData.get("advertiser") ?? ""),
    weight: Number(formData.get("weight") ?? 1) || 1,
    startsOn: textOrNull(formData.get("startsOn")),
    endsOn: textOrNull(formData.get("endsOn")),
    adminNotes: String(formData.get("adminNotes") ?? ""),
  });
}

const MESSAGES: Record<string, string> = {
  invalid_url: "Bitte eine vollständige Adresse mit https:// angeben.",
  invalid_slug: "Die Kennung der Anlage passt nicht.",
  invalid_date: "Bitte ein Datum im Format JJJJ-MM-TT angeben.",
  end_before_start: "Das Ende liegt vor dem Beginn.",
};

function firstError(issues: { path: PropertyKey[]; message: string }[]): string {
  const issue = issues[0];
  return MESSAGES[issue.message] ?? `${issue.path.join(".")}: ${issue.message}`;
}

export async function createAdAction(_state: string | null, formData: FormData): Promise<string | null> {
  await requireAdmin();
  const parsed = readForm(formData);
  if (!parsed.success) return firstError(parsed.error.issues);

  const record = await createAd(parsed.data);
  revalidateAds(record.id);
  redirect(`/admin/werbung/${record.id}`);
}

export async function saveAdAction(_state: string | null, formData: FormData): Promise<string | null> {
  await requireAdmin();
  const id = String(formData.get("id") ?? "");
  const parsed = readForm(formData);
  if (!parsed.success) return firstError(parsed.error.issues);

  await updateAd(id, parsed.data);
  revalidateAds(id);
  return "Gespeichert.";
}

export async function switchAdStatus(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = String(formData.get("id") ?? "");
  const status = adStatus.safeParse(String(formData.get("status") ?? ""));
  if (!status.success) return;

  await setAdStatus(id, status.data);
  revalidateAds(id);
}

export async function removeAd(formData: FormData): Promise<void> {
  await requireAdmin();
  await deleteAd(String(formData.get("id") ?? ""));
  revalidateAds();
  redirect("/admin/werbung");
}
