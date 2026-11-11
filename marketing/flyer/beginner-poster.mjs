#!/usr/bin/env node
// GolfTrack – Einsteiger-Plakat (DIN A4 Hochformat, zusätzlich A3 hochskaliert) im App-Stil.
// Botschaft: Die App begleitet Golf-Neulinge von der Platzreife-Theorie über Training und
// Driving Range bis zur ersten eigenen Runde. Vier Stationen als ansteigender Weg mit
// echten Screenshots, gestrichelte Spur vom Ball zur Fahne, QR auf golftrack.app/download
// (Weiche App Store / Android-APK, web/src/app/(de)/download).
//
// Aufruf:  node beginner-poster.mjs [--png]
// Ausgabe: out/GolfTrack-Einsteiger-Plakat-A4.pdf
//          out/GolfTrack-Einsteiger-Plakat-A3.pdf
//          out/GolfTrack-Einsteiger-Plakat-Vorschau.png   (mit --png)
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import QRCode from "qrcode";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const wantPng = process.argv.includes("--png");
const DOWNLOAD = "https://golftrack.app/download";

const C = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", green: "#28824B" };
const accent = C.gold;

const b64 = (p) => fs.readFileSync(p).toString("base64");
// App-Icon in 1024 – das kleine logo.png wäre im Druck grenzwertig.
const logoB64 = b64(path.join(__dirname, "..", "..", "GolfTrackApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png"));
const shot = (rel) => b64(path.join(__dirname, "..", "screenshots", rel));

// Vier Stationen – links unten beginnend, nach rechts ansteigend.
const STEPS = [
  {
    img: shot("de-69/22-platzreife-uebersicht.png"),
    label: "Vor dem Platz",
    title: "Platzreife lernen",
    text: "150 Prüfungsfragen zu Regeln und Etikette. Fehler kommen zuerst dran, dazu eine Probeprüfung.",
  },
  {
    img: shot("de/12-training.png"),
    label: "Die Basics",
    title: "Griff, Stand, Schwung",
    text: "Kurze Audio-Lektionen zum Mithören. Die erste ist gratis.",
  },
  {
    img: shot("de-69/25-driving-range.png"),
    label: "Auf der Range",
    title: "Weiten kennenlernen",
    text: "Schläger wählen, Weite eintragen. So weißt du, wie weit jeder Schläger fliegt.",
  },
  {
    img: shot("de/19-live-scorecard.png"),
    label: "Auf dem Platz",
    title: "Deine erste Runde",
    text: "Schläge mit einem Tipp zählen, GPS-Distanz zur Fahne, der passende Schläger.",
  },
];

