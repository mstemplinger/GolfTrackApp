"use client";

import { useActionState, useState } from "react";
import type { CourseRecord } from "@/lib/courses";
import { save } from "../actions";

/** Bearbeiten der eingereichten Werte – dieselbe Struktur wie im Formular. */
export function EditForm({ course }: { course: CourseRecord }) {
  const [message, action, pending] = useActionState(save, null);
  const [holes, setHoles] = useState(course.holes);
  const isGolf = course.kind === "golf";

  const holeAt = (index: number) => course.holeData.find((hole) => hole.number === index + 1);

  return (
    <form action={action} className="paper mt-10 rounded-[4px] p-6 sm:p-8">
      <input type="hidden" name="id" value={course.id} />
      <h2 className="font-display text-xl tracking-tight">Angaben bearbeiten</h2>

      <div className="mt-6 grid gap-4 sm:grid-cols-2">
        <Field label="Name" name="name" defaultValue={course.name} required />
        <Field label="Ort" name="location" defaultValue={course.location} />
        <Field label="Kennung (slug)" name="slug" defaultValue={course.slug} mono />
        <Field label="Land" name="country" defaultValue={course.country} />
        <Field
          label={isGolf ? "Löcher" : "Bahnen"}
          name="holes"
          defaultValue={String(course.holes)}
          type="number"
          onChange={(value) => setHoles(Math.min(36, Math.max(1, Number(value) || 1)))}
        />
        <div className="grid grid-cols-2 gap-3">
          <Field label="Breite" name="latitude" defaultValue={course.latitude?.toString() ?? ""} mono />
          <Field label="Länge" name="longitude" defaultValue={course.longitude?.toString() ?? ""} mono />
        </div>
        {isGolf ? (
          <>
            <Field
              label="Course Rating"
              name="courseRating"
              defaultValue={course.courseRating?.toString() ?? ""}
              mono
            />
            <Field
              label="Slope Rating"
              name="slopeRating"
              defaultValue={course.slopeRating?.toString() ?? ""}
              mono
            />
          </>
        ) : null}
      </div>

      <div className="mt-6 grid gap-4">
        <TextArea label="Platzinfos" name="facilityNotes" defaultValue={course.facilityNotes} />
        <TextArea label="Begrüßung" name="welcome" defaultValue={course.welcome} rows={2} />
      </div>

      <div className="mt-6 grid gap-4 sm:grid-cols-3">
        <Field label="Website" name="website" defaultValue={course.website} />
        <Field label="Telefon" name="phone" defaultValue={course.phone} />
        <Field label="E-Mail" name="publicEmail" defaultValue={course.publicEmail} />
      </div>

      {/* Lochwerte */}
      <div className="mt-8 border-t border-ink/15 pt-6">
        <h3 className="label">{isGolf ? "Löcher" : "Bahnen"}</h3>
        <div className="mt-2 overflow-x-auto">
          <table className="w-full min-w-[34rem] border-collapse">
            <thead>
              <tr className="font-mono text-[0.6rem] uppercase tracking-[0.16em] text-ink/65">
                <th scope="col" className="w-10 pb-2 text-left font-normal">
                  #
                </th>
                <th scope="col" className="pb-2 text-left font-normal">
                  Par
                </th>
                <th scope="col" className="pb-2 text-left font-normal">
                  HCP
                </th>
                <th scope="col" className="pb-2 text-left font-normal">
                  Länge
                </th>
                <th scope="col" className="pb-2 text-left font-normal">
                  Abschlag lat / lon
                </th>
                <th scope="col" className="pb-2 text-left font-normal">
                  Fahne lat / lon
                </th>
              </tr>
            </thead>
            <tbody>
              {Array.from({ length: holes }, (_, index) => {
                const hole = holeAt(index);
                return (
                  <tr key={index} className="border-t border-ink/10">
                    <th scope="row" className="py-1 pr-2 text-left font-mono text-sm font-normal text-ink/70">
                      {index + 1}
                    </th>
                    <Cell name={`par-${index}`} defaultValue={hole?.par} width="w-14" />
                    <Cell name={`hcp-${index}`} defaultValue={hole?.hcp} width="w-14" />
                    <Cell name={`length-${index}`} defaultValue={hole?.length} width="w-20" />
                    <td className="py-1 pr-2">
                      <div className="flex gap-1">
                        <Input name={`teeLat-${index}`} defaultValue={hole?.teeLat} />
                        <Input name={`teeLon-${index}`} defaultValue={hole?.teeLon} />
                      </div>
                    </td>
                    <td className="py-1">
                      <div className="flex gap-1">
                        <Input name={`flagLat-${index}`} defaultValue={hole?.flagLat} />
                        <Input name={`flagLon-${index}`} defaultValue={hole?.flagLon} />
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      <div className="mt-8 border-t border-ink/15 pt-6">
        <TextArea label="Interne Notiz" name="adminNotes" defaultValue={course.adminNotes} rows={2} />
      </div>

      <div className="mt-6 flex flex-wrap items-center gap-4">
        <button type="submit" disabled={pending} className="btn-brass !py-2.5 text-sm">
          {pending ? "Speichere …" : "Speichern"}
        </button>
        {message ? (
          <p className={`text-sm ${message === "Gespeichert." ? "text-fairway" : "text-[#a6321f]"}`}>{message}</p>
        ) : null}
      </div>
    </form>
  );
}

function Field({
  label,
  name,
  defaultValue,
  type = "text",
  required,
  mono,
  onChange,
}: {
  label: string;
  name: string;
  defaultValue?: string;
  type?: string;
  required?: boolean;
  mono?: boolean;
  onChange?: (value: string) => void;
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
        defaultValue={defaultValue}
        required={required}
        onChange={onChange ? (event) => onChange(event.target.value) : undefined}
        className={`field ${mono ? "font-mono" : ""}`}
      />
    </div>
  );
}

function TextArea({
  label,
  name,
  defaultValue,
  rows = 3,
}: {
  label: string;
  name: string;
  defaultValue?: string;
  rows?: number;
}) {
  return (
    <div>
      <label className="label" htmlFor={name}>
        {label}
      </label>
      <textarea id={name} name={name} rows={rows} defaultValue={defaultValue} className="field" />
    </div>
  );
}

function Cell({
  name,
  defaultValue,
  width,
}: {
  name: string;
  defaultValue?: number | null;
  width: string;
}) {
  return (
    <td className="py-1 pr-2">
      <input
        name={name}
        defaultValue={defaultValue ?? ""}
        aria-label={name}
        className={`field !py-1 font-mono !text-sm ${width}`}
      />
    </td>
  );
}

function Input({ name, defaultValue }: { name: string; defaultValue?: number | null }) {
  return (
    <input
      name={name}
      defaultValue={defaultValue ?? ""}
      aria-label={name}
      className="field !py-1 !text-xs w-24 font-mono"
    />
  );
}
