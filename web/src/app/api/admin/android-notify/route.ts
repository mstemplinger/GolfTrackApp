import { apiTokenConfigured, apiTokenMatches } from "@/lib/auth";
import { notifyAll, waitlistStats } from "@/lib/waitlist";

/**
 * Play-Store-Erinnerung verschicken. `GET` zeigt nur die Zahlen, `POST`
 * schickt allen bestätigten Adressen die Mail und löscht sie danach.
 * Anmeldung wie bei `/api/admin/queue`: `Authorization: Bearer <ADMIN_API_TOKEN>`.
 */

export const dynamic = "force-dynamic";

function guard(request: Request): Response | null {
  if (!apiTokenConfigured()) return Response.json({ error: "not_configured" }, { status: 503 });
  if (!apiTokenMatches(request.headers.get("authorization"))) {
    return Response.json({ error: "unauthorized" }, { status: 401 });
  }
  return null;
}

export async function GET(request: Request) {
  return guard(request) ?? Response.json(await waitlistStats());
}

export async function POST(request: Request) {
  return guard(request) ?? Response.json(await notifyAll());
}
