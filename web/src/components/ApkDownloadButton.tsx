"use client";

import { useEffect, useState } from "react";
import { AndroidCta } from "@/components/AndroidCta";

const COPY = {
  de: {
    title: "Download läuft …",
    lead: "Die APK aktualisiert sich nicht von selbst. Sollen wir dir Bescheid geben, wenn es eine neue Version gibt?",
    no: "Nein, danke",
  },
  en: {
    title: "Downloading …",
    lead: "The APK doesn't update itself. Shall we let you know when there's a new version?",
    no: "No, thanks",
  },
} as const;

/** Wer schon eingetragen ist oder abgelehnt hat, bekommt das Fenster nicht noch einmal. */
const ASKED_KEY = "golftrack.android.asked";
const SUBSCRIBED_KEY = "golftrack.android.subscribed";

function shouldAsk(): boolean {
  try {
    return !localStorage.getItem(SUBSCRIBED_KEY) && !localStorage.getItem(ASKED_KEY);
  } catch {
    return true;
  }
}

/**
 * Download-Knopf der Android-Seite. Der Download startet sofort; kurz danach
 * fragt ein Fenster, ob man bei neuen Versionen eine Mail bekommen will – mit
 * demselben Double-Opt-in-Formular wie auf der Seite.
 */
export function ApkDownloadButton({ href, label, lang }: { href: string; label: string; lang: "de" | "en" }) {
  const c = COPY[lang];
  const [open, setOpen] = useState(false);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && dismiss();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  function dismiss() {
    try {
      localStorage.setItem(ASKED_KEY, "1");
    } catch {
      /* egal */
    }
    setOpen(false);
  }

  return (
    <>
      <a
        href={href}
        download
        className="btn-brass w-full"
        onClick={() => {
          // Nicht verhindern – der Download soll in jedem Fall starten.
          if (shouldAsk()) setTimeout(() => setOpen(true), 400);
        }}
      >
        {label}
      </a>

      {open ? (
        <div
          className="fixed inset-0 z-[100] flex items-end justify-center bg-black/70 p-4 backdrop-blur-sm sm:items-center"
          onClick={(e) => e.target === e.currentTarget && dismiss()}
        >
          <div
            role="dialog"
            aria-modal="true"
            aria-labelledby="apk-dialog-title"
            className="relative w-full max-w-md rounded-2xl border border-brass/40 bg-[#0e2718] p-6 shadow-[0_30px_80px_-20px_rgba(0,0,0,0.9)]"
          >
            <h2 id="apk-dialog-title" className="font-display text-2xl font-bold tracking-tight">
              {c.title}
            </h2>
            <p className="mt-2 leading-relaxed text-cream/75">{c.lead}</p>
            <div className="mt-4">
              <AndroidCta lang={lang} embedded focus="updates" />
            </div>
            <button
              type="button"
              onClick={dismiss}
              className="mt-4 w-full text-center text-sm text-cream/55 underline underline-offset-4 hover:text-brass"
            >
              {c.no}
            </button>
          </div>
        </div>
      ) : null}
    </>
  );
}
