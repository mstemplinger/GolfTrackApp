#!/usr/bin/env node
// GolfTrack – Bauzaunplanen für den Golfplatz (Flyeralarm „Planen für Bauzäune“, 340 × 173 cm, gesäumt, 20 Ösen).
// Gedacht für einen Bauzaun am ersten Abschlag, der zugleich zur Driving Range zeigt.
// Flyeralarm druckt die Plane nur einseitig (4/0) → zwei Planen Rücken an Rücken am selben Zaunelement.
// Material: 500 g PVC (blickdicht). Mesh scheint durch, dann sieht man die andere Plane spiegelverkehrt.
//
//   abschlag  dunkelgrün – Spieler warten auf die Startzeit, stehen 1–4 m davor → QR auf Augenhöhe
//   range     gold       – gesehen durch das Ballfangnetz aus 20–80 m → KEIN QR (nicht scannbar),
//                          stattdessen riesige Schrift, App-Icon und „im App Store suchen“-Feld zum Merken
//
// Gestaltungsregeln:
//  - Gezeichnet in echten cm, 1:1 Endformat. Ränder 8 cm frei (Saum + Ösen + Spanngummis).
//  - QR-Mitte (--qr-mitte, cm unter Oberkante) so wählen, dass sie ≈ 1,4–1,5 m über dem Standort der Leute liegt:
//    Zaun auf Mauer (Standard, Plane 0,6–2,35 m über dem Weg) → Mitte 86,5 cm; Bauzaun am Boden (0,2–1,93 m) → 53 cm.
//  - QR mit Fehlerkorrektur H: übersteht auch Gitterstäbe davor, falls die Plane hinter der Doppelstabmatte hängt.
//  - Unterste ~20 cm verschwinden oft hinter Gras und Zaunfüßen: nur ruhige Fläche.
//  - Range-Seite: Lesbarkeit ≈ Buchstabenhöhe (cm) × 3 m → Kernbotschaft ≥ 18 cm Versalhöhe.
//
// Aufruf:  node fence-banner.mjs [--bleed=10] [--platz="GC Bayerwald"] [--qr-mitte=86.5]
// Ausgabe: out/bauzaun/GolfTrack-Bauzaunplane-340x173-<abschlag|range>.pdf
//          out/bauzaun/tex/<abschlag|range>.png  (Textur 20 px/cm für das 3D-Modell)
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import QRCode from "qrcode";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const arg = (k, d) => (process.argv.find((a) => a.startsWith(`--${k}=`)) || "").split("=")[1] ?? d;
const BLEED_MM = Number(arg("bleed", "0"));
// Platzname im Scorekarten-Screenshot ersetzen (sonst steht dort „GC München Eichenried“ aus den Store-Bildern)
const PLATZ = arg("platz", "");
const DOWNLOAD = "https://golftrack.app/download";
const PX_PER_CM = 20;
const W = 340, H = 173;
const EDGE = 8; // Saum + Ösen
const QR_MID = Number(arg("qr-mitte", String(H / 2))); // QR-Mitte in cm unter der Oberkante (Bauzaun am Boden: --qr-mitte=53)

const C = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", green: "#28824B", cream: "#F3EEDF", ink: "#10220D" };
const b64 = (p) => fs.readFileSync(p).toString("base64");
const logoB64 = b64(path.join(__dirname, "logo.png"));
const shot = (name) => b64(path.join(__dirname, "..", "screenshots", "de-69", `${name}.png`));

const svg = (paths, sw = 1.8) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round">${paths}</svg>`;
const ICON = {
  pin: svg(`<path d="M12 20.5c4-3.8 6.3-6.8 6.3-10.3a6.3 6.3 0 1 0-12.6 0C5.7 13.7 8 16.7 12 20.5Z"/><circle cx="12" cy="10.2" r="2.4"/>`),
  card: svg(`<rect x="4" y="5" width="16" height="14" rx="2.2"/><path d="M4 10h16"/><path d="M9.3 10v9"/><path d="M14.7 10v9"/>`),
  watch: svg(`<rect x="7" y="7" width="10" height="10" rx="3"/><path d="M9 7l.5-3.2h5L15 7"/><path d="M9 17l.5 3.2h5l.5-3.2"/><path d="M12 10.3v2.4h1.8"/>`),
  friends: svg(`<circle cx="9" cy="8.6" r="3"/><path d="M3.8 19c.6-3 2.7-4.6 5.2-4.6s4.6 1.6 5.2 4.6"/><circle cx="16.4" cy="9.6" r="2.4"/><path d="M15.6 14.5c2.3 0 4 1.3 4.6 4"/>`),
  search: svg(`<circle cx="10.5" cy="10.5" r="6.2"/><path d="m15.2 15.2 5 5"/>`, 2.6),
};

