import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

/**
 * Die Subdomain `play.golftrack.app` läuft auf derselben Anwendung wie
 * golftrack.app – nur ihre Wurzel zeigt etwas anderes.
 *
 * Der Normalfall ist der QR-Code am Abschlag, der direkt auf `/p/<kennung>`
 * führt. Wer stattdessen nur `play.golftrack.app` eintippt – weil der Code
 * verkratzt ist oder jemand die Adresse vom Schild abliest –, soll nicht auf
 * der Marketingseite landen, sondern seinen Platz auswählen können. Deshalb
 * wird die Wurzel dieser Domain auf `/start` umgeschrieben.
 *
 * Alles andere bleibt unangetastet: `/p/<kennung>`, die API und die
 * `apple-app-site-association` müssen auf beiden Namen gleich antworten.
 *
 * Seit Next.js 16 heißt diese Datei `proxy.ts` und nicht mehr `middleware.ts`.
 */

const PLAY_HOSTS = new Set(["play.golftrack.app", "play.localhost"]);

export function proxy(request: NextRequest) {
  const host = request.headers.get("host")?.split(":")[0]?.toLowerCase() ?? "";
  if (request.nextUrl.pathname === "/" && PLAY_HOSTS.has(host)) {
    return NextResponse.rewrite(new URL("/start", request.url));
  }
  return NextResponse.next();
}

export const config = {
  // Nur die Wurzel – jede weitere Route würde hier ohne Grund durchlaufen.
  matcher: "/",
};
