import QRCode from "qrcode";
import { getCourse } from "@/lib/courses";
import { PLAY_URL } from "@/i18n/routes";

/**
 * QR-Code zum Aushängen am Platz – bewusst hier und nicht in der App.
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
 * `/qr/<slug>` liefert SVG (verlustfrei skalierbar, ideal für den Druck),
 * `/qr/<slug>?format=png` ein Rasterbild für Programme, die kein SVG mögen.
 */
export async function GET(request: Request, ctx: RouteContext<"/qr/[slug]">) {
  const { slug } = await ctx.params;
  const course = await getCourse(slug);

  if (!course || course.status !== "approved") {
    return Response.json({ error: "not_found" }, { status: 404 });
  }

  const target = `${PLAY_URL}/p/${course.slug}`;
  const wantsPng = new URL(request.url).searchParams.get("format") === "png";
  // Fehlerkorrektur M: verkraftet Kratzer und Regentropfen auf dem Aushang,
  // ohne das Muster unnötig dicht zu machen.
  const options = { errorCorrectionLevel: "M", margin: 2 } as const;

  const cacheHeaders = {
    "Cache-Control": "public, max-age=3600, s-maxage=86400, stale-while-revalidate=604800",
  };

  if (wantsPng) {
    const png = await QRCode.toBuffer(target, { ...options, type: "png", width: 1024 });
    return new Response(new Uint8Array(png), {
      headers: {
        ...cacheHeaders,
        "Content-Type": "image/png",
        "Content-Disposition": `attachment; filename="golftrack-${course.slug}.png"`,
      },
    });
  }

  const svg = await QRCode.toString(target, { ...options, type: "svg" });
  return new Response(svg, {
    headers: {
      ...cacheHeaders,
      "Content-Type": "image/svg+xml; charset=utf-8",
      "Content-Disposition": `attachment; filename="golftrack-${course.slug}.svg"`,
    },
  });
}
