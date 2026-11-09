#!/usr/bin/env node
// GolfTrack – Bilder für In-App-Events im App Store („Banner“).
//
// Je Event zwei Bilder, beide in Apples Pflichtmaßen:
//   card   1920×1080  – Eventkarte in Suche, Heute-Tab und auf der Produktseite
//   detail 1080×1920  – Kopf der Event-Detailseite
//
// **Kein Text im Bild.** Der App Store legt Badge („Event“, „Challenge“ …),
// Eventname und Kurzbeschreibung selbst unten darüber und dunkelt dafür ab.
// Darum bleibt das untere Drittel ruhig und alles Wichtige sitzt oben/mittig.
//
// Aufruf (aus marketing/flyer, dort liegt puppeteer):
//   node ../appstore/event-banners.mjs [range|freunde|platzreife|all]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(path.join(__dirname, "..", "flyer", "package.json"));
const puppeteer = require("puppeteer");

const ROOT = path.join(__dirname, "..", "..");
const SHOTS = path.join(ROOT, "marketing", "screenshots");
const OUT = path.join(__dirname, "out", "events");

const C = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", green: "#28824B", light: "#7BD389" };

const uri = (p) => "data:image/png;base64," + fs.readFileSync(p).toString("base64");
const shot = (name) => {
  for (const d of ["de-69", "de"]) {
    const p = path.join(SHOTS, d, name + ".png");
    if (fs.existsSync(p)) return uri(p);
  }
  throw new Error(`Screenshot ${name} fehlt`);
};
const logo = uri(path.join(ROOT, "GolfTrackApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png"));

