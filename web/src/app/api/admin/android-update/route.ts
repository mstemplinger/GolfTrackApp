import { z } from "zod";
import { apiTokenConfigured, apiTokenMatches } from "@/lib/auth";
import { notifyApkUpdate } from "@/lib/waitlist";

/**
 * Update-Mail zur aktuell veröffentlichten APK (`lib/android.ts`) an alle
 * Eingetragenen. Jede Fassung geht je Adresse nur einmal raus.
 * Aufruf nach dem Deploy über `android/notify-update.sh`.
 * Body optional: `{ "notes": ["Neu: …", "Behoben: …"] }`.
 */

export const dynamic = "force-dynamic";

const schema = z.object({ notes: z.array(z.string().max(300)).max(10).default([]) });

export async function POST(request: Request) {
  if (!apiTokenConfigured()) return Response.json({ error: "not_configured" }, { status: 503 });
  if (!apiTokenMatches(request.headers.get("authorization"))) {
    return Response.json({ error: "unauthorized" }, { status: 401 });
  }
  const parsed = schema.safeParse(await request.json().catch(() => ({})));
  if (!parsed.success) return Response.json({ error: "invalid" }, { status: 422 });
  return Response.json(await notifyApkUpdate(parsed.data.notes));
}
