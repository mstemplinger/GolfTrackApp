#!/usr/bin/env node
// GolfTrack – Instagram-Story-Generator (1080x1920) im App-Stil (AppTheme.swift)
// Aufruf:  node generate.mjs <config.json> <out.png>
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const [, , configPath, outPath] = process.argv;
if (!configPath || !outPath) {
  console.error("Aufruf: node generate.mjs <config.json> <out.png>");
  process.exit(1);
}

const cfg = JSON.parse(fs.readFileSync(configPath, "utf8"));
const logoB64 = fs.readFileSync(path.join(__dirname, "logo.png")).toString("base64");

// AppTheme-Farben
const C = {
  bg: "#0E2718",
  card: "#163421",
  cardAlt: "#1C4129",
  gold: "#C9A035",
  green: "#28824B",
};
const accent = cfg.accent || C.gold;
const esc = (s = "") =>
  String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html,body { width:1080px; height:1920px; }
  body {
    font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,sans-serif;
    color:#fff;
    background:
      radial-gradient(120% 60% at 50% -8%, ${accent}22 0%, transparent 55%),
      radial-gradient(90% 50% at 50% 108%, ${C.green}26 0%, transparent 55%),
      linear-gradient(180deg, ${C.card} 0%, ${C.bg} 42%, ${C.bg} 100%);
    -webkit-font-smoothing:antialiased;
  }
  .frame {
    position:absolute; inset:0;
    display:flex; flex-direction:column; justify-content:space-between;
    padding:170px 96px 200px;       /* Instagram Safe-Zones oben/unten */
  }
  /* Header */
  .header { display:flex; align-items:center; gap:26px; }
  .badge-icon {
    width:104px; height:104px; border-radius:24px; overflow:hidden;
    box-shadow:0 12px 40px rgba(0,0,0,.45), inset 0 0 0 1px rgba(255,255,255,.10);
    flex:0 0 auto;
  }
  .badge-icon img { width:100%; height:100%; object-fit:cover; display:block; }
  .wordmark { display:flex; flex-direction:column; line-height:1.05; }
  .wordmark .name { font-size:50px; font-weight:800; letter-spacing:-.5px; }
  .wordmark .sub { font-size:27px; font-weight:600; color:rgba(255,255,255,.55); margin-top:4px; }

  /* Card (App cardStyle: #163421, radius 16 -> hier groß skaliert) */
  .card {
    background:${C.card};
    border-radius:48px;
    padding:80px 76px;
    box-shadow:0 30px 80px rgba(0,0,0,.45), inset 0 0 0 1.5px ${accent}40;
    position:relative; overflow:hidden;
  }
  .card::before {   /* dezenter Akzent-Glow oben links */
    content:""; position:absolute; top:-160px; left:-120px;
    width:420px; height:420px; border-radius:50%;
    background:radial-gradient(circle, ${accent}33 0%, transparent 70%);
  }
  .pill {
    display:inline-flex; align-items:center; gap:16px;
    background:${accent}1f; color:${accent};
    border:1.5px solid ${accent}66;
    padding:18px 32px; border-radius:100px;
    font-size:30px; font-weight:800; letter-spacing:3px; text-transform:uppercase;
  }
  .pill .dot { font-size:34px; }
  .headline {
    margin-top:48px;
    font-size:${cfg.headlineSize || 92}px; font-weight:800;
    line-height:1.04; letter-spacing:-1.5px;
  }
  .divider { width:120px; height:8px; border-radius:8px; background:${accent}; margin:48px 0; }
  .body { font-size:42px; font-weight:500; line-height:1.42; color:rgba(255,255,255,.86); }

  /* Footer */
  .footer { display:flex; align-items:center; justify-content:space-between; }
  .handle { font-size:34px; font-weight:600; color:rgba(255,255,255,.62); }
  .cta {
    background:${C.gold}; color:#10220D;
    padding:22px 40px; border-radius:100px;
    font-size:33px; font-weight:800; letter-spacing:.2px;
    box-shadow:0 14px 34px ${C.gold}40;
  }
</style></head><body>
  <div class="frame">
    <div class="header">
      <div class="badge-icon"><img src="data:image/png;base64,${logoB64}"></div>
      <div class="wordmark">
        <div class="name">GolfTrack</div>
        <div class="sub">${esc(cfg.dateLabel || "Golf-Tracking App")}</div>
      </div>
    </div>

    <div class="card">
      <span class="pill"><span class="dot">${esc(cfg.icon || "⛳️")}</span>${esc(cfg.theme || "")}</span>
      <div class="headline">${esc(cfg.headline || "")}</div>
      <div class="divider"></div>
      <div class="body">${esc(cfg.body || "")}</div>
    </div>

    <div class="footer">
      <div class="handle">${esc(cfg.handle || "@golftrack")}</div>
      <div class="cta">${esc(cfg.cta || "Jetzt in GolfTrack")}</div>
    </div>
  </div>
</body></html>`;

const browser = await puppeteer.launch({
  headless: "new",
  args: ["--no-sandbox", "--force-color-profile=srgb"],
});
const page = await browser.newPage();
await page.setViewport({ width: 1080, height: 1920, deviceScaleFactor: 1 });
await page.setContent(html, { waitUntil: "networkidle0" });
await page.screenshot({ path: outPath, type: "png" });
await browser.close();
console.log("OK ->", outPath);
