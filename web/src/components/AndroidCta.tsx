"use client";

import { useState } from "react";
import { APK_URL, PLAY_STORE_LIVE, PLAY_STORE_URL } from "@/lib/android";

/**
 * Android-Einstieg: APK direkt laden, dazu Google Play – solange die App dort
 * noch nicht steht, mit Erinnerung per Mail. Die Erinnerung ist ein
 * Double-Opt-in: erst nach Eingabe des Codes aus der Mail ist die Adresse
 * eingetragen (siehe `lib/waitlist.ts`).
 */

const COPY = {
  de: {
    apk: "APK für Android",
    play: "Google Play",
    playSoon: "Bald bei Google Play",
    remind: "Erinnere mich",
    remindLead: "Wir schicken dir einmalig eine Mail, sobald GolfTrack im Play Store steht.",
    email: "E-Mail-Adresse",
    sendCode: "Code senden",
    codeLead: (email: string) => `Wir haben dir einen sechsstelligen Code an ${email} geschickt.`,
    code: "Bestätigungscode",
    confirm: "Bestätigen",
    otherEmail: "Andere Adresse",
    resend: "Code erneut senden",
    done: "Bestätigt! Du bekommst eine Mail, sobald die App im Play Store ist.",
    already: "Diese Adresse ist schon eingetragen – du bekommst Bescheid.",
    errors: {
      invalid_email: "Bitte prüf die E-Mail-Adresse.",
      rate_limited: "Zu viele Versuche. Bitte später noch einmal.",
      too_many_codes: "Für diese Adresse wurden schon mehrere Codes verschickt. Schau in dein Postfach (auch Spam).",
      mail_unavailable: "Der Mailversand ist gerade nicht eingerichtet. Bitte später noch einmal.",
      send_failed: "Die Mail ließ sich nicht verschicken. Bitte später noch einmal.",
      wrong: "Der Code stimmt nicht.",
      expired: "Der Code ist abgelaufen. Lass dir einen neuen schicken.",
      locked: "Zu viele falsche Versuche. Lass dir einen neuen Code schicken.",
      unknown: "Bitte fordere zuerst einen Code an.",
      network: "Keine Verbindung. Bitte noch einmal versuchen.",
    } as Record<string, string>,
  },
  en: {
    apk: "APK for Android",
    play: "Google Play",
    playSoon: "Coming to Google Play",
    remind: "Remind me",
    remindLead: "We'll email you once when GolfTrack is on Google Play.",
    email: "Email address",
    sendCode: "Send code",
    codeLead: (email: string) => `We've sent a six-digit code to ${email}.`,
    code: "Confirmation code",
    confirm: "Confirm",
    otherEmail: "Different address",
    resend: "Resend code",
    done: "Confirmed! You'll get an email once the app is on Google Play.",
    already: "This address is already registered – we'll let you know.",
    errors: {
      invalid_email: "Please check the email address.",
      rate_limited: "Too many attempts. Please try again later.",
      too_many_codes: "Several codes have already been sent to this address. Check your inbox (and spam).",
      mail_unavailable: "Email sending isn't set up right now. Please try again later.",
      send_failed: "The email couldn't be sent. Please try again later.",
      wrong: "That code isn't right.",
      expired: "The code has expired. Request a new one.",
      locked: "Too many wrong attempts. Request a new code.",
      unknown: "Please request a code first.",
      network: "No connection. Please try again.",
    } as Record<string, string>,
  },
} as const;

type Step = "closed" | "email" | "code" | "done";

