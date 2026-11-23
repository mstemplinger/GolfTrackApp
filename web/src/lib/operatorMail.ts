import "server-only";
import { renderEmail, renderText, type EmailContent } from "./emailTemplate";
import { mailConfigured, sendMail } from "./mail";
import { operatorPortalUrl } from "./operatorPortal";

/**
 * Zugangsmails für Betreiberkonten – bewusst in zwei getrennten Mails:
 *
 * 1. Zugang: Adresse des Portals, Anmeldename, zugewiesene Plätze. Kein Passwort.
 * 2. Passwort: nur das Passwort, ohne Anmeldename und Adresse.
 *
 * Wer nur eine der beiden Mails in die Hände bekommt, kann sich damit nicht
 * anmelden. Gestaltung über die gemeinsame GolfTrack-Vorlage (emailTemplate.ts).
 */

export type MailResult = "sent" | "unconfigured" | "failed";

interface Recipient {
  name: string;
  email: string;
  lang: "de" | "en";
  /** Namen der zugewiesenen Plätze, für die Übersicht in der ersten Mail. */
  courses: string[];
}

const SUPPORT = "contact@golftrack.app";

export function accessMail(r: Recipient, kind: "created" | "reset"): { subject: string; content: EmailContent } {
  const de = r.lang === "de";
  const login = `${operatorPortalUrl()}/login`;
  const created = kind === "created";
  const courses = r.courses.length ? r.courses.join(", ") : de ? "noch keiner" : "none yet";

  const content: EmailContent = {
    lang: r.lang,
    preheader: de
      ? "Deine Zugangsdaten zur Platz-Statistik – das Passwort folgt in einer zweiten E-Mail."
      : "Your access to the course statistics – the password follows in a second email.",
    title: created
      ? de
        ? "Dein Zugang zu GolfTrack für Betreiber"
        : "Your access to GolfTrack for operators"
      : de
        ? "Neues Passwort für deinen Zugang"
        : "New password for your account",
    paragraphs: created
      ? de
        ? [
            `Für „${r.name}“ wurde ein Zugang zur anonymen Rundenstatistik von GolfTrack eingerichtet. Dort siehst du, wann auf deiner Anlage viel los ist, wie lange gespielt wird und welche Bahnen schwer sind.`,
            "Das Passwort schicken wir dir aus Sicherheitsgründen in einer zweiten, separaten E-Mail.",
          ]
        : [
            `An account for the anonymous GolfTrack round statistics has been set up for “${r.name}”. It shows when your course is busy, how long rounds take and which holes are hard.`,
            "For security reasons, we send the password in a second, separate email.",
          ]
      : de
        ? [
            `Für deinen Zugang („${r.name}“) wurde ein neues Passwort erzeugt. Das bisherige gilt nicht mehr, und alle laufenden Anmeldungen wurden beendet.`,
            "Das neue Passwort folgt in einer zweiten, separaten E-Mail.",
          ]
        : [
            `A new password has been created for your account (“${r.name}”). The previous one no longer works and all active sessions have been signed out.`,
            "The new password follows in a second, separate email.",
          ],
    details: [
      { label: de ? "Anmeldung" : "Sign in at", value: login.replace(/^https?:\/\//, "") },
      { label: de ? "Anmeldename (E-Mail)" : "Username (email)", value: r.email },
      {
        label: de ? (r.courses.length === 1 ? "Platz" : "Plätze") : r.courses.length === 1 ? "Course" : "Courses",
        value: courses,
      },
    ],
    button: { label: de ? "Zur Anmeldung" : "Go to sign in", url: login },
    note: de
      ? `Fragen oder diese E-Mail nicht erwartet? Schreib an ${SUPPORT}.`
      : `Questions, or didn’t expect this email? Write to ${SUPPORT}.`,
  };
  const subject = created
    ? de
      ? "Dein Zugang zur Platz-Statistik von GolfTrack"
      : "Your access to GolfTrack course statistics"
    : de
      ? "Neues Passwort für GolfTrack für Betreiber"
      : "New password for GolfTrack for operators";
  return { subject, content };
}

/** Zweite Mail: nur das Passwort – ohne Anmeldename und Adresse. */
export function passwordMail(lang: "de" | "en", password: string): { subject: string; content: EmailContent } {
  const de = lang === "de";
  return {
    subject: de ? "Dein Passwort (GolfTrack)" : "Your password (GolfTrack)",
    content: {
      lang,
      preheader: de ? "Das Passwort zu deinem Zugang." : "The password for your account.",
      title: de ? "Dein Passwort" : "Your password",
      paragraphs: de
        ? [
            "Hier ist das Passwort zu deinem Zugang. Adresse und Anmeldename stehen in der separaten E-Mail, die du gerade bekommen hast.",
          ]
        : [
            "Here is the password for your account. The address and username are in the separate email you just received.",
          ],
      code: password,
      codeStyle: "password",
      codeHint: de ? "Groß- und Kleinschreibung beachten" : "Case-sensitive",
      note: de
        ? `Bitte bewahre das Passwort sicher auf und gib es nicht weiter. Diese E-Mail nicht erwartet? Schreib an ${SUPPORT}.`
        : `Please keep this password safe and don’t share it. Didn’t expect this email? Write to ${SUPPORT}.`,
    },
  };
}

/**
 * Beide Mails nacheinander senden. Scheitert die erste, geht die zweite gar
 * nicht erst raus – ein Passwort ohne Zugang hilft niemandem.
 */
export async function sendOperatorMails(
  r: Recipient,
  password: string,
  kind: "created" | "reset",
): Promise<MailResult> {
  if (!mailConfigured()) return "unconfigured";
  try {
    const a = accessMail(r, kind);
    await sendMail(r.email, a.subject, renderText(a.content), renderEmail(a.content), { replyTo: SUPPORT });
    const p = passwordMail(r.lang, password);
    await sendMail(r.email, p.subject, renderText(p.content), renderEmail(p.content), { replyTo: SUPPORT });
    return "sent";
  } catch (error) {
    console.error("operator mail failed", error);
    return "failed";
  }
}

/**
 * Hinweis an die bisherige Adresse, wenn der Betreiber seine Anmelde-E-Mail
 * ändert – falls das nicht er selbst war, merkt er es so.
 */
export async function sendEmailChangedNotice(
  lang: "de" | "en",
  name: string,
  oldEmail: string,
  newEmail: string,
): Promise<MailResult> {
  if (!mailConfigured()) return "unconfigured";
  const de = lang === "de";
  const content: EmailContent = {
    lang,
    preheader: de
      ? "Die Anmelde-E-Mail deines Zugangs wurde geändert."
      : "The sign-in email of your account was changed.",
    title: de ? "Anmelde-E-Mail geändert" : "Sign-in email changed",
    paragraphs: de
      ? [
          `Für deinen Zugang zu GolfTrack für Betreiber („${name}“) wurde die Anmelde-E-Mail geändert. Anmelden geht ab jetzt nur noch mit der neuen Adresse.`,
          "Warst du das nicht? Dann melde dich bitte sofort bei uns – wir sperren den Zugang.",
        ]
      : [
          `The sign-in email of your GolfTrack operator account (“${name}”) was changed. From now on you can only sign in with the new address.`,
          "Wasn't you? Please contact us right away – we'll lock the account.",
        ],
    details: [
      { label: de ? "Bisher" : "Previously", value: oldEmail },
      { label: de ? "Neu" : "New", value: newEmail },
    ],
    note: de ? `Kontakt: ${SUPPORT}` : `Contact: ${SUPPORT}`,
  };
  try {
    await sendMail(
      oldEmail,
      de ? "Deine Anmelde-E-Mail wurde geändert (GolfTrack)" : "Your sign-in email was changed (GolfTrack)",
      renderText(content),
      renderEmail(content),
      { replyTo: SUPPORT },
    );
    return "sent";
  } catch (error) {
    console.error("operator mail failed", error);
    return "failed";
  }
}
