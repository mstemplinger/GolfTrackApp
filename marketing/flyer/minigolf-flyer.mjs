#!/usr/bin/env node
// GolfTrack – Akquise-Flyer für Minigolf-Anlagen (A4 hoch) im App-Stil als PDF.
//
// Zielgruppe ist NICHT der Gast, sondern der Betreiber der Anlage: der Flyer
// erklärt, warum die App Zettel und Bleistift ersetzt und was der Betreiber
// dafür tun muss (nämlich: einen QR-Code aufhängen).
//
// Aufruf:
//   node minigolf-flyer.mjs [out.pdf] [--kontakt "Name · Tel · Mail"] [--web "domain.de"]
//
// Kontaktzeile bewusst als Parameter: erfundene Adressen haben auf einem Flyer
// nichts zu suchen, der echten Betrieben in die Hand gedrückt wird.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import QRCode from "qrcode";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const argv = process.argv.slice(2);
const flag = (name, fallback) => {
  const i = argv.indexOf(`--${name}`);
  return i >= 0 && argv[i + 1] ? argv[i + 1] : fallback;
};
const positional = argv.filter((a, i) =>
  !a.startsWith("--") && !(i > 0 && argv[i - 1].startsWith("--")));

const outPath = positional[0] || path.join(__dirname, "out", "GolfTrack-Minigolf-Anlagen-A4.pdf");
const KONTAKT = flag("kontakt", "[Ihr Name · Telefon · E-Mail]");
const WEB = flag("web", "[Ihre Website]");
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

const qrDataUrl = await QRCode.toDataURL(APP_STORE_URL, {
  errorCorrectionLevel: "M",
  margin: 1,
  width: 640,
  color: { dark: "#10220D", light: "#FFFFFF" },
});

// Linien-Icons, viewBox 24×24, sichtbarer Inhalt mittig um (12,12)
const svg = (paths, extra = "") =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"${extra}>${paths}</svg>`;

const ICON = {
  phone: svg(`<rect x="6.6" y="2.6" width="10.8" height="18.8" rx="2.6"/><path d="M10.4 5.2h3.2"/><path d="M9.4 10h5.2"/><path d="M9.4 13.2h5.2"/><path d="M9.4 16.4h3"/>`),
  players: svg(`<circle cx="9.2" cy="8.4" r="2.9"/><path d="M4.4 19.4c0-2.9 2.2-5 4.8-5s4.8 2.1 4.8 5"/><circle cx="16.6" cy="9.6" r="2.2"/><path d="M15 14.7c2.4-.5 4.6 1.4 4.6 4.7"/>`),
  seal: svg(`<circle cx="12" cy="10.6" r="6.4"/><path d="M9.2 10.6l1.9 1.9 3.7-3.8"/><path d="M8.4 15.8 7.2 21l4.8-2.3L16.8 21l-1.2-5.2"/>`),
  trophy: svg(`<path d="M8 3.6h8v5.2a4 4 0 0 1-8 0z"/><path d="M8 4.8H5.4c0 2.8 1.2 4.2 2.9 4.6"/><path d="M16 4.8h2.6c0 2.8-1.2 4.2-2.9 4.6"/><path d="M12 12.8v3.4"/><path d="M8.6 20.4h6.8l-.7-4.2H9.3z"/>`),
  watch: svg(`<rect x="7" y="7" width="10" height="10" rx="3"/><path d="M9 7l.5-3.2h5L15 7"/><path d="M9 17l.5 3.2h5l.5-3.2"/><path d="M12 10.3v2.4h1.8"/>`),
  qr: svg(`<rect x="3.4" y="3.4" width="6.4" height="6.4" rx="1.2"/><rect x="14.2" y="3.4" width="6.4" height="6.4" rx="1.2"/><rect x="3.4" y="14.2" width="6.4" height="6.4" rx="1.2"/><path d="M14.2 14.2h2.6v2.6h-2.6z"/><path d="M18.6 14.2h2"/><path d="M20.6 16.8v3.8"/><path d="M14.2 20.6h4"/>`),
  clock: svg(`<circle cx="12" cy="12.4" r="8.2"/><path d="M12 7.8v4.6l3 1.8"/>`),
  cloudOff: svg(`<path d="M4 12.6a4 4 0 0 1 4-4 5.2 5.2 0 0 1 9.9 1.6 3.4 3.4 0 0 1 .5 6.6"/><path d="M8 17h7.4"/><path d="M3.6 3.6l16.8 16.8"/>`),
};

