#!/usr/bin/env node
// GolfTrack – Kopfbild der App-Clip-Karte, 3000 × 2000 PNG.
//
// Das ist das Bild, das jemand sieht, der den QR-Code an der Anlage scannt und
// GolfTrack nicht installiert hat. Darüber legt iOS App-Symbol, Titel und
// Unterzeile.
//
// Deshalb **kein Text im Bild**: Apple blendet die Beschriftung darüber ein,
// und je nach Gerät wird anders beschnitten – geschriebene Wörter geraten
// dabei unter die Karte oder aus dem Rahmen. Aus demselben Grund bleibt die
// Mitte ruhig und alles Wichtige weg von den Rändern.
//
// Aufruf:
//   node marketing/flyer/appclip-card.mjs [out.png]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const OUT = process.argv[2] || path.join(__dirname, "out", "appclip-karte.png");

// Das App-Icon in 1024 – die einzige Fassung des Logos, die für ein Bild
// dieser Größe scharf genug ist. Die rein grafische Variante ohne Schriftzug
// gibt es nur in 192 Pixeln.
const LOGO = path.join(__dirname, "..", "..",
  "GolfTrackApp/Assets.xcassets/AppIcon.appiconset/Unbenanntes_Projekt 7.png");
const logoDataURI = "data:image/png;base64," + fs.readFileSync(LOGO).toString("base64");

// Apples Maß für das Kopfbild. Andere Größen weist die API ab.
const W = 3000;
const H = 2000;

// Dieselben Farben wie AppTheme in der App.
const C = {
  bg: "#0E2718",
  card: "#163421",
  cardAlt: "#1C4129",
  gold: "#C9A035",
  green: "#28824B",
};

/**
 * Bahn, Ball, Loch, Fahne – als SVG, damit bei 3000 px nichts ausfranst.
 * Die Szene sitzt in der unteren Bildhälfte: oben überdeckt die Karte auf
 * manchen Geräten einen Streifen.
 */
const scene = `
<svg viewBox="0 0 1500 1000" xmlns="http://www.w3.org/2000/svg" width="1500" height="1000">
  <defs>
    <linearGradient id="himmel" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"  stop-color="#1A3A26"/>
      <stop offset="46%" stop-color="${C.bg}"/>
      <stop offset="100%" stop-color="#0A1E12"/>
    </linearGradient>
    <linearGradient id="bahn" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"  stop-color="${C.cardAlt}"/>
      <stop offset="100%" stop-color="${C.card}"/>
    </linearGradient>
    <radialGradient id="schein" cx="50%" cy="62%" r="52%">
      <stop offset="0%"   stop-color="${C.green}" stop-opacity="0.30"/>
      <stop offset="100%" stop-color="${C.green}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="ball" cx="36%" cy="32%" r="72%">
      <stop offset="0%"   stop-color="#FFFFFF"/>
      <stop offset="70%"  stop-color="#E8EDE6"/>
      <stop offset="100%" stop-color="#B9C4B7"/>
    </radialGradient>
  </defs>

  <rect width="1500" height="1000" fill="url(#himmel)"/>
  <rect width="1500" height="1000" fill="url(#schein)"/>

  <!-- Die Bahn führt von links unten zum Loch. Sie liegt bewusst mittig:
       die App-Clip-Karte beschneidet oben und unten je nach Gerät. -->
  <path d="M -80 742 C 300 742, 300 512, 620 486 C 880 465, 1000 520, 1150 452"
        fill="none" stroke="url(#bahn)" stroke-width="188"
        stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M -80 742 C 300 742, 300 512, 620 486 C 880 465, 1000 520, 1150 452"
        fill="none" stroke="${C.green}" stroke-width="188"
        stroke-linecap="round" stroke-linejoin="round" opacity="0.20"/>

  <!-- Loch -->
  <ellipse cx="1150" cy="458" rx="60" ry="25" fill="#071409"/>
  <ellipse cx="1150" cy="452" rx="60" ry="25" fill="#0B1D10"/>

  <!-- Fahnenstange und Fahne, mit Abstand zum rechten Rand -->
  <rect x="1143" y="188" width="13" height="266" rx="6" fill="#D8DCD4"/>
  <path d="M 1156 202 L 1348 256 L 1156 310 Z" fill="${C.gold}"/>
  <path d="M 1156 202 L 1348 256 L 1156 256 Z" fill="#E0B84A"/>

  <!-- Kein zweiter Ball: einen trägt das Logo schon. Die Punkte deuten die
       Rollrichtung an und führen den Blick auf die Marke. -->
  <g fill="#FFFFFF" opacity="0.20">
    <circle cx="470" cy="556" r="16"/>
    <circle cx="330" cy="600" r="13"/>
    <circle cx="208" cy="646" r="10"/>
    <circle cx="108" cy="690" r="7"/>
  </g>

</svg>`;

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html, body { width:${W}px; height:${H}px; background:${C.bg}; overflow:hidden; }
  .rahmen { width:${W}px; height:${H}px; position:relative;
            display:flex; align-items:center; justify-content:center; }
  .rahmen > svg { position:absolute; inset:0; width:100%; height:100%; display:block; }
  /* Die Bahn tritt hinter das Logo zurück – sie soll die Szene tragen,
     nicht mit der Marke um Aufmerksamkeit streiten. */
  .rahmen > svg { opacity:0.68; }
  .logo {
    position:relative; z-index:2;
    width:880px; height:880px; border-radius:196px;
    box-shadow:0 48px 120px rgba(3,12,7,0.62), 0 0 0 3px rgba(255,255,255,0.05);
  }
  /* Dezente Vignette: hält den Blick in der Mitte und verzeiht das
     unterschiedliche Beschneiden auf verschiedenen Geräten. */
  .vignette {
    position:absolute; inset:0; z-index:3;
    background:radial-gradient(ellipse at 50% 50%, transparent 46%, rgba(4,14,8,0.62) 100%);
  }
</style></head><body>
  <div class="rahmen">
    ${scene}
    <img class="logo" src="${logoDataURI}" alt="">
    <div class="vignette"></div>
  </div>
</body></html>`;

const browser = await puppeteer.launch({ headless: true });
try {
  const page = await browser.newPage();
  await page.setViewport({ width: W, height: H, deviceScaleFactor: 1 });
  await page.setContent(html, { waitUntil: "load" });
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  await page.screenshot({ path: OUT, type: "png", omitBackground: false });
} finally {
  await browser.close();
}

console.log(`geschrieben: ${OUT} (${W}×${H})`);
