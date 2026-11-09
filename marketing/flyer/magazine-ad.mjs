#!/usr/bin/env node
// GolfTrack – ganzseitige Zeitschriften-Anzeige (DIN A4 Hochformat) im App-Stil.
// Große Headline, drei iPhones mit echten Screenshots, vier Argumente, QR zum App Store.
// Inhalte halten 10 mm Abstand zum Endformat (Satzspiegel für Magazin-Druck).
//
// Aufruf:  node magazine-ad.mjs [--png]
// Ausgabe: out/GolfTrack-Anzeige-A4.pdf            (Endformat 210×297 mm)
//          out/GolfTrack-Anzeige-A4-Beschnitt.pdf  (216×303 mm, 3 mm Beschnitt, ohne Marken – Druckdaten)
//          out/GolfTrack-Anzeige-A4-Vorschau.png   (mit --png)
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import QRCode from "qrcode";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const wantPng = process.argv.includes("--png");
const APP_STORE = "https://apps.apple.com/app/id6767996957";

const C = {
  bg: "#0E2718",
  card: "#163421",
  cardAlt: "#1C4129",
  gold: "#C9A035",
  green: "#28824B",
};
const accent = C.gold;

const b64 = (p) => fs.readFileSync(p).toString("base64");
const logoB64 = b64(path.join(__dirname, "logo.png"));
const shot = (name) => b64(path.join(__dirname, "..", "screenshots", "de", `${name}.png`));
const SHOTS = { left: shot("04-schlaegerdistanzen"), center: shot("19-live-scorecard"), right: shot("06-statistiken-chart") };