/* ── Inhalt ───────────────────────────────────────────────────────────── */

const gegen = [
  "Scorekarten nachdrucken",
  "Bleistifte nachkaufen und anspitzen",
  "Zerknitterte, unleserliche Karten",
  "Streit beim Zusammenrechnen",
  "Papier und Stifte im Müll",
];

const fuer = [
  "Gäste zählen am eigenen Handy",
  "Bis zu 8 Spieler auf einer Karte",
  "Sieger steht automatisch fest",
  "Auch auf der Apple Watch",
  "Kein Material, keine Kosten",
];

const features = [
  {
    icon: ICON.phone,
    title: "Scorekarte für 1–36 Bahnen",
    text: "Bahnzahl frei einstellbar, Schnellauswahl für 6, 9, 12 und 18 Bahnen.",
  },
  {
    icon: ICON.players,
    title: "Bis zu 8 Spieler",
    text: "Namen eintragen, alle auf einer Karte. Rangliste berechnet die App selbst.",
  },
  {
    icon: ICON.seal,
    title: "Kostenlos für alle",
    text: "Gratis-Download, das Minigolf-Zählen kostet nichts. Keine Anmeldung, kein Konto.",
  },
  {
    icon: ICON.trophy,
    title: "Verlauf bleibt gespeichert",
    text: "Letzte Partien mit Datum und Ergebnis. Ihre Gäste kommen mit einem Rekord wieder.",
  },
];

const steps = [
  { n: "1", icon: ICON.qr, title: "QR-Code aufhängen", text: "Am Eingang oder an Bahn 1. Er führt direkt zur App im App Store." },
  { n: "2", icon: ICON.phone, title: "Gast scannt und lädt", text: "App aus dem App Store, in unter einer Minute startklar." },
  { n: "3", icon: ICON.clock, title: "Losspielen", text: "Namen eintippen, Bahn für Bahn zählen. Sie müssen nichts weiter tun." },
];

const row = (items) => items.map((t) => `<li>${t}</li>`).join("");

const featureHtml = features
  .map(
    (f) => `
      <div class="feature">
        <div class="f-icon">${f.icon}</div>
        <div class="f-title">${f.title}</div>
        <div class="f-body">${f.text}</div>
      </div>`
  )
  .join("");

