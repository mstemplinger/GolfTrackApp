// GolfTrack – gemeinsamer Baustein für gestaltete Store-Bilder (1320×2868).
//
// Wird von `store-shots.mjs` (Hauptseite) und `cpp-shots.mjs` (benutzerdefinierte
// Produktseiten) benutzt, damit beide dasselbe Aussehen haben: Rohbild im
// gezeichneten Gerät auf dem App-Hintergrund, darüber Kicker, Überschrift und
// Unterzeile.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(path.join(__dirname, "..", "flyer", "package.json"));
export const puppeteer = require("puppeteer");

export const ROOT = path.join(__dirname, "..", "..");
export const SHOTS = path.join(ROOT, "marketing", "screenshots");
export const OUT = path.join(__dirname, "out");

export const W = 1320;
export const H = 2868;

// Dieselben Farben wie AppTheme in der App.
export const C = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", green: "#28824B", light: "#7BD389" };

const logo = "data:image/png;base64," +
  fs.readFileSync(path.join(ROOT, "GolfTrackApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png")).toString("base64");

/// Rohbild einer Sprache: erst die 6,9-Zoll-Aufnahme, sonst die Website-Aufnahme
/// derselben Sprache – nie die andere Sprache, sonst steht Deutsch auf der
/// englischen Seite.
export function shotPath(lang, name) {
  for (const dir of [`${lang}-69`, lang]) {
    const p = path.join(SHOTS, dir, name + ".png");
    if (fs.existsSync(p)) return p;
  }
  return null;
}

export function dataURI(file) {
  return "data:image/png;base64," + fs.readFileSync(file).toString("base64");
}