const base = (b, bg, fg) => `
  * { margin:0; padding:0; box-sizing:border-box; }
  @page { size:${W + 2 * b}cm ${H + 2 * b}cm; margin:0; }
  html, body { width:${W + 2 * b}cm; height:${H + 2 * b}cm; }
  body { font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,"Helvetica Neue",sans-serif; -webkit-font-smoothing:antialiased; color:${fg}; background:${bg}; }
  .page { position:relative; width:${W + 2 * b}cm; height:${H + 2 * b}cm; overflow:hidden; }
  .safe { position:absolute; left:${b + EDGE}cm; right:${b + EDGE}cm; top:${b + EDGE}cm; bottom:${b + EDGE}cm; }
  .logo { border-radius:22%; overflow:hidden; }
  .logo img { width:100%; height:100%; display:block; }
`;

// ── Abschlag-Seite: Nahwirkung, QR auf Augenhöhe ───────────────────────────────────────────
function tee(b, qr) {
  // QR-Mitte auf halber Planenhöhe: Am Zaun auf der Mauer (GC Thyrnau, 1. Abschlag) hängt die Plane ca. 0,6–2,35 m
  // über dem Weg → Mitte ≈ 1,5 m = Augenhöhe für alle, die am Zaun vorbeigehen.
  const qrSize = 42, qrPad = 1.8;
  const qrMid = QR_MID - EDGE;                   // in .safe-Koordinaten
  const qrBoxTop = qrMid - qrSize / 2 - qrPad;
  const cardTop = qrBoxTop - 29;                 // Platz für Dachzeile + zweizeilige Überschrift
  const phoneW = 58, phoneH = (phoneW - 2.8) * 2868 / 1320 + 2.8; // Innenmaß exakt im Screenshot-Seitenverhältnis
  const grassTop = H - 22;
  const scr = shot("19-live-scorecard");
  const pxCm = (phoneW - 2.8) / 1320; // cm je Screenshot-Pixel
  return `<!doctype html><html><head><meta charset="utf-8"><style>${base(b, `linear-gradient(160deg,#1F4A33 0%,${C.bg} 50%,#0A1E12 100%)`, "#fff")}
  em { font-style:normal; color:${C.gold}; }
  .head { position:absolute; left:0; top:2cm; display:flex; align-items:center; gap:2.2cm; }
  .head .logo { width:15cm; height:15cm; box-shadow:inset 0 0 0 0.12cm rgba(255,255,255,.14); }
  .brand { font-size:9.5cm; font-weight:800; letter-spacing:-0.3cm; }
  .eyebrow { position:absolute; left:0; top:24cm; font-size:3.6cm; font-weight:800; letter-spacing:0.45cm; text-transform:uppercase; color:${C.gold}; display:flex; align-items:center; gap:1.6cm; }
  .eyebrow b { display:inline-flex; align-items:center; justify-content:center; width:6.4cm; height:6.4cm; border-radius:50%; background:${C.gold}; color:${C.ink}; font-size:4.2cm; letter-spacing:0; }
  .hl { position:absolute; left:-0.5cm; top:33cm; width:150cm; font-size:17.5cm; font-weight:800; line-height:.96; letter-spacing:-0.75cm; }
  .sub { position:absolute; left:0; top:74cm; width:128cm; font-size:4.6cm; font-weight:500; line-height:1.3; color:rgba(255,255,255,.76); }
  .steps { position:absolute; left:0; top:104cm; display:flex; align-items:center; gap:3cm; }
  .step { display:flex; align-items:center; gap:1.8cm; font-size:5.4cm; font-weight:800; white-space:nowrap; }
  .step b { display:inline-flex; align-items:center; justify-content:center; width:8cm; height:8cm; border-radius:50%;
            box-shadow:inset 0 0 0 0.4cm ${C.gold}; color:${C.gold}; font-size:4.4cm; }
  .arrow { width:5cm; height:0.45cm; background:${C.gold}66; border-radius:1cm; }
  .phone { position:absolute; left:158cm; top:10cm; width:${phoneW}cm; height:${phoneH}cm; transform:rotate(5deg); transform-origin:50% 0;
           background:#050c08; border-radius:8.5cm; padding:1.4cm; box-shadow:inset 0 0 0 0.45cm #3a4a40; } /* keine weichen Schatten: Chromium-PDF druckt sie als harte Kästen */
  .scr { position:relative; width:100%; height:100%; border-radius:7.2cm; overflow:hidden; }
  .scr > img { width:100%; height:100%; display:block; }
  /* Platzname überdecken: Hintergrund dort ist flach App-Grün, Name steht in Zeile 380–407 px des Screenshots */
  .pn { position:absolute; left:${40 * pxCm}cm; top:${372 * pxCm}cm; width:${900 * pxCm}cm; height:${40 * pxCm}cm; background:${C.bg}; }
  .pn span { display:block; padding-left:${20 * pxCm}cm; line-height:${40 * pxCm}cm; font-size:${40 * pxCm}cm; font-weight:600; color:rgba(255,255,255,.6);
             white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
  .cta { position:absolute; right:-2cm; top:${cardTop}cm; width:100cm; height:${qrBoxTop + qrSize + 2 * qrPad + 5 - cardTop}cm; border-radius:5cm; background:${C.card};
         box-shadow:inset 0 0 0 0.35cm ${C.gold}66; display:flex; flex-direction:column; align-items:center; text-align:center; }
  .qr { position:absolute; left:50%; top:${qrBoxTop - cardTop}cm; transform:translateX(-50%); width:${qrSize}cm; height:${qrSize}cm; background:#fff; border-radius:2.2cm; padding:${qrPad}cm; box-sizing:content-box; }
  .qr img { width:100%; height:100%; display:block; }
  .cta-e { margin-top:5cm; font-size:3.2cm; font-weight:800; letter-spacing:0.35cm; text-transform:uppercase; color:${C.gold}; }
  .cta-h { margin-top:1.3cm; font-size:7.4cm; font-weight:800; line-height:1.02; letter-spacing:-0.25cm; }
  .cta-n { position:absolute; right:-2cm; width:100cm; text-align:center; font-size:3.3cm; font-weight:700; color:rgba(255,255,255,.62); }
  .grass { position:absolute; left:-20cm; right:-20cm; top:${grassTop + b}cm; bottom:0; background:${C.green};
           border-radius:50% 50% 0 0 / 5cm 5cm 0 0; box-shadow:inset 0 0.5cm 0 ${C.gold}; }
  .points { position:absolute; left:0; top:${grassTop - EDGE + 5.6}cm; display:flex; gap:9cm; }
  .pt { display:flex; align-items:center; gap:2cm; font-size:4.3cm; font-weight:800; color:#fff; white-space:nowrap; }
  .pt-i { width:7.4cm; height:7.4cm; color:${C.gold}; }
  .pt-i svg { width:100%; height:100%; }
  .url { position:absolute; right:3cm; top:${grassTop - EDGE + 6.2}cm; font-size:4.6cm; font-weight:800; color:#fff; letter-spacing:0.05cm; }
  .url em { color:${C.cream}; opacity:.75; }
</style></head><body><div class="page">
  <div class="grass"></div>
  <div class="safe">
    <div class="phone"><div class="scr"><img src="data:image/png;base64,${scr}">${PLATZ ? `<div class="pn"><span>${PLATZ}</span></div>` : ""}</div></div>
    <div class="head"><div class="logo"><img src="data:image/png;base64,${logoB64}"></div><div class="brand">GolfTrack</div></div>
    <div class="eyebrow"><b>1</b>Erster Abschlag</div>
    <div class="hl">Ab hier zählt<br><em>jeder Schlag.</em></div>
    <div class="sub">Die Scorekarte aufs Handy: Schläge und Putts mit einem Tipp, GPS-Distanz zur Fahne, Statistik nach der Runde.</div>
    <div class="steps"><div class="step"><b>1</b>Scannen</div><div class="arrow"></div><div class="step"><b>2</b>Platz wählen</div><div class="arrow"></div><div class="step"><b>3</b>Abschlagen</div></div>
    <div class="cta"><div class="qr"><img src="${qr}"></div>
      <div class="cta-e">Noch Zeit bis zum Start?</div>
      <div class="cta-h">Scannen &amp;<br>mitspielen.</div></div>
    <div class="cta-n" style="top:${qrBoxTop + qrSize + 2 * qrPad + 9}cm">Kostenlos · iPhone · Apple Watch · Android</div>
    <div class="points">
      <div class="pt"><div class="pt-i">${ICON.card}</div>Über 800 Plätze</div>
      <div class="pt"><div class="pt-i">${ICON.pin}</div>GPS zur Fahne</div>
      <div class="pt"><div class="pt-i">${ICON.watch}</div>Apple Watch</div>
    </div>
    <div class="url">golftrack.app</div>
  </div>
</div></body></html>`;
}

// ── Range-Seite: Fernwirkung durchs Ballfangnetz, ohne QR ─────────────────────────────────
function range(b) {
  return `<!doctype html><html><head><meta charset="utf-8"><style>${base(b, `linear-gradient(180deg,#D9B24C 0%,${C.gold} 55%,#B98F28 100%)`, C.ink)}
  em { font-style:normal; }
  .icon { position:absolute; left:2cm; top:9cm; width:112cm; height:112cm; border-radius:24%; box-shadow:0 2.4cm 0 rgba(16,34,13,.22); }
  .hl { position:absolute; left:132cm; top:4cm; font-size:30cm; font-weight:900; line-height:.92; letter-spacing:-1.3cm; white-space:nowrap; }
  .sub { position:absolute; left:134cm; top:66cm; font-size:8.6cm; font-weight:800; letter-spacing:-0.2cm; line-height:1.05; }
  .search { position:absolute; left:132cm; right:0; top:90cm; height:34cm; border-radius:17cm; background:#fff;
            display:flex; align-items:center; gap:4cm; padding:0 6cm 0 7cm; box-shadow:0 1.6cm 0 rgba(16,34,13,.25); }
  .search .s-i { width:17cm; height:17cm; flex:0 0 auto; color:${C.ink}; opacity:.55; }
  .search .s-i svg { width:100%; height:100%; }
  .search .t { font-size:21cm; font-weight:900; letter-spacing:-0.9cm; color:${C.ink}; }
  .search .t span { color:#A7801F; }
  .caret { width:1cm; height:20cm; background:#0A84FF; border-radius:.5cm; margin-left:-2.6cm; }
  .note { position:absolute; left:140cm; top:130cm; font-size:7cm; font-weight:800; letter-spacing:0.3cm; text-transform:uppercase; color:${C.ink}; opacity:.8; }
</style></head><body><div class="page">
  <div class="safe">
    <div class="logo icon"><img src="data:image/png;base64,${logoB64}"></div>
    <div class="hl">Jeder Ball<br><em>zählt.</em></div>
    <div class="sub">Range-Training mitschreiben.</div>
    <div class="search"><div class="s-i">${ICON.search}</div><div class="t">Golf<span>Track</span></div><div class="caret"></div></div>
    <div class="note">Im App Store suchen · kostenlos</div>
  </div>
</div></body></html>`;
}

const outDir = path.join(__dirname, "out", "bauzaun");
fs.mkdirSync(path.join(outDir, "tex"), { recursive: true });
const qr = await QRCode.toDataURL(DOWNLOAD, { errorCorrectionLevel: "H", margin: 1, width: 1600, color: { dark: C.ink, light: "#FFFFFF" } });

const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox", "--force-color-profile=srgb"] });
const CM = 96 / 2.54;
for (const [side, fn] of [["abschlag", tee], ["range", range]]) {
  const b = BLEED_MM / 10;
  const page = await browser.newPage();
  await page.setContent(fn(b, qr), { waitUntil: "networkidle0" });
  const slug = PLATZ && side === "abschlag" ? "-" + PLATZ.toLowerCase().replace(/ß/g, "ss").normalize("NFD").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") : "";
  const pdf = path.join(outDir, `GolfTrack-Bauzaunplane-${W}x${H}-${side}${slug}${b ? "-Beschnitt" : ""}.pdf`);
  await page.pdf({ path: pdf, preferCSSPageSize: true, printBackground: true, pageRanges: "1" });
  await page.close();
  const tex = await browser.newPage();
  await tex.setViewport({ width: Math.ceil(W * CM), height: Math.ceil(H * CM), deviceScaleFactor: PX_PER_CM / CM });
  await tex.setContent(fn(0, qr), { waitUntil: "load" });
  await (await tex.$(".page")).screenshot({ path: path.join(outDir, "tex", `${side}.png`) });
  await tex.close();
  console.log("OK ->", path.basename(pdf));
}
await browser.close();
