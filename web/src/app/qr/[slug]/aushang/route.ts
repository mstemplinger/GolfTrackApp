import { readFile } from "node:fs/promises";
import path from "node:path";
import QRCode from "qrcode";
import { getCourse } from "@/lib/courses";
import { PLAY_URL } from "@/i18n/routes";
import { aushangHtml, spracheAusListe, vorauswahl } from "@/lib/aushang";

/**
 * Der mehrsprachige Gäste-Aushang als PDF.
 *
 * `/qr/<kennung>/aushang?sprache=de&sprache=it` – die Sprachen kommen aus dem
 * Formular im Katalog. Ohne Angabe gilt die Landessprache plus Deutsch und
 * Englisch. Eine Sprache ergibt ein Hochformat, mehrere Querblätter (siehe
 * `lib/aushang.ts`).
 *
 * Gedruckt wird mit Headless-Chrome. Fehlt der auf dem Server, kommt dasselbe
 * Blatt als HTML mit Druckknopf – „Als PDF speichern“ im Druckdialog liefert
 * dann das gleiche Ergebnis.
 */
export async function GET(request: Request, ctx: RouteContext<"/qr/[slug]/aushang">) {
  const { slug } = await ctx.params;
  const course = await getCourse(slug);
  if (!course || course.status !== "approved") {
    return Response.json({ error: "not_found" }, { status: 404 });
  }

  const params = new URL(request.url).searchParams;
  const gewaehlt = spracheAusListe(params.getAll("sprache"));
  const sprachen = gewaehlt.length ? gewaehlt : vorauswahl(course.country);

  const link = `${PLAY_URL}/p/${course.slug}`;
  const qrDataUrl = await QRCode.toDataURL(link, {
    errorCorrectionLevel: "M",
    margin: 1,
    width: 900,
    color: { dark: "#10220D", light: "#FFFFFF" },
  });

  const daten = {
    name: course.name,
    ort: course.location,
    bahnen: course.holes,
    art: course.kind === "golf" ? ("golf" as const) : ("minigolf" as const),
    link,
    qrDataUrl,
    logoDataUrl: await logoDataUrl(),
    sprachen,
  };

  const datei = `GolfTrack-Aushang-${course.slug}-${sprachen.join("-").toUpperCase()}`;

  try {
    const pdf = await alsPdf(aushangHtml(daten));
    return new Response(new Uint8Array(pdf), {
      headers: {
        "Content-Type": "application/pdf",
        "Content-Disposition": `attachment; filename="${datei}.pdf"`,
        "Cache-Control": "private, max-age=600",
      },
    });
  } catch (fehler) {
    console.error("aushang: PDF fehlgeschlagen, liefere HTML", fehler);
    return new Response(aushangHtml({ ...daten, druckknopf: true }), {
      headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" },
    });
  }
}

async function alsPdf(html: string): Promise<Uint8Array> {
  // Erst hier laden: Chrome startet nur, wenn wirklich jemand druckt.
  const { default: puppeteer } = await import("puppeteer");
  const browser = await puppeteer.launch({
    // Läuft auf dem Server als root; ohne diese Schalter verweigert Chrome den Start.
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"],
  });
  try {
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: "load" });
    // Seitenmaße kommen aus @page im Dokument.
    return await page.pdf({ printBackground: true, preferCSSPageSize: true });
  } finally {
    await browser.close();
  }
}

async function logoDataUrl(): Promise<string | null> {
  try {
    const bytes = await readFile(path.join(process.cwd(), "public", "logo.png"));
    return `data:image/png;base64,${bytes.toString("base64")}`;
  } catch {
    return null;
  }
}
