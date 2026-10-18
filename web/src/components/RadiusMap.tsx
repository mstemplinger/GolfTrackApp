"use client";

import "leaflet/dist/leaflet.css";
import { useEffect, useRef, useState } from "react";
import type * as L from "leaflet";

/**
 * Karte zum Setzen von Standort und Umkreis – für das Buchungsformular auf
 * `/werbung` und die Maske im Adminpanel.
 *
 * Leaflet mit OpenStreetMap (Umschalter auf Esri-Luftbild): kein Konto, kein
 * Schlüssel, keine Kosten. Geladen wird sie erst nach einem Klick – vorher geht
 * keine Anfrage an die Kartendienste (Datenschutzerklärung, Abschnitt
 * „Werbeplatz anfragen und Karte").
 *
 * Bedienung: Klick in die Karte setzt den Mittelpunkt, der Mittelpunkt lässt
 * sich verschieben, der Griff am Kreisrand ändert den Umkreis. Jeder Platz
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
  courses: MapCourse[];
  centre: { lat: number; lon: number } | null;
  radiusKm: number;
  minKm: number;
  maxKm: number;
  onCentreChange: (lat: number, lon: number) => void;
  onRadiusChange: (km: number) => void;
}

const GERMANY: L.LatLngTuple = [50.6, 10.4];

const COLOURS = {
  golf: "#28824b",
  minigolf: "#c9a035",
  outside: "#8a8f8b",
  circle: "#28824b",
};

function distanceKm(aLat: number, aLon: number, bLat: number, bLon: number): number {
  const toRad = (v: number) => (v * Math.PI) / 180;
  const dLat = toRad(bLat - aLat);
  const dLon = toRad(bLon - aLon);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.min(1, Math.sqrt(h)));
}

/** Punkt genau östlich des Mittelpunkts im Abstand `km` – dort sitzt der Griff. */
function eastOf(lat: number, lon: number, km: number): L.LatLngTuple {
  const dLon = km / (111.32 * Math.cos((lat * Math.PI) / 180));
  return [lat, lon + dLon];
}