const svg = (paths) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${paths}</svg>`;
const ICON = {
  pin: svg(`<path d="M12 20.5c4-3.8 6.3-6.8 6.3-10.3a6.3 6.3 0 1 0-12.6 0C5.7 13.7 8 16.7 12 20.5Z"/><circle cx="12" cy="10.2" r="2.4"/>`),
  card: svg(`<rect x="4" y="5" width="16" height="14" rx="2.2"/><path d="M4 10h16"/><path d="M9.3 10v9"/><path d="M14.7 10v9"/>`),
  chart: svg(`<path d="M4.7 19.2h14.6"/><rect x="6.3" y="13" width="3.2" height="6"/><rect x="10.4" y="9.3" width="3.2" height="9.7"/><rect x="14.5" y="5.4" width="3.2" height="13.6"/>`),
  watch: svg(`<rect x="7" y="7" width="10" height="10" rx="3"/><path d="M9 7l.5-3.2h5L15 7"/><path d="M9 17l.5 3.2h5l.5-3.2"/><path d="M12 10.3v2.4h1.8"/>`),
};
const POINTS = [
  { icon: ICON.pin, title: "GPS zur Fahne", text: "Distanz auf den Meter, bei jedem Schlag." },
  { icon: ICON.card, title: "Über 800 Plätze", text: "Par, Handicap und Längen schon drin." },
  { icon: ICON.chart, title: "Statistik, die hilft", text: "Fairways, Grüns, Putts, Schlägerweiten." },
  { icon: ICON.watch, title: "Apple Watch", text: "Zählen am Handgelenk, iPhone bleibt weg." },
];

function buildHtml(bleed, qrDataUrl) {
  const W = 210 + 2 * bleed, H = 297 + 2 * bleed;
  const pad = 10 + bleed; // Satzspiegel: 10 mm ab Endformat
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  @page { size:${W}mm ${H}mm; margin:0; }
  html, body { width:${W}mm; height:${H}mm; }
  body {
    font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,"Helvetica Neue",sans-serif;
    color:#fff; -webkit-font-smoothing:antialiased;
    background:linear-gradient(180deg, #1F4630 0%, ${C.bg} 46%, #081A0F 100%);
  }
  .page { position:relative; width:${W}mm; height:${H}mm; overflow:hidden; }
  .frame { position:absolute; inset:0; padding:${pad + 2}mm ${pad + 2}mm ${pad}mm; display:flex; flex-direction:column; }

  /* Fairway-Bogen hinter den Telefonen (deckend, kein Verlaufs-Overlay – PDF-Banding) */
  .fairway {
    position:absolute; left:${-30 + bleed}mm; right:${-30 + bleed}mm; top:${148 + bleed}mm; height:240mm;
    border-radius:50% 50% 0 0 / 22% 22% 0 0; background:linear-gradient(180deg, #1C4129 0%, #12301E 40%, #0A1E12 100%);
    box-shadow:inset 0 0.6mm 0 ${accent}55;
  }

  .header { position:relative; display:flex; align-items:center; gap:3mm; }
  .logo { width:12mm; height:12mm; border-radius:3mm; overflow:hidden; box-shadow:inset 0 0 0 1px rgba(255,255,255,.1); }
  .logo img { width:100%; height:100%; display:block; }
  .brand { font-size:6.4mm; font-weight:800; letter-spacing:-.2mm; }
  .tag {
    margin-left:auto; border:0.4mm solid ${accent}66; background:rgba(255,255,255,.05);
    padding:1.8mm 4mm; border-radius:100px; font-size:3.4mm; font-weight:700; color:rgba(255,255,255,.88);
  }

  .eyebrow { position:relative; margin-top:12mm; font-size:4mm; font-weight:800; letter-spacing:1mm; text-transform:uppercase; color:${accent}; }
  .headline { position:relative; margin-top:3mm; font-size:17mm; font-weight:800; line-height:.98; letter-spacing:-.9mm; }
  .headline .accent { color:${accent}; }
  .sub { position:relative; margin-top:5mm; max-width:150mm; font-size:4.9mm; font-weight:500; line-height:1.38; color:rgba(255,255,255,.74); }

  /* Drei iPhones, Mitte vorne und größer */
  /* unten abgeschnitten, sonst schauen die Telefone zwischen den Karten durch */
  .phones { position:relative; flex:1 1 auto; margin-top:6mm; overflow:hidden; margin-left:-${pad}mm; margin-right:-${pad}mm; padding:0 ${pad}mm; }
  .phone {
    position:absolute; aspect-ratio:1206/2622;
    background:#050c08; border-radius:8mm; padding:1.5mm;
    box-shadow:inset 0 0 0 0.5mm #3a4a40;
  }
  .phone .screen { position:relative; width:100%; height:100%; }
  .phone img { width:100%; height:100%; display:block; border-radius:6.6mm; }
  /* Dynamic Island – Lage aus den Screenshots gemessen (1206×2622: x 415–790, y 42–151),
     deckt sich mit der Island, die manche Screenshots schon enthalten */
  .island { position:absolute; left:34.4%; width:31.2%; top:1.6%; height:4.2%; border-radius:100px; background:#000; }
  .phone.side { width:47mm; top:12mm; }
  .phone.l { left:${pad + 6}mm; transform:rotate(-7deg); }
  .phone.r { right:${pad + 6}mm; transform:rotate(7deg); }
  .phone.c { width:55mm; left:50%; top:0; transform:translateX(-50%); border-radius:9mm; }
  .phone.c img { border-radius:7.6mm; }

  .points { position:relative; display:grid; grid-template-columns:repeat(4, 1fr); gap:3mm; margin-top:5mm; }
  .pt { background:${C.card}; border-radius:4mm; padding:3.6mm 3.2mm 3.8mm; box-shadow:inset 0 0 0 0.3mm ${accent}38; }
  .pt-icon { width:8.6mm; height:8.6mm; border-radius:2.4mm; color:${accent}; display:flex; align-items:center; justify-content:center; background:${C.cardAlt}; }
  .pt-icon svg { width:5mm; height:5mm; display:block; }
  .pt-title { margin-top:2.4mm; font-size:4mm; font-weight:800; letter-spacing:-.1mm; line-height:1.12; }
  .pt-text { margin-top:1mm; font-size:3.1mm; font-weight:500; line-height:1.32; color:rgba(255,255,255,.64); }

  .cta {
    position:relative; margin-top:5mm; display:flex; align-items:center; gap:6mm;
    background:${C.cardAlt}; border-radius:5.5mm; padding:4.4mm 5.5mm;
    box-shadow:inset 0 0 0 0.45mm ${accent}66;
  }
  .qr { flex:0 0 auto; width:34mm; height:34mm; background:#fff; border-radius:3.2mm; padding:1.8mm; }
  .qr img { width:100%; height:100%; display:block; }
  .cta-text { flex:1 1 auto; }
  .cta-eyebrow { font-size:3.4mm; font-weight:800; letter-spacing:.7mm; text-transform:uppercase; color:${accent}; }
  .cta-title { margin-top:1.4mm; font-size:7.6mm; font-weight:800; line-height:1.05; letter-spacing:-.3mm; }
  .cta-note { margin-top:2.2mm; font-size:3.4mm; font-weight:500; color:rgba(255,255,255,.6); }
  .store {
    flex:0 0 auto; align-self:center; display:flex; align-items:center; gap:2.2mm;
    background:#000; border-radius:2.6mm; padding:2.2mm 4mm 2.4mm 3.2mm; box-shadow:inset 0 0 0 0.3mm #7a7a7a;
  }
  .store svg { width:6.4mm; height:6.4mm; fill:#fff; }
  .store .s1 { font-size:2.3mm; font-weight:500; line-height:1; }
  .store .s2 { margin-top:.5mm; font-size:4.6mm; font-weight:700; line-height:1; letter-spacing:-.1mm; }

  .foot { position:relative; margin-top:3.4mm; display:flex; justify-content:space-between; font-size:3mm; font-weight:600; color:rgba(255,255,255,.45); }
</style></head><body><div class="page">
  <div class="fairway"></div>
  <div class="frame">
    <div class="header">
      <div class="logo"><img src="data:image/png;base64,${logoB64}"></div>
      <div class="brand">GolfTrack</div>
      <div class="tag">Golf &amp; Minigolf · iPhone &amp; Apple Watch</div>
    </div>

    <div class="eyebrow">Die Scorekarte, die mitdenkt</div>
    <div class="headline">Deine Runde.<br><span class="accent">Jeder Schlag gezählt.</span></div>
    <div class="sub">Schläge und Putts mit einem Tipp, GPS-Distanz zur Fahne und eine Auswertung, die zeigt, wo die Schläge liegen bleiben.</div>

    <div class="phones">
      <div class="phone side l"><div class="screen"><img src="data:image/png;base64,${SHOTS.left}"><div class="island"></div></div></div>
      <div class="phone side r"><div class="screen"><img src="data:image/png;base64,${SHOTS.right}"><div class="island"></div></div></div>
      <div class="phone c"><div class="screen"><img src="data:image/png;base64,${SHOTS.center}"><div class="island"></div></div></div>
    </div>

    <div class="points">${POINTS.map(
      (p) => `<div class="pt"><div class="pt-icon">${p.icon}</div><div class="pt-title">${p.title}</div><div class="pt-text">${p.text}</div></div>`
    ).join("")}</div>

    <div class="cta">
      <div class="qr"><img src="${qrDataUrl}"></div>
      <div class="cta-text">
        <div class="cta-eyebrow">Kostenlos laden</div>
        <div class="cta-title">Code scannen,<br>nächste Runde zählen.</div>
        <div class="cta-note">Gratis im App Store · GolfTrack Pro optional</div>
      </div>
      <div class="store">
        <svg viewBox="0 0 24 24"><path d="M16.4 12.6c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9-.8 0-2-.9-3.4-.9-1.7 0-3.3 1-4.2 2.6-1.8 3.1-.5 7.7 1.3 10.2.9 1.2 1.9 2.6 3.2 2.6 1.3-.1 1.8-.8 3.3-.8s2 .8 3.4.8c1.4 0 2.3-1.3 3.1-2.5 1-1.4 1.4-2.8 1.4-2.9 0 0-2.7-1-2.7-4.1ZM13.9 5c.7-.9 1.2-2 1.1-3.2-1 0-2.3.7-3 1.6-.7.8-1.3 2-1.1 3.1 1.1.1 2.3-.6 3-1.5Z"/></svg>
        <div><div class="s1">Laden im</div><div class="s2">App Store</div></div>
      </div>
    </div>

    <div class="foot"><span>golftrack.app</span><span>Mit Freunden spielen · Driving Range · Platzreife lernen</span></div>
  </div>
</div></body></html>`;
}

const outDir = path.join(__dirname, "out");
fs.mkdirSync(outDir, { recursive: true });
const qrDataUrl = await QRCode.toDataURL(APP_STORE, {
  errorCorrectionLevel: "M", margin: 1, width: 900, color: { dark: "#10220D", light: "#FFFFFF" },
});
const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox", "--force-color-profile=srgb"] });
const base = path.join(outDir, "GolfTrack-Anzeige-A4");

for (const [bleed, file] of [[0, `${base}.pdf`], [3, `${base}-Beschnitt.pdf`]]) {
  const page = await browser.newPage();
  await page.setContent(buildHtml(bleed, qrDataUrl), { waitUntil: "networkidle0" });
  await page.pdf({ path: file, preferCSSPageSize: true, printBackground: true, pageRanges: "1" });
  if (wantPng && bleed === 0) {
    await page.setViewport({ width: 794, height: 1123, deviceScaleFactor: 2 });
    await (await page.$(".page")).screenshot({ path: `${base}-Vorschau.png` });
  }
  await page.close();
  console.log("OK ->", path.basename(file));
}
await browser.close();
