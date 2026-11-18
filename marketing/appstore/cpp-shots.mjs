#!/usr/bin/env node
// GolfTrack – gestaltete Bilder für die benutzerdefinierten Produktseiten.
//
// Liest die Seiten aus `marketing/cpp-pages.json` (dieselbe Datei, aus der
// `asc-custom-product-page.py` hochlädt) und baut je Seite und Sprache die
// 1320×2868-Bilder nach `out/cpp/<slug>/<sprache>/NN-<shot>.png`.
//
// Aufruf (aus marketing/flyer, dort liegt puppeteer):
//   node ../appstore/cpp-shots.mjs [slug|all]
import fs from "node:fs";
import path from "node:path";
import { puppeteer, ROOT, OUT, W, H, shotPath, dataURI, slideHtml, renderSlide } from "./slide.mjs";

const config = JSON.parse(fs.readFileSync(path.join(ROOT, "marketing", "cpp-pages.json"), "utf8"));
const only = process.argv[2] && process.argv[2] !== "all" ? process.argv[2] : null;
const pages = config.pages.filter((p) => !only || p.slug === only);
if (!pages.length) {
  console.error(`Keine Seite „${only}“. Vorhanden: ${config.pages.map((p) => p.slug).join(", ")}`);
  process.exit(1);
}

const browser = await puppeteer.launch({ headless: true });
const page = await browser.newPage();
await page.setViewport({ width: W, height: H, deviceScaleFactor: 1 });

let missing = 0;
for (const p of pages) {
  for (const [locale, spec] of Object.entries(p.locales)) {
    const lang = locale.slice(0, 2);
    const dir = path.join(OUT, "cpp", p.slug, lang);
    fs.rmSync(dir, { recursive: true, force: true });
    fs.mkdirSync(dir, { recursive: true });
    console.log(`\n${p.name} (${locale})`);
    let tilted = 0;
    for (const [i, slide] of (spec.slides || []).entries()) {
      const src = shotPath(lang, slide.shot);
      if (!src) { console.log(`  ✗ ${lang}/${slide.shot} fehlt`); missing += 1; continue; }
      // Gekippte Bilder wechseln die Richtung, damit die Reihe nicht kippt.
      const tilt = slide.layout === "tilt" ? (tilted++ % 2 === 0 ? -5 : 5) : 0;
      const out = path.join(dir, `${String(i + 1).padStart(2, "0")}-${slide.shot}.png`);
      const notes = await renderSlide(page, slideHtml(slide, dataURI(src), { tilt, device: slide.device }), out);
      console.log(`  ✓ ${path.relative(ROOT, out)}${notes.length ? "  ⚠ " + notes.join("; ") : ""}`);
    }
  }
}
await browser.close();
if (missing) { console.error(`\n${missing} Rohbild(er) fehlen.`); process.exit(1); }
