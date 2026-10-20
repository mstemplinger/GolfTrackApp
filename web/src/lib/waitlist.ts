import "server-only";
import { createHash, randomBytes, randomInt, timingSafeEqual } from "node:crypto";
import { query, queryOne } from "@/lib/db";
import { ensureSchema } from "@/lib/migrations";
import { sendMail } from "@/lib/mail";
import { renderEmail } from "@/lib/emailTemplate";
import { SITE_URL, type Lang } from "@/i18n/routes";
import { PLAY_STORE_URL } from "@/lib/android";

/**
 * Erinnerung „Android-App im Play Store“ mit Double-Opt-in per Code.
 *
 * Ablauf: Adresse eintragen → Mail mit sechsstelligem Code → Code eingeben →
 * bestätigt. Nur bestätigte Adressen bekommen später die eine Nachricht, danach
 * wird der Eintrag gelöscht. So kann niemand fremde Adressen eintragen, und Bots
 * kommen ohne Zugriff aufs Postfach nicht weiter.
 */

const CODE_TTL_MIN = 15;
const MAX_CODE_ATTEMPTS = 5;
const MAX_CODES_PER_ADDRESS = 5;

type Row = {
  id: string;
  email: string;
  lang: string;
  code_hash: string | null;
  code_expires_at: Date | null;
  code_attempts: number;
  codes_sent: number;
  confirmed_at: Date | null;
  unsubscribe_token: string;
};

function hashCode(email: string, code: string): string {
  const secret = process.env.ADMIN_SECRET ?? "";
  return createHash("sha256").update(`${email}:${code}:${secret}`).digest("hex");
}

export function normalizeEmail(raw: string): string {
  return raw.trim().toLowerCase();
}

