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
//
// Das Aussehen selbst steht in `slide.mjs` – dieselbe Vorlage nutzen die Bilder
// der benutzerdefinierten Produktseiten (`cpp-shots.mjs`).
import fs from "node:fs";
import path from "node:path";
import { puppeteer, ROOT, OUT, W, H, shotPath, dataURI, slideHtml, renderSlide } from "./slide.mjs";

// Reihenfolge = Reihenfolge im Store. Die ersten drei sieht man in der Suche,
// sie tragen das Versprechen der App.
// `layout`: "up" Gerät gerade · "tilt" leicht gekippt.
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
    const tilt = slide.layout === "tilt" ? (i % 4 === 1 ? -5 : 5) : 0;
    n += 1;
    const out = path.join(dir, `${String(n).padStart(2, "0")}-${slide.shot}.png`);
    const notes = await renderSlide(page, slideHtml(slide[lang], dataURI(src), { tilt }), out);
    console.log(`  ✓ ${path.relative(ROOT, out)}${notes.length ? "  ⚠ " + notes.join("; ") : ""}`);
  }
}
await browser.close();
