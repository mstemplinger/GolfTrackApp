import { geometryUploadSchema, submitGeometry } from "@/lib/courseGeometry";

/**
 * Crowd-Positionen eines Platzes: die App schickt nach einer Runde die daraus
 * abgeleiteten Abschlag- und Grünpunkte (nur mit Einwilligung des Spielers).
 *
 * Gespeichert wird keine Kennung und keine Netzadresse. Die Bremse unten
 * zählt je Adresse nur im Speicher und vergisst nach einer Stunde; nginx
 * schreibt für diesen Pfad kein Zugriffsprotokoll (deploy/nginx-golftrack.conf).
 */

const WINDOW_MS = 60 * 60_000;
const MAX_PER_ADDRESS = 12;
const MAX_PER_ADDRESS_AND_COURSE = 3;
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

export async function POST(request: Request, ctx: RouteContext<"/api/v1/courses/[slug]/geometry">) {
  const { slug } = await ctx.params;
  const address = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "local";
  // Beide Zähler erhöhen, auch wenn der erste schon greift.
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
  const parsed = geometryUploadSchema.safeParse(payload);
  if (!parsed.success) {
    return Response.json({ error: "invalid_body" }, { status: 400 });
  }

  const result = await submitGeometry(slug, parsed.data);
  const noStore = { "Cache-Control": "no-store" };
  switch (result.status) {
    case "unknown_course":
      return Response.json({ error: "not_found" }, { status: 404, headers: noStore });
    case "rejected":
      return Response.json({ error: result.reason }, { status: 422, headers: noStore });
    case "ok":
      return Response.json({ accepted: result.accepted, applied: result.applied }, { headers: noStore });
  }
}
