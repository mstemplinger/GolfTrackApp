"use client";

import { useEffect, useRef, useState } from "react";

/**
 * Karte zum Setzen von Standort und Umkreis – für das Buchungsformular auf
 * `/werbung` und die Maske im Adminpanel.
 *
 * Google Maps, nicht OpenStreetMap: Werbende kennen die Karte und finden ihren
 * Ort darauf sofort. Geladen wird sie erst nach einem Klick – vorher geht keine
 * Anfrage an Google (Datenschutzerklärung, Abschnitt „Karte auf /werbung").
 *
 * Bedienung: Klick in die Karte setzt den Mittelpunkt, der Kreis lässt sich am
 * Mittelpunkt verschieben und am Rand größer und kleiner ziehen. Jeder Platz
 * steht als Punkt darauf; was im Kreis liegt, leuchtet.
 */

export interface MapCourse {
  slug: string;
  name: string;
  kind: "golf" | "minigolf";
  lat: number;
  lon: number;
}

interface Props {
  apiKey: string;
  courses: MapCourse[];
  centre: { lat: number; lon: number } | null;
  radiusKm: number;
  minKm: number;
  maxKm: number;
  onCentreChange: (lat: number, lon: number) => void;
  onRadiusChange: (km: number) => void;
}

/* Die Karte kommt als fremdes Skript ohne Typen ins Projekt; für die paar
   Aufrufe hier lohnt kein eigenes Typpaket. */
/* eslint-disable @typescript-eslint/no-explicit-any */
type GoogleMaps = any;

const GERMANY = { lat: 50.6, lng: 10.4 };
const SCRIPT_ID = "google-maps-js";

let loader: Promise<GoogleMaps> | null = null;

function loadGoogleMaps(apiKey: string): Promise<GoogleMaps> {
  const w = window as any;
  if (w.google?.maps?.Map) return Promise.resolve(w.google.maps);
  if (loader) return loader;
  loader = new Promise((resolve, reject) => {
    const callback = "__golftrackMapsReady";
    w[callback] = () => resolve(w.google.maps);
    const script = document.createElement("script");
    script.id = SCRIPT_ID;
    script.async = true;
    script.src =
      `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(apiKey)}` +
      `&language=de&region=DE&loading=async&callback=${callback}`;
    script.onerror = () => {
      loader = null;
      reject(new Error("maps_failed"));
    };
    document.head.appendChild(script);
  });
  return loader;
}

function distanceKm(aLat: number, aLon: number, bLat: number, bLon: number): number {
  const toRad = (v: number) => (v * Math.PI) / 180;
  const dLat = toRad(bLat - aLat);
  const dLon = toRad(bLon - aLon);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.min(1, Math.sqrt(h)));
}

const COLOURS = {
  golf: "#28824b",
  minigolf: "#c9a035",
  outside: "#8a8f8b",
  circle: "#28824b",
};

export function RadiusMap(props: Props) {
  const [consented, setConsented] = useState(false);
  const [failed, setFailed] = useState(false);

  if (!props.apiKey) return null;

  if (!consented) {
    return (
      <div className="grid aspect-[4/3] place-items-center rounded-[4px] border border-ink/15 bg-ink/[0.04] p-6 text-center sm:aspect-[16/9]">
        <div className="max-w-sm">
          <p className="font-display text-lg tracking-tight">Standort auf der Karte setzen</p>
          <p className="mt-2 text-xs leading-relaxed text-ink/65">
            Die Karte kommt von Google Maps. Erst mit dem Klick wird sie geladen – dabei erfährt
            Google Ihre IP-Adresse. Ohne Karte gehen die Felder darunter genauso.
          </p>
          <button type="button" onClick={() => setConsented(true)} className="btn-ghost mt-4 !py-2.5 text-sm">
            Karte laden
          </button>
        </div>
      </div>
    );
  }

  if (failed) {
    return (
      <p className="rounded-[3px] border border-[#a6321f]/30 bg-[#a6321f]/5 p-4 text-sm text-ink/75">
        Die Karte ließ sich nicht laden. Standort bitte über die Felder darunter eintragen.
      </p>
    );
  }

  return <LiveMap {...props} onFail={() => setFailed(true)} />;
}

