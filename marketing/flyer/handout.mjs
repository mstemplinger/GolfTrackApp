#!/usr/bin/env node
// GolfTrack – Auslege-Flyer DIN A5, doppelseitig (2 PDF-Seiten) im App-Stil (AppTheme.swift).
// Aufruf:  node handout.mjs [out.pdf] [--bleed] [--thyrnau]
//   --bleed    3 mm Beschnittzugabe + Schnittmarken (für die Druckerei)
//   --thyrnau  Empfehlungs-Badge + Gutschein-Block des GC Thyrnau einblenden
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import QRCode from "qrcode";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const flags = new Set(args.filter((a) => a.startsWith("--")));
const BLEED = flags.has("--bleed") ? 3 : 0; // mm
const CLUB = flags.has("--thyrnau");
const outPath =
  args.find((a) => !a.startsWith("--")) ||
  path.join(__dirname, "out", `GolfTrack-Flyer-A5${BLEED ? "-Beschnitt" : ""}.pdf`);
fs.mkdirSync(path.dirname(outPath), { recursive: true });

const APP_STORE_URL = "https://apps.apple.com/app/id6767996957";

// AppTheme-Farben (aus Shared/AppTheme.swift)
const C = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", green: "#28824B" };
const accent = C.gold;

// Seitenmaße DIN A5 + optionaler Beschnitt
const PW = 148 + 2 * BLEED;
const PH = 210 + 2 * BLEED;

const logoB64 = fs.readFileSync(path.join(__dirname, "logo.png")).toString("base64");

const qr = (data, width) =>
  QRCode.toDataURL(data, {
    errorCorrectionLevel: "M",
    margin: 1,
    width,
    color: { dark: "#10220D", light: "#FFFFFF" },
  });
const qrStore = await qr(APP_STORE_URL, 640);
const qrStoreSmall = await qr(APP_STORE_URL, 400);

// Minimalistische Linien-Icons (selbst gezeichnet, im App-Gold), viewBox 24×24, Center 12,12
const svg = (paths) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">${paths}</svg>`;

const ICON = {
  flag: svg(`<path d="M8 20V4"/><path d="M8 4.6 18 7 8 9.4z"/><path d="M6 20h4"/>`),
  pin: svg(
    `<path d="M12 20.5c4-3.8 6.3-6.8 6.3-10.3a6.3 6.3 0 1 0-12.6 0C5.7 13.7 8 16.7 12 20.5Z"/><circle cx="12" cy="10.2" r="2.4"/>`
  ),
  chart: svg(
    `<path d="M4.7 19.2h14.6"/><rect x="6.3" y="13" width="3.2" height="6"/><rect x="10.4" y="9.3" width="3.2" height="9.7"/><rect x="14.5" y="5.4" width="3.2" height="13.6"/>`
  ),
  mic: svg(
    `<rect x="9" y="3.4" width="6" height="10.6" rx="3"/><path d="M6.2 11a5.8 5.8 0 0 0 11.6 0"/><path d="M12 16.8v3.4"/><path d="M8.8 20.2h6.4"/>`
  ),
  watch: svg(
    `<rect x="7" y="7" width="10" height="10" rx="3"/><path d="M9 7l.5-3.2h5L15 7"/><path d="M9 17l.5 3.2h5l.5-3.2"/><path d="M12 10.3v2.4h1.8"/>`
  ),
  club: svg(
    `<path d="M15.4 3.8 9.6 15.9"/><path d="M13.6 6.6l2.7 1.3"/><path d="M9.6 15.9c-1.8 0-3 1-3 2.3 0 1.2 1.1 2 2.4 2 2.1 0 3.6-1.4 4.4-3.3z"/>`
  ),
  play: svg(`<circle cx="12" cy="12" r="8.4"/><path d="M10.3 8.7 15.7 12l-5.4 3.3z"/>`),
  putt: svg(
    `<path d="M3 19.6h18"/><circle cx="7.6" cy="16.9" r="2.7"/><path d="M16.2 19.6V4.4"/><path d="M16.2 4.9 21 6.2l-4.8 1.3z"/>`
  ),
  cloud: svg(
    `<path d="M7.6 18.4h8.9a3.6 3.6 0 0 0 .4-7.2 5.2 5.2 0 0 0-9.9 1.3 3.1 3.1 0 0 0 .6 5.9z"/>`
  ),
};

