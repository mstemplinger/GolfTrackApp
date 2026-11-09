#!/usr/bin/env node
// GolfTrack – gestaltete App-Store-Bilder für den 6,9-Zoll-Slot (APP_IPHONE_69).
//
// Nimmt rohe Simulator-Aufnahmen (1320×2868, iPhone 17 Pro Max) aus
// `marketing/screenshots/<sprache>-69/`, legt sie in einen gezeichneten
// iPhone-Rahmen auf den App-Hintergrund und schreibt Überschrift + Unterzeile
// darüber. Ausgabe wieder 1320×2868 – genau die Größe, die App Store Connect
// für 6,9 Zoll verlangt (und auf 6,5 Zoll herunterrechnet).
//
// Aufruf (aus marketing/flyer, dort liegt puppeteer):
//   node ../appstore/store-shots.mjs [de|en|all]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(path.join(__dirname, "..", "flyer", "package.json"));
const puppeteer = require("puppeteer");

const ROOT = path.join(__dirname, "..", "..");
const SHOTS = path.join(ROOT, "marketing", "screenshots");
const OUT = path.join(__dirname, "out");

const W = 1320;
const H = 2868;

// Dieselben Farben wie AppTheme in der App.
const C = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", green: "#28824B", light: "#7BD389" };

// Reihenfolge = Reihenfolge im Store. Die ersten drei sieht man in der Suche,
// sie tragen das Versprechen der App.
// `layout`: "up" Gerät unten, Text oben · "tilt" leicht gekippt · "down" Text unten.
const SLIDES = [
  { shot: "19-live-scorecard", layout: "up",
    de: { kicker: "Auf dem Platz", title: "Entfernung<br>zur Fahne. <em>Live.</em>", sub: "GPS-Distanz, Schlägerempfehlung und Scorekarte auf einem Bildschirm." },
    en: { kicker: "On the course", title: "Distance to the pin.<br><em>Live.</em>", sub: "GPS distance, club suggestion and scorecard on one screen." } },
  { shot: "01-home", layout: "tilt",
    de: { kicker: "Dein Golf", title: "Alles auf<br><em>einen Blick</em>", sub: "Handicap, letzte Runde, Platzwetter und dein Fortschritt." },
    en: { kicker: "Your golf", title: "Everything<br><em>at a glance</em>", sub: "Handicap, last round, course weather and your progress." } },
  { shot: "02-profil-handicap", layout: "up",
    de: { kicker: "WHS-Handicap", title: "Handicap rechnet<br><em>sich selbst</em>", sub: "Nach jeder Runde automatisch fortgeschrieben – nach World Handicap System." },
    en: { kicker: "WHS handicap", title: "Your handicap,<br><em>calculated</em>", sub: "Updated automatically after every round, using the World Handicap System." } },
  { shot: "09-schlagkarte", layout: "tilt",
    de: { kicker: "Schlag-Tracking", title: "Jeder Schlag<br><em>verortet</em>", sub: "Abschlag, Auftreffpunkt, Schlagweite – Loch für Loch auf der Karte." },
    en: { kicker: "Shot tracking", title: "Every shot<br><em>on the map</em>", sub: "Tee, landing spot, distance – hole by hole on the map." } },
  { shot: "24-mitspieler", layout: "up",
    de: { kicker: "14 Spielformen", title: "Spiel mit<br><em>deinem Flight</em>", sub: "Zählspiel, Stableford, Matchplay, Best Ball, Scramble – Scorekarte für alle." },
    en: { kicker: "14 game formats", title: "Play with<br><em>your flight</em>", sub: "Stroke play, Stableford, match play, best ball, scramble – one card for all." } },
  { shot: "25-driving-range", layout: "tilt",
    de: { kicker: "Driving Range", title: "Weiß, wie weit<br><em>jeder Schläger</em>", sub: "Bälle schlagen, Weite tippen – deine echte Bag-Statistik entsteht von selbst." },
    en: { kicker: "Driving range", title: "Know how far<br><em>every club goes</em>", sub: "Hit balls, log the carry – your real bag statistics build themselves." } },
  { shot: "06-statistiken-chart", layout: "up",
    de: { kicker: "Statistik", title: "Sieh, wie du<br><em>besser wirst</em>", sub: "Putts, Fairways, Greens in Regulation und Score-Verlauf über alle Runden." },
    en: { kicker: "Statistics", title: "See yourself<br><em>improve</em>", sub: "Putts, fairways, greens in regulation and score trend across all rounds." } },
  { shot: "22-platzreife-uebersicht", layout: "tilt", only: ["de"],
    de: { kicker: "Platzreife", title: "Theorie lernen,<br><em>sicher bestehen</em>", sub: "Alle Prüfungsfragen mit Erklärung, Lernstand und Probeprüfung." } },
  { shot: "12-training", layout: "up",
    de: { kicker: "Training", title: "Coaching<br><em>im Ohr</em>", sub: "Audio-Trainings für Technik, Kurzspiel und Kopf – auch auf der Range." },
    en: { kicker: "Training", title: "A coach<br><em>in your ear</em>", sub: "Audio sessions for technique, short game and mindset – right on the range." } },
];

