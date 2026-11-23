"use client";

import { useTransition } from "react";
import { logout } from "./actions";

/** Abmelden – danach lädt der Browser die Anmeldeseite (siehe actions.ts, warum nicht per redirect). */
export function LogoutButton({ label }: { label: string }) {
  const [pending, start] = useTransition();
  return (
    <button
      type="button"
      disabled={pending}
      onClick={() =>
        start(async () => {
          await logout();
          // Volle Navigation gewollt: nur so läuft die Anfrage durch den Proxy der Subdomain.
          // eslint-disable-next-line @next/next/no-location-assign-relative-destination
          window.location.assign("/login");
        })
      }
      className="rounded-lg border border-white/10 px-3 py-1.5 text-cream/75 transition-colors hover:border-brass/60 hover:text-brass disabled:opacity-60"
    >
      {label}
    </button>
  );
}