const svg = (paths) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${paths}</svg>`;
const ICON = {
  chart: svg(`<path d="M4.7 19.2h14.6"/><rect x="6.3" y="13" width="3.2" height="6"/><rect x="10.4" y="9.3" width="3.2" height="9.7"/><rect x="14.5" y="5.4" width="3.2" height="13.6"/>`),
  friends: svg(`<circle cx="9" cy="8.6" r="3"/><path d="M3.8 19c.6-3 2.7-4.6 5.2-4.6s4.6 1.6 5.2 4.6"/><circle cx="16.4" cy="9.6" r="2.4"/><path d="M15.6 14.5c2.3 0 4 1.3 4.6 4"/>`),
  bulb: svg(`<path d="M9.2 17.5h5.6"/><path d="M10 20.4h4"/><path d="M12 3.6a5.6 5.6 0 0 0-3.3 10.1c.5.4.8 1 .8 1.6v.4h5v-.4c0-.6.3-1.2.8-1.6A5.6 5.6 0 0 0 12 3.6Z"/>`),
};
const AFTER = [
  { icon: ICON.chart, text: "Handicap &amp; Statistik" },
  { icon: ICON.bulb, text: "Tipps, was du üben solltest" },
  { icon: ICON.friends, text: "Mit Freunden spielen" },
];

// ---- Geometrie der Weg-Zone (mm, relativ zur .journey-Box) ----
const JW = 186;          // Breite der Inhaltsfläche
const COLW = 42;         // Telefonbreite
const GAP = (JW - 4 * COLW) / 3;
const RISE = [30, 20, 10, 0]; // Oberkante je Telefon (ansteigend)
const MARK = 13;         // Platz über dem Telefon für die Nummer
const TOP = 8;           // Luft oben für die Fahne
const colX = (i) => i * (COLW + GAP);
const markY = (i) => TOP + RISE[i] + MARK / 2 - 1;
const markX = (i) => colX(i) + COLW / 2;

// Spur: Ball links unten → durch die vier Nummern → Fahne rechts oben
const pts = [[3, markY(0) + 7], ...[0, 1, 2, 3].map((i) => [markX(i), markY(i)]), [JW - 4, markY(3) - 3]];
let d = `M ${pts[0][0]} ${pts[0][1]}`;
for (let k = 1; k < pts.length; k++) {
  const [x0, y0] = pts[k - 1], [x1, y1] = pts[k];
  const mx = (x0 + x1) / 2;
  d += ` C ${mx} ${y0}, ${mx} ${y1}, ${x1} ${y1}`;
}

function buildHtml(qrDataUrl) {
  const W = 210, H = 297, pad = 12;
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html, body { width:${W}mm; height:${H}mm; }
  body {
    font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,"Helvetica Neue",sans-serif;
    color:#fff; -webkit-font-smoothing:antialiased;
    background:linear-gradient(180deg, #1F4630 0%, ${C.bg} 42%, #081A0F 100%);
  }
  .page { position:relative; width:${W}mm; height:${H}mm; overflow:hidden; }
  .frame { position:absolute; inset:0; padding:${pad}mm ${pad}mm ${pad - 2}mm; display:flex; flex-direction:column; }

  /* Fairway-Bogen hinter dem Weg (deckend, kein Overlay – PDF-Banding) */
  .fairway {
    position:absolute; left:-30mm; right:-30mm; top:118mm; height:240mm;
    border-radius:50% 50% 0 0 / 20% 20% 0 0; background:linear-gradient(180deg, #1C4129 0%, #12301E 40%, #0A1E12 100%);
    box-shadow:inset 0 0.6mm 0 ${accent}55;
  }

  .header { position:relative; display:flex; align-items:center; gap:3mm; }
  .logo { width:11mm; height:11mm; border-radius:2.8mm; overflow:hidden; box-shadow:inset 0 0 0 1px rgba(255,255,255,.1); }
  .logo img { width:100%; height:100%; display:block; }
  .brand { font-size:6mm; font-weight:800; letter-spacing:-.2mm; }
  .tag {
    margin-left:auto; border:0.4mm solid ${accent}66; background:rgba(255,255,255,.05);
    padding:1.7mm 3.8mm; border-radius:100px; font-size:3.3mm; font-weight:700; color:rgba(255,255,255,.88);
  }

  .eyebrow { position:relative; margin-top:9mm; font-size:4mm; font-weight:800; letter-spacing:1mm; text-transform:uppercase; color:${accent}; }
  .headline { position:relative; margin-top:2.6mm; font-size:15.4mm; font-weight:800; line-height:.98; letter-spacing:-.8mm; }
  .headline .accent { color:${accent}; }
  .sub { position:relative; margin-top:4.4mm; max-width:172mm; font-size:4.6mm; font-weight:500; line-height:1.38; color:rgba(255,255,255,.74); }

  /* Weg: vier ansteigende Telefone, unten von den Karten abgeschnitten */
  .journey { position:relative; flex:1 1 auto; margin-top:5mm; overflow:hidden; }
  .trail { position:absolute; left:0; top:0; width:${JW}mm; height:70mm; overflow:visible; }
  .phone {
    position:absolute; width:${COLW}mm; aspect-ratio:1206/2622;
    background:#050c08; border-radius:6.6mm; padding:1.3mm;
    box-shadow:inset 0 0 0 0.45mm #3a4a40;
  }
  .phone .screen { position:relative; width:100%; height:100%; }
  .phone img { width:100%; height:100%; display:block; border-radius:5.4mm; }
  .island { position:absolute; left:34.4%; width:31.2%; top:1.6%; height:4.2%; border-radius:100px; background:#000; }
  .num {
    position:absolute; width:9mm; height:9mm; margin:-4.5mm 0 0 -4.5mm; border-radius:50%;
    background:#fff; color:${C.bg}; font-size:4.8mm; font-weight:800; display:flex; align-items:center; justify-content:center;
    box-shadow:inset 0 0 0 0.6mm ${accent};
  }

  .steps { position:relative; display:grid; grid-template-columns:repeat(4, ${COLW}mm); column-gap:${GAP}mm; margin-top:-1mm; }
  .st { background:${C.card}; border-radius:3.6mm; padding:3.2mm 3mm 3.4mm; box-shadow:inset 0 0 0 0.3mm ${accent}38; }
  .st-label { font-size:2.6mm; font-weight:800; letter-spacing:.45mm; text-transform:uppercase; color:${accent}; }
  .st-title { margin-top:1.2mm; font-size:4mm; font-weight:800; letter-spacing:-.1mm; line-height:1.12; }
  .st-text { margin-top:1.2mm; font-size:2.95mm; font-weight:500; line-height:1.34; color:rgba(255,255,255,.66); }

  .after { position:relative; margin-top:3.6mm; display:flex; align-items:center; gap:3mm; }
  .after-lead { font-size:3.5mm; font-weight:800; color:${accent}; white-space:nowrap; }
  .chip { display:flex; align-items:center; gap:1.6mm; background:rgba(255,255,255,.06); border-radius:100px; padding:1.5mm 3.2mm 1.5mm 2.2mm; font-size:3.2mm; font-weight:600; color:rgba(255,255,255,.86); white-space:nowrap; }
  .chip svg { width:4.2mm; height:4.2mm; color:${accent}; display:block; }

  .cta {
    position:relative; margin-top:4.4mm; display:flex; align-items:center; gap:5.5mm;
    background:${C.cardAlt}; border-radius:5mm; padding:4mm 5mm;
    box-shadow:inset 0 0 0 0.45mm ${accent}66;
  }
  .qr { flex:0 0 auto; width:31mm; height:31mm; background:#fff; border-radius:3mm; padding:1.6mm; }
  .qr img { width:100%; height:100%; display:block; }
  .cta-text { flex:1 1 auto; }
  .cta-eyebrow { font-size:3.3mm; font-weight:800; letter-spacing:.7mm; text-transform:uppercase; color:${accent}; }
  .cta-title { margin-top:1.3mm; font-size:7.2mm; font-weight:800; line-height:1.05; letter-spacing:-.3mm; }
  .cta-note { margin-top:2mm; font-size:3.3mm; font-weight:500; color:rgba(255,255,255,.6); }
  .stores { flex:0 0 auto; align-self:center; display:flex; flex-direction:column; gap:2mm; }
  .store {
    display:flex; align-items:center; gap:2.2mm;
    background:#000; border-radius:2.6mm; padding:2.2mm 4mm 2.4mm 3.2mm; box-shadow:inset 0 0 0 0.3mm #7a7a7a;
  }
  .store svg { width:6.4mm; height:6.4mm; fill:#fff; }
  .store .s1 { font-size:2.3mm; font-weight:500; line-height:1; }
  .store .s2 { margin-top:.5mm; font-size:4.6mm; font-weight:700; line-height:1; letter-spacing:-.1mm; }

  .foot { position:relative; margin-top:3mm; display:flex; justify-content:space-between; font-size:3mm; font-weight:600; color:rgba(255,255,255,.45); }
</style></head><body><div class="page">
  <div class="fairway"></div>
  <div class="frame">
    <div class="header">
      <div class="logo"><img src="data:image/png;base64,${logoB64}"></div>
      <div class="brand">GolfTrack</div>
      <div class="tag">Neu im Golf? · iPhone &amp; Apple Watch</div>
    </div>

    <div class="eyebrow">Golf lernen mit einer App</div>
    <div class="headline">Von der Platzreife<br><span class="accent">bis zur ersten Runde.</span></div>
    <div class="sub">Theorie lernen, Grundlagen hören, auf der Range üben, dann raus auf den Platz: GolfTrack geht jeden Schritt mit dir.</div>

    <div class="journey">
      ${STEPS.map(
        (s, i) => `<div class="phone" style="left:${colX(i)}mm; top:${TOP + RISE[i] + MARK}mm"><div class="screen"><img src="data:image/png;base64,${s.img}"><div class="island"></div></div></div>`
      ).join("")}
      <svg class="trail" viewBox="0 0 ${JW} 70">
        <path d="${d}" fill="none" stroke="${accent}" stroke-width="0.7" stroke-linecap="round" stroke-dasharray="0.1 2.2"/>
        <circle cx="${pts[0][0]}" cy="${pts[0][1]}" r="2.2" fill="#fff"/>
        <g transform="translate(${pts[pts.length - 1][0] - 1.2} ${pts[pts.length - 1][1] - 11})">
          <path d="M1.2 0 V11" stroke="#fff" stroke-width="0.7" stroke-linecap="round"/>
          <path d="M1.5 0.4 L7.2 2.5 L1.5 4.6 Z" fill="${accent}"/>
          <ellipse cx="1.2" cy="11" rx="2.4" ry="0.8" fill="#081A0F"/>
        </g>
      </svg>
      ${STEPS.map((s, i) => `<div class="num" style="left:${markX(i)}mm; top:${markY(i)}mm">${i + 1}</div>`).join("")}
    </div>

    <div class="steps">${STEPS.map(
      (s) => `<div class="st"><div class="st-label">${s.label}</div><div class="st-title">${s.title}</div><div class="st-text">${s.text}</div></div>`
    ).join("")}</div>

    <div class="after">
      <div class="after-lead">Und danach:</div>
      ${AFTER.map((a) => `<div class="chip">${a.icon}<span>${a.text}</span></div>`).join("")}
    </div>

    <div class="cta">
      <div class="qr"><img src="${qrDataUrl}"></div>
      <div class="cta-text">
        <div class="cta-eyebrow">Kostenlos laden</div>
        <div class="cta-title">Code scannen,<br>heute anfangen.</div>
        <div class="cta-note">Gratis für iPhone und Android · GolfTrack Pro optional</div>
      </div>
      <div class="stores">
      <div class="store">
        <svg viewBox="0 0 24 24"><path d="M16.4 12.6c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9-.8 0-2-.9-3.4-.9-1.7 0-3.3 1-4.2 2.6-1.8 3.1-.5 7.7 1.3 10.2.9 1.2 1.9 2.6 3.2 2.6 1.3-.1 1.8-.8 3.3-.8s2 .8 3.4.8c1.4 0 2.3-1.3 3.1-2.5 1-1.4 1.4-2.8 1.4-2.9 0 0-2.7-1-2.7-4.1ZM13.9 5c.7-.9 1.2-2 1.1-3.2-1 0-2.3.7-3 1.6-.7.8-1.3 2-1.1 3.1 1.1.1 2.3-.6 3-1.5Z"/></svg>
        <div><div class="s1">Laden im</div><div class="s2">App Store</div></div>
      </div>
      <div class="store">
        <svg viewBox="0 0 24 24"><path d="M6 10.2a6 6 0 0 1 12 0Z"/><path d="M8.2 6.3 6.9 4.2M15.8 6.3l1.3-2.1" stroke="#fff" stroke-width="1" stroke-linecap="round"/><circle cx="9.6" cy="8.1" r=".75" fill="#000"/><circle cx="14.4" cy="8.1" r=".75" fill="#000"/><rect x="6" y="11" width="12" height="7.6" rx="1.4"/><rect x="3.4" y="11" width="1.9" height="5.6" rx=".95"/><rect x="18.7" y="11" width="1.9" height="5.6" rx=".95"/><rect x="8.3" y="18" width="1.9" height="3.4" rx=".95"/><rect x="13.8" y="18" width="1.9" height="3.4" rx=".95"/></svg>
        <div><div class="s1">Als APK für</div><div class="s2">Android</div></div>
      </div>
      </div>
    </div>

    <div class="foot"><span>golftrack.app</span><span>Golf &amp; Minigolf · Über 800 Plätze in Deutschland</span></div>
  </div>
</div></body></html>`;
}