const stepHtml = steps
  .map(
    (s) => `
      <div class="step">
        <div class="s-head"><span class="s-num">${s.n}</span><span class="s-icon">${s.icon}</span></div>
        <div class="s-title">${s.title}</div>
        <div class="s-body">${s.text}</div>
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
    /* Deckender Linear-Verlauf ohne überlagerte Transparenz-Layer –
       sonst erzeugt der PDF-Export rechteckige Banding-Artefakte. */
    background:linear-gradient(180deg, #1A3A26 0%, ${C.bg} 46%, #0A1E12 100%);
  }
  .frame { position:absolute; inset:0; display:flex; flex-direction:column; padding: 11mm 14mm 10mm; }

  /* Header */
  .header { display:flex; align-items:center; gap:5mm; }
  .badge-icon {
    width:19mm; height:19mm; border-radius:4.8mm; overflow:hidden; flex:0 0 auto;
    box-shadow:inset 0 0 0 1px rgba(255,255,255,.10);
  }
  .badge-icon img { width:100%; height:100%; object-fit:cover; display:block; }
  .wordmark .name { font-size:11.4mm; font-weight:800; letter-spacing:-.4mm; line-height:1; }
  .wordmark .sub  { font-size:4.3mm; font-weight:600; color:rgba(255,255,255,.58); margin-top:1.3mm; }
  .for-tag {
    margin-left:auto; display:inline-flex; align-items:center;
    background:${accent}; color:#10220D;
    padding:2.3mm 4.4mm; border-radius:100px; font-size:3.7mm; font-weight:800;
    letter-spacing:.4mm; text-transform:uppercase;
  }

  /* Hero */
  .hero { margin-top:3mm; }
  .headline { font-size:11.2mm; font-weight:800; line-height:1.03; letter-spacing:-.6mm; }
  .headline .accent { color:${accent}; }
  .subhead {
    margin-top:2.4mm; font-size:4.4mm; font-weight:500; line-height:1.3;
    color:rgba(255,255,255,.84); max-width:168mm;
  }

  /* Gegenüberstellung */
  .compare { margin-top:4mm; display:flex; gap:4mm; }
  .col { flex:1 1 0; border-radius:5mm; padding:3.2mm 4.4mm 3.4mm; }
  .col.before { background:rgba(255,255,255,.045); box-shadow:inset 0 0 0 0.35mm rgba(255,255,255,.13); }
  .col.after  { background:${C.card}; box-shadow:inset 0 0 0 0.45mm ${accent}66; }
  .col-head { display:flex; align-items:center; gap:2.4mm; font-size:4.4mm; font-weight:800; letter-spacing:-.15mm; }
  .col.before .col-head { color:rgba(255,255,255,.62); }
  .col.after  .col-head { color:${accent}; }
  .col ul { margin-top:2.8mm; list-style:none; }
  .col li {
    position:relative; padding-left:5.6mm; margin-bottom:1.5mm;
    font-size:4mm; font-weight:500; line-height:1.26;
  }
  .col.before li { color:rgba(255,255,255,.62); }
  .col.after  li { color:rgba(255,255,255,.9); }
  .col li:last-child { margin-bottom:0; }
  .col li::before {
    position:absolute; left:0; top:-0.1mm; font-size:4.2mm; font-weight:800; line-height:1.2;
  }
  .col.before li::before { content:"×"; color:rgba(255,255,255,.42); }
  .col.after  li::before { content:"✓"; color:${accent}; }

  /* Features */
  .features {
    margin-top:3.6mm; display:grid; grid-template-columns:1fr 1fr; gap:3mm;
  }
  .feature {
    background:${C.card}; border-radius:4.6mm; padding:3mm 4.2mm 3.2mm;
    box-shadow:inset 0 0 0 0.35mm ${accent}2e;
  }
  .f-icon {
    width:10.4mm; height:10.4mm; border-radius:3mm;
    display:flex; align-items:center; justify-content:center;
    background:${C.cardAlt}; box-shadow:inset 0 0 0 0.3mm ${accent}33; color:${accent};
  }
  .f-icon svg { width:6mm; height:6mm; display:block; }
  .f-title { margin-top:2.2mm; font-size:4.7mm; font-weight:800; letter-spacing:-.2mm; }
  .f-body  { margin-top:1.2mm; font-size:3.8mm; font-weight:500; line-height:1.3; color:rgba(255,255,255,.72); }

  /* Ablauf */
  .steps-wrap { margin-top:3.6mm; }
  .steps-title {
    font-size:4mm; font-weight:800; letter-spacing:.7mm; text-transform:uppercase; color:${accent};
  }
  .steps { margin-top:2.6mm; display:flex; gap:3.4mm; }
  .step {
    flex:1 1 0; background:${C.cardAlt}; border-radius:4.6mm; padding:2.9mm 3.8mm 3.2mm;
    box-shadow:inset 0 0 0 0.35mm rgba(255,255,255,.09);
  }
  .s-head { display:flex; align-items:center; justify-content:space-between; }
  .s-num {
    width:7.4mm; height:7.4mm; border-radius:100px; background:${accent}; color:#10220D;
    font-size:4.4mm; font-weight:800; display:flex; align-items:center; justify-content:center;
  }
  .s-icon { color:${accent}; opacity:.62; }
  .s-icon svg { width:6.4mm; height:6.4mm; display:block; }
  .s-title { margin-top:2.6mm; font-size:4.5mm; font-weight:800; letter-spacing:-.15mm; }
  .s-body  { margin-top:1.2mm; font-size:3.7mm; font-weight:500; line-height:1.26; color:rgba(255,255,255,.7); }

  /* Watch-Zeile */
  .watch {
    margin-top:3.4mm; display:flex; align-items:center; gap:3.6mm;
    background:linear-gradient(100deg, ${C.green}30, ${accent}22);
    border:0.4mm solid ${accent}55; border-radius:4.6mm; padding:2.7mm 4.6mm;
  }
  .watch .w-icon {
    width:11mm; height:11mm; flex:0 0 auto; border-radius:3.1mm;
    display:flex; align-items:center; justify-content:center;
    background:rgba(255,255,255,.08); color:#fff; box-shadow:inset 0 0 0 0.3mm rgba(255,255,255,.12);
  }
  .watch .w-icon svg { width:6.6mm; height:6.6mm; display:block; }
  .watch .w-title { font-size:4.5mm; font-weight:800; }
  .watch .w-sub   { font-size:3.8mm; font-weight:500; color:rgba(255,255,255,.78); margin-top:.6mm; }

  /* Footer / CTA + QR */
  .footer {
    margin-top:auto; padding-top:2.5mm;
    display:flex; align-items:center; justify-content:space-between; gap:6mm;
  }
  .cta-block { flex:1 1 auto; }
  .cta-eyebrow { font-size:3.8mm; font-weight:700; letter-spacing:.6mm; text-transform:uppercase; color:${accent}; }
  .cta-title { margin-top:1.6mm; font-size:6.8mm; font-weight:800; line-height:1.06; letter-spacing:-.3mm; }
  .cta-badge {
    margin-top:2.4mm; display:inline-flex; align-items:center; gap:2.6mm;
    background:${C.gold}; color:#10220D; padding:2.9mm 5mm; border-radius:100px;
    font-size:4.5mm; font-weight:800;
  }
  .cta-contact {
    margin-top:2.6mm; font-size:3.7mm; font-weight:600; line-height:1.32; color:rgba(255,255,255,.6);
  }
  .cta-contact b { color:rgba(255,255,255,.86); font-weight:700; }
  .qr-wrap { flex:0 0 auto; text-align:center; }
  .qr { width:36mm; height:36mm; background:#fff; border-radius:4.2mm; padding:2.4mm; }
  .qr img { width:100%; height:100%; display:block; }
  .qr-label { margin-top:2mm; font-size:3.4mm; font-weight:700; color:rgba(255,255,255,.62); letter-spacing:.3mm; }
</style></head><body>
  <div class="frame">

    <div class="header">
      <div class="badge-icon"><img src="data:image/png;base64,${logoB64}"></div>
      <div class="wordmark">
        <div class="name">GolfTrack</div>
        <div class="sub">Die Minigolf-Scorekarte fürs Handy</div>
      </div>
      <div class="for-tag">Für Anlagen-Betreiber</div>
    </div>

    <div class="hero">
      <div class="headline">Schluss mit Zettel<br><span class="accent">und Bleistift.</span></div>
      <div class="subhead">
        Ihre Gäste zählen am eigenen Handy – digitale Scorekarte für bis zu acht Spieler.
        Reine Scorekarte: keine Kasse, keine Bezahlfunktion, kein Eingriff in Ihren Ablauf.
      </div>
    </div>

    <div class="compare">
      <div class="col before">
        <div class="col-head">Bisher: Zettel und Stift</div>
        <ul>${row(gegen)}</ul>
      </div>
      <div class="col after">
        <div class="col-head">Mit GolfTrack</div>
        <ul>${row(fuer)}</ul>
      </div>
    </div>

    <div class="features">${featureHtml}</div>

    <div class="steps-wrap">
      <div class="steps-title">So läuft es bei Ihnen</div>
      <div class="steps">${stepHtml}</div>
    </div>

    <div class="footer">
      <div class="cta-block">
        <div class="cta-eyebrow">Unverbindlich ausprobieren</div>
        <div class="cta-title">Scannen, laden,<br>eine Runde testen.</div>
        <div class="cta-badge">Gratis im App&nbsp;Store</div>
        <div class="cta-contact">
          Aufsteller mit QR-Code für Ihre Anlage gibt es kostenlos.<br>
          <b>${KONTAKT}</b> &middot; ${WEB}
        </div>
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
// A4 bei 96 dpi = 794 x 1123 px. Überlauf würde im PDF still abgeschnitten,
// deshalb hier hart nachmessen statt darauf zu vertrauen.
await page.setViewport({ width: 794, height: 1123, deviceScaleFactor: 1 });
const fit = await page.evaluate(() => {
  const f = document.querySelector(".frame");
  return { need: Math.ceil(f.scrollHeight), have: 1123 };
});
console.log(`Layout: ${fit.need}px Inhalt / ${fit.have}px A4` +
  (fit.need > fit.have ? `  ÜBERLAUF ${fit.need - fit.have}px` : `  Luft ${fit.have - fit.need}px`));

await page.pdf({
  path: outPath,
  format: "A4",
  printBackground: true,
  preferCSSPageSize: true,
});

// Vorschau-PNG zum Gegenlesen (gleiche Seitengröße, 2× für Lesbarkeit)
await page.setViewport({ width: 794, height: 1123, deviceScaleFactor: 2 });
await page.screenshot({
  path: path.join(path.dirname(outPath), "minigolf_flyer_preview.png"),
  fullPage: false,
});
await browser.close();
console.log("OK ->", outPath);