const COPY = {
  de: {
    codeSubject: (code: string) => `${code} ist dein GolfTrack-Bestätigungscode`,
    codeText: (code: string, unsub: string) =>
      `Hallo,\n\ndein Bestätigungscode lautet:\n\n    ${code}\n\nGib ihn auf golftrack.app ein, dann schreiben wir dir einmalig, sobald GolfTrack im Google Play Store verfügbar ist. Der Code gilt ${CODE_TTL_MIN} Minuten.\n\nDu hast das nicht angefordert? Dann ignoriere diese Mail einfach – ohne Code passiert nichts.\nAbmelden: ${unsub}\n\nGolfTrack · golftrack.app`,
    codeHtml: (code: string, unsub: string) => ({
      lang: "de" as const,
      preheader: `Dein Code: ${code} – gültig für ${CODE_TTL_MIN} Minuten.`,
      title: "Bestätige deine E-Mail-Adresse",
      paragraphs: [
        "Schön, dass du GolfTrack auf Android nutzen willst! Gib diesen Code auf golftrack.app ein – dann sagen wir dir Bescheid, sobald die App im Google Play Store verfügbar ist.",
      ],
      code,
      codeHint: `Gültig für ${CODE_TTL_MIN} Minuten`,
      note: "Du hast das nicht angefordert? Dann ignoriere diese Mail einfach – ohne Code wird nichts gespeichert.",
      unsubscribeUrl: unsub,
    }),
    liveHtml: (unsub: string) => ({
      lang: "de" as const,
      preheader: "GolfTrack für Android ist jetzt im Google Play Store.",
      title: "GolfTrack ist jetzt bei Google Play",
      paragraphs: [
        "Wie versprochen: GolfTrack für Android gibt es ab sofort im Google Play Store – mit automatischen Updates.",
      ],
      button: { label: "Bei Google Play laden", url: PLAY_STORE_URL },
      note: "Das war die einzige Mail. Deine Adresse haben wir jetzt gelöscht.",
      unsubscribeUrl: unsub,
    }),
    welcomeSubject: "Du bist eingetragen – GolfTrack für Android",
    welcomeText: (unsub: string) =>
      `Hallo,\n\ndanke, deine E-Mail-Adresse ist bestätigt. Sobald GolfTrack im Google Play Store verfügbar ist, schreiben wir dir genau einmal – danach löschen wir deine Adresse.\n\nBis dahin kannst du die App schon jetzt als APK laden: ${SITE_URL}/android\n\nAbmelden: ${unsub}\n\nGolfTrack · golftrack.app`,
    welcomeHtml: (unsub: string) => ({
      lang: "de" as const,
      preheader: "Deine Adresse ist bestätigt – wir melden uns, sobald GolfTrack bei Google Play ist.",
      title: "Du bist eingetragen",
      paragraphs: [
        "Danke, deine E-Mail-Adresse ist bestätigt. Sobald GolfTrack im Google Play Store verfügbar ist, schreiben wir dir genau einmal – danach löschen wir deine Adresse.",
        "Bis dahin kannst du die App schon jetzt als APK laden.",
      ],
      button: { label: "Zur Android-APK", url: `${SITE_URL}/android` },
      note: "Du willst doch keine Nachricht? Über „Abmelden“ unten löschen wir deine Adresse sofort.",
      unsubscribeUrl: unsub,
    }),
    liveSubject: "GolfTrack ist jetzt im Google Play Store",
    liveText: (unsub: string) =>
      `Hallo,\n\nwie gewünscht: GolfTrack für Android gibt es jetzt im Google Play Store.\n\n${PLAY_STORE_URL}\n\nDas war die einzige Mail – deine Adresse haben wir jetzt gelöscht.\n\nGolfTrack · golftrack.app\n(Abmeldelink, falls nötig: ${unsub})`,
  },
  en: {
    codeSubject: (code: string) => `${code} is your GolfTrack confirmation code`,
    codeText: (code: string, unsub: string) =>
      `Hi,\n\nyour confirmation code is:\n\n    ${code}\n\nEnter it on golftrack.app and we'll email you once when GolfTrack is available on Google Play. The code is valid for ${CODE_TTL_MIN} minutes.\n\nDidn't request this? Just ignore this email – nothing happens without the code.\nUnsubscribe: ${unsub}\n\nGolfTrack · golftrack.app`,
    codeHtml: (code: string, unsub: string) => ({
      lang: "en" as const,
      preheader: `Your code: ${code} – valid for ${CODE_TTL_MIN} minutes.`,
      title: "Confirm your email address",
      paragraphs: [
        "Great that you want GolfTrack on Android! Enter this code on golftrack.app and we'll let you know as soon as the app is available on Google Play.",
      ],
      code,
      codeHint: `Valid for ${CODE_TTL_MIN} minutes`,
      note: "Didn't request this? Just ignore this email – nothing is stored without the code.",
      unsubscribeUrl: unsub,
    }),
    liveHtml: (unsub: string) => ({
      lang: "en" as const,
      preheader: "GolfTrack for Android is now on Google Play.",
      title: "GolfTrack is now on Google Play",
      paragraphs: ["As promised: GolfTrack for Android is now available on Google Play – with automatic updates."],
      button: { label: "Get it on Google Play", url: PLAY_STORE_URL },
      note: "This was the only email. We have now deleted your address.",
      unsubscribeUrl: unsub,
    }),
    welcomeSubject: "You're on the list – GolfTrack for Android",
    welcomeText: (unsub: string) =>
      `Hi,\n\nthanks, your email address is confirmed. As soon as GolfTrack is available on Google Play we'll email you exactly once – and then delete your address.\n\nUntil then you can already get the app as an APK: ${SITE_URL}/en/android\n\nUnsubscribe: ${unsub}\n\nGolfTrack · golftrack.app`,
    welcomeHtml: (unsub: string) => ({
      lang: "en" as const,
      preheader: "Your address is confirmed – we'll be in touch once GolfTrack is on Google Play.",
      title: "You're on the list",
      paragraphs: [
        "Thanks, your email address is confirmed. As soon as GolfTrack is available on Google Play we'll email you exactly once – and then delete your address.",
        "Until then you can already get the app as an APK.",
      ],
      button: { label: "Get the Android APK", url: `${SITE_URL}/en/android` },
      note: "Changed your mind? Use “Unsubscribe” below and we'll delete your address right away.",
      unsubscribeUrl: unsub,
    }),
    liveSubject: "GolfTrack is now on Google Play",
    liveText: (unsub: string) =>
      `Hi,\n\nas requested: GolfTrack for Android is now available on Google Play.\n\n${PLAY_STORE_URL}\n\nThis was the only email – we have now deleted your address.\n\nGolfTrack · golftrack.app\n(Unsubscribe link, just in case: ${unsub})`,
  },
} as const;

function unsubscribeUrl(token: string): string {
  return `${SITE_URL}/api/android/waitlist/unsubscribe?token=${token}`;
}

export type RequestResult = "sent" | "already_confirmed" | "too_many_codes";

