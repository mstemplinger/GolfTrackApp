"use client";

import { useActionState } from "react";
import { resetPassword, type SaveState } from "./actions";
import { PasswordNotice } from "./PasswordNotice";

/** Neues Zufallspasswort – beendet alle bestehenden Anmeldungen des Kontos. */
export function ResetPasswordForm({ id, email, portalUrl }: { id: string; email: string; portalUrl: string }) {
  const [state, action, pending] = useActionState<SaveState, FormData>(resetPassword, { status: "idle" });

  if (state.status === "ok" && state.password) {
    return (
      <PasswordNotice email={state.email || email} password={state.password} portalUrl={portalUrl} mail={state.mail} />
    );
  }

  return (
    <form
      action={action}
      onSubmit={(e) => {
        if (!confirm("Neues Passwort erzeugen? Das bisherige gilt dann nicht mehr.")) e.preventDefault();
      }}
    >
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="email" value={email} />
      <label className="mb-3 flex items-center gap-3 text-sm">
        <input type="checkbox" name="sendMail" defaultChecked className="h-4 w-4 accent-[#c9a035]" />
        Per E-Mail an {email} senden
      </label>
      <button
        type="submit"
        disabled={pending}
        className="rounded-lg border border-white/15 px-4 py-2 text-sm transition-colors hover:border-brass/60 hover:text-brass disabled:opacity-60"
      >
        {pending ? "Erzeugt …" : "Neues Passwort erzeugen"}
      </button>
    </form>
  );
}
