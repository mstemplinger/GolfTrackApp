"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import { getCourse } from "@/lib/courses";
import { sendOperatorMails, type MailResult } from "@/lib/operatorMail";
import {
  createOperator,
  deleteOperator,
  generatePassword,
  getOperator,
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
  /** Ergebnis des Mailversands – nur, wenn „per E-Mail senden“ angehakt war. */
  mail?: MailResult;
}

/** Beide Zugangsmails an ein Konto – mit den Namen seiner Plätze. */
async function mailAccount(id: string, password: string, kind: "created" | "reset"): Promise<MailResult> {
  const op = await getOperator(id);
  if (!op) return "failed";
  const courses = (await Promise.all(op.courses.map((slug) => getCourse(slug))))
    .map((c) => c?.name)
    .filter((n): n is string => Boolean(n));
  return sendOperatorMails({ name: op.name, email: op.email, lang: op.lang, courses }, password, kind);
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
    lang: formData.get("lang") === "en" ? "en" : "de",
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
  const mail = formData.get("sendMail") === "on" ? await mailAccount(result.id, password, "created") : undefined;
  return { status: "ok", id: result.id, password, email: parsed.data.email, mail };
}

export async function resetPassword(_prev: SaveState, formData: FormData): Promise<SaveState> {
  await requireAdmin();
  const id = String(formData.get("id") ?? "");
  if (!id) return { status: "error", message: "Konto fehlt." };
  const password = generatePassword();
  await resetOperatorPassword(id, password);
  const mail = formData.get("sendMail") === "on" ? await mailAccount(id, password, "reset") : undefined;
  return { status: "ok", id, password, email: String(formData.get("email") ?? ""), mail };
}

export async function removeOperator(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = String(formData.get("id") ?? "");
  if (id) await deleteOperator(id);
  revalidatePath("/admin/betreiber");
  redirect("/admin/betreiber");
}
