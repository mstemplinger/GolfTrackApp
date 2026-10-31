#!/usr/bin/env node
// GolfTrack – QR-Aushang für eine einzelne Minigolfanlage (A4 quer) als PDF.
//
// Zielgruppe ist der GAST an der Anlage: links in drei Sprachen (IT/EN/DE),
// wie GolfTrack geht, rechts der QR-Code. Codiert wird – wie bei
// `web/src/app/qr/[slug]` – die Spielseite `play.golftrack.app/p/<slug>`:
// App, App Clip oder Zählkarte im Browser, ohne Umweg über den Katalog.
//
// Die Anlage muss in der Datenbank freigegeben sein (kind = minigolf),
// sonst führt der Link ins Leere.
//
// Aufruf:
//   node minigolf-qr-sheet.mjs --slug bardolino --name "Minigolf Bardolino" \
//     [--ort "Bardolino · Lago di Garda"] [--bahnen 18] [out.pdf] [--png]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import QRCode from "qrcode";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const argv = process.argv.slice(2);
const flag = (name, fallback) => {
  const i = argv.indexOf(`--${name}`);
  return i >= 0 && argv[i + 1] && !argv[i + 1].startsWith("--") ? argv[i + 1] : fallback;
};
const VALUE_FLAGS = ["--slug", "--name", "--ort", "--bahnen"];
const positional = argv.filter((a, i) =>
  !a.startsWith("--") && !(i > 0 && VALUE_FLAGS.includes(argv[i - 1])));

const SLUG = flag("slug");
const NAME = flag("name");
if (!SLUG || !NAME) {
  console.error('Aufruf: node minigolf-qr-sheet.mjs --slug <slug> --name "<Name>" [--ort "…"] [--bahnen N] [out.pdf] [--png]');
  process.exit(1);
}
const ORT = flag("ort", "");
const BAHNEN = flag("bahnen", "");
const PNG = argv.includes("--png");

const fileBase = NAME.replace(/[^\p{L}\p{N}]+/gu, "-").replace(/^-|-$/g, "");
const outPath = positional[0] || path.join(__dirname, "out", `GolfTrack-QR-${fileBase}-A4-quer.pdf`);
fs.mkdirSync(path.dirname(outPath), { recursive: true });

const LINK = `https://play.golftrack.app/p/${SLUG}`;
const LINK_SHORT = `play.golftrack.app/p/${SLUG}`;

// AppTheme-Farben (aus Shared/AppTheme.swift)
const C = {
  bg: "#0E2718",
  card: "#163421",
  cardAlt: "#1C4129",
  gold: "#C9A035",
  green: "#28824B",
};

const logoB64 = fs.readFileSync(path.join(__dirname, "logo.png")).toString("base64");

const qrDataUrl = await QRCode.toDataURL(LINK, {
  errorCorrectionLevel: "M",
  margin: 1,
  width: 900,
  color: { dark: "#10220D", light: "#FFFFFF" },
});

/* ── Inhalt ───────────────────────────────────────────────────────────── */

// Flaggen als drei Streifen – Emoji-Flaggen rendert Chromium im PDF nicht
// zuverlässig.
const languages = [
  {
    code: "IT",
    flag: ["#009246", "#FFFFFF", "#CE2B37"],
    vertical: true,
    title: "Come funziona GolfTrack",
    steps: [
      "Inquadra il codice QR con la fotocamera.",
      "Apri GolfTrack: su iPhone senza installare nulla, su Android nel browser.",
      "Inserisci i giocatori e segna i colpi buca per buca. La classifica si calcola da sola.",
    ],
  },
  {
    code: "EN",
    flag: ["#012169", "#FFFFFF", "#C8102E"],
    vertical: true,
    uk: true,
    title: "How GolfTrack works",
    steps: [
      "Point your camera at the QR code.",
      "Open GolfTrack: no install needed on iPhone, in the browser on Android.",
      "Add the players and tap in your strokes hole by hole. The leaderboard adds itself up.",
    ],
  },
  {
    code: "DE",
    flag: ["#000000", "#DD0000", "#FFCE00"],
    vertical: false,
    title: "So funktioniert GolfTrack",
    steps: [
      "QR-Code mit der Kamera scannen.",
      "GolfTrack öffnen: auf dem iPhone ohne Installation, auf Android im Browser.",
      "Spieler eintragen und Schläge Bahn für Bahn antippen. Die Rangliste rechnet sich selbst.",
    ],
  },
];