/// `t`: { kicker, title, sub } · `tilt`: Neigung des Geräts in Grad (0 = gerade)
/// `device`: "phone" (Standard) oder "watch" für Aufnahmen der Apple Watch.
export function slideHtml(t, shotURI, { tilt = 0, device = "phone" } = {}) {
  const frame = device === "watch"
    ? `<div class="watch">
         <div class="band top"></div><div class="band bottom"></div>
         <div class="crown"></div><div class="side"></div>
         <div class="case"><div class="wscreen"><img src="${shotURI}"></div></div>
       </div>`
    : `<div class="phone"><div class="screen"><img src="${shotURI}"><div class="island"></div></div></div>`;
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html,body { width:${W}px; height:${H}px; overflow:hidden; }
  body {
    font-family:-apple-system,"SF Pro Display",BlinkMacSystemFont,sans-serif;
    color:#fff; -webkit-font-smoothing:antialiased; position:relative;
    background:
      radial-gradient(120% 45% at 50% -4%, ${C.light}33 0%, transparent 60%),
      radial-gradient(90% 40% at ${tilt < 0 ? "0%" : "100%"} 100%, ${C.gold}26 0%, transparent 60%),
      linear-gradient(180deg, ${C.cardAlt} 0%, ${C.bg} 45%, #0A1E12 100%);
  }
  /* feine Fairway-Streifen, wie gemähter Rasen */
  body::before { content:""; position:absolute; inset:0; opacity:.03;
    background:repeating-linear-gradient(115deg, #fff 0 90px, transparent 90px 180px); }
  .text { position:absolute; left:110px; right:110px; top:190px; z-index:2; }
  .kicker { display:inline-flex; align-items:center; gap:18px; font-size:40px; font-weight:800;
    letter-spacing:6px; text-transform:uppercase; color:${C.gold}; white-space:nowrap; }
  .kicker img { width:64px; height:64px; border-radius:15px; box-shadow:0 6px 20px rgba(0,0,0,.4); }
  h1 { margin-top:36px; font-size:132px; line-height:1.0; font-weight:800; letter-spacing:-3.5px; white-space:nowrap; }
  h1 em { font-style:normal; color:${C.light}; }
  .sub { margin-top:40px; font-size:50px; line-height:1.28; font-weight:500; color:rgba(255,255,255,.72); max-width:1060px; }

  .phone { position:absolute; left:50%; top:1010px; width:1020px; height:${Math.round(1020 * 2868 / 1320) + 52}px;
    transform:translateX(-50%) rotate(${tilt}deg); transform-origin:50% 30%;
    border-radius:150px; padding:26px;
    background:linear-gradient(145deg,#4a4f54 0%,#1d2023 30%,#2b2f33 60%,#0f1113 100%);
    box-shadow:0 60px 140px rgba(0,0,0,.6), 0 0 0 3px #5d6369 inset, 0 0 0 9px #0b0c0d inset; }
  .screen { width:100%; height:100%; border-radius:126px; overflow:hidden; position:relative; background:#000; }
  .screen img { width:100%; height:100%; display:block; }
  .island { position:absolute; top:30px; left:50%; transform:translateX(-50%); width:290px; height:86px;
    background:#000; border-radius:50px; }
  .glow { position:absolute; left:50%; top:1300px; width:1300px; height:900px; transform:translateX(-50%);
    background:radial-gradient(closest-side, ${C.green}55, transparent); filter:blur(40px); }

  /* Apple Watch: Gehäuse mit Krone, Armband läuft oben und unten aus dem Bild. */
  .watch { position:absolute; left:50%; top:1290px; width:860px; height:1010px;
    transform:translateX(-50%) rotate(${tilt}deg); transform-origin:50% 50%; }
  .band { position:absolute; left:50%; width:640px; transform:translateX(-50%);
    background:linear-gradient(90deg,#0d2416 0%,#1d4a2e 18%,#236039 50%,#1d4a2e 82%,#0d2416 100%);
    box-shadow:0 40px 120px rgba(0,0,0,.55); }
  .band.top { top:-560px; height:700px; border-radius:120px 120px 0 0; }
  .band.bottom { top:870px; height:1500px; }
  .crown { position:absolute; right:-34px; top:250px; width:58px; height:150px; border-radius:20px;
    background:linear-gradient(90deg,#2b2f33,#6a7077 45%,#1d2023); box-shadow:0 0 0 3px #0b0c0d inset; }
  .side { position:absolute; right:-18px; top:520px; width:30px; height:210px; border-radius:14px;
    background:linear-gradient(90deg,#2b2f33,#565c62 50%,#1d2023); }
  .case { position:absolute; inset:0; border-radius:230px; padding:58px;
    background:linear-gradient(145deg,#4a4f54 0%,#1d2023 30%,#2b2f33 60%,#0f1113 100%);
    box-shadow:0 60px 140px rgba(0,0,0,.6), 0 0 0 3px #5d6369 inset, 0 0 0 12px #0b0c0d inset; }
  .wscreen { width:100%; height:100%; border-radius:176px; overflow:hidden; background:#000; }
  .wscreen img { width:100%; height:100%; display:block; object-fit:cover; }
</style></head><body>
  <div class="glow"></div>
  <div class="text">
    <div class="kicker"><img src="${logo}">${t.kicker}</div>
    <h1>${t.title}</h1>
    <div class="sub">${t.sub}</div>
  </div>
  ${frame}
</body></html>`;
}

/// Rendert ein Bild. Eine Überschriftzeile, die breiter ist als die Textspalte,
/// wird verkleinert statt umbrochen – sonst schiebt sie den Text ins Gerät.
/// Liefert Hinweise, wenn der Textblock dem Gerät zu nahe kommt.
export async function renderSlide(page, html, out) {
  await page.setContent(html, { waitUntil: "load" });
  const info = await page.evaluate(() => {
    const h1 = document.querySelector("h1");
    const col = document.querySelector(".text").clientWidth;
    let size = parseFloat(getComputedStyle(h1).fontSize);
    while (h1.scrollWidth > col && size > 80) {
      size -= 4;
      h1.style.fontSize = size + "px";
      h1.style.letterSpacing = (-3.5 * size / 132) + "px";
    }
    const device = document.querySelector(".phone, .case").getBoundingClientRect();
    return { size, textBottom: document.querySelector(".text").getBoundingClientRect().bottom, deviceTop: device.top };
  });
  await page.screenshot({ path: out, clip: { x: 0, y: 0, width: W, height: H } });
  const notes = [];
  if (info.size < 132) notes.push(`Überschrift auf ${info.size}px verkleinert`);
  if (info.textBottom > info.deviceTop - 20) notes.push(`Text reicht bis ${Math.round(info.textBottom)}px, Gerät beginnt bei ${Math.round(info.deviceTop)}px`);
  return notes;
}
