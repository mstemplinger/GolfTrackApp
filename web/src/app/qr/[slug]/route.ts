import QRCode from "qrcode";
import { getCourse } from "@/lib/courses";
import { SITE_URL } from "@/i18n/routes";

/**
 * QR-Code zum Aushängen an der Anlage – bewusst hier und nicht in der App.
 *
 * Codiert wird der Universal Link `…/minigolf/<slug>`: Mit installierter App
 * fängt iOS ihn ab und die Runde startet sofort, ohne App landet der Gast auf
 * der Anlagenseite und findet dort den Weg zum App Store.
 *
 * `/qr/<slug>` liefert SVG (verlustfrei skalierbar, ideal für den Druck),
 * `/qr/<slug>?format=png` ein Rasterbild für Programme, die kein SVG mögen.
 */
export async function GET(request: Request, ctx: RouteContext<"/qr/[slug]">) {
  const { slug } = await ctx.params;
  const course = await getCourse(slug);

  // Nur Minigolfanlagen haben eine Landeseite unter /minigolf/<slug>, auf die
  // der Code zeigen könnte.
  if (!course || course.status !== "approved" || course.kind !== "minigolf") {
    return Response.json({ error: "not_found" }, { status: 404 });
  }

  const target = `${SITE_URL}/minigolf/${course.slug}`;
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
