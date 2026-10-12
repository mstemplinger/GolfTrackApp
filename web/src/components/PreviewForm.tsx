"use client";

import { useActionState } from "react";
import { preview } from "@/app/(de)/bald/actions";

/** Aufklappbarer Zugang zur Vorschau, wie auf toob360.com. */
export function PreviewForm({ lang }: { lang: "de" | "en" }) {
  const [error, action, pending] = useActionState(preview, null);
  const de = lang === "de";
  return (
    <details className="group w-full max-w-sm text-sm" open={Boolean(error)}>
      <summary className="tap mx-auto w-fit cursor-pointer gap-2 text-muted hover:text-cream">
        <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden>
          <rect x="4" y="11" width="16" height="10" rx="2" />
          <path d="M8 11V7a4 4 0 0 1 8 0v4" />
        </svg>
        {de ? "Vorschau mit Passwort" : "Preview with password"}
      </summary>
      <form action={action} className="mt-3 flex flex-col gap-2 sm:flex-row">
        <input type="hidden" name="lang" value={lang} />
        <label className="sr-only" htmlFor="preview-password">
          {de ? "Passwort" : "Password"}
        </label>
        <input
          id="preview-password"
          name="password"
          type="password"
          required
          autoComplete="current-password"
          placeholder={de ? "Passwort" : "Password"}
          className="min-h-[44px] flex-1 rounded-full border border-cream/25 bg-white/5 px-5 text-cream placeholder:text-muted/70 focus:border-brass focus:outline-none"
        />
        <button
          type="submit"
          disabled={pending}
          className="tap justify-center rounded-full bg-cream/90 px-5 font-semibold text-night hover:bg-cream disabled:opacity-60"
        >
          {de ? "Seite öffnen" : "Open site"}
        </button>
      </form>
      {error ? <p role="alert" className="mt-2 text-center text-[#e89a8a]">{error}</p> : null}
    </details>
  );
}
