#!/usr/bin/env node
// GolfTrack – Instagram-Story (1080×1920): Android-APK jetzt über die Website.
// Aufruf:  node android-story.mjs [out.png]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outPath = process.argv[2] || path.join(__dirname, "out", "story-android-apk.png");

const logoB64 = fs.readFileSync(path.join(__dirname, "logo.png")).toString("base64");

const C = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", green: "#28824B", lightGreen: "#7BD389" };

const svg = (p) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${p}</svg>`;
const ICON = {
  globe: svg(`<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17"/><path d="M12 3.5c2.4 2.4 3.6 5.2 3.6 8.5s-1.2 6.1-3.6 8.5c-2.4-2.4-3.6-5.2-3.6-8.5S9.6 5.9 12 3.5Z"/>`),
  download: svg(`<path d="M12 4v11"/><path d="m7.5 10.8 4.5 4.5 4.5-4.5"/><path d="M5 19.5h14"/>`),
  check: svg(`<circle cx="12" cy="12" r="8.5"/><path d="m8.3 12.3 2.5 2.5 5-5.2"/>`),
};
const steps = [
  { icon: ICON.globe, title: "golftrack.app/android", text: "im Handy-Browser öffnen" },
  { icon: ICON.download, title: "APK herunterladen", text: "direkt von unserer Website" },
  { icon: ICON.check, title: "Installieren & losspielen", text: "Runden, Scores, GPS-Distanzen" },
];
const stepHtml = steps.map((s, i) => `
  <div class="step">
    <div class="num">${i + 1}</div>
    <div class="s-text"><div class="s-title">${s.title}</div><div class="s-body">${s.text}</div></div>
    <div class="s-icon">${s.icon}</div>
  </div>`).join("");

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html,body { width:1080px; height:1920px; }
  body {
    font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,sans-serif;
    color:#fff; -webkit-font-smoothing:antialiased;
    background:
      radial-gradient(110% 55% at 50% -6%, ${C.lightGreen}2e 0%, transparent 55%),
      radial-gradient(90% 50% at 50% 108%, ${C.gold}22 0%, transparent 55%),
      linear-gradient(180deg, ${C.card} 0%, ${C.bg} 40%, ${C.bg} 100%);
  }
  .frame { position:absolute; inset:0; display:flex; flex-direction:column; padding:160px 84px 190px; }
  .header { display:flex; align-items:center; gap:26px; }
  .logo { width:104px; height:104px; border-radius:24px; overflow:hidden;
    box-shadow:0 12px 40px rgba(0,0,0,.45), inset 0 0 0 1px rgba(255,255,255,.1); }
  .logo img { width:100%; height:100%; display:block; object-fit:cover; }
  .name { font-size:50px; font-weight:800; letter-spacing:-.5px; line-height:1.05; }
  .sub { font-size:27px; font-weight:600; color:rgba(255,255,255,.55); margin-top:4px; }
  .new { margin-left:auto; background:${C.gold}; color:#10220D; font-weight:800; font-size:28px;
    letter-spacing:3px; padding:14px 26px; border-radius:100px; box-shadow:0 10px 30px ${C.gold}55; }

  .pill { margin-top:84px; align-self:flex-start; display:inline-flex; align-items:center; gap:14px;
    background:${C.lightGreen}1f; color:${C.lightGreen}; border:1.5px solid ${C.lightGreen}66;
    padding:16px 30px; border-radius:100px; font-size:29px; font-weight:800; letter-spacing:3px; }
  .headline { margin-top:36px; font-size:112px; font-weight:800; line-height:1.0; letter-spacing:-2.5px; }
  .headline em { font-style:normal; color:${C.lightGreen}; }
  .lead { margin-top:34px; font-size:42px; font-weight:500; line-height:1.38; color:rgba(255,255,255,.84); }
  .lead b { color:#fff; }

  .card { margin-top:56px; background:${C.card}; border-radius:44px; padding:26px 30px;
    box-shadow:0 30px 80px rgba(0,0,0,.45), inset 0 0 0 1.5px ${C.lightGreen}38; }
  .step { display:flex; align-items:center; gap:28px; padding:26px 16px; }
  .step + .step { border-top:1.5px solid rgba(255,255,255,.08); }
  .num { width:72px; height:72px; flex:0 0 auto; border-radius:50%; background:${C.cardAlt};
    color:${C.gold}; font-size:36px; font-weight:800; display:flex; align-items:center; justify-content:center;
    box-shadow:inset 0 0 0 2px ${C.gold}66; }
  .s-title { font-size:40px; font-weight:800; letter-spacing:-.3px; }
  .s-body { font-size:30px; font-weight:500; color:rgba(255,255,255,.6); margin-top:6px; }
  .s-icon { margin-left:auto; width:56px; height:56px; color:${C.lightGreen}; flex:0 0 auto; }

  /* Freie Fläche für den Instagram-Link-Sticker */
  .bottom { margin-top:auto; display:flex; flex-direction:column; align-items:center; gap:22px; }
  .hint { font-size:32px; font-weight:700; color:${C.gold}; letter-spacing:.5px; }
  .slot { width:100%; height:150px; border-radius:100px; border:3px dashed ${C.gold}80;
    background:${C.gold}10; }
</style></head><body>
  <div class="frame">
    <div class="header">
      <div class="logo"><img src="data:image/png;base64,${logoB64}"></div>
      <div><div class="name">GolfTrack</div><div class="sub">@golftrack.app</div></div>
      <div class="new">NEU</div>
    </div>

    <div class="pill">🤖 ANDROID</div>
    <div class="headline">Jetzt auch<br>für <em>Android</em>.</div>
    <div class="lead">GolfTrack gibt’s ab sofort als <b>APK zum Download</b> auf unserer Website – kostenlos.</div>

    <div class="card">${stepHtml}</div>

    <div class="bottom">
      <div class="hint">👇 Hier geht’s zum Download</div>
      <div class="slot"></div>
    </div>
  </div>
</body></html>`;

fs.mkdirSync(path.dirname(outPath), { recursive: true });
const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox", "--force-color-profile=srgb"] });
const page = await browser.newPage();
await page.setViewport({ width: 1080, height: 1920, deviceScaleFactor: 1 });
await page.setContent(html, { waitUntil: "networkidle0" });
await page.screenshot({ path: outPath, type: "png" });
await browser.close();
console.log("OK ->", outPath);
