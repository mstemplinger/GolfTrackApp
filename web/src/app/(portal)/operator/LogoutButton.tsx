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
      aria-label={label}
      title={label}
      className="grid size-11 place-items-center rounded-lg text-cream/75 transition-colors hover:text-brass disabled:opacity-60 sm:flex sm:size-auto sm:min-h-9 sm:border sm:border-white/10 sm:px-3 sm:py-1.5 sm:hover:border-brass/60"
    >
      {/* Am Handy nur das Zeichen – Text und Name passen dort nicht nebeneinander. */}
      <svg aria-hidden viewBox="0 0 20 20" className="size-5 sm:hidden" fill="none" stroke="currentColor" strokeWidth="1.6">
        <path d="M8 4H5.5A1.5 1.5 0 0 0 4 5.5v9A1.5 1.5 0 0 0 5.5 16H8M12.5 13.5 16 10l-3.5-3.5M16 10H8" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
      <span className="hidden sm:inline">{label}</span>
    </button>
  );
}