// Szenen als SVG, Koordinaten im 1920×1080-Rahmen. Für das Hochformat wird
// dieselbe Szene breiter beschnitten.
const SCENES = {
  // Range: Abschlagmatte vorn, Ballflugkurven mit Weitenfahnen in die Tiefe
  range: `
    <defs>
      <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#21442F"/><stop offset=".55" stop-color="${C.bg}"/><stop offset="1" stop-color="#081A0F"/>
      </linearGradient>
      <linearGradient id="trail" x1="0" y1="1" x2="1" y2="0">
        <stop offset="0" stop-color="${C.gold}" stop-opacity="0"/><stop offset="1" stop-color="${C.gold}"/>
      </linearGradient>
    </defs>
    <rect width="1920" height="1080" fill="url(#sky)"/>
    ${[0, 1, 2, 3, 4, 5].map((i) => `<path d="M${-200 + i * 420} 1080 L960 560 L${-40 + i * 420} 1080Z" fill="#fff" opacity=".025"/>`).join("")}
    ${[["640", "380", "50"], ["780", "330", "100"], ["980", "300", "150"], ["1200", "320", "200"], ["1380", "370", "250"]]
      .map(([x, y, m], i) => `
      <g opacity="${0.55 + i * 0.09}">
        <line x1="${x}" y1="${+y + 210}" x2="${x}" y2="${+y + 120}" stroke="#fff" stroke-width="4"/>
        <path d="M${x} ${+y + 120} l46 14 -46 14z" fill="${i === 4 ? C.gold : C.light}"/>
        <ellipse cx="${x}" cy="${+y + 212}" rx="38" ry="8" fill="#000" opacity=".3"/>
      </g>`).join("")}
    ${[[-80, 470], [60, 380], [180, 300]].map(([dx, top]) =>
      `<path d="M960 980 Q ${1180 + dx} ${top} ${1380 + dx * 1.4} ${560 + dx * 0.3}" fill="none" stroke="url(#trail)" stroke-width="6" stroke-linecap="round" stroke-dasharray="2 18"/>`).join("")}
    <circle cx="960" cy="975" r="16" fill="#fff"/>
    <rect x="840" y="990" width="240" height="40" rx="8" fill="${C.green}" opacity=".8"/>`,

  // Freunde: vier Ballmarker, verbunden – ein Flight auf dem Grün
  freunde: `
    <defs>
      <radialGradient id="green" cx=".5" cy=".55" r=".6">
        <stop offset="0" stop-color="#2E6B44"/><stop offset=".6" stop-color="${C.card}"/><stop offset="1" stop-color="#081A0F"/>
      </radialGradient>
    </defs>
    <rect width="1920" height="1080" fill="url(#green)"/>
    <ellipse cx="960" cy="560" rx="760" ry="330" fill="none" stroke="#fff" stroke-opacity=".06" stroke-width="80"/>
    <ellipse cx="960" cy="560" rx="560" ry="230" fill="none" stroke="#fff" stroke-opacity=".05" stroke-width="60"/>
    <g transform="translate(160 0)">
    <g stroke="${C.gold}" stroke-width="4" stroke-dasharray="4 16" stroke-linecap="round" opacity=".8">
      <line x1="640" y1="420" x2="960" y2="520"/><line x1="1360" y1="420" x2="960" y2="520"/>
      <line x1="740" y1="760" x2="960" y2="520"/><line x1="1220" y1="760" x2="960" y2="520"/>
    </g>
    <circle cx="960" cy="520" r="34" fill="#000" opacity=".55"/>
    <line x1="960" y1="520" x2="960" y2="210" stroke="#fff" stroke-width="7"/>
    <path d="M960 210 l120 40 -120 40z" fill="${C.gold}"/>
    ${[[640, 420, "A"], [1360, 420, "M"], [740, 760, "Z"], [1220, 760, "L"]].map(([x, y, l], i) => `
      <circle cx="${x}" cy="${y}" r="62" fill="${i === 0 ? C.gold : C.green}" stroke="#fff" stroke-width="6"/>
      <text x="${x}" y="${y + 20}" text-anchor="middle" font-size="56" font-weight="800" fill="${i === 0 ? "#10220D" : "#fff"}"
        font-family="-apple-system,sans-serif">${l}</text>`).join("")}
    </g>`,

  // Platzreife: Winterabend, Regelbuch-Seiten als Karten, Fahne im Schnee
  platzreife: `
    <defs>
      <linearGradient id="night" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#14301F"/><stop offset=".7" stop-color="${C.bg}"/><stop offset="1" stop-color="#E8EFEA" stop-opacity=".15"/>
      </linearGradient>
    </defs>
    <rect width="1920" height="1080" fill="url(#night)"/>
    ${Array.from({ length: 70 }, (_, i) => {
      const x = (i * 283) % 1920, y = (i * 157) % 900, r = 2 + (i % 4);
      return `<circle cx="${x}" cy="${y}" r="${r}" fill="#fff" opacity="${0.12 + (i % 5) * 0.06}"/>`;
    }).join("")}
    <path d="M0 900 Q 480 820 960 870 T 1920 850 V1080 H0Z" fill="#E8EFEA" opacity=".12"/>
    ${[[-14, 640, "#1C4129"], [-4, 800, "#163421"], [8, 960, "#1C4129"]].map(([rot, x, f], i) => `
      <g transform="translate(${x} 470) rotate(${rot})">
        <rect x="-150" y="-200" width="300" height="400" rx="28" fill="${f}" stroke="${C.gold}" stroke-opacity=".5" stroke-width="3"/>
        ${[0, 1, 2, 3].map((k) => `<rect x="-100" y="${-120 + k * 60}" width="${k === 3 ? 120 : 200}" height="14" rx="7" fill="#fff" opacity=".22"/>`).join("")}
        ${i === 2 ? `<circle cx="90" cy="140" r="44" fill="${C.light}"/><path d="M70 140 l14 14 28 -30" stroke="#10220D" stroke-width="10" fill="none" stroke-linecap="round" stroke-linejoin="round"/>` : ""}
      </g>`).join("")}
    <line x1="1400" y1="860" x2="1400" y2="420" stroke="#fff" stroke-width="7"/>
    <path d="M1400 420 l130 44 -130 44z" fill="${C.gold}"/>`,
};

