#!/usr/bin/env node
// GolfTrack – Werbetafel für den 1. Abschlag (A3 Querformat) im App-Stil (AppTheme.swift) als PDF.
// Plakativ, aus Distanz lesbar, großer QR-Code. Aufruf:  node board.mjs [out.pdf]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import QRCode from "qrcode";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outPath = process.argv[2] || path.join(__dirname, "out", "GolfTrack-Werbetafel-A2-quer.pdf");
fs.mkdirSync(path.dirname(outPath), { recursive: true });

const APP_STORE_URL = "https://apps.apple.com/app/id6767996957";

// AppTheme-Farben (aus Shared/AppTheme.swift)
const C = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", green: "#28824B" };
const accent = C.gold;

const logoB64 = fs.readFileSync(path.join(__dirname, "logo.png")).toString("base64");
const qrDataUrl = await QRCode.toDataURL(APP_STORE_URL, {
  errorCorrectionLevel: "M",
  margin: 1,
  width: 1200,
  color: { dark: "#10220D", light: "#FFFFFF" },
});

// Minimalistische Linien-Icons (mittig in 24×24)
const svg = (paths) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">${paths}</svg>`;
const ICON = {
  flag: svg(`<path d="M8 20V4"/><path d="M8 4.6 18 7 8 9.4z"/><path d="M6 20h4"/>`),
  pin: svg(`<path d="M12 20.5c4-3.8 6.3-6.8 6.3-10.3a6.3 6.3 0 1 0-12.6 0C5.7 13.7 8 16.7 12 20.5Z"/><circle cx="12" cy="10.2" r="2.4"/>`),
  chart: svg(`<path d="M4.7 19.2h14.6"/><rect x="6.3" y="13" width="3.2" height="6"/><rect x="10.4" y="9.3" width="3.2" height="9.7"/><rect x="14.5" y="5.4" width="3.2" height="13.6"/>`),
  mic: svg(`<rect x="9" y="3.4" width="6" height="10.6" rx="3"/><path d="M6.2 11a5.8 5.8 0 0 0 11.6 0"/><path d="M12 16.8v3.4"/><path d="M8.8 20.2h6.4"/>`),
  watch: svg(`<rect x="7" y="7" width="10" height="10" rx="3"/><path d="M9 7l.5-3.2h5L15 7"/><path d="M9 17l.5 3.2h5l.5-3.2"/><path d="M12 10.3v2.4h1.8"/>`),
};

const features = [
  { icon: ICON.flag, title: "Runden & Scores tracken", text: "Alle Spielmodi · über 80 Plätze vorinstalliert" },
  { icon: ICON.pin, title: "GPS-Distanzen & Schuss-Tracking", text: "Exakte Entfernungen zu Grün und Hindernissen" },
  { icon: ICON.chart, title: "Statistiken & KI-Caddy", text: "Auswertungen, Schlägerverwaltung & Sprach-Assistent" },
];

