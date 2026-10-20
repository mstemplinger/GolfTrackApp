import "server-only";
import { createHash, randomBytes, randomInt, timingSafeEqual } from "node:crypto";
import { query, queryOne } from "@/lib/db";
import { ensureSchema } from "@/lib/migrations";
import { sendMail } from "@/lib/mail";
import { renderEmail, renderText, type EmailContent } from "@/lib/emailTemplate";
import { SITE_URL, type Lang } from "@/i18n/routes";
import { ANDROID_RELEASE, PLAY_STORE_URL } from "@/lib/android";

/**
 * Android-Mailingliste mit Double-Opt-in per Code.
 *
 * Wofür man sich einträgt (so steht es auch im Formular): Mail bei jeder neuen
 * APK-Fassung – die APK aktualisiert sich nicht selbst – und sobald die App im
 * Play Store steht. Werbung und Neuigkeiten nur mit eigener, freiwilliger
 * Einwilligung (`marketing_consent`, UWG § 7 / DSGVO Art. 6 Abs. 1 lit. a);
 * die lässt sich im Formular oder später über den Knopf in der Mail geben.
 *
 * Ablauf: Adresse eintragen → Mail mit sechsstelligem Code → Code eingeben →
 * bestätigt. Der Eintrag bleibt bis zur Abmeldung über den Link in jeder Mail.
 */

const CODE_TTL_MIN = 15;
const MAX_CODE_ATTEMPTS = 5;
const MAX_CODES_PER_ADDRESS = 5;
/** Frühestens nach dieser Zeit geht an dieselbe Adresse die nächste Code-Mail. */
export const RESEND_COOLDOWN_S = 60;

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
  last_code_sent_at: Date | null;
  marketing_consent: boolean;
  apk_updates: boolean;
  last_update_version: number;
};

function hashCode(email: string, code: string): string {
  const secret = process.env.ADMIN_SECRET ?? "";
  return createHash("sha256").update(`${email}:${code}:${secret}`).digest("hex");
}

export function normalizeEmail(raw: string): string {
  return raw.trim().toLowerCase();
}

const linkUrl = (path: string, token: string) => `${SITE_URL}/api/android/waitlist/${path}?token=${token}`;
const androidPage = (lang: Lang) => `${SITE_URL}${lang === "de" ? "/android" : "/en/android"}`;

