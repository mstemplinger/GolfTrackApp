"use client";

import { useState } from "react";
import type { MailResult } from "@/lib/operatorMail";

/**
 * Rückmeldung nach dem Anlegen bzw. neuen Passwort. Sind die Zugangsmails
 * raus, bleibt das Passwort verdeckt (nur auf Klick sichtbar). Ging nichts
 * raus, steht es offen da – zum Weitergeben von Hand. Es wird nur jetzt
 * angezeigt; gespeichert ist allein der Hash.
 */
export function PasswordNotice({
  email,
  password,
  portalUrl,
  created,
  mail,
}: {
  email: string;
  password: string;
  portalUrl: string;
  created?: boolean;
  mail?: MailResult;
}) {
  const sent = mail === "sent";
  const [reveal, setReveal] = useState(!sent);
  const [copied, setCopied] = useState(false);
  const text = `Zugang zur Platz-Statistik von GolfTrack\n\nAdresse: ${portalUrl}/login\nE-Mail: ${email}\nPasswort: ${password}`;

  return (
    <div className="rounded-xl border border-brass/50 bg-brass/[0.07] p-5">
      <p className="font-medium text-brass">{created ? "Konto angelegt." : "Neues Passwort erzeugt."}</p>

      {sent ? (
        <p className="mt-2 text-sm text-[#7fd19b]">
          ✓ Zugangsdaten an {email} verschickt – in zwei getrennten E-Mails (Zugang, dann Passwort).
        </p>
      ) : mail === "unconfigured" ? (
        <p className="mt-2 text-sm text-[#e0a063]">
          Keine E-Mail verschickt: Auf diesem Server ist kein Mailversand eingerichtet. Bitte die Zugangsdaten selbst
          weitergeben.
        </p>
      ) : mail === "failed" ? (
        <p className="mt-2 text-sm text-[#e07a63]">
          Der Mailversand ist fehlgeschlagen. Bitte die Zugangsdaten selbst weitergeben – oder später ein neues Passwort
          erzeugen und es erneut versuchen.
        </p>
      ) : (
        <p className="mt-2 text-sm text-cream/60">Keine E-Mail verschickt. Das Passwort wird nur jetzt angezeigt.</p>
      )}

      <dl className="mt-4 grid gap-x-6 gap-y-2 text-sm sm:grid-cols-[auto_1fr]">
        <dt className="text-cream/55">Anmeldung</dt>
        <dd className="font-mono">{portalUrl}/login</dd>
        <dt className="text-cream/55">E-Mail</dt>
        <dd className="font-mono">{email}</dd>
        <dt className="text-cream/55">Passwort</dt>
        <dd className="font-mono text-lg tracking-wide text-cream">
          {reveal ? (
            password
          ) : (
            <button
              type="button"
              onClick={() => setReveal(true)}
              className="text-sm text-brass underline underline-offset-4"
            >
              Trotzdem anzeigen
            </button>
          )}
        </dd>
      </dl>

      {reveal ? (
        <>
          <button
            type="button"
            onClick={async () => {
              try {
                await navigator.clipboard.writeText(text);
                setCopied(true);
              } catch {
                setCopied(false);
              }
            }}
            className="mt-4 rounded-lg border border-brass/60 px-4 py-2 text-sm text-brass transition-colors hover:bg-brass/10"
          >
            {copied ? "✓ Zugangsdaten kopiert" : "Zugangsdaten kopieren"}
          </button>
          {!sent ? (
            <p className="mt-3 text-xs text-cream/50">
              Am besten getrennt schicken: Adresse und E-Mail per Mail, das Passwort per Telefon oder SMS.
            </p>
          ) : null}
        </>
      ) : null}
      {!created ? (
        <p className="mt-3 text-xs text-cream/50">Alle bisherigen Anmeldungen des Kontos sind beendet.</p>
      ) : null}
    </div>
  );
}
