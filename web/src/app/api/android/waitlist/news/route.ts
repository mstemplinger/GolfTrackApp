import { grantMarketing } from "@/lib/waitlist";

/**
 * „Ja, Neuigkeiten erhalten“ aus der Bestätigungsmail.
 *
 * Der Link aus der Mail (GET) zeigt nur eine Seite mit Knopf; erst der Klick
 * darauf (POST) erteilt die Einwilligung. Sonst würden Virenscanner, die Links
 * in Mails vorab aufrufen, die Einwilligung ungefragt erteilen.
 */

function page(body: string): Response {
  return new Response(
    `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>GolfTrack</title>
<body style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;background:#0e2718;color:#f2ede3;display:grid;place-items:center;min-height:100vh;margin:0;padding:24px;text-align:center">
<div style="max-width:420px"><img src="/logo.png" width="56" height="56" alt="" style="border-radius:14px"><div style="font-weight:800;font-size:22px;margin:12px 0 20px">Golf<span style="color:#c9a035">Track</span></div>${body}
<p style="margin-top:28px"><a style="color:#9fb3a6" href="/">golftrack.app</a></p></div></body>`,
    { headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" } },
  );
}

const esc = (s: string) => s.replace(/[^A-Za-z0-9_-]/g, "");

export async function GET(request: Request) {
  const token = esc(new URL(request.url).searchParams.get("token") ?? "");
  return page(`<p style="line-height:1.55">Neue Funktionen und Aktionen von GolfTrack per Mail – höchstens einmal im Monat, jederzeit abbestellbar.<br><span style="color:#9fb3a6">News, new features and offers from GolfTrack by email – at most once a month, unsubscribe any time.</span></p>
<form method="post" action="/api/android/waitlist/news?token=${token}">
<button style="margin-top:12px;background:#c9a035;color:#0e2718;border:0;border-radius:999px;padding:14px 26px;font-weight:700;font-size:16px;cursor:pointer">Ja, Neuigkeiten erhalten · Yes, send me news</button></form>`);
}

export async function POST(request: Request) {
  const token = new URL(request.url).searchParams.get("token") ?? "";
  const ok = token.length > 10 && (await grantMarketing(token));
  return page(
    ok
      ? `<p style="line-height:1.55;color:#c9a035">Danke! Du bekommst ab jetzt auch Neuigkeiten.<br>Thanks! You'll now also get news.</p>`
      : `<p>Dieser Link ist nicht mehr gültig. / This link is no longer valid.</p>`,
  );
}
