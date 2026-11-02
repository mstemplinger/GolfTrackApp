#!/usr/bin/env node
// GolfTrack – Clubhaus-Plakat für EINEN Golfplatz (A4 + A3 Hochformat) im App-Stil.
// Indirekte Werbung: „Die Scorekarte dieses Platzes gibt's aufs Handy" + QR, der direkt
// in die Runde auf diesem Platz führt (play.golftrack.app/p/<slug> – nicht der App Store).
// Platzdaten (Par je Loch, CR/Slope) kommen live aus /api/v1/courses/<slug>; Texte und
// Par-Leiste richten sich danach, was hinterlegt ist (kein Versprechen ohne Daten).
//
// Aufruf:  node clubhaus-poster.mjs [--slug <kennung>] [--of "vom Raßbach"] [--file <Dateiname-Teil>] [--png]
//          node clubhaus-poster.mjs --near 48.6745,13.4706 [--km 30] [--png]   (alle Golfplätze im Umkreis)
// Ausgabe: out/GolfTrack-Clubhaus-<file>-A4.pdf und -A3.pdf
// A3 ist dasselbe A4-Layout, per page.pdf({format:'A3', scale:√2}) verlustfrei hochskaliert.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import QRCode from "qrcode";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const arg = (name, def) => {
  const i = process.argv.indexOf(`--${name}`);
  return i > -1 ? process.argv[i + 1] : def;
};
const wantPng = process.argv.includes("--png");
const API = "https://golftrack.app/api/v1/courses";
const RASSBACH = "donau-golf-club-passau-rassbach-e-v";

// Headline-Zeile 2 („Die Scorekarte <of>.") und Dateiname je Platz; unbekannte Plätze
// bekommen „vom <Name>" und den Slug als Dateinamen.
const PRESETS = {
  [RASSBACH]: { of: "vom Raßbach", file: "Passau-Rassbach" },
  "golfclub-tittling": { of: "vom GC Tittling", file: "Tittling" },
  "golf-und-landclub-bayerwald-e-v": { of: "vom GLC Bayerwald", file: "Bayerwald" },
  "3-loch-uebungsrunde-gc-bayerwald": { of: "der 3-Loch-Runde", file: "Bayerwald-3-Loch" },
  "golfclub-am-nationalpark-bayerischer-wald": { of: "vom GC am Nationalpark", file: "Nationalpark-Bayerischer-Wald" },
  "panorama-golf-passau": { of: "vom Panorama Golf", file: "Panorama-Golf-Passau" },
  "golfclub-vilshofen": { of: "vom GC Vilshofen", file: "Vilshofen" },
  "quellness-golf-brunnwies": { of: "von Brunnwies", file: "Quellness-Brunnwies" },
};

const km = (a, b, c, d) => {
  const r = (x) => (x * Math.PI) / 180;
  const h = Math.sin(r(c - a) / 2) ** 2 + Math.cos(r(a)) * Math.cos(r(c)) * Math.sin(r(d - b) / 2) ** 2;
  return 12742 * Math.asin(Math.sqrt(h));
};

let jobs;
if (arg("near")) {
  const [lat, lon] = arg("near").split(",").map(Number);
  const radius = Number(arg("km", "30"));
  const { courses } = await (await fetch(API)).json();
  jobs = courses
    .filter((c) => c.kind === "golf" && c.lat != null && km(lat, lon, c.lat, c.lon) <= radius)
    .sort((a, b) => km(lat, lon, a.lat, a.lon) - km(lat, lon, b.lat, b.lon))
    .map((c) => ({ slug: c.id, ...PRESETS[c.id] }));
} else {
  const slug = arg("slug", RASSBACH);
  jobs = [{ slug, ...PRESETS[slug], ...(arg("of") && { of: arg("of") }), ...(arg("file") && { file: arg("file") }) }];
}

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
const shots = path.join(__dirname, "..", "screenshots", "de");
const shot = (name) => b64(path.join(shots, `${name}.png`));
// Screenshot 13 zeigt eine echte Runde in Passau-Raßbach – nur dort verwenden. Für alle
// anderen Plätze zwei Ansichten ohne Platznamen.
const SHOTS_RASSBACH = { front: shot("13-rundendetail-gps"), back: shot("06-statistiken-chart") };
const SHOTS_NEUTRAL = { front: shot("06-statistiken-chart"), back: shot("04-schlaegerdistanzen") };