export function RadiusMap(props: Props) {
  const [consented, setConsented] = useState(false);
  const [failed, setFailed] = useState(false);

  if (!consented) {
    return (
      <div className="grid aspect-[4/3] place-items-center rounded-[4px] border border-ink/15 bg-ink/[0.04] p-6 text-center sm:aspect-[16/9]">
        <div className="max-w-sm">
          <p className="font-display text-lg tracking-tight">Standort auf der Karte setzen</p>
          <p className="mt-2 text-xs leading-relaxed text-ink/65">
            Die Karte kommt von OpenStreetMap, das Luftbild von Esri. Erst mit dem Klick wird sie
            geladen – dabei erfahren diese Dienste Ihre IP-Adresse. Ohne Karte gehen die Felder
            darunter genauso.
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
  const lib = useRef<typeof L | null>(null);
  const map = useRef<L.Map | null>(null);
  const circle = useRef<L.Circle | null>(null);
  const centreHandle = useRef<L.Marker | null>(null);
  const edgeHandle = useRef<L.Marker | null>(null);
  const markers = useRef<{ course: MapCourse; marker: L.CircleMarker }[]>([]);
  const [ready, setReady] = useState(false);

  // Rückrufe in Refs, damit die Kartenereignisse nicht bei jedem Rendern neu
  // gebunden werden müssen.
  const callbacks = useRef({ onCentreChange, onRadiusChange, minKm, maxKm });
  useEffect(() => {
    callbacks.current = { onCentreChange, onRadiusChange, minKm, maxKm };
  }, [onCentreChange, onRadiusChange, minKm, maxKm]);

  useEffect(() => {
    let cancelled = false;
    import("leaflet")
      .then((module) => {
        const leaflet = (module as unknown as { default?: typeof L }).default ?? (module as unknown as typeof L);
        if (cancelled || !element.current) return;
        lib.current = leaflet;
        const instance = leaflet.map(element.current, { scrollWheelZoom: false }).setView(GERMANY, 6);

        const street = leaflet.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
          maxZoom: 19,
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        });
        const satellite = leaflet.tileLayer(
          "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
          { maxZoom: 19, attribution: "Esri, Maxar, Earthstar Geographics" },
        );
        street.addTo(instance);
        leaflet.control.layers({ Karte: street, Luftbild: satellite }, undefined, { position: "topright" }).addTo(instance);

        // Mausrad erst nach einem Klick in die Karte, damit die Seite beim
        // Scrollen nicht hängen bleibt.
        instance.on("focus", () => instance.scrollWheelZoom.enable());
        instance.on("blur", () => instance.scrollWheelZoom.disable());

        instance.on("click", (event: L.LeafletMouseEvent) => {
          callbacks.current.onCentreChange(event.latlng.lat, event.latlng.lng);
        });

        markers.current = courses.map((course) => {
          const marker = leaflet
            .circleMarker([course.lat, course.lon], dot(COLOURS.outside, 5))
            .bindPopup(
              `<strong>${escapeHtml(course.name)}</strong><br>${course.kind === "golf" ? "Golfplatz" : "Minigolfanlage"}`,
            )
            .addTo(instance);
          return { course, marker };
        });
        map.current = instance;
        setReady(true);
      })
      .catch(() => {
        if (!cancelled) onFail();
      });
    return () => {
      cancelled = true;
      map.current?.remove();
      map.current = null;
    };
    // Bewusst nur einmal: die Karte wird nicht für jede Eingabe neu aufgebaut.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Kreis, Griffe und Hervorhebung folgen dem Zustand des Formulars.
  useEffect(() => {
    const leaflet = lib.current;
    const instance = map.current;
    if (!ready || !leaflet || !instance) return;

    if (!centre) {
      circle.current?.remove();
      centreHandle.current?.remove();
      edgeHandle.current?.remove();
      circle.current = centreHandle.current = edgeHandle.current = null;
    } else {
      const position: L.LatLngTuple = [centre.lat, centre.lon];
      const edge = eastOf(centre.lat, centre.lon, radiusKm);
      if (!circle.current) {
        circle.current = leaflet
          .circle(position, {
            radius: radiusKm * 1000,
            color: COLOURS.circle,
            weight: 2,
            fillColor: COLOURS.circle,
            fillOpacity: 0.12,
            interactive: false,
          })
          .addTo(instance);

        centreHandle.current = leaflet
          .marker(position, { draggable: true, icon: handle(leaflet, 18), title: "Mittelpunkt verschieben" })
          .addTo(instance);
        centreHandle.current.on("drag", () => {
          const p = centreHandle.current!.getLatLng();
          circle.current?.setLatLng(p);
          const km = circle.current!.getRadius() / 1000;
          edgeHandle.current?.setLatLng(eastOf(p.lat, p.lng, km));
        });
        centreHandle.current.on("dragend", () => {
          const p = centreHandle.current!.getLatLng();
          callbacks.current.onCentreChange(p.lat, p.lng);
        });

        edgeHandle.current = leaflet
          .marker(edge, { draggable: true, icon: handle(leaflet, 14), title: "Umkreis ändern" })
          .addTo(instance);
        const radiusFromEdge = () => {
          const c = centreHandle.current!.getLatLng();
          const e = edgeHandle.current!.getLatLng();
          const { minKm: lo, maxKm: hi } = callbacks.current;
          return Math.min(hi, Math.max(lo, Math.round(distanceKm(c.lat, c.lng, e.lat, e.lng))));
        };
        edgeHandle.current.on("drag", () => circle.current?.setRadius(radiusFromEdge() * 1000));
        edgeHandle.current.on("dragend", () => {
          const km = radiusFromEdge();
          const c = centreHandle.current!.getLatLng();
          // Griff zurück auf den Kreisrand, auch wenn über die Grenze gezogen.
          edgeHandle.current?.setLatLng(eastOf(c.lat, c.lng, km));
          callbacks.current.onRadiusChange(km);
        });

        instance.fitBounds(circle.current.getBounds(), { padding: [24, 24] });
      } else {
        circle.current.setLatLng(position);
        circle.current.setRadius(radiusKm * 1000);
        centreHandle.current?.setLatLng(position);
        edgeHandle.current?.setLatLng(edge);
      }
    }

    for (const { course, marker } of markers.current) {
      const inside = centre && distanceKm(centre.lat, centre.lon, course.lat, course.lon) <= radiusKm;
      marker.setStyle(dot(inside ? COLOURS[course.kind] : COLOURS.outside, inside ? 7 : 5));
      marker.setRadius(inside ? 7 : 5);
      if (inside) marker.bringToFront();
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
        <span>Klick in die Karte setzt den Standort · Griff am Kreisrand ziehen ändert den Umkreis</span>
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

function dot(colour: string, radius: number): L.CircleMarkerOptions {
  return { radius, color: "#ffffff", weight: 1.5, fillColor: colour, fillOpacity: 1 };
}

function handle(leaflet: typeof L, size: number): L.DivIcon {
  return leaflet.divIcon({
    html: `<span style="display:block;width:${size}px;height:${size}px;border-radius:999px;background:#fff;border:3px solid ${COLOURS.circle};box-shadow:0 1px 3px rgba(0,0,0,.4);cursor:grab"></span>`,
    className: "",
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
  });
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);
}
