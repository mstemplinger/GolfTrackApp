/**
 * Universal Links und App Clip für die Minigolf-QR-Codes.
 * Muss ohne Dateiendung und als `application/json` ausgeliefert werden –
 * genau dafür dieser Route Handler.
 */
/**
 * Muss die Team-Kennung sein, mit der die **ausgelieferte** App signiert ist –
 * in Xcode `DEVELOPMENT_TEAM` des Ziels GolfTrackApp, gleichbedeutend mit der
 * Apple-Distribution-Identität im Schlüsselbund. Stimmt sie nicht, prüft iOS
 * den Universal Link stillschweigend als ungültig: der QR-Code öffnet dann nur
 * die Website, weder App noch App Clip.
 *
 * Hier stand bis zum 1.9.2026 CH9C3LJXC8 – eine Kennung, die zu keiner
 * Signatur dieses Kontos gehört. Damit hat der Universal Link nie funktioniert.
 */
const TEAM_ID = process.env.APPLE_TEAM_ID ?? "NY363CML59";
const BUNDLE_ID = process.env.APPLE_BUNDLE_ID ?? "com.TobiasAufschlaeger.GolfTrackandwatch";
const APP_ID = `${TEAM_ID}.${BUNDLE_ID}`;

export const dynamic = "force-static";

export async function GET() {
  const body = {
    applinks: {
      details: [
        {
          appIDs: [APP_ID],
          components: [
            { "/": "/minigolf/*", comment: "Startet eine Minigolfrunde an dieser Anlage" },
          ],
        },
      ],
    },
    appclips: {
      apps: [`${APP_ID}.Clip`],
    },
  };

  return new Response(JSON.stringify(body, null, 2), {
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "public, max-age=3600",
    },
  });
}
