"use server";

import { redirect } from "next/navigation";
import { createSession, passwordMatches } from "@/lib/auth";

/**
 * Vorschau vor der Freischaltung: dasselbe Passwort und dieselbe Sitzung wie
 * im Adminpanel. Der Proxy lässt angemeldete Besucher durch.
 */
export async function preview(_state: string | null, formData: FormData): Promise<string | null> {
  const password = String(formData.get("password") ?? "");
  const lang = formData.get("lang") === "en" ? "en" : "de";
  if (!passwordMatches(password)) return lang === "de" ? "Passwort stimmt nicht." : "Wrong password.";
  await createSession();
  redirect(lang === "de" ? "/" : "/en");
}