/** Texte aller Mails. Jede Mail entsteht aus einem `EmailContent` – HTML und Textfassung gleich. */
const MAILS = {
  code: (lang: Lang, code: string, unsub: string): [string, EmailContent] =>
    lang === "de"
      ? [
          `${code} ist dein GolfTrack-Bestätigungscode`,
          {
            lang,
            preheader: `Dein Code: ${code} – gültig für ${CODE_TTL_MIN} Minuten.`,
            title: "Bestätige deine E-Mail-Adresse",
            paragraphs: [
              "Schön, dass du GolfTrack auf Android nutzen willst! Gib diesen Code auf golftrack.app ein – dann sagen wir dir Bescheid, wenn es eine neue Version gibt und sobald die App im Google Play Store verfügbar ist.",
            ],
            code,
            codeHint: `Gültig für ${CODE_TTL_MIN} Minuten`,
            note: "Du hast das nicht angefordert? Dann ignoriere diese Mail einfach – ohne Code wird nichts gespeichert.",
            unsubscribeUrl: unsub,
          },
        ]
      : [
          `${code} is your GolfTrack confirmation code`,
          {
            lang,
            preheader: `Your code: ${code} – valid for ${CODE_TTL_MIN} minutes.`,
            title: "Confirm your email address",
            paragraphs: [
              "Great that you want GolfTrack on Android! Enter this code on golftrack.app and we'll let you know whenever there's a new version and as soon as the app is available on Google Play.",
            ],
            code,
            codeHint: `Valid for ${CODE_TTL_MIN} minutes`,
            note: "Didn't request this? Just ignore this email – nothing is stored without the code.",
            unsubscribeUrl: unsub,
          },
        ],

  welcome: (lang: Lang, unsub: string, newsUrl: string | null): [string, EmailContent] =>
    lang === "de"
      ? [
          "Du bist eingetragen – GolfTrack für Android",
          {
            lang,
            preheader: "Deine Adresse ist bestätigt – wir melden uns bei jeder neuen Version.",
            title: "Du bist eingetragen",
            paragraphs: [
              "Danke, deine E-Mail-Adresse ist bestätigt. Die APK aktualisiert sich nicht von selbst – deshalb schreiben wir dir, sobald eine neue Version bereitsteht, und sobald GolfTrack im Google Play Store ist.",
            ],
            button: { label: "Zur Android-APK", url: androidPage(lang) },
            secondary: newsUrl
              ? {
                  text: "Willst du neue Funktionen und Aktionen als Erste erfahren? Höchstens einmal im Monat, jederzeit abbestellbar.",
                  label: "Ja, Neuigkeiten erhalten",
                  url: newsUrl,
                }
              : undefined,
            note: "Keine Mails mehr gewünscht? Über „Abmelden“ unten löschen wir deine Adresse sofort.",
            unsubscribeUrl: unsub,
          },
        ]
      : [
          "You're on the list – GolfTrack for Android",
          {
            lang,
            preheader: "Your address is confirmed – we'll be in touch with every new version.",
            title: "You're on the list",
            paragraphs: [
              "Thanks, your email address is confirmed. The APK doesn't update itself – so we'll email you whenever a new version is ready, and once GolfTrack is on Google Play.",
            ],
            button: { label: "Get the Android APK", url: androidPage(lang) },
            secondary: newsUrl
              ? {
                  text: "Want to hear about new features and offers first? At most once a month, unsubscribe any time.",
                  label: "Yes, send me news",
                  url: newsUrl,
                }
              : undefined,
            note: "No more emails wanted? Use “Unsubscribe” below and we'll delete your address right away.",
            unsubscribeUrl: unsub,
          },
        ],

  update: (lang: Lang, unsub: string, version: string, notes: string[]): [string, EmailContent] =>
    lang === "de"
      ? [
          `GolfTrack ${version} für Android ist da`,
          {
            lang,
            preheader: `Neue Version ${version} – jetzt laden und über die alte installieren.`,
            title: `GolfTrack ${version} ist da`,
            paragraphs: [
              "Eine neue Version der Android-App steht bereit. Lade die APK und installiere sie einfach über die alte – deine Runden bleiben erhalten.",
              ...notes,
            ],
            button: { label: `Version ${version} laden`, url: androidPage(lang) },
            unsubscribeUrl: unsub,
          },
        ]
      : [
          `GolfTrack ${version} for Android is here`,
          {
            lang,
            preheader: `New version ${version} – download it and install over the old one.`,
            title: `GolfTrack ${version} is here`,
            paragraphs: [
              "A new version of the Android app is ready. Download the APK and simply install it over the old one – your rounds are kept.",
              ...notes,
            ],
            button: { label: `Get version ${version}`, url: androidPage(lang) },
            unsubscribeUrl: unsub,
          },
        ],

  live: (lang: Lang, unsub: string): [string, EmailContent] =>
    lang === "de"
      ? [
          "GolfTrack ist jetzt im Google Play Store",
          {
            lang,
            preheader: "GolfTrack für Android ist jetzt im Google Play Store.",
            title: "GolfTrack ist jetzt bei Google Play",
            paragraphs: ["Wie versprochen: GolfTrack für Android gibt es ab sofort im Google Play Store – mit automatischen Updates."],
            button: { label: "Bei Google Play laden", url: PLAY_STORE_URL },
            unsubscribeUrl: unsub,
          },
        ]
      : [
          "GolfTrack is now on Google Play",
          {
            lang,
            preheader: "GolfTrack for Android is now on Google Play.",
            title: "GolfTrack is now on Google Play",
            paragraphs: ["As promised: GolfTrack for Android is now available on Google Play – with automatic updates."],
            button: { label: "Get it on Google Play", url: PLAY_STORE_URL },
            unsubscribeUrl: unsub,
          },
        ],
};

async function send(to: string, [subject, content]: [string, EmailContent]): Promise<void> {
  await sendMail(to, subject, renderText(content), renderEmail(content));
}

const langOf = (row: Row): Lang => (row.lang === "en" ? "en" : "de");

export type RequestResult =
  | { status: "sent" | "already_confirmed" | "too_many_codes" }
  | { status: "cooldown"; retryAfter: number };

/**
 * Legt die Adresse an (oder findet sie) und schickt einen neuen Code.
 * `marketing`: freiwilliges Häkchen für Neuigkeiten und Angebote.
 */