function LiveMap({
  apiKey,
  courses,
  centre,
  radiusKm,
  minKm,
  maxKm,
  onCentreChange,
  onRadiusChange,
  onFail,
}: Props & { onFail: () => void }) {
  const element = useRef<HTMLDivElement>(null);
  const map = useRef<GoogleMaps>(null);
  const circle = useRef<GoogleMaps>(null);
  const markers = useRef<{ course: MapCourse; marker: GoogleMaps }[]>([]);
  const maps = useRef<GoogleMaps>(null);
  const [ready, setReady] = useState(false);

  // Rückrufe in Refs, damit die Kartenereignisse nicht bei jedem Rendern neu
  // gebunden werden müssen.
  const callbacks = useRef({ onCentreChange, onRadiusChange, minKm, maxKm });
  useEffect(() => {
    callbacks.current = { onCentreChange, onRadiusChange, minKm, maxKm };
  }, [onCentreChange, onRadiusChange, minKm, maxKm]);
  /** Verhindert, dass ein Setzen von außen als Ziehen zurückgemeldet wird. */
  const syncing = useRef(false);

  useEffect(() => {
    let cancelled = false;
    loadGoogleMaps(apiKey)
      .then((g) => {
        if (cancelled || !element.current) return;
        maps.current = g;
        map.current = new g.Map(element.current, {
          center: GERMANY,
          zoom: 6,
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: true,
          clickableIcons: false,
          gestureHandling: "cooperative",
        });
        map.current.addListener("click", (event: GoogleMaps) => {
          callbacks.current.onCentreChange(event.latLng.lat(), event.latLng.lng());
        });

        const info = new g.InfoWindow();
        markers.current = courses.map((course) => {
          const marker = new g.Marker({
            map: map.current,
            position: { lat: course.lat, lng: course.lon },
            title: course.name,
            icon: dot(g, COLOURS.outside, 5),
          });
          marker.addListener("click", () => {
            info.setContent(
              `<strong>${escapeHtml(course.name)}</strong><br>${course.kind === "golf" ? "Golfplatz" : "Minigolfanlage"}`,
            );
            info.open({ map: map.current, anchor: marker });
          });
          return { course, marker };
        });
        setReady(true);
      })
      .catch(() => {
        if (!cancelled) onFail();
      });
    return () => {
      cancelled = true;
    };
    // Bewusst nur einmal: die Karte wird nicht für jede Eingabe neu aufgebaut.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [apiKey]);

  // Kreis und Hervorhebung folgen dem Zustand des Formulars.
  useEffect(() => {
    const g = maps.current;
    if (!ready || !g) return;

    if (!centre) {
      circle.current?.setMap(null);
      circle.current = null;
    } else {
      const position = { lat: centre.lat, lng: centre.lon };
      syncing.current = true;
      if (!circle.current) {
        circle.current = new g.Circle({
          map: map.current,
          center: position,
          radius: radiusKm * 1000,
          editable: true,
          draggable: true,
          strokeColor: COLOURS.circle,
          strokeWeight: 2,
          fillColor: COLOURS.circle,
          fillOpacity: 0.12,
        });
        circle.current.addListener("center_changed", () => {
          if (syncing.current) return;
          const c = circle.current.getCenter();
          callbacks.current.onCentreChange(c.lat(), c.lng());
        });
        circle.current.addListener("radius_changed", () => {
          if (syncing.current) return;
          const { minKm: lo, maxKm: hi } = callbacks.current;
          const km = Math.min(hi, Math.max(lo, Math.round(circle.current.getRadius() / 1000)));
          callbacks.current.onRadiusChange(km);
          // Über die Grenze gezogen: Kreis auf die Grenze zurücksetzen.
          if (km * 1000 !== circle.current.getRadius()) {
            syncing.current = true;
            circle.current.setRadius(km * 1000);
            syncing.current = false;
          }
        });
        map.current.fitBounds(circle.current.getBounds());
      } else {
        const current = circle.current.getCenter();
        if (Math.abs(current.lat() - centre.lat) > 1e-5 || Math.abs(current.lng() - centre.lon) > 1e-5) {
          circle.current.setCenter(position);
        }
        if (circle.current.getRadius() !== radiusKm * 1000) circle.current.setRadius(radiusKm * 1000);
      }
      syncing.current = false;
    }

    for (const { course, marker } of markers.current) {
      const inside = centre && distanceKm(centre.lat, centre.lon, course.lat, course.lon) <= radiusKm;
      marker.setIcon(dot(g, inside ? COLOURS[course.kind] : COLOURS.outside, inside ? 7 : 5));
      marker.setZIndex(inside ? 2 : 1);
    }
  }, [ready, centre, radiusKm]);

  return (
    <div>
      <div
        ref={element}
        className="aspect-[4/3] w-full overflow-hidden rounded-[4px] border border-ink/15 bg-ink/[0.04] sm:aspect-[16/9]"
        role="application"
        aria-label="Karte: Klick setzt den Standort, der Kreis zeigt den Umkreis"
      />
      <p className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-ink/65">
        <span>Klick in die Karte setzt den Standort · Kreisrand ziehen ändert den Umkreis</span>
        <Legend colour={COLOURS.golf} label="Golfplatz im Umkreis" />
        <Legend colour={COLOURS.minigolf} label="Minigolf im Umkreis" />
        <Legend colour={COLOURS.outside} label="außerhalb" />
      </p>
    </div>
  );
}

function Legend({ colour, label }: { colour: string; label: string }) {
  return (
    <span className="inline-flex items-center gap-1.5">
      <span aria-hidden className="inline-block size-2.5 rounded-full" style={{ background: colour }} />
      {label}
    </span>
  );
}

function dot(g: GoogleMaps, colour: string, scale: number) {
  return {
    path: g.SymbolPath.CIRCLE,
    scale,
    fillColor: colour,
    fillOpacity: 1,
    strokeColor: "#ffffff",
    strokeWeight: 1.5,
  };
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);
}
