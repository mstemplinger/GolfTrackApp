"use client";

import { useState } from "react";

/** Zeigt ein frisch erzeugtes Passwort genau einmal – mit Knopf zum Kopieren. */
export function PasswordNotice({
  email,
  password,
  portalUrl,
  created,
}: {
  email: string;
  password: string;
  portalUrl: string;
  created?: boolean;
}) {
  const [copied, setCopied] = useState(false);
  const text = `Zugang zur Platz-Statistik von GolfTrack\n\nAdresse: ${portalUrl}/login\nE-Mail: ${email}\nPasswort: ${password}`;

  return (
    <div className="rounded-xl border border-brass/50 bg-brass/[0.07] p-5">
      <p className="font-medium text-brass">
        {created ? "Konto angelegt." : "Neues Passwort erzeugt."} Das Passwort wird nur jetzt angezeigt.
      </p>
      <dl className="mt-4 grid gap-x-6 gap-y-2 text-sm sm:grid-cols-[auto_1fr]">
        <dt className="text-cream/55">Anmeldung</dt>
        <dd className="font-mono">{portalUrl}/login</dd>
        <dt className="text-cream/55">E-Mail</dt>
        <dd className="font-mono">{email}</dd>
        <dt className="text-cream/55">Passwort</dt>
        <dd className="font-mono text-lg tracking-wide text-cream">{password}</dd>
      </dl>
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
      <p className="mt-3 text-xs text-cream/50">
        Am besten getrennt schicken: Adresse und E-Mail per Mail, das Passwort per Telefon oder SMS.
        {created ? "" : " Alle bisherigen Anmeldungen dieses Kontos sind damit beendet."}
      </p>
    </div>
  );
}
