#!/usr/bin/env node
// GolfTrack – Print-Plakat (A4 Hochformat) im App-Stil (AppTheme.swift) als PDF.
// Aufruf:  node poster.mjs [out.pdf]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import QRCode from "qrcode";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outPath = process.argv[2] || path.join(__dirname, "out", "GolfTrack-Plakat-A4.pdf");
fs.mkdirSync(path.dirname(outPath), { recursive: true });

const APP_STORE_URL = "https://apps.apple.com/app/id6767996957";

// AppTheme-Farben (aus Shared/AppTheme.swift)
const C = {
  bg: "#0E2718",
  card: "#163421",
  cardAlt: "#1C4129",
  gold: "#C9A035",
  green: "#28824B",
};
const accent = C.gold;

const logoB64 = fs.readFileSync(path.join(__dirname, "logo.png")).toString("base64");

// QR-Code als PNG-DataURL – dunkle Module auf Weiß, damit gut scanbar
const qrDataUrl = await QRCode.toDataURL(APP_STORE_URL, {
  errorCorrectionLevel: "M",
  margin: 1,
  width: 640,
  color: { dark: "#10220D", light: "#FFFFFF" },
});

// Minimalistische Linien-Icons (selbst gezeichnet, im App-Gold), viewBox 24×24
const svg = (paths) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">${paths}</svg>`;

const ICON = {
  // Zeichenflächen so gewählt, dass der sichtbare Inhalt in 24×24 mittig sitzt (Center ≈ 12,12)
  flag: svg(`<path d="M8 20V4"/><path d="M8 4.6 18 7 8 9.4z"/><path d="M6 20h4"/>`),
  pin: svg(`<path d="M12 20.5c4-3.8 6.3-6.8 6.3-10.3a6.3 6.3 0 1 0-12.6 0C5.7 13.7 8 16.7 12 20.5Z"/><circle cx="12" cy="10.2" r="2.4"/>`),
  chart: svg(`<path d="M4.7 19.2h14.6"/><rect x="6.3" y="13" width="3.2" height="6"/><rect x="10.4" y="9.3" width="3.2" height="9.7"/><rect x="14.5" y="5.4" width="3.2" height="13.6"/>`),
  mic: svg(`<rect x="9" y="3.4" width="6" height="10.6" rx="3"/><path d="M6.2 11a5.8 5.8 0 0 0 11.6 0"/><path d="M12 16.8v3.4"/><path d="M8.8 20.2h6.4"/>`),
  watch: svg(`<rect x="7" y="7" width="10" height="10" rx="3"/><path d="M9 7l.5-3.2h5L15 7"/><path d="M9 17l.5 3.2h5l.5-3.2"/><path d="M12 10.3v2.4h1.8"/>`),
};