const outDir = path.join(__dirname, "out");
fs.mkdirSync(outDir, { recursive: true });
const qrDataUrl = await QRCode.toDataURL(DOWNLOAD, {
  errorCorrectionLevel: "M", margin: 1, width: 900, color: { dark: "#10220D", light: "#FFFFFF" },
});
const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox", "--force-color-profile=srgb"] });
const base = path.join(outDir, "GolfTrack-Einsteiger-Plakat");

const page = await browser.newPage();
await page.setContent(buildHtml(qrDataUrl), { waitUntil: "networkidle0" });
// A4 nativ, A3 = gleiches Layout × √2. @page je Ziel setzen (fester @page im CSS verhindert das Skalieren).
for (const [fmt, w, h, scale] of [["A4", 210, 297, 1], ["A3", 297, 420, Math.SQRT2]]) {
  await page.addStyleTag({ content: `@page { size:${w}mm ${h}mm; margin:0; }` });
  const file = `${base}-${fmt}.pdf`;
  await page.pdf({ path: file, width: `${w}mm`, height: `${h}mm`, scale, printBackground: true, pageRanges: "1" });
  console.log("OK ->", path.basename(file));
}
if (wantPng) {
  await page.setViewport({ width: 794, height: 1123, deviceScaleFactor: 2 });
  await (await page.$(".page")).screenshot({ path: `${base}-Vorschau.png` });
  console.log("OK ->", path.basename(`${base}-Vorschau.png`));
}
await browser.close();
