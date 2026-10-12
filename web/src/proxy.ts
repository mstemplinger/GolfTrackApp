import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { COOKIE, validSession } from "@/lib/auth";
import { launched } from "@/lib/launch";

/**
 * Zwei Aufgaben vor jeder Seite.
 *
 * 1. Die Subdomain `play.golftrack.app` läuft auf derselben Anwendung wie
 *    golftrack.app – nur ihre Wurzel zeigt etwas anderes. Der Normalfall ist
 *    der QR-Code am Abschlag, der direkt auf `/p/<kennung>` führt. Wer nur
 *    `play.golftrack.app` eintippt, soll seinen Platz auswählen können, nicht
 *    auf der Marketingseite landen. Deshalb wird dort `/` auf `/start`
 *    umgeschrieben.
 *
 * 2. Bis zur Freischaltung (`lib/launch.ts`) zeigen die Marketingseiten den
 *    Zähler. Umgeschrieben, nicht umgeleitet: die Adresse bleibt stehen, und
 *    wenn der Zähler bei null neu lädt, kommt dieselbe Adresse als echte Seite.
 *    Alles, wovon die App, der App Clip oder das App-Store-Review abhängt,
 *    bleibt offen – siehe OPEN. Wer angemeldet ist (Adminpanel oder der
 *    Vorschau-Knopf auf dem Zähler, beide mit dem Adminpasswort), sieht die
 *    Seite schon vorher.
 *
 * Seit Next.js 16 heißt diese Datei `proxy.ts` und nicht mehr `middleware.ts`.
 */

const PLAY_HOSTS = new Set(["play.golftrack.app", "play.localhost"]);

/** Pfade, die auch vor der Freischaltung antworten müssen. */
const OPEN = [
  "/bald", // der Zähler selbst und sein Kurzimpressum
  "/en/soon",
  "/admin",
  "/p/", // QR-Code am Abschlag
  "/start",
  "/minigolf/", // Universal Links und App Clip
  "/golf/",
  "/datenschutz", // Datenschutz- und Support-Adresse im App Store
  "/en/privacy",
  "/support",
  "/en/support",
];

function isOpen(pathname: string): boolean {
  return OPEN.some((p) => pathname === p || pathname.startsWith(p.endsWith("/") ? p : `${p}/`));
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const host = request.headers.get("host")?.split(":")[0]?.toLowerCase() ?? "";

  if (pathname === "/" && PLAY_HOSTS.has(host)) {
    return NextResponse.rewrite(new URL("/start", request.url));
  }

  if (launched() || isOpen(pathname) || (await validSession(request.cookies.get(COOKIE)?.value))) {
    return NextResponse.next();
  }

  // Das ausführliche Impressum wartet mit, an seiner Adresse steht solange das kurze.
  if (pathname === "/impressum" || pathname === "/en/legal-notice") {
    return NextResponse.rewrite(new URL("/bald/impressum", request.url));
  }

  const english = pathname === "/en" || pathname.startsWith("/en/");
  const response = NextResponse.rewrite(new URL(english ? "/en/soon" : "/bald", request.url));
  response.headers.set("Cache-Control", "no-store");
  return response;
}

export const config = {
  // Nur Seiten: API, QR-Codes, apple-app-site-association und Dateien mit
  // Endung (Bilder, robots.txt, sitemap.xml) laufen hier gar nicht durch.
  matcher: ["/((?!_next/|api/|qr/|\\.well-known/|.*\\.[a-z0-9]+$).*)"],
};
