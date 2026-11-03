import { apiTokenConfigured, apiTokenMatches } from "@/lib/auth";
import { notifyPrivacyUpdate } from "@/lib/waitlist";

/**
 * Info-Mail „Datenschutzerklärung aktualisiert“ an alle bestätigten Adressen.
 * Bewusst ohne Bitte um Einwilligung – die wäre selbst schon Werbung.
 * Anmeldung: `Authorization: Bearer <ADMIN_API_TOKEN>`.
 */

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  if (!apiTokenConfigured()) return Response.json({ error: "not_configured" }, { status: 503 });
  if (!apiTokenMatches(request.headers.get("authorization"))) {
    return Response.json({ error: "unauthorized" }, { status: 401 });
  }
  return Response.json(await notifyPrivacyUpdate());
}
