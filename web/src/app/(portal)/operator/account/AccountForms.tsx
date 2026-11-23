"use client";

import { useRouter } from "next/navigation";
import { useActionState, useEffect, useState } from "react";
import { MIN_OPERATOR_PASSWORD, operatorCopy, type AccountCopy, type OperatorLang } from "@/i18n/operator";
import { changePassword, requestCourseName, updateProfile, withdrawCourseName, type AccountState } from "../actions";

const field =
  "w-full rounded-lg border border-white/10 bg-white/[0.04] px-4 py-2.5 text-sm text-cream placeholder:text-cream/35 focus:border-brass/60 focus:outline-none";
const button =
  "rounded-lg bg-brass px-5 py-2.5 text-sm font-semibold text-night transition-colors hover:bg-brass-soft disabled:opacity-60";

/** Meldung zu einem Schlüssel aus AccountCopy. */
function Message({ state, t }: { state: AccountState; t: AccountCopy }) {
  if (!state.message) return null;
  const raw = t[state.message as keyof AccountCopy];
  const text = typeof raw === "function" ? (raw as (n: number) => string)(MIN_OPERATOR_PASSWORD) : String(raw ?? "");
  return (
    <span role="status" className={`text-sm ${state.status === "ok" ? "text-[#7fd19b]" : "text-[#e07a63]"}`}>
      {state.status === "ok" ? "✓ " : ""}
      {text}
    </span>
  );
}

export function ProfileForm({ lang, name, email }: { lang: OperatorLang; name: string; email: string }) {
  const t = operatorCopy(lang).account;
  const [state, action, pending] = useActionState<AccountState, FormData>(updateProfile, {});
  const router = useRouter();
  // Beide Felder kontrolliert: React setzt Formulare nach einer Aktion auf
  // ihre Ausgangswerte zurück – sonst stünde nach dem Speichern wieder der
  // alte Name da (und ginge beim nächsten Speichern zurück in die Datenbank).
  const [currentName, setCurrentName] = useState(name);
  const [currentEmail, setCurrentEmail] = useState(email);
  // Gespeichert: Seite neu laden, damit Kopfzeile und Ausgangswerte stimmen.
  useEffect(() => {
    if (state.status === "ok") router.refresh();
  }, [state, router]);
  const emailChanged = currentEmail.trim().toLowerCase() !== email;

  return (
    <form action={action} className="space-y-4">
      <label className="block">
        <span className="mb-1.5 block text-sm text-cream/70">{t.name}</span>
        <input
          name="name"
          required
          maxLength={120}
          value={currentName}
          onChange={(e) => setCurrentName(e.target.value)}
          className={field}
        />
        <span className="mt-1 block text-xs text-cream/45">{t.nameHint}</span>
      </label>
      <label className="block">
        <span className="mb-1.5 block text-sm text-cream/70">{t.email}</span>
        <input
          name="email"
          type="email"
          required
          autoComplete="username"
          value={currentEmail}
          onChange={(e) => setCurrentEmail(e.target.value)}
          className={field}
        />
        <span className="mt-1 block text-xs text-cream/45">{t.emailHint}</span>
      </label>
      {emailChanged ? (
        <label className="block">
          <span className="mb-1.5 block text-sm text-cream/70">{t.currentPassword}</span>
          <input name="currentPassword" type="password" required autoComplete="current-password" className={field} />
          <span className="mt-1 block text-xs text-cream/45">{t.currentPasswordHint}</span>
        </label>
      ) : null}
      <div className="flex flex-wrap items-center gap-4">
        <button type="submit" disabled={pending} className={button}>
          {pending ? t.saving : t.save}
        </button>
        <Message state={state} t={t} />
      </div>
    </form>
  );
}

export function PasswordForm({ lang }: { lang: OperatorLang }) {
  const t = operatorCopy(lang).account;
  const [state, action, pending] = useActionState<AccountState, FormData>(changePassword, {});
  return (
    <form action={action} className="space-y-4">
      <label className="block">
        <span className="mb-1.5 block text-sm text-cream/70">{t.currentPassword}</span>
        <input name="currentPassword" type="password" required autoComplete="current-password" className={field} />
      </label>
      <label className="block">
        <span className="mb-1.5 block text-sm text-cream/70">{t.newPassword}</span>
        <input
          name="newPassword"
          type="password"
          required
          minLength={MIN_OPERATOR_PASSWORD}
          autoComplete="new-password"
          className={field}
        />
        <span className="mt-1 block text-xs text-cream/45">{t.newPasswordHint(MIN_OPERATOR_PASSWORD)}</span>
      </label>
      <label className="block">
        <span className="mb-1.5 block text-sm text-cream/70">{t.repeatPassword}</span>
        <input
          name="repeatPassword"
          type="password"
          required
          minLength={MIN_OPERATOR_PASSWORD}
          autoComplete="new-password"
          className={field}
        />
      </label>
      <div className="flex flex-wrap items-center gap-4">
        <button type="submit" disabled={pending} className={button}>
          {pending ? t.saving : t.changePassword}
        </button>
        <Message state={state} t={t} />
      </div>
    </form>
  );
}

export function CourseNameForm({
  lang,
  slug,
  name,
  kindLabel,
  pending,
}: {
  lang: OperatorLang;
  slug: string;
  name: string;
  kindLabel: string;
  /** Offener Wunsch für diesen Platz. */
  pending: { id: string; requestedName: string; since: string } | null;
}) {
  const t = operatorCopy(lang).account;
  const [state, action, busy] = useActionState<AccountState, FormData>(requestCourseName, {});
  const [withdrawing, setWithdrawing] = useState(false);
  const shownPending = state.status === "ok" ? null : pending;

  return (
    <div className="rounded-xl border border-white/10 bg-white/[0.02] p-4">
      <span className="text-xs uppercase tracking-[0.14em] text-cream/45">{kindLabel}</span>
      <form action={action} className="mt-2 flex flex-col gap-3 sm:flex-row sm:items-end">
        <input type="hidden" name="slug" value={slug} />
        <label className="block flex-1">
          <span className="sr-only">{t.courseName}</span>
          <input name="name" required maxLength={120} defaultValue={name} className={field} />
        </label>
        <button type="submit" disabled={busy} className={`${button} shrink-0`}>
          {busy ? t.saving : t.requestChange}
        </button>
      </form>
      <div className="mt-2 min-h-5">
        {state.message ? (
          <Message state={state} t={t} />
        ) : shownPending ? (
          <form
            action={async (fd) => {
              setWithdrawing(true);
              await withdrawCourseName(fd);
              window.location.reload();
            }}
            className="flex flex-wrap items-center gap-2 text-sm text-[#e0c583]"
          >
            <input type="hidden" name="id" value={shownPending.id} />
            <span>
              {t.pendingSince(shownPending.since)} <strong>„{shownPending.requestedName}“</strong>
            </span>
            <button
              type="submit"
              disabled={withdrawing}
              className="text-cream/60 underline underline-offset-4 hover:text-cream"
            >
              {t.withdraw}
            </button>
          </form>
        ) : null}
      </div>
    </div>
  );
}
