"use client";

import "leaflet/dist/leaflet.css";
import { useEffect, useRef, useState } from "react";
import type * as L from "leaflet";
import type { Lang } from "@/i18n/routes";

/**
 * Satellitenkarte zum Setzen von Abschlag und Grün (bzw. Start und Loch)
 * jeder Bahn im Platzformular.
 *
 * Luftbilder von Esri World Imagery über Leaflet: braucht keinen Schlüssel und
 * ist auf Platzniveau scharf genug, um Abschlag und Grün zu erkennen. Geladen
 * wird erst nach einem Klick – vorher geht keine Anfrage an Esri
 * (Datenschutzerklärung, Abschnitt „Platz eintragen").
 *
 * Bedienung: Bahn wählen, in die Karte klicken. Der erste Klick setzt den
 * Abschlag, der zweite das Grün, danach springt die Auswahl zur nächsten Bahn.
 * Gesetzte Punkte lassen sich verschieben.
 */

export interface HolePoint {
  lat: number;
  lon: number;
}

export interface HolePositions {
  tee: HolePoint | null;
  flag: HolePoint | null;
}

export type PointKind = "tee" | "flag";

interface Props {
  lang: Lang;
  isGolf: boolean;
  positions: HolePositions[];
  /** Mittelpunkt der Anlage aus dem Formular, falls schon eingetragen. */
  centre: HolePoint | null;
  onChange: (index: number, kind: PointKind, point: HolePoint | null) => void;
}

const GERMANY: L.LatLngTuple = [50.6, 10.4];
const COLOURS = { tee: "#ffffff", flag: "#c9a035", line: "#ffffff", active: "#28824b" };

const TEXT = {
  de: {
    title: "Abschläge und Grüns auf der Karte setzen",
    titleMinigolf: "Start und Loch jeder Bahn auf der Karte setzen",
    consent:
      "Die Luftbilder kommen von Esri (World Imagery). Erst mit dem Klick wird die Karte geladen – dabei erfährt Esri deine IP-Adresse. Ohne Karte lässt sich der Platz genauso eintragen.",
    load: "Satellitenkarte laden",
    failed: "Die Karte ließ sich nicht laden.",
    hole: "Loch",
    lane: "Bahn",
    tee: "Abschlag",
    flag: "Grün",
    start: "Start",
    cup: "Loch",
    next: "Klick in die Karte setzt",
    clear: "Punkte dieser Bahn löschen",
    locate: "Mein Standort",
    distance: "Entfernung",
    hint: "Erster Klick Abschlag, zweiter Klick Grün, dann geht es mit der nächsten Bahn weiter. Punkte lassen sich verschieben.",
    hintMinigolf: "Erster Klick Start, zweiter Klick Loch, dann geht es mit der nächsten Bahn weiter. Punkte lassen sich verschieben.",
  },
  en: {
    title: "Set tees and greens on the map",
    titleMinigolf: "Set start and hole of each lane on the map",
    consent:
      "The aerial images come from Esri (World Imagery). The map only loads after you click – Esri then receives your IP address. You can list the venue just as well without the map.",
    load: "Load satellite map",
    failed: "The map could not be loaded.",
    hole: "Hole",
    lane: "Lane",
    tee: "Tee",
    flag: "Green",
    start: "Start",
    cup: "Hole",
    next: "Clicking the map sets",
    clear: "Clear this lane's points",
    locate: "My location",
    distance: "Distance",
    hint: "First click sets the tee, second the green, then it moves on to the next hole. Points can be dragged.",
    hintMinigolf: "First click sets the start, second the hole, then it moves on to the next lane. Points can be dragged.",
  },
} as const;

export function distanceMetres(a: HolePoint, b: HolePoint): number {
  const toRad = (v: number) => (v * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLon = toRad(b.lon - a.lon);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLon / 2) ** 2;
  return 6_371_000 * 2 * Math.asin(Math.min(1, Math.sqrt(h)));
}

export function HolePositionsMap(props: Props) {
  const [consented, setConsented] = useState(false);
  const [failed, setFailed] = useState(false);
  const text = TEXT[props.lang];

  if (!consented) {
    return (
      <div className="grid aspect-[4/3] place-items-center rounded-[4px] border border-ink/15 bg-ink/[0.04] p-6 text-center sm:aspect-[16/9]">
        <div className="max-w-sm">
          <p className="font-display text-lg tracking-tight">{props.isGolf ? text.title : text.titleMinigolf}</p>
          <p className="mt-2 text-xs leading-relaxed text-ink/65">{text.consent}</p>
          <button type="button" onClick={() => setConsented(true)} className="btn-ghost mt-4 !py-2.5 text-sm">
            {text.load}
          </button>
        </div>
      </div>
    );
  }

  if (failed) {
    return (
      <p className="rounded-[3px] border border-[#a6321f]/30 bg-[#a6321f]/5 p-4 text-sm text-ink/75">{text.failed}</p>
    );
  }

  return <LiveMap {...props} onFail={() => setFailed(true)} />;
}

