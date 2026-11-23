import "server-only";
import { z } from "zod";
import { mailConfigured, sendMail } from "./mail";
import { PRINT_ITEM_LABEL, PRINT_ITEMS } from "./printItems";

/**
 * Anfrage eines Golfplatzes nach Druckwerbung (Werbesäulen, Bauzaunplane,
 * Plakate) von `/werbung/golfplatz`. Geht nur per Mail an den Betreiber von
 * golftrack.app (REPORT_EMAIL, sonst die öffentliche Kontaktadresse), Antwort
 * per Reply-To direkt an den Club. Kein Eintrag in der Datenbank: Schlägt der
 * Versand fehl, sagt das Formular es und bietet die Mailadresse an – eine
 * Anfrage, die still in einer Tabelle liegt, liest niemand.
 */

export const printRequestSchema = z.object({
  club: z.string().trim().min(2, "Bitte den Namen des Platzes angeben.").max(160),
  location: z.string().trim().max(160).optional().default(""),
  name: z.string().trim().min(2, "Bitte einen Ansprechpartner angeben.").max(120),
  email: z.email("Bitte eine gültige Mailadresse angeben.").max(200),
  phone: z.string().trim().max(60).optional().default(""),
  items: z.array(z.enum(PRINT_ITEMS)).min(1, "Bitte mindestens ein Werbemittel wählen.").max(PRINT_ITEMS.length),
  message: z.string().trim().max(3000).optional().default(""),
  consent: z.literal(true, "Bitte der Bearbeitung zustimmen."),
  /** Honigtopf – Menschen sehen das Feld nicht. */
  company: z.string().optional().default(""),
});
export type PrintRequestInput = z.infer<typeof printRequestSchema>;

function recipient(): string | null {
  return process.env.REPORT_EMAIL || process.env.NEXT_PUBLIC_CONTACT_EMAIL || null;
}

export type PrintRequestResult = "sent" | "unavailable";

export async function submitPrintRequest(input: PrintRequestInput): Promise<PrintRequestResult> {
  const to = recipient();
  if (!to || !mailConfigured()) return "unavailable";

  const text = [
    `Neue Anfrage nach Druckwerbung von „${input.club}“`,
    "",
    `Platz:     ${input.club}${input.location ? ` (${input.location})` : ""}`,
    `Kontakt:   ${input.name}`,
    `E-Mail:    ${input.email}`,
    `Telefon:   ${input.phone || "–"}`,
    "",
    "Gewünscht:",
    ...input.items.map((item) => `  – ${PRINT_ITEM_LABEL[item]}`),
    "",
    "Nachricht:",
    input.message || "–",
  ].join("\n");

  try {
    await sendMail(to, `Werbemittel angefragt: ${input.club}`, text, undefined, { replyTo: input.email });
  } catch (error) {
    console.error("print request mail failed", input.club, error);
    return "unavailable";
  }
  return "sent";
}
