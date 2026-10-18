"use client";

import { useActionState, useCallback, useMemo, useState } from "react";
import { HintsEditor } from "@/components/HintsEditor";
import { HoleCountInput } from "@/components/HoleCountInput";
import { HolePositionsMap, type HolePoint, type PointKind } from "@/components/HolePositionsMap";
import type { CourseRecord } from "@/lib/courses";
import { save } from "../actions";

/** Bearbeiten der eingereichten Werte – dieselbe Struktur wie im Formular. */
export function EditForm({ course }: { course: CourseRecord }) {
  const [message, action, pending] = useActionState(save, null);
  const [holes, setHoles] = useState(course.holes);
  const isGolf = course.kind === "golf";

  const holeAt = (index: number) => course.holeData.find((hole) => hole.number === index + 1);

  // Koordinaten als Text, damit sie sich von Hand und über die Karte setzen lassen.
  const text = (value: number | null | undefined) => (value ?? "").toString();
  const [coords, setCoords] = useState<Coords[]>(() =>
    Array.from({ length: 36 }, (_, index) => {
      const hole = holeAt(index);
      return {
        teeLat: text(hole?.teeLat),
        teeLon: text(hole?.teeLon),
        flagLat: text(hole?.flagLat),
        flagLon: text(hole?.flagLon),
      };
    }),
  );
  const [place, setPlace] = useState({
    latitude: text(course.latitude),
    longitude: text(course.longitude),
    firstTeeLat: text(course.firstTeeLat),
    firstTeeLon: text(course.firstTeeLon),
  });

  const setCoord = (index: number, key: keyof Coords, value: string) =>
    setCoords((previous) => previous.map((row, i) => (i === index ? { ...row, [key]: value } : row)));

  const setPosition = useCallback((index: number, kind: PointKind, point: HolePoint | null) => {
    const lat = point ? point.lat.toFixed(6) : "";
    const lon = point ? point.lon.toFixed(6) : "";
    setCoords((previous) =>
      previous.map((row, i) =>
        i !== index
          ? row
          : kind === "tee"
            ? { ...row, teeLat: lat, teeLon: lon }
            : { ...row, flagLat: lat, flagLon: lon },
      ),
    );
    if (point && index === 0 && kind === "tee") {
      setPlace((previous) => ({
        ...previous,
        firstTeeLat: lat,
        firstTeeLon: lon,
      }));
    }
  }, []);

  const positions = useMemo(
    () =>
      coords.slice(0, holes).map((row) => ({
        tee: toPoint(row.teeLat, row.teeLon),
        flag: toPoint(row.flagLat, row.flagLon),
      })),
    [coords, holes],
  );
  const centre = useMemo(() => toPoint(place.latitude, place.longitude), [place.latitude, place.longitude]);

  return (
    <form action={action} className="paper mt-10 rounded-[4px] p-6 sm:p-8">
      <input type="hidden" name="id" value={course.id} />
      <h2 className="font-display text-xl tracking-tight">Angaben bearbeiten</h2>

      <div className="mt-6 grid gap-4 sm:grid-cols-2">
        <Field label="Name" name="name" defaultValue={course.name} required />
        <Field label="Ort" name="location" defaultValue={course.location} />
        <Field label="Kennung (slug)" name="slug" defaultValue={course.slug} mono />
        <Field label="Land" name="country" defaultValue={course.country} />
        <div>
          <span className="label">{isGolf ? "Löcher" : "Bahnen"}</span>
          <HoleCountInput value={holes} onChange={setHoles} label={isGolf ? "Löcher" : "Bahnen"} name="holes" />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Field
            label="Breite"
            name="latitude"
            value={place.latitude}
            onChange={(value) => setPlace((p) => ({ ...p, latitude: value }))}
            mono
          />
          <Field
            label="Länge"
            name="longitude"
            value={place.longitude}
            onChange={(value) => setPlace((p) => ({ ...p, longitude: value }))}
            mono
          />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Field
            label="1. Abschlag – Breite"
            name="firstTeeLat"
            value={place.firstTeeLat}
            onChange={(value) => setPlace((p) => ({ ...p, firstTeeLat: value }))}
            mono
          />
          <Field
            label="1. Abschlag – Länge"
            name="firstTeeLon"
            value={place.firstTeeLon}
            onChange={(value) => setPlace((p) => ({ ...p, firstTeeLon: value }))}
            mono
          />
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
        <div>
          <span className="label">Hinweise für Gäste</span>
          <HintsEditor
            name="facilityHints"
            initial={course.facilityHints}
            labels={{
              add: "Hinweis hinzufügen",
              remove: "Hinweis entfernen",
              placeholder: "z. B. Unterstellhaus bei Gewitter an Bahn 5",
              kinds: {
                toilet: "Toiletten",
                shelter: "Unterstellhaus",
                drinks: "Getränke",
                food: "Gastronomie",
                rental: "Ausleihe",
                parking: "Parkplatz",
                water: "Wasserstelle",
                firstAid: "Erste Hilfe",
                info: "Sonstiges",
              },
            }}
          />
        </div>
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
        <div className="mt-2">
          <HolePositionsMap lang="de" isGolf={isGolf} positions={positions} centre={centre} onChange={setPosition} />
        </div>
        <div className="mt-5 overflow-x-auto">
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
                        <Input
                          name={`teeLat-${index}`}
                          value={coords[index].teeLat}
                          onChange={(v) => setCoord(index, "teeLat", v)}
                        />
                        <Input
                          name={`teeLon-${index}`}
                          value={coords[index].teeLon}
                          onChange={(v) => setCoord(index, "teeLon", v)}
                        />
                      </div>
                    </td>
                    <td className="py-1">
                      <div className="flex gap-1">
                        <Input
                          name={`flagLat-${index}`}
                          value={coords[index].flagLat}
                          onChange={(v) => setCoord(index, "flagLat", v)}
                        />
                        <Input
                          name={`flagLon-${index}`}
                          value={coords[index].flagLon}
                          onChange={(v) => setCoord(index, "flagLon", v)}
                        />
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
  value,
  type = "text",
  required,
  mono,
  onChange,
}: {
  label: string;
  name: string;
  defaultValue?: string;
  value?: string;
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
        defaultValue={value === undefined ? defaultValue : undefined}
        value={value}
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

interface Coords {
  teeLat: string;
  teeLon: string;
  flagLat: string;
  flagLon: string;
}

function toPoint(lat: string, lon: string): HolePoint | null {
  const a = Number(lat.trim().replace(",", "."));
  const b = Number(lon.trim().replace(",", "."));
  if (!lat.trim() || !lon.trim() || !Number.isFinite(a) || !Number.isFinite(b)) return null;
  return { lat: a, lon: b };
}

function Input({ name, value, onChange }: { name: string; value: string; onChange: (value: string) => void }) {
  return (
    <input
      name={name}
      value={value}
      onChange={(event) => onChange(event.target.value)}
      aria-label={name}
      className="field !py-1 !text-xs w-24 font-mono"
    />
  );
}
