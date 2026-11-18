#!/usr/bin/env node
// GolfTrack – Fotomontage der Bauzaunplane in die echte Szene (1. Abschlag Passau-Raßbach, Zaun auf der Mauer).
// Legt die Textur aus fence-banner.mjs perspektivisch korrekt (Homographie → CSS matrix3d) ins Foto.
//
// Foto: out/bauzaun/szene/foto-abschlag.jpg (2000 × 1125, vom Weg oberhalb des Abschlags)
// Eckpunkte aus dem Foto vermessen: Die vorhandene Plane ist ebenfalls 340 × 173 cm (Seitenverhältnis passt),
// Doppelstabmatten-Feld 2,5 m ≈ 298 px, Zaunhöhe ≈ 1,83 m.
//   ersatz  – anstelle der vorhandenen Plane, das grüne Schild davor bleibt im Vordergrund
//   daneben – auf dem freien Feld rechts bis zur Netzstange (≈ 3,5 m frei)
//
// Aufruf:  node fence-banner.mjs --platz="…" && node fence-banner-mockup.mjs
// Ausgabe: out/bauzaun/szene/montage-<variante>.jpg und montage-<variante>-nah.jpg
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dir = path.join(__dirname, "out", "bauzaun", "szene");
const photo = fs.readFileSync(path.join(dir, "foto-abschlag.jpg")).toString("base64");
const tex = fs.readFileSync(path.join(__dirname, "out", "bauzaun", "tex", "abschlag.png")).toString("base64");
const PW = 2000, PH = 1125;
const TW = 1700, TH = 865; // Texturfläche im Montage-DOM (Seitenverhältnis 340:173)

// Ecken: oben links, oben rechts, unten rechts, unten links
const VARIANTS = {
  ersatz: { quad: [[248, 381], [660, 358], [660, 652], [248, 698]],
            // Schild + Pfosten vorne links verdecken die Plane → Foto dort wieder darüberlegen
            occluders: [
              [[185, 515], [215, 515], [215, 540], [240, 544], [262, 551], [282, 560], [297, 568], [297, 1125], [185, 1125]], // Schild
              [[302, 561], [309, 561], [309, 1125], [302, 1125]],                                                              // Pfosten
            ],
            crop: [140, 250, 1100, 600] },
  daneben: { quad: [[680, 356.5], [1081, 328], [1081, 610.6], [680, 649.6]], occluders: [], crop: [180, 230, 1100, 600] },
};

// Homographie Rechteck (0,0,w,h) → Viereck, als CSS matrix3d
function solve(A, b) {
  const n = b.length;
  for (let i = 0; i < n; i++) {
    let m = i;
    for (let r = i + 1; r < n; r++) if (Math.abs(A[r][i]) > Math.abs(A[m][i])) m = r;
    [A[i], A[m]] = [A[m], A[i]]; [b[i], b[m]] = [b[m], b[i]];
    for (let r = i + 1; r < n; r++) {
      const f = A[r][i] / A[i][i];
      for (let c = i; c < n; c++) A[r][c] -= f * A[i][c];
      b[r] -= f * b[i];
    }
  }
  const x = Array(n).fill(0);
  for (let i = n - 1; i >= 0; i--) {
    let s = b[i];
    for (let c = i + 1; c < n; c++) s -= A[i][c] * x[c];
    x[i] = s / A[i][i];
  }
  return x;
}
function matrix3d(w, h, quad) {
  const src = [[0, 0], [w, 0], [w, h], [0, h]];
  const A = [], b = [];
  src.forEach(([x, y], i) => {
    const [u, v] = quad[i];
    A.push([x, y, 1, 0, 0, 0, -u * x, -u * y]); b.push(u);
    A.push([0, 0, 0, x, y, 1, -v * x, -v * y]); b.push(v);
  });
  const [a, bb, c, d, e, f, g, hh] = solve(A, b);
  // Spaltenweise für CSS: (a d 0 g) (b e 0 h) (0 0 1 0) (c f 0 1)
  return `matrix3d(${[a, d, 0, g, bb, e, 0, hh, 0, 0, 1, 0, c, f, 0, 1].join(",")})`;
}

function html(v) {
  const occ = v.occluders.map((poly) => `<div class="occ" style="clip-path:polygon(${poly.map(([x, y]) => `${x}px ${y}px`).join(",")})"></div>`).join("");
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; }
  body { width:${PW}px; height:${PH}px; overflow:hidden; }
  .photo, .occ { position:absolute; inset:0; background:url(data:image/jpeg;base64,${photo}) 0 0 / ${PW}px ${PH}px; }
  .banner { position:absolute; left:0; top:0; width:${TW}px; height:${TH}px; transform-origin:0 0; transform:${matrix3d(TW, TH, v.quad)}; }
  /* An das Foto angleichen: bedeckter Himmel, leichter Dunst, Handykamera-Schärfe */
  .banner img { width:100%; height:100%; display:block; filter:brightness(.9) contrast(.9) saturate(.88) blur(1.2px); }
  .banner .haze { position:absolute; inset:0; background:linear-gradient(180deg,rgba(214,222,206,.10),rgba(214,222,206,.04)); }
  /* Saum: Plane ist umgenäht, Kante minimal heller */
  .banner .hem { position:absolute; inset:0; box-shadow:inset 0 0 0 6px rgba(255,255,255,.08); }
</style></head><body>
  <div class="photo"></div>
  <div class="banner"><img src="data:image/png;base64,${tex}"><div class="haze"></div><div class="hem"></div></div>
  ${occ}
</body></html>`;
}

const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox", "--force-color-profile=srgb"] });
for (const [name, v] of Object.entries(VARIANTS)) {
  const page = await browser.newPage();
  await page.setViewport({ width: PW, height: PH, deviceScaleFactor: 1 });
  await page.setContent(html(v), { waitUntil: "load" });
  await page.screenshot({ path: path.join(dir, `montage-${name}.jpg`), type: "jpeg", quality: 90 });
  const [x, y, w, h] = v.crop;
  await page.setViewport({ width: PW, height: PH, deviceScaleFactor: 2 });
  await page.screenshot({ path: path.join(dir, `montage-${name}-nah.jpg`), type: "jpeg", quality: 90, clip: { x, y, width: w, height: h } });
  await page.close();
  console.log("OK ->", `montage-${name}.jpg`);
}
await browser.close();
