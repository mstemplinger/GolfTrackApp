import "server-only";
import path from "node:path";
import nodemailer, { type Transporter } from "nodemailer";
import { LOGO_CID } from "@/lib/emailTemplate";

/**
 * Versand über das Postfach bei IONOS (MX von golftrack.app). Zugangsdaten
 * stehen in `.env.production`: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS,
 * SMTP_FROM. Fehlen sie, meldet `mailConfigured()` false und die Formulare
 * sagen das, statt still nichts zu verschicken.
 */
export function mailConfigured(): boolean {
  return Boolean(process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS);
}

let transport: Transporter | null = null;

function getTransport(): Transporter {
  if (!transport) {
    const port = Number(process.env.SMTP_PORT ?? 465);
    transport = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port,
      secure: port === 465,
      requireTLS: port !== 465,
      auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
    });
  }
  return transport;
}

/** `html` optional: dann geht die Mail mit Text- und HTML-Fassung und eingebettetem Logo raus. */
export async function sendMail(to: string, subject: string, text: string, html?: string): Promise<void> {
  if (!mailConfigured()) throw new Error("mail_unconfigured");
  await getTransport().sendMail({
    from: process.env.SMTP_FROM ?? `GolfTrack <${process.env.SMTP_USER}>`,
    to,
    subject,
    text,
    ...(html
      ? {
          html,
          attachments: [
            { filename: "golftrack.png", path: path.join(process.cwd(), "public", "logo.png"), cid: LOGO_CID },
          ],
        }
      : {}),
  });
}
