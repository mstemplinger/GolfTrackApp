/**
 * Universal Links und App Clip für die Minigolf-QR-Codes.
 * Muss ohne Dateiendung und als `application/json` ausgeliefert werden –
 * genau dafür dieser Route Handler.
 */
const TEAM_ID = process.env.APPLE_TEAM_ID ?? "CH9C3LJXC8";
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