// ── Vorderseite: drei Kernargumente ──────────────────────────────────────────
const highlights = [
  { icon: ICON.flag, title: "Jede Runde festhalten", text: "Zählspiel, Stableford, Match & Netto – solo oder im Flight." },
  { icon: ICON.pin, title: "GPS-Distanzen zum Grün", text: "Exakte Meter zu Pin, Bunker und Wasser – live auf dem Loch." },
  { icon: ICON.watch, title: "Alles an der Apple Watch", text: "Score eintragen und Distanz checken, ohne das iPhone zu zücken." },
];

// ── Rückseite: Feature-Raster ────────────────────────────────────────────────
const features = [
  { icon: ICON.chart, title: "Statistiken", text: "Fairways, GIR, Putts und Scoring-Trends über alle Runden." },
  { icon: ICON.club, title: "Schlägerverwaltung", text: "Deine echten Durchschnitts­distanzen pro Schläger." },
  { icon: ICON.mic, title: "KI-Caddy", text: "Sprachassistent, der dich auf der Runde berät." },
  { icon: ICON.play, title: "Trainingsvideos", text: "Lektionen und Übungen für Schwung, Chip und Putt." },
  { icon: ICON.putt, title: "Minigolf-Zählkarte", text: "Eigener Modus für die Anlage um die Ecke – auch auf der Watch." },
  { icon: ICON.cloud, title: "Wetter & Platzinfos", text: "Wind und Wetter zur Runde, über 90 Plätze schon dabei." },
];

const hlHtml = highlights
  .map(
    (f) => `<div class="hl">
      <div class="hl-icon">${f.icon}</div>
      <div><div class="hl-title">${f.title}</div><div class="hl-body">${f.text}</div></div>
    </div>`
  )
  .join("");

const ftHtml = features
  .map(
    (f) => `<div class="ft">
      <div class="ft-icon">${f.icon}</div>
      <div class="ft-title">${f.title}</div>
      <div class="ft-body">${f.text}</div>
    </div>`
  )
  .join("");

// Fakten-Leiste – entfällt im Club-Modus, dort steht an dieser Stelle der Gutschein
const factsHtml = CLUB
  ? ""
  : `<div class="facts">
      <div class="fact"><b>90+</b><span>Plätze in Bayern,<br>Österreich &amp; Tschechien</span></div>
      <div class="fact"><b>5</b><span>Sprachen<br>an Bord</span></div>
      <div class="fact"><b>+</b><span>Minigolf-Zählkarte<br>inklusive</span></div>
    </div>`;

const recHtml = CLUB ? `<div class="rec"><span class="star">★</span> Empfohlen vom GC&nbsp;Thyrnau</div>` : "";
const couponHtml = CLUB
  ? `<div class="coupon">
      <div class="c-tag">Gratis</div>
      <div>
        <div class="c-offer">1 Monat Trainings-Audios geschenkt</div>
        <div class="c-code">Code <b>THYRNAU26</b> · im App&nbsp;Store einlösen</div>
      </div>
    </div>`
  : "";

