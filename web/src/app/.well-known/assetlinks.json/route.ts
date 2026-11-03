/**
 * Android App Links: erlaubt der APK, Links auf golftrack.app (/golf/,
 * /minigolf/, /lobby/) direkt zu öffnen statt im Browser.
 *
 * Der Fingerabdruck gehört zum Release-Schlüssel `android/golftrack-release.jks`
 * (`keytool -list -v`). Wird die APK mit einem anderen Schlüssel signiert,
 * prüft Android den Link als ungültig und öffnet nur die Website.
 */
const PACKAGE = "app.golftrack";
const SHA256 =
  "2B:E2:A0:08:A7:D4:43:BA:41:66:0B:90:E2:19:8C:65:36:14:71:F7:81:27:36:65:0D:DA:87:08:25:42:BC:53";

export const dynamic = "force-static";

export async function GET() {
  const body = [
    {
      relation: ["delegate_permission/common.handle_all_urls"],
      target: { namespace: "android_app", package_name: PACKAGE, sha256_cert_fingerprints: [SHA256] },
    },
  ];
  return Response.json(body);
}
