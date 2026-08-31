"use client";

import { useActionState } from "react";
import { login } from "./actions";

export function LoginForm() {
  const [error, action, pending] = useActionState(login, null);

  return (
    <form action={action} className="paper rounded-[4px] p-8 text-left">
      <h1 className="font-display text-2xl tracking-tight">Adminpanel</h1>
      <p className="mt-1.5 text-sm text-ink/70">Zugang nur für die Platzfreigabe.</p>

      <label className="label mt-6" htmlFor="password">
        Passwort
      </label>
      <input
        id="password"
        name="password"
        type="password"
        autoComplete="current-password"
        required
        autoFocus
        className="field"
        aria-invalid={Boolean(error)}
      />
      {error ? <p className="mt-2 text-sm text-[#a6321f]">{error}</p> : null}

      <button type="submit" disabled={pending} className="btn-brass mt-6 w-full">
        {pending ? "Prüfe …" : "Anmelden"}
      </button>
    </form>
  );
}
