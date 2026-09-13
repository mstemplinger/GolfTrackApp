import { readFile } from "node:fs/promises";
import path from "node:path";
import QRCode from "qrcode";
import { getCourse } from "@/lib/courses";
import { PLAY_URL } from "@/i18n/routes";

/**
 * Der Aushang für den Abschlag – ein fertiges DIN-A4-Blatt zum Ausdrucken.
 *
 * Codiert wird die Kurzform `play.golftrack.app/p/<kennung>`: Mit installierter
 * App fängt iOS sie ab und die Runde startet sofort, ohne App startet der
 * App Clip, und ganz ohne beides steht dort die Zählkarte im Browser.
 *
 * Warum die kurze Form und nicht `golftrack.app/<art>/<kennung>`: weniger
 * Zeichen heißt ein gröberes Muster, das vom Schild am Abschlag auch aus zwei
 * Metern liest – und ein einziger Eintrag als Advanced App Clip Experience
 * deckt über den Präfix-Vergleich alle Plätze ab.
 *
 * - `/qr/<kennung>` liefert das A4-Blatt als SVG. Drucken: Datei öffnen,
 *   „Tatsächliche Größe" wählen, fertig – die Maße stehen in Millimetern im
 *   Dokument.
 * - `?format=code` nur das Muster als SVG, für eigene Gestaltung.
 * - `?format=png` nur das Muster als 1024er Rasterbild, für Programme ohne
 *   SVG-Unterstützung.
 */

/** DIN A4 hochkant in Millimetern. */
const A4 = { w: 210, h: 297 };

/** Farben wie in der App. */
const GRUEN = "#0E2718";
const KARTE = "#163421";
const GOLD = "#C9A035";
const CREME = "#F2EDE3";

