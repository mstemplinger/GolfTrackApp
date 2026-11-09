#!/usr/bin/env node
// GolfTrack – Werbe-Visitenkarte 85 × 55 mm, doppelseitig (2 PDF-Seiten) im App-Stil.
// Zum Mitgeben auf dem Platz, an der Theke oder im Pro-Shop.
// Vorderseite: Marke + Claim. Rückseite: drei Argumente + QR zum App Store.
//
// Aufruf:  node business-card.mjs [out.pdf] [--bleed] [--sheet] [--png]
//   --bleed  3 mm Beschnittzugabe + Schnittmarken (für die Druckerei)
//   --sheet  DIN-A4-Bogen mit 10 Karten (2 × 5) zum Selbstdrucken, doppelseitig:
//            Seite 1 = Vorderseiten, Seite 2 = Rückseiten, deckungsgleich beim
//            Wenden an der langen Kante. Karten stoßen ohne Lücke aneinander und
//            der dunkle Grund läuft 2 mm über den Rand – so blitzt bei leichtem
//            Versatz zwischen Vorder- und Rückseite kein Weiß an den Schnittkanten.
//   --png    zusätzlich PNG-Vorschau je Seite
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import QRCode from "qrcode";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const flags = new Set(args.filter((a) => a.startsWith("--")));
const SHEET = flags.has("--sheet");
const BLEED = !SHEET && flags.has("--bleed") ? 3 : 0; // mm
const PNG = flags.has("--png");
const outPath =
  args.find((a) => !a.startsWith("--")) ||
  path.join(__dirname, "out", `GolfTrack-Visitenkarte${SHEET ? "n-A4-Bogen" : BLEED ? "-Beschnitt" : ""}.pdf`);
fs.mkdirSync(path.dirname(outPath), { recursive: true });

const APP_STORE_URL = "https://apps.apple.com/app/id6767996957";

// AppTheme-Farben (aus Shared/AppTheme.swift)
const C = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", green: "#28824B" };

// Visitenkarte EU-Standard + optionaler Beschnitt
const PW = 85 + 2 * BLEED;
const PH = 55 + 2 * BLEED;

// A4-Bogen: 2 Spalten × 5 Reihen = 170 × 275 mm, mittig auf 210 × 297 mm.
// Die Ränder (20 mm seitlich, 11 mm oben/unten) liegen außerhalb des nicht
// bedruckbaren Bereichs üblicher Bürodrucker.
const A4 = { w: 210, h: 297 };
const COLS = 2, ROWS = 5;
const GX = (A4.w - COLS * 85) / 2;
const GY = (A4.h - ROWS * 55) / 2;
const UNDER = 2; // mm dunkler Grund rund um das Raster

// Das App-Icon in 1024 – das kleine logo.png wäre im Druck grenzwertig.
const LOGO = path.join(__dirname, "..", "..",
  "GolfTrackApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png");
const logoB64 = fs.readFileSync(LOGO).toString("base64");

const qrStore = await QRCode.toDataURL(APP_STORE_URL, {
  errorCorrectionLevel: "M",
  margin: 1,
  width: 600,
  color: { dark: "#10220D", light: "#FFFFFF" },
});

// Linien-Icons wie im A5-Flyer, viewBox 24×24, Center 12,12
const svg = (paths) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${paths}</svg>`;
const ICON = {
  flag: svg(`<path d="M8 20V4"/><path d="M8 4.6 18 7 8 9.4z"/><path d="M6 20h4"/>`),
  pin: svg(
    `<path d="M12 20.5c4-3.8 6.3-6.8 6.3-10.3a6.3 6.3 0 1 0-12.6 0C5.7 13.7 8 16.7 12 20.5Z"/><circle cx="12" cy="10.2" r="2.4"/>`
  ),
  watch: svg(
    `<rect x="7" y="7" width="10" height="10" rx="3"/><path d="M9 7l.5-3.2h5L15 7"/><path d="M9 17l.5 3.2h5l.5-3.2"/><path d="M12 10.3v2.4h1.8"/>`
  ),
};

const points = [
  { icon: ICON.flag, text: "Digitale Scorekarte, auch im Flight" },
  { icon: ICON.pin, text: "GPS-Meter zu Grün, Bunker &amp; Wasser" },
  { icon: ICON.watch, text: "Alles auch an der Apple Watch" },
];

// Schnittmarken außerhalb des Endformats (nur mit --bleed)
const cropMarks = BLEED
  ? `<div class="crop tl"></div><div class="crop tr"></div><div class="crop bl"></div><div class="crop br"></div>`
  : "";

// Dezente Bahn mit Fahne als Hintergrundgrafik der Vorderseite (deckende Flächen,
// keine halbtransparenten Verläufe – die posterisiert Chromiums PDF-Ausgabe).
const fairway = `
<svg class="fairway" viewBox="0 0 850 550" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg">
  <path d="M -60 520 C 220 520, 260 380, 470 360 C 640 344, 720 380, 900 330"
        fill="none" stroke="${C.card}" stroke-width="120" stroke-linecap="round"/>
  <path d="M -60 520 C 220 520, 260 380, 470 360 C 640 344, 720 380, 900 330"
        fill="none" stroke="${C.cardAlt}" stroke-width="60" stroke-linecap="round"/>
  <ellipse cx="742" cy="352" rx="17" ry="7" fill="#081A0F"/>
  <rect x="739" y="250" width="5" height="102" rx="2.5" fill="#B9C2B5"/>
  <path d="M 744 256 L 812 275 L 744 294 Z" fill="${C.gold}"/>
