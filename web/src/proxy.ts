import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { COOKIE, validSession } from "@/lib/auth";
import { launched } from "@/lib/launch";
import { OPERATOR_HOSTS, operatorPortalUrl } from "@/lib/operatorPortal";

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
  "/werbung/", // Ziel der Anzeigen in der App (nur mit Kennung, nicht /werbung selbst)
  "/en/ad/",
  "/datenschutz", // Datenschutz- und Support-Adresse im App Store
  "/en/privacy",
  "/support",
  "/en/support",
  "/android", // APK-Download, verlinkt vom Zähler
  "/en/android",
  "/laden", // Weiche App Store / APK, verlinkt von den Anlagenseiten
  "/download", // dieselbe Weiche, Ziel des QR-Codes auf den Druckplakaten
  "/lobby/", // QR-Code der gemeinsamen Runde (Universal Link in die App)
  "/einladen/", // Einladungslink der Weiterempfehlung (Universal Link in die App)
];

function isOpen(pathname: string): boolean {
  return OPEN.some((p) => pathname === p || pathname.startsWith(p.endsWith("/") ? p : `${p}/`));
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const host = request.headers.get("host")?.split(":")[0]?.toLowerCase() ?? "";

  // Betreiber-Portal: auf der Subdomain liegt jede Adresse unter /operator
  // (operator.golftrack.app/login → /operator/login). Der Zähler gilt dort
  // nicht – Betreiber sollen ihre Statistik auch vor der Freischaltung sehen.
  if (OPERATOR_HOSTS.has(host)) {
    if (pathname === "/operator" || pathname.startsWith("/operator/")) return NextResponse.next();
    const target = request.nextUrl.clone();
    target.pathname = `/operator${pathname === "/" ? "" : pathname}`;
    return NextResponse.rewrite(target);
  }
  // Auf der Hauptdomain gibt es das Portal nicht – weiter zur Subdomain, damit
  // Anmeldung und Cookie dort bleiben. /betreiber war der erste Name.
  for (const prefix of ["/operator", "/betreiber"]) {
    if (pathname === prefix || pathname.startsWith(`${prefix}/`)) {
      const rest = pathname.slice(prefix.length) || "/";
      return NextResponse.redirect(`${operatorPortalUrl()}${rest}${request.nextUrl.search}`);
    }
  }

  if (pathname === "/" && PLAY_HOSTS.has(host)) {
    // Die Suche mitnehmen, sonst geht ein `?lang=` vom Aushang verloren.
    const target = request.nextUrl.clone();
    target.pathname = "/start";
    return NextResponse.rewrite(target);
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