const svg = (paths) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${paths}</svg>`;
const ICON = {
  card: svg(`<rect x="4" y="5" width="16" height="14" rx="2.2"/><path d="M4 10h16"/><path d="M9.3 10v9"/><path d="M14.7 10v9"/>`),
  pin: svg(`<path d="M12 20.5c4-3.8 6.3-6.8 6.3-10.3a6.3 6.3 0 1 0-12.6 0C5.7 13.7 8 16.7 12 20.5Z"/><circle cx="12" cy="10.2" r="2.4"/>`),
  tap: svg(`<circle cx="12" cy="12" r="7.6"/><path d="M12 8.6v6.8"/><path d="M8.6 12h6.8"/>`),
  chart: svg(`<path d="M4.7 19.2h14.6"/><rect x="6.3" y="13" width="3.2" height="6"/><rect x="10.4" y="9.3" width="3.2" height="9.7"/><rect x="14.5" y="5.4" width="3.2" height="13.6"/>`),
  watch: svg(`<rect x="7" y="7" width="10" height="10" rx="3"/><path d="M9 7l.5-3.2h5L15 7"/><path d="M9 17l.5 3.2h5l.5-3.2"/><path d="M12 10.3v2.4h1.8"/>`),
};

const fmt = (n) => String(n).replace(".", ",");

function buildHtml(course, of, qrDataUrl) {
const n = course.holes;
const full = (arr) => arr.length === n;
const pars = full(course.parValues) ? course.parValues : [];
const parTotal = pars.reduce((a, b) => a + b, 0);

// Punkt 1 und 2 nur so stark, wie die Daten es hergeben
let dataText = "Par, Handicap und Länge – nichts abtippen.";
if (!full(course.hcpValues)) dataText = full(course.holeLengths) ? "Par und Länge – nichts abtippen." : "Par je Bahn – nichts abtippen.";
const first = pars.length
  ? { icon: ICON.card, title: `Alle ${n} Bahnen schon drin`, text: dataText }
  : { icon: ICON.card, title: "Platz schon angelegt", text: "Auswählen und sofort losspielen." };
const gps = full(course.flagLatitudes)
  ? { icon: ICON.pin, title: "GPS-Distanz zur Fahne", text: "Auf den Meter, bei jedem Schlag." }
  : { icon: ICON.pin, title: "GPS-Distanz zur Fahne", text: "Fahne einmal setzen, dann live gemessen." };
const points = [
  first,
  gps,
  { icon: ICON.tap, title: "Zählen mit einem Tipp", text: "Schläge, Putts, Fairway, Grün." },
  { icon: ICON.chart, title: "Auswertung danach", text: "Scorekarte, Schlagkarte, Statistik." },
  { icon: ICON.watch, title: "Auch an der Apple Watch", text: "iPhone bleibt in der Tasche." },
];

const { front: shotFront, back: shotBack } = course.id === RASSBACH ? SHOTS_RASSBACH : SHOTS_NEUTRAL;
const holeCells = pars
  .map((p, i) => `<div class="hc${i === 8 && n === 18 ? " turn" : ""}"><div class="hn">${i + 1}</div><div class="hp">${p}</div></div>`)
  .join("");
const meta = [
  `Par <b>${parTotal}</b>`,
  course.courseRating != null && `CR <b>${fmt(course.courseRating)}</b>`,
  course.slopeRating != null && `Slope <b>${course.slopeRating}</b>`,
].filter(Boolean).join(" · ");
const scorecard = pars.length
  ? `<div class="scorecard">
      <div class="sc-head">
        <div class="sc-title">Schon hinterlegt: alle ${n} Bahnen</div>
        <div class="sc-meta">${meta}</div>
      </div>
      <div class="holes" style="grid-template-columns:${n >= 9 ? `repeat(${n}, 1fr)` : `repeat(${n}, 16mm)`}">${holeCells}</div>
    </div>`
  : "";

return `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html, body { width: 210mm; height: 297mm; }
  body {
    font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,"Helvetica Neue",sans-serif;
    color:#fff; -webkit-font-smoothing:antialiased;
    background:linear-gradient(180deg, #1A3A26 0%, ${C.bg} 50%, #0A1E12 100%);
  }
  .page { position:relative; width:210mm; height:297mm; overflow:hidden; }
  .frame { position:absolute; inset:0; display:flex; flex-direction:column; padding:12mm 14mm 10mm; }

  .header { display:flex; align-items:center; gap:3.2mm; }
  .logo { width:11mm; height:11mm; border-radius:2.8mm; overflow:hidden; box-shadow:inset 0 0 0 1px rgba(255,255,255,.1); }
  .logo img { width:100%; height:100%; display:block; }
  .brand { font-size:6mm; font-weight:800; letter-spacing:-.2mm; }
  .club {
    margin-left:auto; display:inline-flex; align-items:center; gap:2mm;
    border:0.4mm solid ${accent}66; background:rgba(255,255,255,.05);
    padding:2mm 4mm; border-radius:100px; font-size:3.6mm; font-weight:700; color:rgba(255,255,255,.9);
  }
  .club svg { width:4mm; height:4mm; color:${accent}; }

  .eyebrow { margin-top:7mm; font-size:4mm; font-weight:800; letter-spacing:1mm; text-transform:uppercase; color:${accent}; }
  .headline { margin-top:2.6mm; font-size:13mm; font-weight:800; line-height:1.02; letter-spacing:-.7mm; }
  .headline .accent { color:${accent}; }

  .middle { margin-top:5mm; display:flex; gap:4mm; align-items:center; }
  .points { flex:1 1 auto; display:flex; flex-direction:column; gap:3mm; }
  .pt { display:flex; gap:3.6mm; align-items:center; }
  .pt-icon {
    width:11mm; height:11mm; flex:0 0 auto; border-radius:3mm; color:${accent};
    display:flex; align-items:center; justify-content:center;
    background:${C.card}; box-shadow:inset 0 0 0 0.3mm ${accent}40;
  }
  .pt-icon svg { width:6mm; height:6mm; display:block; }
  .pt-title { font-size:5mm; font-weight:800; letter-spacing:-.15mm; line-height:1.1; }
  .pt-text { margin-top:.7mm; font-size:3.8mm; font-weight:500; color:rgba(255,255,255,.66); }

  /* Zwei iPhones, das hintere leicht gedreht */
  .phones { position:relative; flex:0 0 70mm; height:96mm; }
  .phone {
    position:absolute; width:44mm; aspect-ratio:1206/2622;
    background:#050c08; border-radius:7mm; padding:1.3mm;
    box-shadow:inset 0 0 0 0.45mm #3a4a40;
  }
  .phone img { width:100%; height:100%; display:block; border-radius:5.8mm; }
  .phone.back  { right:0; top:1mm; transform:rotate(7deg); }
  .phone.front { left:0; top:3mm; transform:rotate(-4deg); }

  .scorecard {
    margin-top:4mm; background:${C.card}; border-radius:4.5mm; padding:3.4mm 4.5mm 3.8mm;
    box-shadow:inset 0 0 0 0.35mm ${accent}2e;
  }
  .sc-head { display:flex; justify-content:space-between; align-items:baseline; }
  .sc-title { font-size:4mm; font-weight:800; }
  .sc-meta { font-size:3.5mm; font-weight:600; color:rgba(255,255,255,.6); }
  .sc-meta b { color:${accent}; font-weight:800; }
  .holes { margin-top:2.6mm; display:grid; gap:0.9mm; }
  .hc { background:${C.cardAlt}; border-radius:1.4mm; text-align:center; padding:1.2mm 0 1.4mm; }
  .hc.turn { box-shadow:inset -0.5mm 0 0 ${accent}88; }
  .hn { font-size:2.6mm; font-weight:600; color:rgba(255,255,255,.5); }
  .hp { margin-top:.3mm; font-size:4.2mm; font-weight:800; }

  .qr-band {
    margin-top:auto; flex:0 0 auto; display:flex; align-items:center; gap:7mm;
    background:${C.cardAlt}; border-radius:6mm; padding:4.5mm 6mm;
    box-shadow:inset 0 0 0 0.45mm ${accent}66;
  }
  .qr { flex:0 0 auto; width:47mm; height:47mm; background:#fff; border-radius:4mm; padding:2.4mm; }
  .qr img { width:100%; height:100%; display:block; }
  .qr-text { flex:1 1 auto; }
  .qr-eyebrow { font-size:3.7mm; font-weight:800; letter-spacing:.7mm; text-transform:uppercase; color:${accent}; }
  .qr-title { margin-top:1.8mm; font-size:8.6mm; font-weight:800; line-height:1.05; letter-spacing:-.3mm; }
  .steps { margin-top:3.6mm; display:flex; flex-direction:column; gap:1.5mm; }
  .step { display:flex; align-items:center; gap:2.6mm; font-size:3.9mm; font-weight:600; color:rgba(255,255,255,.85); }
  .step .n {
    width:5.4mm; height:5.4mm; flex:0 0 auto; border-radius:50%; background:${accent}; color:#10220D;
    font-size:3.2mm; font-weight:800; display:flex; align-items:center; justify-content:center;
  }
  .qr-note { margin-top:3.2mm; font-size:3.3mm; font-weight:500; color:rgba(255,255,255,.5); }

  .foot { margin-top:3.6mm; display:flex; justify-content:space-between; font-size:3.2mm; font-weight:600; color:rgba(255,255,255,.42); }
</style></head><body><div class="page">
  <div class="frame">
    <div class="header">
      <div class="logo"><img src="data:image/png;base64,${logoB64}"></div>
      <div class="brand">GolfTrack</div>
      <div class="club">${ICON.pin} ${course.name.replace(/ e\.V\.$/, "")}</div>
    </div>

    <div class="eyebrow">Für deine Runde heute</div>
    <div class="headline">Die Scorekarte<br>${of}.<br><span class="accent">Jetzt am Handy.</span></div>

    <div class="middle"${pars.length ? "" : ' style="flex:1"'}>
      <div class="points">${points
        .map(
          (p) => `<div class="pt"><div class="pt-icon">${p.icon}</div><div>
            <div class="pt-title">${p.title}</div><div class="pt-text">${p.text}</div></div></div>`
        )
        .join("")}</div>
      <div class="phones">
        <div class="phone back"><img src="data:image/png;base64,${shotBack}"></div>
        <div class="phone front"><img src="data:image/png;base64,${shotFront}"></div>
      </div>
    </div>

    ${scorecard}

    <div class="qr-band">
      <div class="qr"><img src="${qrDataUrl}"></div>
      <div class="qr-text">
        <div class="qr-eyebrow">Am 1. Abschlag</div>
        <div class="qr-title">Scannen &amp;<br>Runde starten.</div>
        <div class="steps">
          <div class="step"><span class="n">1</span>Kamera auf den Code halten</div>
          <div class="step"><span class="n">2</span>Platz ist schon gewählt</div>
          <div class="step"><span class="n">3</span>Loslegen und mitzählen</div>
        </div>
        <div class="qr-note">Kostenlos · ohne Anmeldung · iPhone, Apple&nbsp;Watch oder Browser</div>
      </div>
    </div>

    <div class="foot"><span>golftrack.app</span><span>Mehr Plätze, Training &amp; KI-Caddy in der App</span></div>
  </div>
</div></body></html>`;
}

const outDir = path.join(__dirname, "out");
fs.mkdirSync(outDir, { recursive: true });
const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox", "--force-color-profile=srgb"] });

for (const job of jobs) {
  const res = await fetch(`${API}/${job.slug}`);
  if (!res.ok) throw new Error(`Platz ${job.slug} nicht gefunden (${res.status})`);
  const course = await res.json();
  const playUrl = `https://play.golftrack.app/p/${job.slug}`;
  const qrDataUrl = await QRCode.toDataURL(playUrl, {
    errorCorrectionLevel: "M",
    margin: 1,
    width: 900,
    color: { dark: "#10220D", light: "#FFFFFF" },
  });
  const of = job.of || `vom ${course.name.replace(/ e\.V\.$/, "")}`;
  const base = path.join(outDir, `GolfTrack-Clubhaus-${job.file || job.slug}`);

  const page = await browser.newPage();
  await page.setContent(buildHtml(course, of, qrDataUrl), { waitUntil: "networkidle0" });
  // @page muss die Zielgröße tragen (wie bei board.mjs), das Layout bleibt in A4-mm.
  await page.addStyleTag({ content: "@page { size: A4 portrait; margin: 0; }" });
  await page.pdf({ path: `${base}-A4.pdf`, format: "A4", printBackground: true, pageRanges: "1" });
  await page.addStyleTag({ content: "@page { size: A3 portrait; margin: 0; }" });
  await page.pdf({ path: `${base}-A3.pdf`, format: "A3", printBackground: true, scale: Math.SQRT2, pageRanges: "1" });
  if (wantPng) {
    await page.setViewport({ width: 794, height: 1123, deviceScaleFactor: 2 });
    await (await page.$(".page")).screenshot({ path: `${base}-Vorschau.png` });
  }
  await page.close();
  console.log("OK ->", path.basename(base), "QR:", playUrl);
}
await browser.close();
