#!/usr/bin/env node
// GolfTrack – Werbetafel für den 1. Abschlag, HOCHFORMAT (A3 portrait) im App-Stil.
// Plakativ, aus Distanz lesbar, großer QR-Code unten. Aufruf:  node board-portrait.mjs [out.pdf]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import QRCode from "qrcode";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outPath = process.argv[2] || path.join(__dirname, "out", "GolfTrack-Werbetafel-A2-hoch.pdf");
fs.mkdirSync(path.dirname(outPath), { recursive: true });

const APP_STORE_URL = "https://apps.apple.com/app/id6767996957";

const C = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", green: "#28824B" };
const accent = C.gold;

const logoB64 = fs.readFileSync(path.join(__dirname, "logo.png")).toString("base64");
const qrDataUrl = await QRCode.toDataURL(APP_STORE_URL, {
  errorCorrectionLevel: "M",
  margin: 1,
  width: 1200,
  color: { dark: "#10220D", light: "#FFFFFF" },
});

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
  /* Layout in A3-Maßen (297×420) gezeichnet und beim PDF-Export per scale=√2
     verlustfrei auf A2 (420×594) hochskaliert. */
  @page { size: A2 portrait; margin: 0; }
  html, body { width: 297mm; height: 420mm; }
  body {
    font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,"Helvetica Neue",sans-serif;
    color:#fff; -webkit-font-smoothing:antialiased;
    background:linear-gradient(180deg, #1A3A26 0%, ${C.bg} 46%, #0A1E12 100%);
  }
  .frame { position:absolute; inset:0; display:flex; flex-direction:column; padding:28mm 26mm; }

  .header { display:flex; align-items:center; gap:6mm; }
  .badge-icon {
    width:28mm; height:28mm; border-radius:7mm; overflow:hidden; flex:0 0 auto;
    box-shadow:inset 0 0 0 1px rgba(255,255,255,.10);
  }
  .badge-icon img { width:100%; height:100%; object-fit:cover; display:block; }
  .wordmark .name { font-size:18mm; font-weight:800; letter-spacing:-.5mm; line-height:1; }
  .wordmark .sub  { font-size:6.2mm; font-weight:600; color:rgba(255,255,255,.58); margin-top:2mm; }
  .rec {
    margin-left:auto; display:inline-flex; align-items:center; gap:2.4mm; text-align:right;
    background:rgba(255,255,255,.06); border:0.5mm solid ${accent}66; color:#fff;
    padding:3mm 5.5mm; border-radius:100px; font-size:4.9mm; font-weight:700; line-height:1.15;
  }
  .rec .star { color:${accent}; font-size:5.4mm; line-height:1; flex:0 0 auto; }

  .coupon {
    margin-top:6mm; display:flex; align-items:center; gap:6mm;
    background:${C.cardAlt}; border:0.6mm dashed ${accent}; border-radius:5.5mm; padding:5mm 6mm;
  }
  .c-tag {
    flex:0 0 auto; background:${accent}; color:#10220D; font-weight:800;
    font-size:4.6mm; letter-spacing:.6mm; text-transform:uppercase; padding:2.8mm 4.8mm; border-radius:3mm;
  }
  .c-offer { font-size:6.4mm; font-weight:800; }
  .c-code  { margin-top:1.6mm; font-size:5.2mm; font-weight:500; color:rgba(255,255,255,.8); }
  .c-code b { color:${accent}; font-weight:800; letter-spacing:.4mm; }

  .pill {
    align-self:flex-start; margin-top:12mm;
    display:inline-flex; align-items:center;
    background:${accent}20; color:${accent}; border:0.5mm solid ${accent}66;
    padding:3mm 6.5mm; border-radius:100px;
    font-size:5mm; font-weight:800; letter-spacing:1.6mm; text-transform:uppercase;
  }
  .headline { margin-top:8mm; font-size:26mm; font-weight:800; line-height:1.02; letter-spacing:-1mm; }
  .headline .accent { color:${accent}; }
  .subhead {
    margin-top:6mm; font-size:7.4mm; font-weight:500; line-height:1.34; color:rgba(255,255,255,.84);
  }

  .features { margin-top:13mm; display:flex; flex-direction:column; gap:6mm; }
  .feature { display:flex; align-items:center; gap:6.5mm; }
  .f-icon {
    width:18mm; height:18mm; flex:0 0 auto; border-radius:5mm;
    display:flex; align-items:center; justify-content:center;
    background:${C.card}; color:${accent}; box-shadow:inset 0 0 0 0.4mm ${accent}40;
  }
  .f-icon svg { width:10mm; height:10mm; display:block; }
  .f-title { font-size:8mm; font-weight:800; letter-spacing:-.2mm; }
  .f-body  { margin-top:1.2mm; font-size:6mm; font-weight:500; color:rgba(255,255,255,.72); }

  .watch {
    margin-top:8mm; display:flex; align-items:center; gap:5.5mm;
    background:linear-gradient(100deg, ${C.green}30, ${accent}22);
    border:0.5mm solid ${accent}55; border-radius:6.5mm; padding:5.5mm 7mm; align-self:flex-start;
  }
  .watch .w-icon {
    width:18mm; height:18mm; flex:0 0 auto; border-radius:5mm;
    display:flex; align-items:center; justify-content:center;
    background:rgba(255,255,255,.08); color:#fff; box-shadow:inset 0 0 0 0.4mm rgba(255,255,255,.14);
  }
  .watch .w-icon svg { width:10.5mm; height:10.5mm; display:block; }
  .watch .w-title { font-size:7mm; font-weight:800; }
  .watch .w-sub   { font-size:5.4mm; font-weight:500; color:rgba(255,255,255,.8); margin-top:1mm; }

  /* Unten: QR-Band über volle Breite */
  .qr-band {
    margin-top:auto; display:flex; align-items:center; gap:12mm;
    background:${C.card}; border-radius:9mm; padding:12mm 14mm;
    box-shadow:inset 0 0 0 0.5mm ${accent}33;
  }
  .qr-text { flex:1 1 auto; }
  .qr-eyebrow { font-size:5.6mm; font-weight:800; letter-spacing:1.6mm; text-transform:uppercase; color:${accent}; }
  .qr-title { margin-top:3mm; font-size:13mm; font-weight:800; line-height:1.04; letter-spacing:-.4mm; }
  .qr-scan { margin-top:5mm; font-size:6.4mm; font-weight:600; color:rgba(255,255,255,.82); }
  .cta-badge {
    margin-top:7mm; display:inline-block; background:${C.gold}; color:#10220D;
    padding:4.6mm 9mm; border-radius:100px; font-size:6.6mm; font-weight:800;
  }
  .qr {
    flex:0 0 auto; width:80mm; height:80mm; background:#fff; border-radius:6mm; padding:4.5mm;
  }
  .qr img { width:100%; height:100%; display:block; }
</style></head><body>
  <div class="frame">
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

    <div class="watch">
      <div class="w-icon">${ICON.watch}</div>
      <div>
        <div class="w-title">Komplett per Apple Watch bedienbar</div>
        <div class="w-sub">Score & Distanzen direkt vom Handgelenk – ohne das iPhone zu zücken.</div>
      </div>
    </div>

    <div class="qr-band">
      <div class="qr-text">
        <div class="qr-eyebrow">Jetzt kostenlos laden</div>
        <div class="qr-title">Scannen &amp; loslegen</div>
        <div class="qr-scan">iPhone-Kamera auf den Code halten &rarr;</div>
        <div class="cta-badge">Gratis im App&nbsp;Store</div>
        <div class="coupon">
          <div class="c-tag">Gratis</div>
          <div>
            <div class="c-offer">1 Monat Trainings-Audios geschenkt</div>
            <div class="c-code">Code <b>THYRNAU26</b> · im App&nbsp;Store einlösen</div>
          </div>
        </div>
      </div>
      <div class="qr"><img src="${qrDataUrl}"></div>
    </div>
  </div>
</body></html>`;

const browser = await puppeteer.launch({
  headless: "new",
  args: ["--no-sandbox", "--force-color-profile=srgb"],
});
const page = await browser.newPage();
await page.setContent(html, { waitUntil: "networkidle0" });
await page.pdf({ path: outPath, format: "A2", landscape: false, printBackground: true, scale: Math.SQRT2 });
await browser.close();
console.log("OK ->", outPath);
