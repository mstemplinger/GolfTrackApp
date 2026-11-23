"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import {
  createOperator,
  deleteOperator,
  generatePassword,
  operatorInputSchema,
  resetOperatorPassword,
  updateOperator,
} from "@/lib/operators";

/**
 * Aktionen für Betreiberkonten. Das Passwort entsteht hier zufällig und geht
 * genau einmal an das Formular zurück – gespeichert wird nur der Hash.
 */

export interface SaveState {
  status: "idle" | "ok" | "error";
  id?: string;
  /** Nur direkt nach dem Anlegen bzw. Zurücksetzen gesetzt. */
  password?: string;
  email?: string;
  message?: string;
}

async function requireAdmin(): Promise<void> {
  if (!(await isAuthenticated())) throw new Error("not_authenticated");
}

function readInput(formData: FormData) {
  return operatorInputSchema.safeParse({
    name: formData.get("name") ?? "",
    email: formData.get("email") ?? "",
    notes: formData.get("notes") ?? "",
    permissions: formData.getAll("permissions").map(String),
    courses: formData.getAll("courses").map(String),
    active: formData.get("active") === "on",
  });
}

const MESSAGES: Record<string, string> = {
  name_required: "Bitte einen Namen eintragen.",
  email_invalid: "Diese E-Mail-Adresse sieht nicht gültig aus.",
};

export async function saveOperator(_prev: SaveState, formData: FormData): Promise<SaveState> {
  await requireAdmin();
  const parsed = readInput(formData);
  if (!parsed.success) {
    const code = parsed.error.issues[0]?.message ?? "";
    return { status: "error", message: MESSAGES[code] ?? "Bitte die Angaben prüfen." };
  }
  const id = String(formData.get("id") ?? "");

  if (id) {
    const result = await updateOperator(id, parsed.data);
    if (result.status === "email_taken") {
      return { status: "error", message: "Diese E-Mail-Adresse hat schon ein anderes Konto." };
    }
    revalidatePath("/admin/betreiber");
    return { status: "ok", id, message: "Gespeichert." };
  }

  const password = generatePassword();
  const result = await createOperator(parsed.data, password);
  if (result.status === "email_taken") {
    return { status: "error", message: "Für diese E-Mail-Adresse gibt es schon ein Konto." };
  }
  revalidatePath("/admin/betreiber");
  return { status: "ok", id: result.id, password, email: parsed.data.email };
}

export async function resetPassword(_prev: SaveState, formData: FormData): Promise<SaveState> {
  await requireAdmin();
  const id = String(formData.get("id") ?? "");
  if (!id) return { status: "error", message: "Konto fehlt." };
  const password = generatePassword();
  await resetOperatorPassword(id, password);
  return { status: "ok", id, password, email: String(formData.get("email") ?? "") };
}

export async function removeOperator(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = String(formData.get("id") ?? "");
  if (id) await deleteOperator(id);
  revalidatePath("/admin/betreiber");
  redirect("/admin/betreiber");
}