function LiveMap({ lang, isGolf, positions, centre, onChange, onFail }: Props & { onFail: () => void }) {
  const text = TEXT[lang];
  const element = useRef<HTMLDivElement>(null);
  const leaflet = useRef<typeof L | null>(null);
  const map = useRef<L.Map | null>(null);
  const layer = useRef<L.LayerGroup | null>(null);
  const [ready, setReady] = useState(false);
  const [selected, setSelected] = useState(0);
  const [kind, setKind] = useState<PointKind>("tee");

  // Zustand für die Kartenereignisse, ohne sie bei jedem Rendern neu zu binden.
  const live = useRef({ selected, kind, positions, onChange });
  useEffect(() => {
    live.current = { selected, kind, positions, onChange };
  }, [selected, kind, positions, onChange]);

  const teeLabel = isGolf ? text.tee : text.start;
  const flagLabel = isGolf ? text.flag : text.cup;
  const unit = isGolf ? text.hole : text.lane;

  /** Setzt einen Punkt und rückt danach zum nächsten fehlenden vor. */
  const place = (point: HolePoint) => {
    const { selected: index, kind: current, positions: all, onChange: change } = live.current;
    change(index, current, point);
    if (current === "tee") {
      setKind("flag");
    } else if (index + 1 < all.length) {
      setSelected(index + 1);
      setKind(all[index + 1]?.tee ? "flag" : "tee");
    }
  };
  const placeRef = useRef(place);
  useEffect(() => {
    placeRef.current = place;
  });

  useEffect(() => {
    let cancelled = false;
    import("leaflet")
      .then((module) => {
        const lib = (module as unknown as { default?: typeof L }).default ?? (module as unknown as typeof L);
        if (cancelled || !element.current) return;
        leaflet.current = lib;
        const instance = lib.map(element.current, { zoomControl: true, maxZoom: 20 });
        lib
          .tileLayer(
            "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
            {
              maxNativeZoom: 19,
              maxZoom: 20,
              attribution: "Esri, Maxar, Earthstar Geographics, GIS User Community",
            },
          )
          .on("tileerror", () => undefined)
          .addTo(instance);
        lib
          .tileLayer(
            "https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}",
            { maxNativeZoom: 19, maxZoom: 20 },
          )
          .addTo(instance);

        const first = live.current.positions.find((p) => p.tee || p.flag);
        const start = first?.tee ?? first?.flag ?? centre;
        if (start) instance.setView([start.lat, start.lon], 17);
        else instance.setView(GERMANY, 6);

        instance.on("click", (event: L.LeafletMouseEvent) => {
          placeRef.current({ lat: event.latlng.lat, lon: event.latlng.lng });
        });
        layer.current = lib.layerGroup().addTo(instance);
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

  // Anlage im Formular eingetragen, aber noch kein Punkt gesetzt: dorthin springen.
  const centreKey = centre ? `${centre.lat.toFixed(5)},${centre.lon.toFixed(5)}` : "";
  useEffect(() => {
    if (!ready || !centre || !map.current) return;
    if (live.current.positions.some((p) => p.tee || p.flag)) return;
    map.current.setView([centre.lat, centre.lon], 17);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ready, centreKey]);

  // Punkte und Linien neu zeichnen, wenn sich etwas ändert.
  useEffect(() => {
    const lib = leaflet.current;
    const group = layer.current;
    if (!ready || !lib || !group) return;
    group.clearLayers();

    positions.forEach((hole, index) => {
      const active = index === selected;
      if (hole.tee && hole.flag) {
        lib
          .polyline(
            [
              [hole.tee.lat, hole.tee.lon],
              [hole.flag.lat, hole.flag.lon],
            ],
            {
              color: active ? COLOURS.active : COLOURS.line,
              weight: active ? 3 : 2,
              opacity: active ? 0.95 : 0.6,
              dashArray: active ? undefined : "4 6",
              interactive: false,
            },
          )
          .addTo(group);
      }
      for (const pointKind of ["tee", "flag"] as const) {
        const point = hole[pointKind];
        if (!point) continue;
        const marker = lib.marker([point.lat, point.lon], {
          draggable: true,
          icon: pin(lib, pointKind, index + 1, active),
          zIndexOffset: active ? 1000 : 0,
          title: `${unit} ${index + 1} · ${pointKind === "tee" ? teeLabel : flagLabel}`,
        });
        marker.on("dragend", () => {
          const position = marker.getLatLng();
          live.current.onChange(index, pointKind, { lat: position.lat, lon: position.lng });
        });
        marker.on("click", () => {
          setSelected(index);
          setKind(pointKind);
        });
        marker.addTo(group);
      }
    });
  }, [ready, positions, selected, unit, teeLabel, flagLabel]);

  const current = positions[selected] ?? { tee: null, flag: null };
  const metres = current.tee && current.flag ? Math.round(distanceMetres(current.tee, current.flag)) : null;

  const select = (index: number) => {
    setSelected(index);
    const hole = positions[index];
    setKind(hole?.tee && !hole.flag ? "flag" : "tee");
    const point = hole?.tee ?? hole?.flag;
    if (point && map.current) map.current.panTo([point.lat, point.lon]);
  };

  const locate = () => {
    navigator.geolocation?.getCurrentPosition(
      (position) => map.current?.setView([position.coords.latitude, position.coords.longitude], 18),
      () => undefined,
      { enableHighAccuracy: true, timeout: 10_000 },
    );
  };

  return (
    <div>
      <div className="mb-3 flex flex-wrap gap-1.5" role="group" aria-label={unit}>
        {positions.map((hole, index) => {
          const done = Boolean(hole.tee && hole.flag);
          const half = Boolean(hole.tee || hole.flag) && !done;
          return (
            <button
              key={index}
              type="button"
              onClick={() => select(index)}
              aria-pressed={index === selected}
              className={`tap grid h-9 min-w-9 place-items-center rounded-[3px] border px-2 font-mono text-sm transition-colors ${
                index === selected
                  ? "border-fairway bg-fairway text-white"
                  : done
                    ? "border-fairway/50 bg-fairway/10 text-ink"
                    : half
                      ? "border-[#c9a035]/60 bg-[#c9a035]/10 text-ink"
                      : "border-ink/20 text-ink/70 hover:border-ink/40"
              }`}
            >
              {index + 1}
            </button>
          );
        })}
      </div>

      <div className="mb-3 flex flex-wrap items-center gap-2 text-sm">
        <span className="text-ink/65">
          {unit} {selected + 1} · {text.next}
        </span>
        {(["tee", "flag"] as const).map((option) => (
          <button
            key={option}
            type="button"
            onClick={() => setKind(option)}
            aria-pressed={kind === option}
            className={`tap rounded-full border px-3 py-1 transition-colors ${
              kind === option ? "border-fairway bg-fairway/10 font-medium" : "border-ink/20 hover:border-ink/40"
            }`}
          >
            {option === "tee" ? teeLabel : flagLabel}
            {current[option] ? " ✓" : ""}
          </button>
        ))}
        {metres !== null ? (
          <span className="font-mono text-ink/75">
            {text.distance}: {metres} m
          </span>
        ) : null}
      </div>

      <div
        ref={element}
        className="aspect-[4/3] w-full overflow-hidden rounded-[4px] border border-ink/15 bg-ink/[0.04] sm:aspect-[16/9]"
        role="application"
        aria-label={isGolf ? text.hint : text.hintMinigolf}
      />

      <div className="mt-2 flex flex-wrap items-center justify-between gap-2 text-xs text-ink/65">
        <span>{isGolf ? text.hint : text.hintMinigolf}</span>
        <span className="flex gap-3">
          <button type="button" onClick={locate} className="underline underline-offset-4 hover:text-ink">
            {text.locate}
          </button>
          {current.tee || current.flag ? (
            <button
              type="button"
              onClick={() => {
                onChange(selected, "tee", null);
                onChange(selected, "flag", null);
                setKind("tee");
              }}
              className="underline underline-offset-4 hover:text-ink"
            >
              {text.clear}
            </button>
          ) : null}
        </span>
      </div>
    </div>
  );
}

function pin(lib: typeof L, kind: PointKind, number: number, active: boolean): L.DivIcon {
  const ring = active ? COLOURS.active : "rgba(0,0,0,0.55)";
  const html =
    kind === "tee"
      ? `<span style="display:grid;place-items:center;width:24px;height:24px;border-radius:999px;background:${COLOURS.tee};border:2px solid ${ring};font:600 11px/1 ui-monospace,monospace;color:#1a1f1c;box-shadow:0 1px 3px rgba(0,0,0,.4)">${number}</span>`
      : `<span style="display:grid;place-items:center;width:24px;height:24px;border-radius:999px;background:${COLOURS.flag};border:2px solid ${ring};box-shadow:0 1px 3px rgba(0,0,0,.4)"><svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="#1a1f1c" stroke-width="2.4" stroke-linecap="round"><path d="M7 21V4"/><path d="M7 4h10l-3 4 3 4H7" fill="#1a1f1c"/></svg></span>`;
  return lib.divIcon({ html, className: "", iconSize: [24, 24], iconAnchor: [12, 12] });
}
