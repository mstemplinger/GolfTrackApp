"use client";

import { useActionState, useEffect } from "react";
import type { OperatorCopy } from "@/i18n/operator";
import { login, type LoginState } from "../actions";

const field =
  "w-full rounded-lg border border-white/10 bg-white/[0.04] px-4 py-3 text-cream placeholder:text-cream/35 focus:border-brass/60 focus:outline-none";

type Labels = Pick<OperatorCopy, "email" | "password" | "signIn" | "signingIn" | "wrongCredentials" | "locked">;

export function LoginForm({ t }: { t: Labels }) {
  const [state, action, pending] = useActionState<LoginState, FormData>(login, {});
  // Echte Navigation statt Server-Weiterleitung – siehe actions.ts.
  useEffect(() => {
    // Volle Navigation gewollt: nur so läuft die Anfrage durch den Proxy der Subdomain.
    // eslint-disable-next-line @next/next/no-location-assign-relative-destination
    if (state.done) window.location.assign("/");
  }, [state.done]);

  return (
    <form action={action} className="space-y-4">
      <label className="block">
        <span className="mb-1.5 block text-sm text-cream/70">{t.email}</span>
        <input
          name="email"
          type="email"
          autoComplete="username"
          required
          defaultValue={state.email}
          className={field}
        />
      </label>
      <label className="block">
        <span className="mb-1.5 block text-sm text-cream/70">{t.password}</span>
        <input name="password" type="password" autoComplete="current-password" required className={field} />
      </label>
      {state.error ? (
        <p role="alert" className="text-sm text-[#e07a63]">
          {state.error === "locked" ? t.locked : t.wrongCredentials}
        </p>
      ) : null}
      <button
        type="submit"
        disabled={pending || state.done}
        className="w-full rounded-lg bg-brass py-3 font-semibold text-night transition-colors hover:bg-brass-soft disabled:opacity-60"
      >
        {pending || state.done ? t.signingIn : t.signIn}
      </button>
    </form>
  );
}