export async function requestCode(rawEmail: string, lang: Lang, marketing = false): Promise<RequestResult> {
  await ensureSchema();
  const email = normalizeEmail(rawEmail);
  let row = await queryOne<Row>("SELECT * FROM android_waitlist WHERE email = $1", [email]);
  if (row?.confirmed_at) return { status: "already_confirmed" };
  if (row?.last_code_sent_at) {
    const waited = (Date.now() - new Date(row.last_code_sent_at).getTime()) / 1000;
    if (waited < RESEND_COOLDOWN_S) return { status: "cooldown", retryAfter: Math.ceil(RESEND_COOLDOWN_S - waited) };
  }
  if (row && row.codes_sent >= MAX_CODES_PER_ADDRESS) return { status: "too_many_codes" };

  const code = String(randomInt(0, 1_000_000)).padStart(6, "0");
  const codeHash = hashCode(email, code);
  if (!row) {
    // Wer sich jetzt einträgt, hat die aktuelle Fassung schon – Update-Mails erst ab der nächsten.
    row = await queryOne<Row>(
      `INSERT INTO android_waitlist (email, lang, code_hash, code_expires_at, codes_sent, unsubscribe_token,
         last_code_sent_at, marketing_consent, last_update_version)
       VALUES ($1, $2, $3, now() + interval '${CODE_TTL_MIN} minutes', 1, $4, now(), $5, $6) RETURNING *`,
      [email, lang, codeHash, randomBytes(24).toString("base64url"), marketing, ANDROID_RELEASE.versionCode],
    );
  } else {
    row = await queryOne<Row>(
      `UPDATE android_waitlist SET code_hash = $2, code_expires_at = now() + interval '${CODE_TTL_MIN} minutes',
         code_attempts = 0, codes_sent = codes_sent + 1, lang = $3, last_code_sent_at = now(),
         marketing_consent = $4 WHERE id = $1 RETURNING *`,
      [row.id, codeHash, lang, marketing],
    );
  }
  await send(email, MAILS.code(lang, code, linkUrl("unsubscribe", row!.unsubscribe_token)));
  return { status: "sent" };
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
      `UPDATE android_waitlist SET confirmed_at = now(), code_hash = NULL, code_expires_at = NULL,
         marketing_consent_at = CASE WHEN marketing_consent THEN now() END WHERE id = $1`,
      [row.id],
    );
    // Bestätigung der Anmeldung – wer das Häkchen nicht gesetzt hat, bekommt
    // darin das Angebot, Neuigkeiten nachträglich zu bestellen. Scheitert der
    // Versand, bleibt die Anmeldung trotzdem gültig.
    const newsUrl = row.marketing_consent ? null : linkUrl("news", row.unsubscribe_token);
    await send(email, MAILS.welcome(langOf(row), linkUrl("unsubscribe", row.unsubscribe_token), newsUrl)).catch(() => {});
    return "confirmed";
  }
  await query("UPDATE android_waitlist SET code_attempts = code_attempts + 1 WHERE id = $1", [row.id]);
  return row.code_attempts + 1 >= MAX_CODE_ATTEMPTS ? "locked" : "wrong";
}

/** Nachträgliche Einwilligung in Neuigkeiten über den Knopf in der Mail. */
export async function grantMarketing(token: string): Promise<boolean> {
  await ensureSchema();
  const rows = await query<{ id: string }>(
    `UPDATE android_waitlist SET marketing_consent = true, marketing_consent_at = now()
     WHERE unsubscribe_token = $1 AND confirmed_at IS NOT NULL RETURNING id`,
    [token],
  );
  return rows.length > 0;
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

export async function waitlistStats(): Promise<{ confirmed: number; pending: number; marketing: number }> {
  await ensureSchema();
  const row = await queryOne<{ confirmed: string; pending: string; marketing: string }>(
    `SELECT COUNT(*) FILTER (WHERE confirmed_at IS NOT NULL) AS confirmed,
            COUNT(*) FILTER (WHERE confirmed_at IS NULL) AS pending,
            COUNT(*) FILTER (WHERE confirmed_at IS NOT NULL AND marketing_consent) AS marketing
     FROM android_waitlist`,
  );
  return {
    confirmed: Number(row?.confirmed ?? 0),
    pending: Number(row?.pending ?? 0),
    marketing: Number(row?.marketing ?? 0),
  };
}

async function sendToEach(rows: Row[], mail: (row: Row) => [string, EmailContent], after: (row: Row) => Promise<unknown>) {
  let sent = 0;
  let failed = 0;
  for (const row of rows) {
    try {
      await send(row.email, mail(row));
      await after(row);
      sent++;
    } catch {
      failed++;
    }
  }
  return { sent, failed };
}

/**
 * Meldet die aktuelle APK-Fassung (`ANDROID_RELEASE`) an alle bestätigten
 * Adressen, die sie noch nicht bekommen haben. Mehrfach aufrufen schadet
 * nicht – gemeldet wird jede Fassung nur einmal.
 */
export async function notifyApkUpdate(notes: string[] = []): Promise<{ version: string; sent: number; failed: number }> {
  await ensureSchema();
  const code = ANDROID_RELEASE.versionCode;
  const rows = await query<Row>(
    `SELECT * FROM android_waitlist WHERE confirmed_at IS NOT NULL AND apk_updates AND last_update_version < $1`,
    [code],
  );
  const result = await sendToEach(
    rows,
    (row) => MAILS.update(langOf(row), linkUrl("unsubscribe", row.unsubscribe_token), ANDROID_RELEASE.versionName, notes),
    (row) => query("UPDATE android_waitlist SET last_update_version = $2 WHERE id = $1", [row.id, code]),
  );
  return { version: ANDROID_RELEASE.versionName, ...result };
}

/**
 * Play-Store-Nachricht an alle bestätigten Adressen, einmal je Adresse
 * (`notified_at`). Erst aufrufen, wenn die App wirklich im Store steht.
 */
export async function notifyAll(): Promise<{ sent: number; failed: number }> {
  await ensureSchema();
  const rows = await query<Row>("SELECT * FROM android_waitlist WHERE confirmed_at IS NOT NULL AND notified_at IS NULL");
  return sendToEach(
    rows,
    (row) => MAILS.live(langOf(row), linkUrl("unsubscribe", row.unsubscribe_token)),
    (row) => query("UPDATE android_waitlist SET notified_at = now() WHERE id = $1", [row.id]),
  );
}
