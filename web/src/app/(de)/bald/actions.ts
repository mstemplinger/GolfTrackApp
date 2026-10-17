"use server";

import { redirect } from "next/navigation";
import { attemptLogin, createSession } from "@/lib/auth";

/**
 * Vorschau vor der Freischaltung: dasselbe Passwort und dieselbe Sitzung wie
 * im Adminpanel. Der Proxy lässt angemeldete Besucher durch.
 */
export async function preview(_state: string | null, formData: FormData): Promise<string | null> {
  const password = String(formData.get("password") ?? "");
  const lang = formData.get("lang") === "en" ? "en" : "de";
  const result = await attemptLogin(password);
  if (result === "locked") {
    return lang === "de"
      ? "Zu viele Fehlversuche. Bitte in 15 Minuten erneut versuchen."
      : "Too many failed attempts. Please try again in 15 minutes.";
  }
  if (result === "wrong") return lang === "de" ? "Passwort stimmt nicht." : "Wrong password.";
  await createSession();
  redirect(lang === "de" ? "/" : "/en");
}