export function AndroidCta({
  lang,
  align = "start",
  showApk = true,
}: {
  lang: "de" | "en";
  align?: "start" | "center";
  /** Auf der Android-Seite steht der große Download-Knopf schon daneben. */
  showApk?: boolean;
}) {
  const c = COPY[lang];
  const [step, setStep] = useState<Step>("closed");
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [trap, setTrap] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [note, setNote] = useState<string | null>(null);

  async function post(url: string, body: object): Promise<{ ok?: boolean; status?: string; error?: string }> {
    try {
      const res = await fetch(url, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body) });
      return await res.json();
    } catch {
      return { error: "network" };
    }
  }

  async function sendCode() {
    setBusy(true);
    setError(null);
    const r = await post("/api/android/waitlist", { email, lang, website: trap });
    setBusy(false);
    if (r.error) return setError(c.errors[r.error] ?? c.errors.send_failed);
    if (r.status === "already_confirmed") {
      setNote(c.already);
      return setStep("done");
    }
    setCode("");
    setStep("code");
  }

  async function confirm() {
    setBusy(true);
    setError(null);
    const r = await post("/api/android/waitlist/confirm", { email, code });
    setBusy(false);
    if (r.error) return setError(c.errors[r.error] ?? c.errors.wrong);
    setNote(c.done);
    setStep("done");
  }

  const justify = align === "center" ? "justify-center" : "";
  const input =
    "min-h-[44px] flex-1 rounded-full border border-cream/25 bg-white/5 px-5 text-cream placeholder:text-muted/70 focus:border-brass focus:outline-none";
  const pill =
    "tap justify-center gap-2 rounded-full border border-cream/25 px-5 font-semibold text-cream hover:border-brass hover:text-brass";

  return (
    <div className={`flex w-full flex-col gap-3 ${align === "center" ? "items-center" : "items-start"}`}>
      <div className={`flex w-full flex-col items-stretch gap-3 sm:w-auto sm:flex-row ${justify}`}>
        {APK_URL && showApk ? (
          <a href={lang === "de" ? "/android" : "/en/android"} className={`${pill} whitespace-nowrap`}>
            <AndroidMark />
            {c.apk}
          </a>
        ) : null}
        {PLAY_STORE_LIVE ? (
          <a href={PLAY_STORE_URL} target="_blank" rel="noreferrer" className={pill}>
            <PlayMark />
            {c.play}
          </a>
        ) : (
          <button
            type="button"
            onClick={() => setStep(step === "closed" ? "email" : "closed")}
            aria-expanded={step !== "closed"}
            className={pill}
          >
            <PlayMark />
            <span>
              {c.playSoon} · <span className="text-brass">{c.remind}</span>
            </span>
          </button>
        )}
      </div>

      {step !== "closed" && !PLAY_STORE_LIVE ? (
        <div className={`w-full max-w-md rounded-2xl border border-cream/15 bg-black/25 p-4 text-left text-sm ${align === "center" ? "mx-auto" : ""}`}>
          {step === "email" ? (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                void sendCode();
              }}
              className="flex flex-col gap-3"
            >
              <p className="text-cream/70">{c.remindLead}</p>
              {/* Honigtopf für Bots */}
              <input
                tabIndex={-1}
                autoComplete="off"
                aria-hidden
                className="hidden"
                name="website"
                value={trap}
                onChange={(e) => setTrap(e.target.value)}
              />
              <div className="flex flex-col gap-2 sm:flex-row">
                <label className="sr-only" htmlFor="android-email">{c.email}</label>
                <input
                  id="android-email"
                  type="email"
                  required
                  autoComplete="email"
                  placeholder={c.email}
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className={input}
                />
                <button type="submit" disabled={busy} className="btn-brass min-h-11 !py-2">
                  {c.sendCode}
                </button>
              </div>
            </form>
          ) : null}

          {step === "code" ? (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                void confirm();
              }}
              className="flex flex-col gap-3"
            >
              <p className="text-cream/70">{c.codeLead(email)}</p>
              <div className="flex flex-col gap-2 sm:flex-row">
                <label className="sr-only" htmlFor="android-code">{c.code}</label>
                <input
                  id="android-code"
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  pattern="\d{6}"
                  maxLength={6}
                  required
                  placeholder="123456"
                  value={code}
                  onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))}
                  className={`${input} font-mono tracking-[0.4em]`}
                />
                <button type="submit" disabled={busy || code.length !== 6} className="btn-brass min-h-11 !py-2">
                  {c.confirm}
                </button>
              </div>
              <div className="flex gap-4 text-xs text-cream/60">
                <button type="button" className="underline underline-offset-4 hover:text-brass" onClick={() => void sendCode()} disabled={busy}>
                  {c.resend}
                </button>
                <button type="button" className="underline underline-offset-4 hover:text-brass" onClick={() => setStep("email")}>
                  {c.otherEmail}
                </button>
              </div>
            </form>
          ) : null}

          {step === "done" ? <p className="text-brass">{note}</p> : null}
          {error ? <p className="mt-3 text-[#ff8a7a]" role="alert">{error}</p> : null}
        </div>
      ) : null}
    </div>
  );
}

function AndroidMark() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden className="h-4 w-4" fill="currentColor">
      <path d="M17.6 9.48l1.84-3.18a.38.38 0 0 0-.66-.38l-1.86 3.22A11.4 11.4 0 0 0 12 8.2c-1.77 0-3.43.35-4.92.94L5.22 5.92a.38.38 0 1 0-.66.38L6.4 9.48A10.8 10.8 0 0 0 1 18h22a10.8 10.8 0 0 0-5.4-8.52zM7 15.25a1.25 1.25 0 1 1 0-2.5 1.25 1.25 0 0 1 0 2.5zm10 0a1.25 1.25 0 1 1 0-2.5 1.25 1.25 0 0 1 0 2.5z" />
    </svg>
  );
}

function PlayMark() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden className="h-4 w-4" fill="currentColor">
      <path d="M4 2.8v18.4c0 .5.5.8.9.6L21 12.6a.7.7 0 0 0 0-1.2L4.9 2.2c-.4-.2-.9.1-.9.6z" />
    </svg>
  );
}
