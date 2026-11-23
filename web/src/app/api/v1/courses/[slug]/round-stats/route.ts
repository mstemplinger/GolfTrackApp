import { roundStatsSchema, submitRoundStats } from "@/lib/roundStats";

/**
 * Anonyme Rundenstatistik eines Platzes: App, App Clip und Browser-Scorekarte
 * schicken nach einer Runde eine grobe Zusammenfassung – nur mit Einwilligung
 * des Spielers.
 *
 * Gespeichert wird keine Kennung und keine Netzadresse. Die Bremse unten
 * zählt je Adresse nur im Speicher und vergisst nach einer Stunde; nginx
 * schreibt für diesen Pfad kein Zugriffsprotokoll (deploy/nginx-golftrack.conf).
 */

const WINDOW_MS = 60 * 60_000;
const MAX_PER_ADDRESS = 20;
const MAX_PER_ADDRESS_AND_COURSE = 6;
const counters = new Map<string, { count: number; resetAt: number }>();

function allowed(key: string, max: number): boolean {
  const now = Date.now();
  const entry = counters.get(key);
  if (!entry || entry.resetAt < now) {
    counters.set(key, { count: 1, resetAt: now + WINDOW_MS });
    if (counters.size > 5000) {
      for (const [k, v] of counters) if (v.resetAt < now) counters.delete(k);
    }
    return true;
  }
  entry.count += 1;
  return entry.count <= max;
}

export async function POST(request: Request, ctx: RouteContext<"/api/v1/courses/[slug]/round-stats">) {
  const { slug } = await ctx.params;
  const address = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "local";
  const perAddress = allowed(address, MAX_PER_ADDRESS);
  const perCourse = allowed(`${address}|${slug}`, MAX_PER_ADDRESS_AND_COURSE);
  if (!perAddress || !perCourse) {
    return Response.json({ error: "rate_limited" }, { status: 429, headers: { "Retry-After": "3600" } });
  }

  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }
  const parsed = roundStatsSchema.safeParse(payload);
  if (!parsed.success) {
    return Response.json({ error: "invalid_body" }, { status: 400 });
  }

  const result = await submitRoundStats(slug, parsed.data);
  const noStore = { "Cache-Control": "no-store" };
  switch (result.status) {
    case "unknown_course":
      return Response.json({ error: "not_found" }, { status: 404, headers: noStore });
    case "rejected":
      return Response.json({ error: result.reason }, { status: 422, headers: noStore });
    case "ok":
      return Response.json({ accepted: true }, { headers: noStore });
  }
}
