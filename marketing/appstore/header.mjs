#!/usr/bin/env node
// GolfTrack – Kopfzeile der Produktseite + Bild in den Suchergebnissen.
//
// Apple nimmt für beide Plätze (und für das Bild der Retention-Nachricht) ein
// „universelles“ PNG in genau 5244×2950 (16:9, ohne Alpha). Der App Store
// beschneidet es je nach Platz:
//   Kopfzeile   21:9 → mittleres Band, oben/unten je ~13 % weg
//   Suche        3:2 → mittlerer Ausschnitt, links/rechts je ~8 % weg
// Alles Wichtige sitzt darum in der Schnittmenge (Rahmen SAFE unten). Unten
// legt der App Store Symbol, Name und Laden-Knopf darüber – dort bleibt es ruhig.
//
// **Kein Text im Bild**: Apple schreibt selbst, und so passt ein Bild je
// Sprache der App-Bildschirme (de = deutsche Oberfläche, en = englische).
//
// Aufruf (aus marketing/flyer, dort liegt puppeteer):
//   node ../appstore/header.mjs [de|en|all]
// Danach Alpha entfernen (macht das Skript selbst über python3.12 + Pillow).
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(path.join(__dirname, "..", "flyer", "package.json"));
const puppeteer = require("puppeteer");

const ROOT = path.join(__dirname, "..", "..");
const SHOTS = path.join(ROOT, "marketing", "screenshots");
const OUT = path.join(__dirname, "out", "header");

// Gerendert in halber Größe mit deviceScaleFactor 2 → 5244×2950.
const W = 2622, H = 1475, SCALE = 2;
const SAFE = { x: Math.round((W - H * 1.5) / 2), y: Math.round((H - W * 9 / 21) / 2) };

const C = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", green: "#28824B", light: "#7BD389" };

const uri = (p) => "data:image/png;base64," + fs.readFileSync(p).toString("base64");
const shot = (lang, name) => {
  for (const d of [`${lang}-69`, lang]) {
    const p = path.join(SHOTS, d, name + ".png");
    if (fs.existsSync(p)) return uri(p);
  }
  throw new Error(`Screenshot ${lang}/${name} fehlt`);
};

// Abendliche Golfbahn: Baumlinie am Horizont, Fairway schwingt nach rechts zum
// Grün mit Fahne, goldene Ballflugbahn vom Abschlag links vorn.
const scene = `
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0B2014"/>
      <stop offset=".38" stop-color="#1B3D28"/>
      <stop offset=".47" stop-color="#3E5A33"/>
      <stop offset=".5" stop-color="#22432D"/>
      <stop offset="1" stop-color="#081A0F"/>
    </linearGradient>
    <radialGradient id="sun" cx=".62" cy=".44" r=".42">
      <stop offset="0" stop-color="${C.gold}" stop-opacity=".55"/>
      <stop offset=".35" stop-color="${C.gold}" stop-opacity=".14"/>
      <stop offset="1" stop-color="${C.gold}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="fair" x1="0" y1="1" x2=".7" y2="0">
      <stop offset="0" stop-color="#1F4A2E"/><stop offset="1" stop-color="#2C6B40"/>
    </linearGradient>
    <linearGradient id="trail" x1="0" y1="1" x2="1" y2="0">
      <stop offset="0" stop-color="${C.gold}" stop-opacity=".1"/><stop offset="1" stop-color="${C.gold}"/>
    </linearGradient>
    <filter id="blur"><feGaussianBlur stdDeviation="6"/></filter>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#sky)"/>
  <rect width="${W}" height="${H}" fill="url(#sun)"/>
  ${Array.from({ length: 46 }, (_, i) => {
    const x = (i * 211) % W, y = 40 + (i * 97) % 420, r = 1.2 + (i % 3) * 0.8;
    return `<circle cx="${x}" cy="${y}" r="${r}" fill="#fff" opacity="${0.08 + (i % 4) * 0.05}"/>`;
  }).join("")}
  <!-- Baumlinie -->
  <path d="M0 700 ${Array.from({ length: 60 }, (_, i) => {
    const x = i * 46, y = 640 - ((i * 37) % 70) - (i % 5 === 0 ? 40 : 0);
    return `Q ${x + 23} ${y - 30} ${x + 46} ${y + 20}`;
  }).join(" ")} L${W} 760 L0 760Z" fill="#0A1D11" opacity=".95"/>
  <path d="M0 735 Q 700 690 1400 720 T ${W} 705 V${H} H0Z" fill="#12301D"/>
  <!-- Fairway -->
  <path d="M-100 ${H} C 500 1080, 900 900, 1600 800 S 2300 720, 2480 735
           C 2560 740, 2590 770, 2470 785 C 2250 795, 1900 860, 1500 980 S 700 1260, 520 ${H}Z" fill="url(#fair)" opacity=".9"/>
  ${[0, 1, 2, 3, 4, 5, 6].map((k) => `<path d="M${-60 + k * 120} ${H} C ${560 + k * 60} ${1100 - k * 18}, ${960 + k * 50} ${930 - k * 10}, ${1640 + k * 40} ${815 - k * 4}"
     fill="none" stroke="#fff" stroke-opacity=".035" stroke-width="40"/>`).join("")}
  <!-- Grün + Fahne -->
  <ellipse cx="2240" cy="742" rx="210" ry="34" fill="#3A8352"/>
  <ellipse cx="2240" cy="742" rx="150" ry="22" fill="#45955F"/>
  <ellipse cx="2262" cy="746" rx="12" ry="4" fill="#06140B"/>
  <line x1="2262" y1="746" x2="2262" y2="560" stroke="#fff" stroke-width="5"/>
  <path d="M2262 560 l86 28 -86 28z" fill="${C.gold}"/>
  <!-- Ballflug -->
  <path d="M430 1190 C 760 260, 1700 180, 2250 735" fill="none" stroke="${C.gold}" stroke-opacity=".25"
        stroke-width="22" filter="url(#blur)"/>
  <path d="M430 1190 C 760 260, 1700 180, 2250 735" fill="none" stroke="url(#trail)" stroke-width="7"
        stroke-linecap="round" stroke-dasharray="2 22"/>
  <circle cx="430" cy="1190" r="15" fill="#fff"/>
  <ellipse cx="430" cy="1208" rx="30" ry="7" fill="#000" opacity=".35"/>
  <circle cx="2250" cy="735" r="10" fill="#fff" opacity=".9"/>`;