export async function GET(request: Request, ctx: RouteContext<"/qr/[slug]">) {
  const { slug } = await ctx.params;
  const course = await getCourse(slug);

  if (!course || course.status !== "approved") {
    return Response.json({ error: "not_found" }, { status: 404 });
  }

  const target = `${PLAY_URL}/p/${course.slug}`;
  const format = new URL(request.url).searchParams.get("format");
  // Fehlerkorrektur M: verkraftet Kratzer und Regentropfen auf dem Aushang,
  // ohne das Muster unnötig dicht zu machen.
  const options = { errorCorrectionLevel: "M", margin: 2 } as const;

  const cacheHeaders = {
    "Cache-Control": "public, max-age=3600, s-maxage=86400, stale-while-revalidate=604800",
  };

  if (format === "png") {
    const png = await QRCode.toBuffer(target, { ...options, type: "png", width: 1024 });
    return new Response(new Uint8Array(png), {
      headers: {
        ...cacheHeaders,
        "Content-Type": "image/png",
        "Content-Disposition": `attachment; filename="golftrack-${course.slug}.png"`,
      },
    });
  }

  const codeSvg = await QRCode.toString(target, { ...options, type: "svg" });

  if (format === "code") {
    return new Response(codeSvg, {
      headers: {
        ...cacheHeaders,
        "Content-Type": "image/svg+xml; charset=utf-8",
        "Content-Disposition": `attachment; filename="golftrack-${course.slug}.svg"`,
      },
    });
  }

  const blatt = await aushang({
    codeSvg,
    name: course.name,
    ort: course.location,
    art: course.kind === "golf" ? "Golfplatz" : "Minigolf",
    adresse: target.replace(/^https:\/\//, ""),
  });

  return new Response(blatt, {
    headers: {
      ...cacheHeaders,
      "Content-Type": "image/svg+xml; charset=utf-8",
      "Content-Disposition": `attachment; filename="golftrack-aushang-${course.slug}.svg"`,
    },
  });
}

/** Das Markenzeichen als Data-URI, damit das Blatt eine einzige Datei bleibt. */
async function logoDataUri(): Promise<string | null> {
  try {
    const datei = path.join(process.cwd(), "public", "logo.png");
    const bytes = await readFile(datei);
    return `data:image/png;base64,${bytes.toString("base64")}`;
  } catch {
    // Ohne Zeichen ist das Blatt immer noch brauchbar.
    return null;
  }
}

/** Nutzbare Textbreite auf dem Blatt: 210 mm minus je 30 mm Rand. */
const TEXTBREITE = A4.w - 60;

/**
 * Zeichenbreiten als Anteil der Schriftgröße: Helvetica fett liegt bei etwa
 * 0,58, Menlo als Schreibmaschinenschrift bei 0,6. Das reicht, um zu
 * entscheiden, ob eine Zeile passt – gesetzt wird ohnehin vom Zeichenprogramm.
 */
const FETT = 0.58;
const SCHREIBMASCHINE = 0.6;

/**
 * Bricht eine Zeile an Wortgrenzen um. SVG kann das nicht selbst, und ein
 * Platzname wie „Golfclub am Nationalpark Bayerischer Wald" passt sonst nicht
 * auf die Seite.
 */
function umbrechen(text: string, maxZeichen: number, maxZeilen: number): string[] {
  const woerter = text.split(/\s+/);
  const zeilen: string[] = [];
  let aktuell = "";

  for (const wort of woerter) {
    const versuch = aktuell ? `${aktuell} ${wort}` : wort;
    if (versuch.length <= maxZeichen || !aktuell) {
      aktuell = versuch;
    } else {
      zeilen.push(aktuell);
      aktuell = wort;
    }
    if (zeilen.length === maxZeilen) break;
  }
  if (zeilen.length < maxZeilen && aktuell) zeilen.push(aktuell);

  // Rest abschneiden, aber sichtbar machen.
  const zusammen = zeilen.join(" ");
  if (zusammen.length < text.length && zeilen.length) {
    zeilen[zeilen.length - 1] = `${zeilen[zeilen.length - 1]}…`;
  }
  return zeilen;
}

function xmlEscape(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

async function aushang(daten: {
  codeSvg: string;
  name: string;
  ort: string;
  art: string;
  adresse: string;
}): Promise<string> {
  const logo = await logoDataUri();

  // Das erzeugte Muster ist ein eigenständiges <svg> mit eigener viewBox.
  // Für das Blatt wird es als verschachteltes <svg> eingesetzt – so bleibt es
  // eine Datei, ohne Bild-Verweis nach außen.
  const raster = Number(daten.codeSvg.match(/viewBox="0 0 (\d+)/)?.[1] ?? 33);
  const codeInhalt = daten.codeSvg
    .replace(/^[\s\S]*?<svg[^>]*>/, "")
    .replace(/<\/svg>\s*$/, "");

  // Der Name schrumpft, bis er vollständig auf die Seite passt: erst zwei
  // Zeilen in großer Schrift, notfalls drei in kleiner. Abgeschnitten wird
  // erst, wenn selbst das nicht reicht – ein halber Platzname auf dem Aushang
  // wäre das Schlechteste.
  const stufen: { groesse: number; zeilen: number }[] = [
    { groesse: 16, zeilen: 1 },
    { groesse: 16, zeilen: 2 },
    { groesse: 13, zeilen: 2 },
    { groesse: 13, zeilen: 3 },
    { groesse: 11, zeilen: 3 },
  ];
  let nameGroesse = 11;
  let nameZeilen = umbrechen(daten.name, 40, 3);
  for (const stufe of stufen) {
    const maxZeichen = Math.floor(TEXTBREITE / (stufe.groesse * FETT));
    const versuch = umbrechen(daten.name, maxZeichen, stufe.zeilen);
    if (!versuch.some((z) => z.endsWith("…"))) {
      nameGroesse = stufe.groesse;
      nameZeilen = versuch;
      break;
    }
  }

  // Senkrechte Aufteilung der 297 mm, von oben nach unten. Die Werte sind so
  // gewählt, dass auch ein zweizeiliger Name nicht in das Musterfeld läuft und
  // unten acht Millimeter Rand bleiben.
  const nameOben = 72;
  const ortUnten = nameOben + nameZeilen.length * (nameGroesse + 2) + 2;

  // Die Adresse schrumpft, bis sie in ihren Kasten passt. Bei einer langen
  // Kennung wird sie klein, steht aber vollständig da – abgeschnitten wäre sie
  // zum Abtippen wertlos.
  const adresseGroesse = Math.max(
    3.2,
    Math.min(8, (TEXTBREITE - 8) / (daten.adresse.length * SCHREIBMASCHINE)),
  );

  // Weißes Feld für das Muster: Ein QR-Code muss dunkel auf hell stehen.
  const feld = { size: 130, y: 110 };
  const feldX = (A4.w - feld.size) / 2;
  const feldUnten = feld.y + feld.size;
  const rand = 10;

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
     width="${A4.w}mm" height="${A4.h}mm" viewBox="0 0 ${A4.w} ${A4.h}">
  <title>${xmlEscape(daten.name)} · Runde mitzählen mit GolfTrack</title>
  <rect width="${A4.w}" height="${A4.h}" fill="${GRUEN}"/>

  <!-- Kopf: Zeichen und Wortmarke -->
  ${logo ? `<image x="30" y="24" width="18" height="18" href="${logo}" xlink:href="${logo}"/>` : ""}
  <text x="${logo ? 54 : 30}" y="37.5" font-family="Helvetica, Arial, sans-serif"
        font-size="13" font-weight="700" fill="${CREME}">Golf<tspan fill="${GOLD}">Track</tspan></text>

  <!-- Platz -->
  <text x="30" y="58" font-family="Helvetica, Arial, sans-serif" font-size="6"
        letter-spacing="1.6" fill="${GOLD}">${xmlEscape(daten.art.toUpperCase())}</text>
  ${nameZeilen
    .map(
      (zeile, i) =>
        `<text x="30" y="${nameOben + i * (nameGroesse + 2)}" font-family="Helvetica, Arial, sans-serif"
        font-size="${nameGroesse}" font-weight="700" fill="${CREME}">${xmlEscape(zeile)}</text>`,
    )
    .join("\n  ")}
  ${
    daten.ort
      ? `<text x="30" y="${ortUnten}"
        font-family="Helvetica, Arial, sans-serif" font-size="7"
        fill="${CREME}" fill-opacity="0.6">${xmlEscape(daten.ort)}</text>`
      : ""
  }

  <!-- Das Muster auf hellem Grund -->
  <rect x="${feldX}" y="${feld.y}" width="${feld.size}" height="${feld.size}" rx="6" fill="#FFFFFF"/>
  <svg x="${feldX + rand}" y="${feld.y + rand}" width="${feld.size - rand * 2}"
       height="${feld.size - rand * 2}" viewBox="0 0 ${raster} ${raster}"
       shape-rendering="crispEdges">${codeInhalt}</svg>

  <!-- Anleitung -->
  <text x="${A4.w / 2}" y="${feldUnten + 16}" text-anchor="middle"
        font-family="Helvetica, Arial, sans-serif" font-size="9" font-weight="700"
        fill="${CREME}">Code scannen und Runde mitzählen</text>
  <text x="${A4.w / 2}" y="${feldUnten + 25}" text-anchor="middle"
        font-family="Helvetica, Arial, sans-serif" font-size="6"
        fill="${CREME}" fill-opacity="0.6">Mit der App, ohne Installation oder direkt im Browser</text>

  <!-- Adresse zum Abtippen, falls die Kamera streikt -->
  <rect x="30" y="${feldUnten + 34}" width="${A4.w - 60}" height="15" rx="4" fill="${KARTE}"/>
  <text x="${A4.w / 2}" y="${feldUnten + 44}" text-anchor="middle"
        font-family="Menlo, Consolas, monospace" font-size="${adresseGroesse.toFixed(1)}"
        fill="${CREME}" fill-opacity="0.85">${xmlEscape(daten.adresse)}</text>
</svg>
`;
}
