/**
 * Stand der Android-APK unter `public/downloads/`. Wird von
 * `android/release.sh` beim Veröffentlichen neu geschrieben – nicht von Hand
 * pflegen. Die APK selbst liegt nicht im Repository (öffentlich), sie kommt
 * über `deploy/deploy.sh` mit `public/` auf den Server.
 *
 * `file: null` = noch keine APK veröffentlicht; die Seite zeigt dann einen
 * Hinweis statt des Knopfs.
 */
export const ANDROID_RELEASE: {
  file: string | null;
  versionName: string;
  versionCode: number;
  sizeBytes: number;
  sha256: string;
  releasedAt: string;
} = {
  file: "golftrack-1.0.apk",
  versionName: "1.0",
  versionCode: 1,
  sizeBytes: 22598649,
  sha256: "7bf0daf68dcceec540888878f9da85f5e7852d849dc0b9f89a58958a9264e28a",
  releasedAt: "2026-10-20T13:13:30Z",
};

/**
 * Eintrag im Google Play Store – schon vorbereitet, die App steht dort aber
 * noch nicht. Solange `PLAY_STORE_LIVE` false ist, zeigt die Website „bald bei
 * Google Play“ mit Erinnerungsknopf statt des Links. Nach der Freigabe auf true
 * setzen, deployen und `POST /api/admin/android-notify` aufrufen.
 */
export const PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=app.golftrack";
export const PLAY_STORE_LIVE = false;

/** Direkter Link auf die aktuelle APK, oder null, solange keine veröffentlicht ist. */
export const APK_URL: string | null = ANDROID_RELEASE.file ? `/downloads/${ANDROID_RELEASE.file}` : null;
