import { unsubscribe } from "@/lib/waitlist";

/** Abmeldelink aus jeder Mail – löscht die Adresse sofort. */
export async function GET(request: Request) {
  const token = new URL(request.url).searchParams.get("token") ?? "";
  const done = token.length > 10 && (await unsubscribe(token));
  const text = done
    ? "Erledigt – deine Adresse ist gelöscht. / Done – your address has been deleted."
    : "Dieser Link ist nicht mehr gültig. / This link is no longer valid.";
  return new Response(
    `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>GolfTrack</title><body style="font-family:system-ui;background:#0e2718;color:#f3ead7;display:grid;place-items:center;min-height:100vh;margin:0;padding:24px;text-align:center"><p>${text}</p><p><a style="color:#c9a035" href="/">golftrack.app</a></p></body>`,
    { headers: { "content-type": "text/html; charset=utf-8" } },
  );
}