// Drei Geräte, gefächert. Mitte: Live-Scorekarte (das Versprechen der App).
const PHONES = [
  { shot: "09-schlagkarte",       x: -470, y: 330, w: 330, rot: -9, z: 1 },
  { shot: "19-live-scorecard",    x: 0,    y: 250, w: 380, rot: 0,  z: 3 },
  { shot: "06-statistiken-chart", x: 470,  y: 330, w: 330, rot: 9,  z: 2 },
];

function phone(lang, p) {
  const h = Math.round(p.w * 2868 / 1320) + 18;
  const left = W / 2 + p.x - p.w / 2;
  return `<div class="phone" style="left:${left}px;top:${p.y}px;width:${p.w}px;height:${h}px;
      transform:rotate(${p.rot}deg);z-index:${p.z};border-radius:${p.w * 0.15}px;padding:${p.w * 0.026}px">
    <div class="screen" style="border-radius:${p.w * 0.125}px"><img src="${shot(lang, p.shot)}">
      <div class="island" style="top:${p.w * 0.03}px;width:${p.w * 0.28}px;height:${p.w * 0.085}px"></div></div></div>`;
}

const html = (lang, guides) => `<!doctype html><html><head><meta charset="utf-8"><style>
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:${W}px;height:${H}px;overflow:hidden;background:${C.bg}}
  body{position:relative}
  svg{position:absolute;inset:0}
  .phone{position:absolute;background:linear-gradient(145deg,#4a4f54 0%,#1d2023 30%,#2b2f33 60%,#0f1113 100%);
    box-shadow:0 40px 90px rgba(0,0,0,.65),0 0 0 2px #5d6369 inset,0 0 0 5px #0b0c0d inset}
  .screen{width:100%;height:100%;overflow:hidden;position:relative;background:#000}
  .screen img{width:100%;height:100%;display:block;object-fit:cover;object-position:top}
  .island{position:absolute;left:50%;transform:translateX(-50%);background:#000;border-radius:999px}
  /* unten schreibt der App Store – Geräte tauchen ins Dunkel */
  .shade{position:absolute;left:0;right:0;bottom:0;height:34%;z-index:5;
    background:linear-gradient(180deg,rgba(8,26,15,0),rgba(8,26,15,.75) 55%,rgba(8,26,15,.95))}
  .vign{position:absolute;inset:0;z-index:4;background:radial-gradient(ellipse at 50% 45%,transparent 55%,rgba(0,0,0,.35))}
  .guide{position:absolute;z-index:9;border:3px dashed #f0f}
</style></head><body>
  <svg viewBox="0 0 ${W} ${H}" width="${W}" height="${H}" xmlns="http://www.w3.org/2000/svg">${scene}</svg>
  ${PHONES.map((p) => phone(lang, p)).join("")}
  <div class="vign"></div><div class="shade"></div>
  ${guides ? `<div class="guide" style="left:0;right:0;top:${SAFE.y}px;bottom:${SAFE.y}px"></div>
              <div class="guide" style="top:0;bottom:0;left:${SAFE.x}px;right:${SAFE.x}px"></div>` : ""}
</body></html>`;