const featureHtml = features
  .map(
    (f) => `
      <div class="feature">
        <div class="f-icon">${f.icon}</div>
        <div class="f-text">
          <div class="f-title">${f.title}</div>
          <div class="f-body">${f.text}</div>
        </div>
      </div>`
  )
  .join("");

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  /* Layout in A3-Maßen (420×297) gezeichnet und beim PDF-Export per scale=√2
     verlustfrei auf A2 (594×420) hochskaliert. */
  @page { size: A2 landscape; margin: 0; }
  html, body { width: 420mm; height: 297mm; }
  body {
    font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,"Helvetica Neue",sans-serif;
    color:#fff; -webkit-font-smoothing:antialiased;
    background:linear-gradient(180deg, #1A3A26 0%, ${C.bg} 46%, #0A1E12 100%);
  }
  .frame { position:absolute; inset:0; display:flex; padding:24mm 26mm; gap:24mm; }

  /* Linke Spalte: Botschaft */
  .left { flex:1 1 auto; display:flex; flex-direction:column; }
  .header { display:flex; align-items:center; gap:6mm; }
  .badge-icon {
    width:26mm; height:26mm; border-radius:6.4mm; overflow:hidden; flex:0 0 auto;
    box-shadow:inset 0 0 0 1px rgba(255,255,255,.10);
  }
  .badge-icon img { width:100%; height:100%; object-fit:cover; display:block; }
  .wordmark .name { font-size:17mm; font-weight:800; letter-spacing:-.5mm; line-height:1; }
  .wordmark .sub  { font-size:6mm; font-weight:600; color:rgba(255,255,255,.58); margin-top:2mm; }
  .rec {
    margin-left:auto; display:inline-flex; align-items:center; gap:2.4mm;
    background:rgba(255,255,255,.06); border:0.5mm solid ${accent}66; color:#fff;
    padding:3mm 6mm; border-radius:100px; font-size:4.8mm; font-weight:700;
  }
  .rec .star { color:${accent}; font-size:5.4mm; line-height:1; }

  .coupon {
    margin-top:auto; display:flex; align-items:center; gap:6mm; align-self:flex-start;
    background:${C.cardAlt}; border:0.6mm dashed ${accent}; border-radius:6mm; padding:5mm 6.5mm;
  }
  .c-tag {
    flex:0 0 auto; background:${accent}; color:#10220D; font-weight:800;
    font-size:4.4mm; letter-spacing:.6mm; text-transform:uppercase; padding:2.6mm 4.6mm; border-radius:3mm;
  }
  .c-offer { font-size:6mm; font-weight:800; }
  .c-code  { margin-top:1.6mm; font-size:5mm; font-weight:500; color:rgba(255,255,255,.8); }
  .c-code b { color:${accent}; font-weight:800; letter-spacing:.4mm; }

  .pill {
    align-self:flex-start; margin-top:12mm;
    display:inline-flex; align-items:center;
    background:${accent}20; color:${accent}; border:0.5mm solid ${accent}66;
    padding:2.8mm 6mm; border-radius:100px;
    font-size:4.6mm; font-weight:800; letter-spacing:1.4mm; text-transform:uppercase;
  }
  .headline {
    margin-top:7mm; font-size:22mm; font-weight:800; line-height:1.02; letter-spacing:-.9mm;
  }
  .headline .accent { color:${accent}; }
  .subhead {
    margin-top:5mm; font-size:6.6mm; font-weight:500; line-height:1.34; color:rgba(255,255,255,.84); max-width:200mm;
  }

  .features { margin-top:11mm; display:flex; flex-direction:column; gap:5mm; }
  .feature { display:flex; align-items:center; gap:6mm; }
  .f-icon {
    width:16mm; height:16mm; flex:0 0 auto; border-radius:4.4mm;
    display:flex; align-items:center; justify-content:center;
    background:${C.card}; color:${accent}; box-shadow:inset 0 0 0 0.4mm ${accent}40;
  }
  .f-icon svg { width:9mm; height:9mm; display:block; }
  .f-title { font-size:7mm; font-weight:800; letter-spacing:-.2mm; }
  .f-body  { margin-top:1mm; font-size:5.4mm; font-weight:500; color:rgba(255,255,255,.72); }

  .watch {
    margin-top:5mm; display:flex; align-items:center; gap:5mm;
    background:linear-gradient(100deg, ${C.green}30, ${accent}22);
    border:0.5mm solid ${accent}55; border-radius:6mm; padding:5mm 6.5mm; align-self:flex-start;
  }
  .watch .w-icon {
    width:16mm; height:16mm; flex:0 0 auto; border-radius:4.4mm;
    display:flex; align-items:center; justify-content:center;
    background:rgba(255,255,255,.08); color:#fff; box-shadow:inset 0 0 0 0.4mm rgba(255,255,255,.14);
  }
  .watch .w-icon svg { width:9.5mm; height:9.5mm; display:block; }
  .watch .w-title { font-size:6.4mm; font-weight:800; }
  .watch .w-sub   { font-size:5mm; font-weight:500; color:rgba(255,255,255,.8); margin-top:1mm; }

  /* Rechte Spalte: großer QR-Code */
  .right {
    flex:0 0 118mm; display:flex; flex-direction:column; align-items:center; justify-content:center;
    background:${C.card}; border-radius:10mm; padding:14mm 12mm;
    box-shadow:inset 0 0 0 0.5mm ${accent}33;
  }
  .r-eyebrow { font-size:5.4mm; font-weight:800; letter-spacing:1.4mm; text-transform:uppercase; color:${accent}; }
  .r-title { margin-top:3mm; font-size:11mm; font-weight:800; line-height:1.05; text-align:center; letter-spacing:-.3mm; }
  .qr {
    margin-top:9mm; width:94mm; height:94mm; background:#fff; border-radius:7mm; padding:5mm;
  }
  .qr img { width:100%; height:100%; display:block; }
  .r-scan { margin-top:7mm; font-size:6.2mm; font-weight:700; color:#fff; text-align:center; }
  .cta-badge {
    margin-top:6mm; background:${C.gold}; color:#10220D;
    padding:4.4mm 9mm; border-radius:100px; font-size:6.4mm; font-weight:800; letter-spacing:.2mm;
  }
  .r-note { margin-top:5mm; font-size:4.8mm; font-weight:500; color:rgba(255,255,255,.55); text-align:center; }
</style></head><body>
  <div class="frame">
    <div class="left">
      <div class="header">
        <div class="badge-icon"><img src="data:image/png;base64,${logoB64}"></div>
        <div class="wordmark">
          <div class="name">GolfTrack</div>
          <div class="sub">Deine Golf-Runde. Komplett im Griff.</div>
        </div>
        <div class="rec"><span class="star">★</span> Empfohlen vom GC&nbsp;Thyrnau</div>
      </div>

      <span class="pill">Golf-Tracking für iPhone &amp; Apple&nbsp;Watch</span>
      <div class="headline">Better Golf –<br><span class="accent">ab dem 1. Abschlag.</span></div>
      <div class="subhead">Tracke jeden Schlag, kenne jede Distanz und werte deine Runde aus – direkt auf iPhone &amp; Apple&nbsp;Watch.</div>

      <div class="features">${featureHtml}</div>

      <div class="coupon">
        <div class="c-tag">Gratis-Aktion</div>
        <div>
          <div class="c-offer">1 Monat Trainings-Audios geschenkt</div>
          <div class="c-code">Code <b>THYRNAU26</b> · im App&nbsp;Store einlösen</div>
        </div>
      </div>

      <div class="watch">
        <div class="w-icon">${ICON.watch}</div>
        <div>
          <div class="w-title">Komplett per Apple Watch bedienbar</div>
          <div class="w-sub">Score & Distanzen direkt vom Handgelenk – ohne das iPhone zu zücken.</div>
        </div>
      </div>
    </div>

    <div class="right">
      <div class="r-eyebrow">Jetzt kostenlos</div>
      <div class="r-title">Scannen &amp;<br>loslegen</div>
      <div class="qr"><img src="${qrDataUrl}"></div>
      <div class="r-scan">iPhone-Kamera auf den Code halten</div>
      <div class="cta-badge">Gratis im App&nbsp;Store</div>
      <div class="r-note">apps.apple.com · für iPhone &amp; Apple&nbsp;Watch</div>
    </div>
  </div>
</body></html>`;

const browser = await puppeteer.launch({
  headless: "new",
  args: ["--no-sandbox", "--force-color-profile=srgb"],
});
const page = await browser.newPage();
await page.setContent(html, { waitUntil: "networkidle0" });
await page.pdf({ path: outPath, format: "A2", landscape: true, printBackground: true, scale: Math.SQRT2 });
await browser.close();
console.log("OK ->", outPath);