/** Legt die Adresse an (oder findet sie) und schickt einen neuen Code. */
export async function requestCode(rawEmail: string, lang: Lang): Promise<RequestResult> {
  await ensureSchema();
  const email = normalizeEmail(rawEmail);
  let row = await queryOne<Row>("SELECT * FROM android_waitlist WHERE email = $1", [email]);
  if (row?.confirmed_at) return "already_confirmed";
  if (row && row.codes_sent >= MAX_CODES_PER_ADDRESS) return "too_many_codes";

  const code = String(randomInt(0, 1_000_000)).padStart(6, "0");
  const codeHash = hashCode(email, code);
  if (!row) {
    row = await queryOne<Row>(
      `INSERT INTO android_waitlist (email, lang, code_hash, code_expires_at, codes_sent, unsubscribe_token)
       VALUES ($1, $2, $3, now() + interval '${CODE_TTL_MIN} minutes', 1, $4) RETURNING *`,
      [email, lang, codeHash, randomBytes(24).toString("base64url")],
    );
  } else {
    row = await queryOne<Row>(
      `UPDATE android_waitlist SET code_hash = $2, code_expires_at = now() + interval '${CODE_TTL_MIN} minutes',
         code_attempts = 0, codes_sent = codes_sent + 1, lang = $3 WHERE id = $1 RETURNING *`,
      [row.id, codeHash, lang],
    );
  }
  const c = COPY[lang];
  const unsub = unsubscribeUrl(row!.unsubscribe_token);
  await sendMail(email, c.codeSubject(code), c.codeText(code, unsub), renderEmail(c.codeHtml(code, unsub)));
  return "sent";
}

export type ConfirmResult = "confirmed" | "wrong" | "expired" | "locked" | "unknown";

export async function confirmCode(rawEmail: string, code: string): Promise<ConfirmResult> {
  await ensureSchema();
  const email = normalizeEmail(rawEmail);
  const row = await queryOne<Row>("SELECT * FROM android_waitlist WHERE email = $1", [email]);
  if (!row) return "unknown";
  if (row.confirmed_at) return "confirmed";
  if (!row.code_hash || !row.code_expires_at) return "expired";
  if (row.code_attempts >= MAX_CODE_ATTEMPTS) return "locked";
  if (new Date(row.code_expires_at).getTime() < Date.now()) return "expired";

  const expected = Buffer.from(row.code_hash, "hex");
  const given = Buffer.from(hashCode(email, code.trim()), "hex");
  if (expected.length === given.length && timingSafeEqual(expected, given)) {
    await query(
      "UPDATE android_waitlist SET confirmed_at = now(), code_hash = NULL, code_expires_at = NULL WHERE id = $1",
      [row.id],
    );
    // Bestätigung der Anmeldung. Scheitert der Versand, bleibt die Anmeldung trotzdem gültig.
    const c = COPY[row.lang === "en" ? "en" : "de"];
    const unsub = unsubscribeUrl(row.unsubscribe_token);
    await sendMail(email, c.welcomeSubject, c.welcomeText(unsub), renderEmail(c.welcomeHtml(unsub))).catch(() => {});
    return "confirmed";
  }
  await query("UPDATE android_waitlist SET code_attempts = code_attempts + 1 WHERE id = $1", [row.id]);
  return row.code_attempts + 1 >= MAX_CODE_ATTEMPTS ? "locked" : "wrong";
}

export async function unsubscribe(token: string): Promise<boolean> {
  await ensureSchema();
  const rows = await query<{ id: string }>(
    "DELETE FROM android_waitlist WHERE unsubscribe_token = $1 RETURNING id",
    [token],
  );
  return rows.length > 0;
}

/** Unbestätigte Einträge nach einem Tag wegwerfen – sie bekommen nie Post. */
export async function purgeUnconfirmed(): Promise<void> {
  await ensureSchema();
  await query(
    "DELETE FROM android_waitlist WHERE confirmed_at IS NULL AND created_at < now() - interval '24 hours'",
  );
}

export async function waitlistStats(): Promise<{ confirmed: number; pending: number }> {
  await ensureSchema();
  const row = await queryOne<{ confirmed: string; pending: string }>(
    `SELECT COUNT(*) FILTER (WHERE confirmed_at IS NOT NULL) AS confirmed,
            COUNT(*) FILTER (WHERE confirmed_at IS NULL) AS pending FROM android_waitlist`,
  );
  return { confirmed: Number(row?.confirmed ?? 0), pending: Number(row?.pending ?? 0) };
}

/**
 * Schickt allen bestätigten Adressen die Play-Store-Nachricht und löscht sie
 * danach. Erst aufrufen, wenn die App wirklich im Store steht.
 */
export async function notifyAll(): Promise<{ sent: number; failed: number }> {
  await ensureSchema();
  const rows = await query<Row>("SELECT * FROM android_waitlist WHERE confirmed_at IS NOT NULL AND notified_at IS NULL");
  let sent = 0;
  let failed = 0;
  for (const row of rows) {
    const c = COPY[row.lang === "en" ? "en" : "de"];
    try {
      const unsub = unsubscribeUrl(row.unsubscribe_token);
      await sendMail(row.email, c.liveSubject, c.liveText(unsub), renderEmail(c.liveHtml(unsub)));
      await query("DELETE FROM android_waitlist WHERE id = $1", [row.id]);
      sent++;
    } catch {
      failed++;
    }
  }
  return { sent, failed };
}