const features = [
  {
    icon: ICON.flag,
    title: "Runden & Scores tracken",
    text: "Alle Spielmodi – Zählspiel, Stableford, Match, Netto. Über 80 Plätze bereits vorinstalliert.",
  },
  {
    icon: ICON.pin,
    title: "GPS-Entfernungen & Schuss-Tracking",
    text: "Exakte Distanzen zu Grün und Hindernissen, jeder Schlag per GPS aufgezeichnet.",
  },
  {
    icon: ICON.chart,
    title: "Statistiken & Schlägerverwaltung",
    text: "Fairways, GIR, Putts und deine Durchschnitts­distanzen pro Schläger – klar ausgewertet.",
  },
  {
    icon: ICON.mic,
    title: "KI-Caddy & Trainingsvideos",
    text: "Dein Sprach-Assistent auf der Runde plus Profi-Lektionen für ein besseres Spiel.",
  },
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
  @page { size: A4 portrait; margin: 0; }
  html, body { width: 210mm; height: 297mm; }
  body {
    font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,"Helvetica Neue",sans-serif;
    color:#fff;
    -webkit-font-smoothing:antialiased;
    /* Einfacher, deckender Linear-Verlauf – keine überlagerten Transparenz-Layer,
       damit der PDF-Export keine rechteckigen Banding-Artefakte erzeugt. */
    background:linear-gradient(180deg, #1A3A26 0%, ${C.bg} 46%, #0A1E12 100%);
  }
  .frame {
    position:absolute; inset:0;
    display:flex; flex-direction:column;
    padding: 13mm 15mm 13mm;
  }

  /* Header */
  .header { display:flex; align-items:center; gap:5mm; }
  .badge-icon {
    width:21mm; height:21mm; border-radius:5.2mm; overflow:hidden; flex:0 0 auto;
    box-shadow:inset 0 0 0 1px rgba(255,255,255,.10);
  }
  .badge-icon img { width:100%; height:100%; object-fit:cover; display:block; }
  .wordmark .name { font-size:13mm; font-weight:800; letter-spacing:-.4mm; line-height:1; }
  .wordmark .sub  { font-size:4.8mm; font-weight:600; color:rgba(255,255,255,.58); margin-top:1.5mm; }
  .rec {
    margin-left:auto; display:inline-flex; align-items:center; gap:1.8mm;
    background:rgba(255,255,255,.06); border:0.4mm solid ${accent}66; color:#fff;
    padding:2.2mm 4.2mm; border-radius:100px; font-size:3.5mm; font-weight:700;
  }
  .rec .star { color:${accent}; font-size:4mm; line-height:1; }

  .coupon {
    margin-top:2mm; display:flex; align-items:center; gap:4.5mm;
    background:${C.cardAlt}; border:0.45mm dashed ${accent}; border-radius:4.5mm; padding:2.7mm 4.8mm;
  }
  .c-tag {
    flex:0 0 auto; background:${accent}; color:#10220D; font-weight:800;
    font-size:3.5mm; letter-spacing:.5mm; text-transform:uppercase; padding:2mm 3.6mm; border-radius:2.4mm;
  }
  .c-offer { font-size:4.7mm; font-weight:800; line-height:1.1; }
  .c-code  { margin-top:.9mm; font-size:3.9mm; font-weight:500; color:rgba(255,255,255,.8); }
  .c-code b { color:${accent}; font-weight:800; letter-spacing:.3mm; }

  /* Hero */
  .hero { margin-top:4mm; }
  .pill {
    display:inline-flex; align-items:center; gap:2.5mm;
    background:${accent}20; color:${accent}; border:0.4mm solid ${accent}66;
    padding:2.2mm 4.6mm; border-radius:100px;
    font-size:3.7mm; font-weight:800; letter-spacing:1mm; text-transform:uppercase;
  }
  .headline {
    margin-top:5mm; font-size:13mm; font-weight:800; line-height:1.04; letter-spacing:-.6mm;
  }
  .headline .accent { color:${accent}; }
  .subhead {
    margin-top:2.6mm; font-size:4.5mm; font-weight:500; line-height:1.3; color:rgba(255,255,255,.82); max-width:150mm;
  }

  /* Features */
  .features { margin-top:3.5mm; display:flex; flex-direction:column; gap:2mm; }
  .feature {
    display:flex; align-items:flex-start; gap:4.5mm;
    background:${C.card}; border-radius:5mm; padding:3.1mm 5.2mm;
    box-shadow:inset 0 0 0 0.35mm ${accent}2e;
  }
  .f-icon {
    width:12mm; height:12mm; flex:0 0 auto; border-radius:3.4mm;
    display:flex; align-items:center; justify-content:center;
    background:${C.cardAlt}; box-shadow:inset 0 0 0 0.3mm ${accent}33;
    color:${accent};
  }
  .f-icon svg { width:6.6mm; height:6.6mm; display:block; }
  .f-title { font-size:5.6mm; font-weight:800; letter-spacing:-.2mm; }
  .f-body  { margin-top:1.2mm; font-size:4.2mm; font-weight:500; line-height:1.3; color:rgba(255,255,255,.72); }

  /* Watch-Banner */
  .watch {
    margin-top:2mm; display:flex; align-items:center; gap:4mm;
    background:linear-gradient(100deg, ${C.green}30, ${accent}22);
    border:0.4mm solid ${accent}55; border-radius:5mm; padding:3.1mm 5.2mm;
  }
  .watch .w-icon {
    width:14mm; height:14mm; flex:0 0 auto; border-radius:3.8mm;
    display:flex; align-items:center; justify-content:center;
    background:rgba(255,255,255,.08); color:#fff;
    box-shadow:inset 0 0 0 0.3mm rgba(255,255,255,.12);
  }
  .watch .w-icon svg { width:8mm; height:8mm; display:block; }
  .watch .w-title { font-size:5.2mm; font-weight:800; }
  .watch .w-sub   { font-size:4mm; font-weight:500; color:rgba(255,255,255,.78); margin-top:.8mm; }

  /* Footer / CTA + QR */
  .footer {
    margin-top:auto; padding-top:3mm;
    display:flex; align-items:center; justify-content:space-between; gap:7mm;
  }
  .cta-block { flex:1 1 auto; }
  .cta-eyebrow { font-size:4mm; font-weight:700; letter-spacing:.6mm; text-transform:uppercase; color:${accent}; }
  .cta-title { margin-top:2mm; font-size:8mm; font-weight:800; line-height:1.06; letter-spacing:-.3mm; }
  .cta-badge {
    margin-top:3.5mm; display:inline-flex; align-items:center; gap:3mm;
    background:${C.gold}; color:#10220D; padding:3.2mm 5.5mm; border-radius:100px;
    font-size:4.8mm; font-weight:800;
  }
  .cta-badge .apple { font-size:5.6mm; line-height:1; }
  .cta-note { margin-top:3mm; font-size:3.7mm; font-weight:500; color:rgba(255,255,255,.5); }
  .qr-wrap { flex:0 0 auto; text-align:center; }
  .qr {
    width:42mm; height:42mm; background:#fff; border-radius:4.5mm; padding:2.6mm;
  }
  .qr img { width:100%; height:100%; display:block; }
  .qr-label { margin-top:2.4mm; font-size:3.6mm; font-weight:700; color:rgba(255,255,255,.62); letter-spacing:.3mm; }
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

    <div class="hero">
      <span class="pill">Golf-Tracking für iPhone &amp; Apple&nbsp;Watch</span>
      <div class="headline">Spiel besser.<br><span class="accent">Tracke jeden Schlag.</span></div>
      <div class="subhead">Scoring, GPS-Distanzen, Statistiken &amp; KI-Caddy – alles in einer App.</div>
    </div>

    <div class="features">${featureHtml}</div>

    <div class="watch">
      <div class="w-icon">${ICON.watch}</div>
      <div>
        <div class="w-title">Komplett per Apple Watch bedienbar</div>
        <div class="w-sub">Score eintragen, Distanzen checken und Runde steuern – direkt vom Handgelenk, ohne das iPhone zu zücken.</div>
      </div>
    </div>

    <div class="coupon">
      <div class="c-tag">Gratis-Aktion</div>
      <div>
        <div class="c-offer">1 Monat Trainings-Audios geschenkt</div>
        <div class="c-code">Code <b>THYRNAU26</b> · im App&nbsp;Store einlösen</div>
      </div>
    </div>

    <div class="footer">
      <div class="cta-block">
        <div class="cta-eyebrow">Jetzt kostenlos laden</div>
        <div class="cta-title">Scanne den<br>QR-Code &rarr;</div>
        <div class="cta-badge">Gratis im App&nbsp;Store laden</div>
        <div class="cta-note">apps.apple.com &middot; für iPhone &amp; Apple&nbsp;Watch</div>
      </div>
      <div class="qr-wrap">
        <div class="qr"><img src="${qrDataUrl}"></div>
        <div class="qr-label">ZUM APP&nbsp;STORE</div>
      </div>
    </div>
  </div>
</body></html>`;

const browser = await puppeteer.launch({
  headless: "new",
  args: ["--no-sandbox", "--force-color-profile=srgb"],
});
const page = await browser.newPage();
await page.setContent(html, { waitUntil: "networkidle0" });
await page.pdf({
  path: outPath,
  format: "A4",
  printBackground: true,
  preferCSSPageSize: true,
});
await browser.close();
console.log("OK ->", outPath);