const flagHtml = (l) => {
  if (l.uk) {
    // Union Jack vereinfacht: blaues Feld mit rot-weißem Kreuz
    return `<span class="flag" style="background:${l.flag[0]}">
      <svg viewBox="0 0 30 20" preserveAspectRatio="none">
        <path d="M0 0L30 20M30 0L0 20" stroke="#fff" stroke-width="4"/>
        <path d="M0 0L30 20M30 0L0 20" stroke="#C8102E" stroke-width="1.4"/>
        <path d="M15 0V20M0 10H30" stroke="#fff" stroke-width="6"/>
        <path d="M15 0V20M0 10H30" stroke="#C8102E" stroke-width="3.4"/>
      </svg></span>`;
  }
  const dir = l.vertical ? "90deg" : "180deg";
  const [a, b, c] = l.flag;
  return `<span class="flag" style="background:linear-gradient(${dir}, ${a} 0 33.34%, ${b} 33.34% 66.67%, ${c} 66.67% 100%)"></span>`;
};

const langHtml = languages
  .map(
    (l) => `
    <section class="lang">
      <div class="lang-head">${flagHtml(l)}<span class="lang-code">${l.code}</span><span class="lang-title">${l.title}</span></div>
      <ol class="steps">
        ${l.steps.map((s, i) => `<li><span class="num">${i + 1}</span><span class="txt">${s}</span></li>`).join("")}
      </ol>
    </section>`
  )
  .join("");