// ── Suchergebnis ──────────────────────────────────────────────────────────
// Eigenes Bild, 3:2 (3840×2560). In der Suche zeigt der App Store davon nur
// einen flachen Streifen (~3:1, etwa 330 pt breit) – drei kleine Geräte werden
// dort unlesbar. Darum: eine kurze, große Aussage links, rechts EIN Gerät groß
// und angeschnitten, so dass „01“ und „Noch 350 m zum Loch“ lesbar bleiben.
// Alles Wichtige im mittleren Band (SW × SW/3), Rest ist nur Hintergrund.
const SW = 1920, SH = 1280;
const BAND = { top: (SH - SW / 3) / 2, bottom: (SH + SW / 3) / 2 };
const CLAIM = {
  de: "Entfernung<br>zur Fahne. <em>Live.</em>",
  en: "Distance<br>to the pin. <em>Live.</em>",
};

const searchHtml = (lang, guides) => {
  const pw = 600, ph = Math.round(pw * 2868 / 1320) + 18;
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:${SW}px;height:${SH}px;overflow:hidden;background:${C.bg}}
  body{position:relative;font-family:-apple-system,"SF Pro Display",BlinkMacSystemFont,sans-serif;
    -webkit-font-smoothing:antialiased;color:#fff}
  svg{position:absolute;inset:0}
  .phone{position:absolute;left:1140px;top:${BAND.top - 40}px;width:${pw}px;height:${ph}px;transform:rotate(7deg);
    border-radius:${pw * 0.15}px;padding:${pw * 0.026}px;z-index:3;
    background:linear-gradient(145deg,#4a4f54 0%,#1d2023 30%,#2b2f33 60%,#0f1113 100%);
    box-shadow:0 40px 90px rgba(0,0,0,.65),0 0 0 2px #5d6369 inset,0 0 0 5px #0b0c0d inset}
  .screen{width:100%;height:100%;overflow:hidden;position:relative;border-radius:${pw * 0.125}px}
  .screen img{width:100%;height:100%;display:block}
  .island{position:absolute;left:50%;top:${pw * 0.03}px;transform:translateX(-50%);
    width:${pw * 0.28}px;height:${pw * 0.085}px;background:#000;border-radius:999px}
  h1{position:absolute;left:150px;top:50%;transform:translateY(-50%);z-index:4;
    font-size:132px;line-height:1.02;font-weight:800;letter-spacing:-3.5px;text-shadow:0 6px 30px rgba(0,0,0,.45)}
  h1 em{font-style:normal;color:${C.gold}}
  .vign{position:absolute;inset:0;z-index:2;
    background:linear-gradient(90deg,rgba(8,26,15,.75),rgba(8,26,15,.15) 55%,transparent)}
  .guide{position:absolute;left:0;right:0;z-index:9;border:3px dashed #f0f}
</style></head><body>
  <svg viewBox="420 120 1950 1300" width="${SW}" height="${SH}" preserveAspectRatio="xMidYMid slice"
       xmlns="http://www.w3.org/2000/svg">${scene}</svg>
  <div class="vign"></div>
  <h1>${CLAIM[lang]}</h1>
  <div class="phone"><div class="screen"><img src="${shot(lang, "19-live-scorecard")}"><div class="island"></div></div></div>
  ${guides ? `<div class="guide" style="top:${BAND.top}px;height:${BAND.bottom - BAND.top}px"></div>` : ""}
</body></html>`;
};

const arg = process.argv[2] || "all";
const guides = process.argv.includes("--guides");
const langs = arg === "all" ? ["de", "en"] : [arg];
fs.mkdirSync(OUT, { recursive: true });

// --only header|search: nur eine Bildart rendern
const only = process.argv.includes("--only") ? process.argv[process.argv.indexOf("--only") + 1] : null;
const browser = await puppeteer.launch({ headless: true, protocolTimeout: 180000 });
const jobs = langs.flatMap((lang) => [
  { kind: "header", name: `header-${lang}-${W * SCALE}x${H * SCALE}`, w: W, h: H, html: () => html(lang, guides) },
  { kind: "search", name: `search-${lang}-${SW * SCALE}x${SH * SCALE}`, w: SW, h: SH, html: () => searchHtml(lang, guides) },
]).filter((job) => !only || job.kind === only);
for (const job of jobs) {
  // Je Bild eine frische Seite: Größenwechsel auf derselben Seite ließ das
  // Bildschirmfoto bei 5244 px hängen.
  const page = await browser.newPage();
  await page.setViewport({ width: job.w, height: job.h, deviceScaleFactor: SCALE });
  await page.setContent(job.html(), { waitUntil: "load" });
  const out = path.join(OUT, `${job.name}${guides ? "-guides" : ""}.png`);
  await page.screenshot({ path: out, clip: { x: 0, y: 0, width: job.w, height: job.h } });
  await page.close();
  // Apple lehnt Bilder mit Alphakanal ab.
  execFileSync("/usr/local/bin/python3.12", ["-c",
    "import sys;from PIL import Image;Image.open(sys.argv[1]).convert('RGB').save(sys.argv[1])", out]);
  console.log(`  ✓ ${path.relative(ROOT, out)}`);
}
await browser.close();
