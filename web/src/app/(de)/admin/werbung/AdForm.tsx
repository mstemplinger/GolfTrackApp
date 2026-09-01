"use client";

import { useActionState, useState } from "react";
import type { AdRecord } from "@/lib/ads";
import { createAdAction, saveAdAction } from "./actions";

export interface CourseOption {
  slug: string;
  name: string;
  location: string;
}

/**
 * Anlegen und Bearbeiten einer Anzeige – dieselbe Maske für beides.
 * Rechts daneben steht die Vorschau: der Platz im Banner ist knapp, das soll
 * man beim Tippen sehen und nicht erst auf dem Gerät.
 */
export function AdForm({ ad, courses }: { ad?: AdRecord; courses: CourseOption[] }) {
  const [message, action, pending] = useActionState(ad ? saveAdAction : createAdAction, null);

  const [title, setTitle] = useState(ad?.title ?? "");
  const [subtitle, setSubtitle] = useState(ad?.subtitle ?? "");
  const [imageURL, setImageURL] = useState(ad?.imageURL ?? "");
  const [courseSlug, setCourseSlug] = useState(ad?.courseSlug ?? "");

  return (
    <div className="mt-8 grid gap-8 lg:grid-cols-[minmax(0,1fr)_18rem]">
      <form action={action} className="paper rounded-[4px] p-6 sm:p-8">
        {ad ? <input type="hidden" name="id" value={ad.id} /> : null}
        <input type="hidden" name="placement" value="minigolf_scoring" />

        <h2 className="font-display text-xl tracking-tight">
          {ad ? "Anzeige bearbeiten" : "Neue Anzeige"}
        </h2>

        <div className="mt-6 grid gap-4 sm:grid-cols-2">
          <div>
            <label className="label" htmlFor="status">
              Zustand
            </label>
            <select id="status" name="status" defaultValue={ad?.status ?? "draft"} className="field">
              <option value="draft">Entwurf – wird nicht ausgeliefert</option>
              <option value="active">Aktiv – läuft in der App</option>
              <option value="paused">Pausiert</option>
            </select>
          </div>

          <div>
            <label className="label" htmlFor="courseSlug">
              Anlage
            </label>
            <select
              id="courseSlug"
              name="courseSlug"
              value={courseSlug}
              onChange={(event) => setCourseSlug(event.target.value)}
              className="field"
            >
              <option value="">Überall (alle Anlagen)</option>
              {courses.map((course) => (
                <option key={course.slug} value={course.slug}>
                  {course.name}
                  {course.location ? ` · ${course.location}` : ""}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="mt-6 grid gap-4">
          <Field
            label="Überschrift (max. 40 Zeichen)"
            name="title"
            value={title}
            onChange={setTitle}
            maxLength={40}
            required
          />
          <Field
            label="Zeile darunter (max. 80 Zeichen)"
            name="subtitle"
            value={subtitle}
            onChange={setSubtitle}
            maxLength={80}
          />
        </div>

        <div className="mt-6 grid gap-4 sm:grid-cols-2">
          <Field label="Bild (https://…, quadratisch)" name="imageURL" value={imageURL} onChange={setImageURL} />
          <Field label="Ziel beim Antippen (https://…)" name="linkURL" defaultValue={ad?.linkURL ?? ""} />
          <Field label="Wer wirbt" name="advertiser" defaultValue={ad?.advertiser ?? ""} />
          <Field
            label="Gewicht (1–100, häufigere Anzeige)"
            name="weight"
            type="number"
            defaultValue={String(ad?.weight ?? 1)}
            mono
          />
          <Field label="Läuft ab" name="startsOn" type="date" defaultValue={ad?.startsOn ?? ""} mono />
          <Field label="Läuft bis" name="endsOn" type="date" defaultValue={ad?.endsOn ?? ""} mono />
        </div>

        <div className="mt-6">
          <label className="label" htmlFor="adminNotes">
            Interne Notiz (Preis, Ansprechpartner, Rechnung)
          </label>
          <textarea
            id="adminNotes"
            name="adminNotes"
            rows={3}
            defaultValue={ad?.adminNotes ?? ""}
            className="field"
          />
        </div>

        <div className="mt-8 flex flex-wrap items-center gap-4">
          <button type="submit" disabled={pending} className="btn-brass !py-2.5 text-sm">
            {pending ? "Speichert …" : ad ? "Speichern" : "Anlegen"}
          </button>
          {message ? <p className="text-sm text-cream/75">{message}</p> : null}
        </div>
      </form>

      <Preview title={title} subtitle={subtitle} imageURL={imageURL} everywhere={courseSlug === ""} />
    </div>
  );
}

/**
 * Nachbau des Banners aus der App: dunkle Karte, goldene Kante, links das
 * Bild. Bewusst mit denselben Farben wie `AppTheme` in der iOS-App.
 */
function Preview({
  title,
  subtitle,
  imageURL,
  everywhere,
}: {
  title: string;
  subtitle: string;
  imageURL: string;
  everywhere: boolean;
}) {
  return (
    <aside className="lg:sticky lg:top-8 lg:self-start">
      <h2 className="marginal">Vorschau</h2>
      <div className="mt-3 rounded-[4px] bg-[#0E2718] p-4">
        <div className="flex items-center gap-3 rounded-xl bg-[#163421] p-3">
          {imageURL ? (
            // eslint-disable-next-line @next/next/no-img-element -- fremde Adresse, absichtlich ohne Optimierung
            <img
              src={imageURL}
              alt=""
              className="size-11 shrink-0 rounded-lg object-cover"
              onError={(event) => {
                event.currentTarget.style.visibility = "hidden";
              }}
            />
          ) : (
            <span className="grid size-11 shrink-0 place-items-center rounded-lg bg-[#1C4129] text-[#C9A035]">
              ★
            </span>
          )}
          <span className="min-w-0 flex-1">
            <span className="flex items-center gap-1.5">
              <span className="rounded-[3px] bg-white/10 px-1.5 py-px font-mono text-[0.55rem] uppercase tracking-[0.12em] text-white/55">
                Anzeige
              </span>
            </span>
            <span className="mt-0.5 block truncate text-sm font-semibold text-white">
              {title || "Überschrift"}
            </span>
            <span className="block truncate text-xs text-white/60">
              {subtitle || "Zeile darunter"}
            </span>
          </span>
          <span className="text-white/30">›</span>
        </div>
      </div>
      <p className="mt-3 text-xs leading-relaxed text-cream/60">
        {everywhere
          ? "Läuft auf allen Anlagen – nur wenn dort keine eigene Anzeige gebucht ist."
          : "Läuft nur auf der gewählten Anlage und hat dort Vorrang vor allgemeinen Anzeigen."}
      </p>
    </aside>
  );
}

function Field({
  label,
  name,
  value,
  defaultValue,
  onChange,
  type = "text",
  required,
  mono,
  maxLength,
}: {
  label: string;
  name: string;
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  type?: string;
  required?: boolean;
  mono?: boolean;
  maxLength?: number;
}) {
  return (
    <div>
      <label className="label" htmlFor={name}>
        {label}
      </label>
      <input
        id={name}
        name={name}
        type={type}
        value={value}
        defaultValue={defaultValue}
        required={required}
        maxLength={maxLength}
        onChange={onChange ? (event) => onChange(event.target.value) : undefined}
        className={`field ${mono ? "font-mono" : ""}`}
      />
    </div>
  );
}
