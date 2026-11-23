"use client";

import { useRef, useState, type FormEvent } from "react";

export type ReportCopy = {
  button: string;
  title: string;
  lead: string;
  category: string;
  categories: Record<"name" | "holes" | "rating" | "location" | "closed" | "other", string>;
  message: string;
  messagePlaceholder: string;
  role: string;
  roles: Record<"owner" | "player" | "other", string>;
  name: string;
  email: string;
  emailHint: string;
  send: string;
  sending: string;
  cancel: string;
  close: string;
  thanks: string;
  errorShort: string;
  errorRate: string;
  errorGeneric: string;
};

type State = "idle" | "sending" | "done" | "error";

/**
 * Knopf „Fehler melden“ mit Formular im Dialog. Schickt an /api/course-reports;
 * die Meldung landet per Mail beim Betreiber von golftrack.app.
 */
export function ReportCourseButton({
  slug,
  courseName,
  copy,
  className,
}: {
  slug: string;
  courseName: string;
  copy: ReportCopy;
  className?: string;
}) {
  const dialog = useRef<HTMLDialogElement>(null);
  const [state, setState] = useState<State>("idle");
  const [error, setError] = useState("");

  function open() {
    setState("idle");
    setError("");
    dialog.current?.showModal();
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const message = String(form.get("message") ?? "").trim();
    if (message.length < 10) {
      setError(copy.errorShort);
      return;
    }
    setState("sending");
    setError("");
    try {
      const response = await fetch("/api/course-reports", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          slug,
          category: form.get("category"),
          message,
          role: form.get("role"),
          name: String(form.get("name") ?? "").trim(),
          email: String(form.get("email") ?? "").trim(),
          company: String(form.get("company") ?? ""),
        }),
      });
      if (response.ok) {
        setState("done");
        return;
      }
      setState("error");
      setError(response.status === 429 ? copy.errorRate : copy.errorGeneric);
    } catch {
      setState("error");
      setError(copy.errorGeneric);
    }
  }

  const field =
    "mt-1.5 w-full rounded-sm border border-cream/25 bg-white/5 px-3 py-2.5 text-cream placeholder:text-muted/70 focus:border-brass focus:outline-none";

  return (
    <>
      <button
        type="button"
        onClick={open}
        className={className ?? "tap text-xs text-cream/55 underline underline-offset-4 hover:text-brass"}
      >
        {copy.button}
      </button>
      <dialog
        ref={dialog}
        className="m-auto w-[min(32rem,calc(100vw-2rem))] rounded-sm border rule bg-night p-0 text-left text-cream backdrop:bg-black/70"
        onClick={(event) => {
          if (event.target === dialog.current) dialog.current?.close();
        }}
      >
        <div className="p-6 sm:p-7">
          <p className="marginal">{copy.title}</p>
          <h2 className="mt-2 font-display text-2xl leading-snug tracking-tight">{courseName}</h2>

          {state === "done" ? (
            <>
              <p className="mt-5 leading-relaxed text-cream/80">{copy.thanks}</p>
              <button type="button" className="btn-brass mt-6" onClick={() => dialog.current?.close()}>
                {copy.close}
              </button>
            </>
          ) : (
            <form onSubmit={submit} className="mt-4 space-y-4 text-sm">
              <p className="leading-relaxed text-cream/65">{copy.lead}</p>
              <label className="block">
                <span className="text-cream/80">{copy.category}</span>
                <select name="category" defaultValue="holes" className={field}>
                  {Object.entries(copy.categories).map(([value, label]) => (
                    <option key={value} value={value} className="bg-night">
                      {label}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block">
                <span className="text-cream/80">{copy.message}</span>
                <textarea
                  name="message"
                  required
                  minLength={10}
                  maxLength={3000}
                  rows={5}
                  placeholder={copy.messagePlaceholder}
                  className={field}
                />
              </label>
              <label className="block">
                <span className="text-cream/80">{copy.role}</span>
                <select name="role" defaultValue="player" className={field}>
                  {Object.entries(copy.roles).map(([value, label]) => (
                    <option key={value} value={value} className="bg-night">
                      {label}
                    </option>
                  ))}
                </select>
              </label>
              <div className="grid gap-4 sm:grid-cols-2">
                <label className="block">
                  <span className="text-cream/80">{copy.name}</span>
                  <input name="name" maxLength={120} autoComplete="name" className={field} />
                </label>
                <label className="block">
                  <span className="text-cream/80">{copy.email}</span>
                  <input name="email" type="email" maxLength={200} autoComplete="email" className={field} />
                </label>
              </div>
              <p className="text-xs text-cream/50">{copy.emailHint}</p>
              {/* Honigtopf */}
              <input name="company" tabIndex={-1} autoComplete="off" aria-hidden="true" className="hidden" />
              {error ? (
                <p role="alert" className="text-sm text-red-300">
                  {error}
                </p>
              ) : null}
              <div className="flex flex-wrap gap-3 pt-1">
                <button type="submit" className="btn-brass" disabled={state === "sending"}>
                  {state === "sending" ? copy.sending : copy.send}
                </button>
                <button type="button" className="btn-ghost" onClick={() => dialog.current?.close()}>
                  {copy.cancel}
                </button>
              </div>
            </form>
          )}
        </div>
      </dialog>
    </>
  );
}