</svg>`;

const frontCard = `<section class="card front">
  ${fairway}
  <div class="inner">
    <div class="brand">
      <img src="data:image/png;base64,${logoB64}" alt="">
      <div>
        <div class="name">GolfTrack</div>
        <div class="sub">Golf &amp; Minigolf</div>
      </div>
    </div>
    <div>
      <div class="claim">Deine Runde.<br><em>Jeder Schlag gezählt.</em></div>
      <div class="tag">Scorekarte · GPS · Statistik · Apple Watch</div>
    </div>
  </div>
  ${cropMarks}
</section>`;

const backCard = `<section class="card back">
  <div class="inner">
    <div class="left">
      <h2>Schluss mit Bleistift<br>und Papierkarte.</h2>
      <ul class="pts">
        ${points.map((p) => `<li><span class="ic">${p.icon}</span>${p.text}</li>`).join("")}
      </ul>
      <div class="foot"><b>golftrack.app</b><br>Android: golftrack.app/android</div>
    </div>
    <div class="qrbox">
      <div class="qr"><img src="${qrStore}" alt=""></div>
      <div class="cta">Scannen &amp; laden</div>
      <div class="free">Gratis im App Store</div>
    </div>
  </div>
  ${cropMarks}
</section>`;

// Ein A4-Bogen mit 10 gleichen Karten. Für die Rückseite wird das Raster an
// der senkrechten Mittelachse gespiegelt (Wenden an der langen Kante); weil
// das Raster mittig sitzt, landet jede Rückseite exakt hinter ihrer Vorderseite.
function sheet(card, mirror) {
  const cells = [];
  for (let r = 0; r < ROWS; r++)
    for (let c = 0; c < COLS; c++) {
      const x = mirror ? A4.w - GX - (c + 1) * 85 : GX + c * 85;
      cells.push(card.replace('class="card', `style="left:${x}mm;top:${GY + r * 55}mm" class="card`));
    }
  // Schnittmarken im weißen Rand an jeder Schnittlinie
  const marks = [];
  for (let c = 0; c <= COLS; c++) {
    const x = GX + c * 85;
    marks.push(`<div class="mark" style="left:${x - 0.1}mm;top:4mm;width:.2mm;height:${GY - UNDER - 5}mm"></div>`);
    marks.push(`<div class="mark" style="left:${x - 0.1}mm;top:${A4.h - GY + UNDER + 1}mm;width:.2mm;height:${GY - UNDER - 5}mm"></div>`);
  }
  for (let r = 0; r <= ROWS; r++) {
    const y = GY + r * 55;
    marks.push(`<div class="mark" style="top:${y - 0.1}mm;left:5mm;height:.2mm;width:${GX - UNDER - 6}mm"></div>`);
    marks.push(`<div class="mark" style="top:${y - 0.1}mm;left:${A4.w - GX + UNDER + 1}mm;height:.2mm;width:${GX - UNDER - 6}mm"></div>`);
  }
  const under = `<div class="under" style="left:${GX - UNDER}mm;top:${GY - UNDER}mm;width:${COLS * 85 + 2 * UNDER}mm;height:${ROWS * 55 + 2 * UNDER}mm"></div>`;
  return `<div class="page sheet">${under}${cells.join("")}${marks.join("")}</div>`;
}