const logo = "data:image/png;base64," +
  fs.readFileSync(path.join(ROOT, "GolfTrackApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png")).toString("base64");

function slideHtml(slide, lang, shotURI, index) {
  const t = slide[lang];
  const tilt = slide.layout === "tilt" ? (index % 4 === 1 ? -5 : 5) : 0;
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html,body { width:${W}px; height:${H}px; overflow:hidden; }
  body {
    font-family:-apple-system,"SF Pro Display",BlinkMacSystemFont,sans-serif;
    color:#fff; -webkit-font-smoothing:antialiased; position:relative;
    background:
      radial-gradient(120% 45% at 50% -4%, ${C.light}33 0%, transparent 60%),
      radial-gradient(90% 40% at ${tilt < 0 ? "0%" : "100%"} 100%, ${C.gold}26 0%, transparent 60%),
      linear-gradient(180deg, ${C.cardAlt} 0%, ${C.bg} 45%, #0A1E12 100%);
  }
  /* feine Fairway-Streifen, wie gemähter Rasen */
  body::before { content:""; position:absolute; inset:0; opacity:.03;
    background:repeating-linear-gradient(115deg, #fff 0 90px, transparent 90px 180px); }
  .text { position:absolute; left:110px; right:110px; top:190px; z-index:2; }
  .kicker { display:inline-flex; align-items:center; gap:18px; font-size:40px; font-weight:800;
    letter-spacing:6px; text-transform:uppercase; color:${C.gold}; }
  .kicker img { width:64px; height:64px; border-radius:15px; box-shadow:0 6px 20px rgba(0,0,0,.4); }
  h1 { margin-top:36px; font-size:132px; line-height:1.0; font-weight:800; letter-spacing:-3.5px; }
  h1 em { font-style:normal; color:${C.light}; }
  .sub { margin-top:40px; font-size:50px; line-height:1.28; font-weight:500; color:rgba(255,255,255,.72); max-width:1060px; }

  .phone { position:absolute; left:50%; top:1010px; width:1020px; height:${Math.round(1020 * 2868 / 1320) + 52}px;
    transform:translateX(-50%) rotate(${tilt}deg); transform-origin:50% 30%;
    border-radius:150px; padding:26px;
    background:linear-gradient(145deg,#4a4f54 0%,#1d2023 30%,#2b2f33 60%,#0f1113 100%);
    box-shadow:0 60px 140px rgba(0,0,0,.6), 0 0 0 3px #5d6369 inset, 0 0 0 9px #0b0c0d inset; }
  .screen { width:100%; height:100%; border-radius:126px; overflow:hidden; position:relative; background:#000; }
  .screen img { width:100%; height:100%; display:block; }
  .island { position:absolute; top:30px; left:50%; transform:translateX(-50%); width:290px; height:86px;
    background:#000; border-radius:50px; }
  .glow { position:absolute; left:50%; top:1300px; width:1300px; height:900px; transform:translateX(-50%);
    background:radial-gradient(closest-side, ${C.green}55, transparent); filter:blur(40px); }
</style></head><body>
  <div class="glow"></div>
  <div class="text">
    <div class="kicker"><img src="${logo}">${t.kicker}</div>
    <h1>${t.title}</h1>
    <div class="sub">${t.sub}</div>
  </div>
  <div class="phone"><div class="screen"><img src="${shotURI}"><div class="island"></div></div></div>
</body></html>`;
}

function shotPath(lang, name) {
  // Erst die 6,9-Zoll-Aufnahme, sonst die Website-Aufnahme derselben Sprache –
  // nie die andere Sprache, sonst steht Deutsch auf der englischen Seite.
  for (const dir of [`${lang}-69`, lang]) {
    const p = path.join(SHOTS, dir, name + ".png");
    if (fs.existsSync(p)) return p;
  }
  return null;
}

const arg = process.argv[2] || "all";
const langs = arg === "all" ? ["de", "en"] : [arg];

const browser = await puppeteer.launch({ headless: true });
const page = await browser.newPage();
await page.setViewport({ width: W, height: H, deviceScaleFactor: 1 });

for (const lang of langs) {
  const dir = path.join(OUT, lang);
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(dir, { recursive: true });
  let n = 0;
  for (const [i, slide] of SLIDES.entries()) {
    if (slide.only && !slide.only.includes(lang)) continue;
    if (!slide[lang]) continue;
    const src = shotPath(lang, slide.shot);
    if (!src) { console.log(`  – ${lang}/${slide.shot} fehlt, übersprungen`); continue; }
    const uri = "data:image/png;base64," + fs.readFileSync(src).toString("base64");
    await page.setContent(slideHtml(slide, lang, uri, i), { waitUntil: "load" });
    n += 1;
    const out = path.join(dir, `${String(n).padStart(2, "0")}-${slide.shot}.png`);
    await page.screenshot({ path: out, clip: { x: 0, y: 0, width: W, height: H } });
    console.log(`  ✓ ${path.relative(ROOT, out)}`);
  }
}
await browser.close();