// Jedes Event: Szene + echtes App-Bild im Gerät, das zum Event passt.
const EVENTS = {
  range:      { scene: "range",      shot: "25-driving-range",         side: "right" },
  freunde:    { scene: "freunde",    shot: "24-mitspieler",            side: "left" },
  platzreife: { scene: "platzreife", shot: "22-platzreife-uebersicht", side: "right" },
};

function html(ev, w, h) {
  const portrait = h > w;
  // Hochformat: Szene auf volle Höhe skalieren und mittig beschneiden.
  const svgAttrs = portrait
    ? `viewBox="420 0 1080 1080" width="${h}" height="${h}" style="position:absolute;left:${(w - h) / 2}px;top:0"`
    : `viewBox="0 0 1920 1080" width="${w}" height="${h}"`;
  const phoneW = portrait ? 520 : 400;
  const phoneH = Math.round(phoneW * 2868 / 1320) + 26;
  const phoneLeft = portrait ? (w - phoneW) / 2 : ev.side === "right" ? w - phoneW - 210 : 210;
  const phoneTop = portrait ? 260 : 90;
  const rot = portrait ? 0 : ev.side === "right" ? 6 : -6;
  return `<!doctype html><html><head><meta charset="utf-8"><style>
    *{margin:0;padding:0;box-sizing:border-box}
    html,body{width:${w}px;height:${h}px;overflow:hidden;background:${C.bg}}
    body{position:relative}
    .phone{position:absolute;left:${phoneLeft}px;top:${phoneTop}px;width:${phoneW}px;height:${phoneH}px;
      transform:rotate(${rot}deg);border-radius:${phoneW * 0.15}px;padding:${phoneW * 0.026}px;
      background:linear-gradient(145deg,#4a4f54 0%,#1d2023 30%,#2b2f33 60%,#0f1113 100%);
      box-shadow:0 40px 100px rgba(0,0,0,.6),0 0 0 2px #5d6369 inset,0 0 0 5px #0b0c0d inset}
    .screen{width:100%;height:100%;border-radius:${phoneW * 0.125}px;overflow:hidden;position:relative}
    .screen img{width:100%;height:100%;display:block}
    .island{position:absolute;top:${phoneW * 0.03}px;left:50%;transform:translateX(-50%);
      width:${phoneW * 0.28}px;height:${phoneW * 0.085}px;background:#000;border-radius:999px}
    /* Fuß abdunkeln: hier schreibt der App Store */
    .shade{position:absolute;left:0;right:0;bottom:0;height:${portrait ? 46 : 42}%;
      background:linear-gradient(180deg,transparent,rgba(5,15,9,.85))}
    .logo{position:absolute;${portrait ? `left:${w / 2 - 60}px;top:110px` : ev.side === "right" ? "left:120px;top:110px" : `right:120px;top:110px`};
      width:120px;height:120px;border-radius:28px;box-shadow:0 10px 30px rgba(0,0,0,.45)}
  </style></head><body>
    <svg xmlns="http://www.w3.org/2000/svg" ${svgAttrs} preserveAspectRatio="xMidYMid slice">${SCENES[ev.scene]}</svg>
    <img class="logo" src="${logo}">
    <div class="phone"><div class="screen"><img src="${shot(ev.shot)}"><div class="island"></div></div></div>
    <div class="shade"></div>
  </body></html>`;
}

const arg = process.argv[2] || "all";
const names = arg === "all" ? Object.keys(EVENTS) : [arg];
fs.mkdirSync(OUT, { recursive: true });

const browser = await puppeteer.launch({ headless: true });
const page = await browser.newPage();
for (const name of names) {
  for (const [kind, w, h] of [["card", 1920, 1080], ["detail", 1080, 1920]]) {
    await page.setViewport({ width: w, height: h, deviceScaleFactor: 1 });
    await page.setContent(html(EVENTS[name], w, h), { waitUntil: "load" });
    const out = path.join(OUT, `${name}-${kind}-${w}x${h}.png`);
    await page.screenshot({ path: out, clip: { x: 0, y: 0, width: w, height: h } });
    console.log(`  ✓ ${path.relative(ROOT, out)}`);
  }
}
await browser.close();