// Schnittmarken (nur mit --bleed): dünne Linien in den vier Ecken außerhalb des Formats
const marks = BLEED
  ? ["tl", "tr", "bl", "br"].map((p) => `<span class="mark ${p} h"></span><span class="mark ${p} v"></span>`).join("")
  : "";

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  @page { size: ${PW}mm ${PH}mm; margin: 0; }
  html, body { width:${PW}mm; }
  body {
    font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,"Helvetica Neue",sans-serif;
    color:#fff; -webkit-font-smoothing:antialiased;
  }
  /* Eine Seite = A5 (+ Beschnitt). Deckender Linear-Verlauf, keine transparenten
     Overlay-Layer und keine weichen Schatten – sonst Banding im PDF-Export. */
  .page {
    position:relative; width:${PW}mm; height:${PH}mm; overflow:hidden;
    background:linear-gradient(180deg, #1A3A26 0%, ${C.bg} 48%, #0A1E12 100%);
    page-break-after:always; break-after:page;
  }
  .page:last-child { page-break-after:auto; break-after:auto; }
  .safe {
    position:absolute; inset:${BLEED}mm; padding:10mm 11mm;
    display:flex; flex-direction:column;
  }
  .mark { position:absolute; background:rgba(255,255,255,.55); }
  .mark.h { width:${BLEED}mm; height:.2mm; }
  .mark.v { width:.2mm; height:${BLEED}mm; }
  .mark.tl.h { left:0; top:${BLEED}mm; } .mark.tl.v { left:${BLEED}mm; top:0; }
  .mark.tr.h { right:0; top:${BLEED}mm; } .mark.tr.v { right:${BLEED}mm; top:0; }
  .mark.bl.h { left:0; bottom:${BLEED}mm; } .mark.bl.v { left:${BLEED}mm; bottom:0; }
  .mark.br.h { right:0; bottom:${BLEED}mm; } .mark.br.v { right:${BLEED}mm; bottom:0; }

  /* Kopf */
  .header { display:flex; align-items:center; gap:3.4mm; }
  .badge-icon { width:15mm; height:15mm; border-radius:3.8mm; overflow:hidden; flex:0 0 auto;
    box-shadow:inset 0 0 0 1px rgba(255,255,255,.10); }
  .badge-icon img { width:100%; height:100%; object-fit:cover; display:block; }
  .wordmark .name { font-size:9mm; font-weight:800; letter-spacing:-.3mm; line-height:1; }
  .wordmark .sub { font-size:3.4mm; font-weight:600; color:rgba(255,255,255,.58); margin-top:1.1mm; }
  .rec { margin-left:auto; display:inline-flex; align-items:center; gap:1.2mm; text-align:right;
    background:rgba(255,255,255,.06); border:0.35mm solid ${accent}66;
    padding:1.6mm 2.8mm; border-radius:100px; font-size:2.7mm; font-weight:700; line-height:1.15; }
  .rec .star { color:${accent}; font-size:3mm; line-height:1; }

  /* Hero */
  .pill { display:inline-flex; align-items:center; background:${accent}20; color:${accent};
    border:0.35mm solid ${accent}66; padding:1.7mm 3.4mm; border-radius:100px;
    font-size:2.8mm; font-weight:800; letter-spacing:.7mm; text-transform:uppercase; }
  .hero { margin-top:7mm; }
  .headline { margin-top:4mm; font-size:11mm; font-weight:800; line-height:1.03; letter-spacing:-.45mm; }
  .headline .accent { color:${accent}; }
  .subhead { margin-top:3mm; font-size:3.9mm; font-weight:500; line-height:1.32; color:rgba(255,255,255,.82); }

  /* Kernargumente (Vorderseite) */
  .highlights { margin-top:6mm; display:flex; flex-direction:column; gap:2.2mm; }
  .hl { display:flex; align-items:flex-start; gap:3.6mm; background:${C.card};
    border-radius:4mm; padding:3mm 4mm; box-shadow:inset 0 0 0 .3mm ${accent}2e; }
  .hl-icon { width:9.6mm; height:9.6mm; flex:0 0 auto; border-radius:2.8mm; color:${accent};
    display:flex; align-items:center; justify-content:center;
    background:${C.cardAlt}; box-shadow:inset 0 0 0 .28mm ${accent}33; }
  .hl-icon svg { width:5.4mm; height:5.4mm; display:block; }
  .hl-title { font-size:4.3mm; font-weight:800; letter-spacing:-.15mm; }
  .hl-body { margin-top:.9mm; font-size:3.3mm; font-weight:500; line-height:1.28; color:rgba(255,255,255,.72); }

  /* Gutschein */
  .coupon { margin-top:3mm; display:flex; align-items:center; gap:3.4mm;
    background:${C.cardAlt}; border:0.4mm dashed ${accent}; border-radius:3.6mm; padding:2.4mm 3.6mm; }
  .c-tag { flex:0 0 auto; background:${accent}; color:#10220D; font-weight:800; font-size:2.7mm;
    letter-spacing:.4mm; text-transform:uppercase; padding:1.6mm 2.6mm; border-radius:1.8mm; }
  .c-offer { font-size:3.7mm; font-weight:800; line-height:1.1; }
  .c-code { margin-top:.7mm; font-size:3.1mm; font-weight:500; color:rgba(255,255,255,.8); }
  .c-code b { color:${accent}; font-weight:800; letter-spacing:.2mm; }

  /* Fakten-Leiste (Vorderseite) */
  .facts { margin-top:3.4mm; margin-bottom:3.4mm; display:flex; gap:2.4mm; }
  .fact { flex:1 1 0; background:${C.cardAlt}; border-radius:3.4mm; padding:2.6mm 3mm;
    box-shadow:inset 0 0 0 .28mm ${accent}26; }
  .fact b { display:block; font-size:5.4mm; font-weight:800; color:${accent}; line-height:1; letter-spacing:-.2mm; }
  .fact span { display:block; margin-top:1.4mm; font-size:2.8mm; font-weight:600; line-height:1.3;
    color:rgba(255,255,255,.72); }

  /* CTA + QR (Vorderseite) */
  .cta { margin-top:auto; display:flex; align-items:center; gap:5mm;
    background:linear-gradient(100deg, ${C.green}30, ${accent}22);
    border:0.4mm solid ${accent}55; border-radius:4.6mm; padding:4mm 4.6mm; }
  .cta-text { flex:1 1 auto; }
  .cta-eyebrow { font-size:2.9mm; font-weight:800; letter-spacing:.55mm; text-transform:uppercase; color:${accent}; }
  .cta-title { margin-top:1.6mm; font-size:6.2mm; font-weight:800; line-height:1.08; letter-spacing:-.25mm; }
  .cta-badge { margin-top:2.6mm; display:inline-flex; background:${accent}; color:#10220D;
    padding:2.2mm 3.8mm; border-radius:100px; font-size:3.5mm; font-weight:800; }
  .cta-note { margin-top:2mm; font-size:2.8mm; font-weight:500; color:rgba(255,255,255,.55); }
  .qr { width:32mm; height:32mm; flex:0 0 auto; background:#fff; border-radius:3.4mm; padding:1.9mm; }
  .qr img { width:100%; height:100%; display:block; }

  /* Rückseite */
  .back-head { display:flex; align-items:flex-end; justify-content:space-between; gap:4mm; }
  .back-title { font-size:8.4mm; font-weight:800; line-height:1.05; letter-spacing:-.35mm; }
  .back-title .accent { color:${accent}; }
  .back-sub { margin-top:2.4mm; font-size:3.5mm; font-weight:500; line-height:1.3; color:rgba(255,255,255,.78); }
  .features { margin-top:6mm; display:grid; grid-template-columns:1fr 1fr; gap:2.6mm; }
  .ft { background:${C.card}; border-radius:4mm; padding:3.4mm 3.8mm;
    box-shadow:inset 0 0 0 .3mm ${accent}2e; }
  .ft-icon { width:8.8mm; height:8.8mm; border-radius:2.6mm; color:${accent};
    display:flex; align-items:center; justify-content:center;
    background:${C.cardAlt}; box-shadow:inset 0 0 0 .28mm ${accent}33; }
  .ft-icon svg { width:5mm; height:5mm; display:block; }
  .ft-title { margin-top:2.4mm; font-size:4mm; font-weight:800; letter-spacing:-.12mm; }
  .ft-body { margin-top:1.2mm; font-size:3.1mm; font-weight:500; line-height:1.3; color:rgba(255,255,255,.7); }

  .steps { margin-top:5mm; display:flex; gap:2.6mm; }
  .step { flex:1 1 0; background:${C.cardAlt}; border-radius:3.6mm; padding:2.8mm 3.2mm;
    box-shadow:inset 0 0 0 .28mm ${accent}26; }
  .step .n { font-size:3mm; font-weight:800; color:${accent}; letter-spacing:.4mm; }
  .step .t { margin-top:1.2mm; font-size:3.2mm; font-weight:700; line-height:1.25; }

  .back-foot { margin-top:auto; padding-top:5mm; display:flex; align-items:center; gap:4.4mm; }
  .foot-qr { width:24mm; height:24mm; flex:0 0 auto; background:#fff; border-radius:2.8mm; padding:1.5mm; }
  .foot-qr img { width:100%; height:100%; display:block; }
  .foot-text .f-big { font-size:4.6mm; font-weight:800; line-height:1.1; }
  .foot-text .f-small { margin-top:1.6mm; font-size:3mm; font-weight:500; line-height:1.35; color:rgba(255,255,255,.6); }
  .foot-text .f-small b { color:rgba(255,255,255,.85); font-weight:700; }
  .price { margin-left:auto; text-align:right; flex:0 0 auto; }
  .price .p-big { font-size:6.4mm; font-weight:800; color:${accent}; line-height:1; letter-spacing:-.25mm; }
  .price .p-small { margin-top:1.4mm; font-size:2.8mm; font-weight:600; color:rgba(255,255,255,.6); }
</style></head><body>

  <!-- ── Vorderseite ─────────────────────────────────────────────────────── -->
  <div class="page">${marks}
    <div class="safe">
      <div class="header">
        <div class="badge-icon"><img src="data:image/png;base64,${logoB64}"></div>
        <div class="wordmark">
          <div class="name">GolfTrack</div>
          ${CLUB ? "" : `<div class="sub">Deine Golf-Runde. Komplett im Griff.</div>`}
        </div>
        ${recHtml}
      </div>

      <div class="hero">
        <span class="pill">Für iPhone &amp; Apple&nbsp;Watch</span>
        <div class="headline">Spiel besser.<br><span class="accent">Tracke jeden Schlag.</span></div>
        <div class="subhead">Scoring, GPS-Distanzen, Statistiken und KI-Caddy – alles in einer App, ohne Zettel und Bleistift.</div>
      </div>

      <div class="highlights">${hlHtml}</div>
      ${couponHtml}

      ${factsHtml}

      <div class="cta">
        <div class="cta-text">
          <div class="cta-eyebrow">Jetzt laden</div>
          <div class="cta-title">QR-Code scannen<br>&amp; loslegen</div>
          <div class="cta-badge">Gratis im App&nbsp;Store</div>
          <div class="cta-note">apps.apple.com &middot; iPhone &amp; Apple&nbsp;Watch</div>
        </div>
        <div class="qr"><img src="${qrStore}"></div>
      </div>
    </div>
  </div>

  <!-- ── Rückseite ───────────────────────────────────────────────────────── -->
  <div class="page">${marks}
    <div class="safe">
      <div class="back-head">
        <div>
          <div class="back-title">Was drin&nbsp;ist.<br><span class="accent">Und was es bringt.</span></div>
          <div class="back-sub">Von der ersten Runde bis zum Handicap-Ziel: GolfTrack sammelt deine Daten und macht daraus Erkenntnisse.</div>
        </div>
      </div>

      <div class="features">${ftHtml}</div>

      <div class="steps">
        <div class="step"><div class="n">01</div><div class="t">App laden &amp; Platz wählen</div></div>
        <div class="step"><div class="n">02</div><div class="t">Runde starten, Schläge eintragen</div></div>
        <div class="step"><div class="n">03</div><div class="t">Statistik ansehen &amp; besser werden</div></div>
      </div>

      <div class="back-foot">
        <div class="foot-qr"><img src="${qrStoreSmall}"></div>
        <div class="foot-text">
          <div class="f-big">golftrack.app</div>
          <div class="f-small">Fragen? <b>tobi@triline.de</b><br>Deutsch, Englisch, Französisch, Italienisch, Spanisch</div>
        </div>
        <div class="price">
          <div class="p-big">0 €</div>
          <div class="p-small">Grundfunktionen kostenlos<br>Caddy &amp; Training als Abo</div>
        </div>
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
await page.pdf({ path: outPath, printBackground: true, preferCSSPageSize: true });

// Optional: PNG-Vorschau je Seite (--png) zum Prüfen des Layouts
if (flags.has("--png")) {
  await page.setViewport({ width: Math.round(PW * 4), height: Math.round(PH * 4), deviceScaleFactor: 2 });
  const pages = await page.$$(".page");
  for (let i = 0; i < pages.length; i++) {
    const png = outPath.replace(/\.pdf$/i, "") + `-S${i + 1}.png`;
    await pages[i].screenshot({ path: png });
    console.log("PNG ->", png);
  }
}

await browser.close();
console.log(`OK -> ${outPath}  (${PW}×${PH} mm, 2 Seiten${BLEED ? ", mit Beschnitt" : ""})`);