const html = `<!doctype html><html lang="de"><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family:-apple-system, "SF Pro Display", "Helvetica Neue", Arial, sans-serif;
         color:#fff; -webkit-print-color-adjust:exact; print-color-adjust:exact; }
  @page { size: ${SHEET ? `${A4.w}mm ${A4.h}mm` : `${PW}mm ${PH}mm`}; margin: 0; }
  .card { width:${PW}mm; height:${PH}mm; position:relative; overflow:hidden;
          background:linear-gradient(160deg, #143220 0%, ${C.bg} 60%, #0A1E12 100%); }
  .page { page-break-after:always; }
  .page:last-child { page-break-after:auto; }
  html, body { background:${SHEET ? "#fff" : C.bg}; }
  .sheet { width:${A4.w}mm; height:${A4.h}mm; position:relative; overflow:hidden; background:#fff; }
  .sheet .card { position:absolute; }
  .under { position:absolute; background:${C.bg}; }
  .mark { position:absolute; background:#000; }
  /* Sicherheitsabstand: 4 mm vom Endformat */
  .inner { position:absolute; inset:${BLEED + 4}mm; }

  /* ── Vorderseite ── */
  .fairway { position:absolute; inset:0; width:100%; height:100%; }
  .front .inner { display:flex; flex-direction:column; justify-content:space-between; }
  .brand { display:flex; align-items:center; gap:3.2mm; }
  .brand img { width:13mm; height:13mm; border-radius:3mm;
               box-shadow:inset 0 0 0 .2mm ${C.gold}55; }
  .brand .name { font-size:6.4mm; font-weight:700; letter-spacing:-.15mm; line-height:1; }
  .brand .sub { font-size:2.35mm; color:${C.gold}; font-weight:600; letter-spacing:.35mm;
                text-transform:uppercase; margin-top:1.1mm; }
  .claim { font-size:4.3mm; font-weight:700; line-height:1.15; letter-spacing:-.05mm; max-width:52mm; }
  .claim em { font-style:normal; color:${C.gold}; }
  .tag { font-size:2.3mm; color:#C9D3C6; margin-top:1.4mm; }

  /* ── Rückseite ── */
  .back .inner { display:flex; gap:4mm; align-items:stretch; }
  .back .left { flex:1; display:flex; flex-direction:column; justify-content:space-between; }
  .back h2 { font-size:3.5mm; font-weight:700; line-height:1.15; }
  .back h2 em { font-style:normal; color:${C.gold}; }
  .pts { list-style:none; display:flex; flex-direction:column; gap:1.9mm; }
  .pts li { display:flex; align-items:center; gap:1.8mm; font-size:2.35mm; line-height:1.2; color:#E4EAE2; }
  .pts .ic { flex:none; width:4.6mm; height:4.6mm; border-radius:1.2mm; background:${C.cardAlt};
             color:${C.gold}; display:flex; align-items:center; justify-content:center;
             box-shadow:inset 0 0 0 .15mm ${C.gold}44; }
  .pts .ic svg { width:3.2mm; height:3.2mm; }
  .foot { font-size:2.1mm; color:#AEBBAA; line-height:1.35; }
  .foot b { color:#fff; font-weight:600; }
  .qrbox { flex:none; width:25mm; display:flex; flex-direction:column; align-items:center; justify-content:center;
           gap:1.6mm; }
  .qrbox .qr { width:25mm; height:25mm; background:#fff; border-radius:2mm; padding:1.2mm; }
  .qrbox .qr img { width:100%; height:100%; display:block; }
  .qrbox .cta { font-size:2.3mm; font-weight:700; color:${C.gold}; text-align:center; line-height:1.2; }
  .qrbox .free { font-size:1.9mm; color:#AEBBAA; text-align:center; }

  /* Schnittmarken */
  .crop { position:absolute; width:${BLEED}mm; height:${BLEED}mm; }
  .crop::before, .crop::after { content:""; position:absolute; background:#fff; }
  .crop.tl { left:0; top:0; } .crop.tr { right:0; top:0; }
  .crop.bl { left:0; bottom:0; } .crop.br { right:0; bottom:0; }
  .crop::before { width:100%; height:.1mm; } .crop::after { width:.1mm; height:100%; }
  .crop.tl::before, .crop.tr::before { bottom:0; } .crop.bl::before, .crop.br::before { top:0; }
  .crop.tl::after, .crop.bl::after { right:0; } .crop.tr::after, .crop.br::after { left:0; }
</style></head><body>
${SHEET ? sheet(frontCard, false) + sheet(backCard, true) : `<div class="page">${frontCard}</div><div class="page">${backCard}</div>`}
</body></html>`;

const browser = await puppeteer.launch({ headless: true });
try {
  const page = await browser.newPage();
  await page.setContent(html, { waitUntil: "load" });
  const [W, H] = SHEET ? [A4.w, A4.h] : [PW, PH];
  await page.pdf({ path: outPath, width: `${W}mm`, height: `${H}mm`, printBackground: true });
  console.log(`geschrieben: ${outPath}`);

  if (PNG) {
    // 1 mm ≈ 3.78 px bei 96 dpi; Faktor 8 ergibt ~770 dpi für eine scharfe Vorschau.
    await page.setViewport({ width: Math.ceil(W * 3.78), height: Math.ceil(H * 3.78 * 2), deviceScaleFactor: SHEET ? 3 : 8 });
    const pages = await page.$$(SHEET ? ".sheet" : ".card");
    for (const [i, el] of pages.entries()) {
      const png = outPath.replace(/\.pdf$/, `-${i === 0 ? "vorne" : "hinten"}.png`);
      await el.screenshot({ path: png });
      console.log(`geschrieben: ${png}`);
    }
  }
} finally {
  await browser.close();
}