const meta = [ORT, BAHNEN ? `${BAHNEN} buche · holes · Bahnen` : ""].filter(Boolean).join("  ·  ");

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  @page { size: A4 landscape; margin: 0; }
  html, body { width: 297mm; height: 210mm; }
  body {
    font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,"Helvetica Neue",sans-serif;
    color:#fff;
    -webkit-font-smoothing:antialiased;
    /* Deckender Verlauf ohne Transparenz-Layer – sonst Banding im PDF. */
    background:linear-gradient(135deg, #1A3A26 0%, ${C.bg} 50%, #0A1E12 100%);
  }
  .frame { position:absolute; inset:0; display:flex; flex-direction:column; padding: 11mm 13mm 9mm; }

  /* Kopf */
  .header { display:flex; align-items:center; gap:4.5mm; }
  .badge-icon { width:17mm; height:17mm; border-radius:4.2mm; overflow:hidden; flex:0 0 auto;
    box-shadow:inset 0 0 0 1px rgba(255,255,255,.10); }
  .badge-icon img { width:100%; height:100%; object-fit:cover; display:block; }
  .wordmark .name { font-size:10mm; font-weight:800; letter-spacing:-.35mm; line-height:1; }
  .wordmark .sub  { font-size:3.9mm; font-weight:600; color:rgba(255,255,255,.6); margin-top:1.2mm; }
  .course { margin-left:auto; text-align:right; }
  .course .c-name { font-size:8.4mm; font-weight:800; letter-spacing:-.3mm; line-height:1.05; color:${C.gold}; }
  .course .c-meta { font-size:3.8mm; font-weight:600; color:rgba(255,255,255,.66); margin-top:1.4mm; }

  .rule { height:0.35mm; background:rgba(255,255,255,.12); margin:5mm 0 5mm; }

  /* Hauptteil */
  .main { flex:1 1 auto; display:flex; gap:9mm; min-height:0; }
  .left { flex:1 1 0; display:flex; flex-direction:column; gap:4mm; }

  .lang { flex:1 1 0; display:flex; flex-direction:column; justify-content:center;
    background:${C.card}; border-radius:4.6mm; padding:3.6mm 5mm 3.8mm;
    box-shadow:inset 0 0 0 0.3mm rgba(255,255,255,.08); }
  .lang-head { display:flex; align-items:center; gap:2.6mm; }
  .flag { position:relative; width:7.2mm; height:4.8mm; border-radius:0.8mm; overflow:hidden; flex:0 0 auto;
    box-shadow:0 0 0 0.25mm rgba(255,255,255,.35); }
  .flag svg { position:absolute; inset:0; width:100%; height:100%; display:block; }
  .lang-code { font-size:3.3mm; font-weight:800; letter-spacing:.4mm; color:${C.gold}; }
  .lang-title { font-size:6mm; font-weight:800; letter-spacing:-.15mm; }
  .steps { list-style:none; margin-top:3.2mm; display:flex; gap:3.6mm; }
  .steps li { flex:1 1 0; display:flex; gap:2.2mm; align-items:flex-start; }
  .num { flex:0 0 auto; width:6.2mm; height:6.2mm; border-radius:50%; background:${C.gold}; color:#10220D;
    font-size:3.4mm; font-weight:800; display:flex; align-items:center; justify-content:center; margin-top:0.2mm; }
  .txt { font-size:4.15mm; font-weight:500; line-height:1.32; color:rgba(255,255,255,.9); }

  /* QR-Karte */
  .right { flex:0 0 98mm; display:flex; flex-direction:column; align-items:center; justify-content:center;
    background:${C.cardAlt}; border-radius:6mm; padding:6mm 7mm;
    box-shadow:inset 0 0 0 0.5mm ${C.gold}88; }
  .scan { font-size:6.4mm; font-weight:800; letter-spacing:-.2mm; text-align:center; line-height:1.15; }
  .scan .sep { color:${C.gold}; font-weight:700; padding:0 1.2mm; }
  .qr { margin-top:4.6mm; width:76mm; height:76mm; background:#fff; border-radius:4mm; padding:3.2mm; }
  .qr img { width:100%; height:100%; display:block; image-rendering:pixelated; }
  .free { margin-top:4.6mm; display:inline-flex; align-items:center; background:${C.gold}; color:#10220D;
    padding:1.8mm 4.4mm; border-radius:100px; font-size:3.6mm; font-weight:800; letter-spacing:.25mm; }
  .link { margin-top:3mm; font-size:3.4mm; font-weight:600; color:rgba(255,255,255,.62); }

  .footer { margin-top:4.5mm; display:flex; justify-content:space-between; font-size:3.2mm; font-weight:500;
    color:rgba(255,255,255,.5); }
</style></head><body>
  <div class="frame">
    <div class="header">
      <div class="badge-icon"><img src="data:image/png;base64,${logoB64}"></div>
      <div class="wordmark">
        <div class="name">GolfTrack</div>
        <div class="sub">Scorecard digitale · Digital scorecard · Digitale Zählkarte</div>
      </div>
      <div class="course">
        <div class="c-name">${NAME}</div>
        ${meta ? `<div class="c-meta">${meta}</div>` : ""}
      </div>
    </div>
    <div class="rule"></div>
    <div class="main">
      <div class="left">${langHtml}</div>
      <div class="right">
        <div class="scan">Scansiona<span class="sep">·</span>Scan<span class="sep">·</span>Scannen</div>
        <div class="qr"><img src="${qrDataUrl}"></div>
        <div class="free">GRATIS · FREE · KOSTENLOS</div>
        <div class="link">${LINK_SHORT}</div>
      </div>
    </div>
    <div class="footer">
      <span>Niente carta, niente matita · No paper, no pencil · Kein Zettel, kein Bleistift</span>
      <span>golftrack.app</span>
    </div>
  </div>
</body></html>`;

const browser = await puppeteer.launch();
const page = await browser.newPage();
await page.setViewport({ width: 1123, height: 794, deviceScaleFactor: 2 });
await page.setContent(html, { waitUntil: "load" });
await page.pdf({ path: outPath, width: "297mm", height: "210mm", printBackground: true });
if (PNG) {
  await page.screenshot({ path: outPath.replace(/\.pdf$/, ".png"), fullPage: false });
}
await browser.close();
console.log(outPath);
