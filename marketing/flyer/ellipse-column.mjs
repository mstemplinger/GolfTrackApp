#!/usr/bin/env node
// GolfTrack – Druckmotive für elliptische Werbesäulen aus Wellpappe (Flyeralarm „Werbesäulen Ellipse“).
// Die Säule hat zwei gewölbte Druckflächen (vorne/hinten), mittig quer gefalzt.
// Drei Motive als Trio, je eine Größe aus dem Flyeralarm-Programm:
//   golf      60×200 cm  dunkelgrün  – Scorekarte / GPS
//   minigolf  60×180 cm  creme       – Minigolf ohne Zettel
//   lernen    50×155 cm  gold        – Platzreife → Range → Runde
//
// Gestaltungsregeln für die Säule:
//  - Gezeichnet in echten cm (CSS-Einheit cm), 1:1 Endformat.
//  - Wichtiges in den mittleren ~80 % der Breite: an den Rändern biegt die Fläche weg.
//  - QR liegt ÜBER dem Mittelfalz (Knick quer durch den Code stört das Scannen), auf Greifhöhe.
//  - Unterste ~25 cm stehen am Boden: dort nur ruhige Fläche (Grün/Fairway).
//
// Aufruf:  node ellipse-column.mjs [--bleed=3] [--only=golf]
// Ausgabe: out/ellipsensaeule/GolfTrack-Saeule-<id>-<vorne|hinten>.pdf  (Druckdaten, Endformat [+Beschnitt])
//          out/ellipsensaeule/tex/<id>-<vorne|hinten>.png              (Textur 20 px/cm für das 3D-Modell)
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import QRCode from "qrcode";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const arg = (k, d) => (process.argv.find((a) => a.startsWith(`--${k}=`)) || "").split("=")[1] ?? d;
const BLEED_MM = Number(arg("bleed", "0"));
const ONLY = arg("only", "");
const DOWNLOAD = "https://golftrack.app/download";
const PX_PER_CM = 20; // Texturauflösung

const C = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", green: "#28824B", cream: "#F3EEDF", ink: "#10220D" };

const b64 = (p) => fs.readFileSync(p).toString("base64");
const logoB64 = b64(path.join(__dirname, "logo.png"));
const shot = (name) => b64(path.join(__dirname, "..", "screenshots", "de-69", `${name}.png`));

const svg = (paths) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${paths}</svg>`;
const ICON = {
  pin: svg(`<path d="M12 20.5c4-3.8 6.3-6.8 6.3-10.3a6.3 6.3 0 1 0-12.6 0C5.7 13.7 8 16.7 12 20.5Z"/><circle cx="12" cy="10.2" r="2.4"/>`),
  card: svg(`<rect x="4" y="5" width="16" height="14" rx="2.2"/><path d="M4 10h16"/><path d="M9.3 10v9"/><path d="M14.7 10v9"/>`),
  chart: svg(`<path d="M4.7 19.2h14.6"/><rect x="6.3" y="13" width="3.2" height="6"/><rect x="10.4" y="9.3" width="3.2" height="9.7"/><rect x="14.5" y="5.4" width="3.2" height="13.6"/>`),
  watch: svg(`<rect x="7" y="7" width="10" height="10" rx="3"/><path d="M9 7l.5-3.2h5L15 7"/><path d="M9 17l.5 3.2h5l.5-3.2"/><path d="M12 10.3v2.4h1.8"/>`),
  friends: svg(`<circle cx="9" cy="8.6" r="3"/><path d="M3.8 19c.6-3 2.7-4.6 5.2-4.6s4.6 1.6 5.2 4.6"/><circle cx="16.4" cy="9.6" r="2.4"/><path d="M15.6 14.5c2.3 0 4 1.3 4.6 4"/>`),
  cube: svg(`<path d="M12 3.5 19.5 7.7v8.6L12 20.5 4.5 16.3V7.7Z"/><path d="M4.5 7.7 12 12l7.5-4.3"/><path d="M12 12v8.5"/>`),
  book: svg(`<path d="M4.5 5.5c2.6-.9 5.1-.6 7.5 1v13c-2.4-1.6-4.9-1.9-7.5-1Z"/><path d="M19.5 5.5c-2.6-.9-5.1-.6-7.5 1v13c2.4-1.6 4.9-1.9 7.5-1Z"/>`),
  target: svg(`<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4.4"/><circle cx="12" cy="12" r="1.2"/>`),
  flag: svg(`<path d="M7 21V3.5"/><path d="M7 4.2h10.5l-2.6 3.6 2.6 3.6H7"/>`),
};

// Farbschemata: dunkel (App-Look), creme, gold
const THEMES = {
  dark: { bg: `linear-gradient(180deg,#1F4630 0%,${C.bg} 45%,#0A1E12 100%)`, fg: "#fff", sub: "rgba(255,255,255,.74)", accent: C.gold, card: C.card, cardLine: `${C.gold}55`, chipBg: C.cardAlt, chipFg: C.gold, logoRing: "rgba(255,255,255,.12)" },
  cream: { bg: `linear-gradient(180deg,#FBF8EF 0%,${C.cream} 60%,#E9E2CC 100%)`, fg: C.ink, sub: "rgba(16,34,13,.72)", accent: "#A7801F", card: "#fff", cardLine: "#A7801F66", chipBg: C.bg, chipFg: C.gold, logoRing: "rgba(16,34,13,.12)" },
  gold: { bg: `linear-gradient(180deg,#D8B04A 0%,${C.gold} 55%,#B48C27 100%)`, fg: C.ink, sub: "rgba(16,34,13,.78)", accent: C.ink, card: C.bg, cardLine: "rgba(16,34,13,.0)", chipBg: C.bg, chipFg: C.gold, logoRing: "rgba(16,34,13,.18)" },
};

const MOTIFS = [
  {
    id: "golf", W: 60, H: 200, theme: "dark", backTheme: "gold",
    eyebrow: "Golf · Scorekarte · GPS",
    headline: ["Deine", "Runde.", "<em>Jeder Schlag</em>", "<em>gezählt.</em>"],
    hl: 7.9, sub: "Schläge und Putts mit einem Tipp. GPS-Distanz zur Fahne.",
    phones: [{ s: "19-live-scorecard" }],
    points: [{ i: ICON.card, t: "Über 800 Plätze" }, { i: ICON.pin, t: "GPS zur Fahne" }, { i: ICON.watch, t: "Apple Watch" }],
  },
  {
    id: "minigolf", W: 60, H: 180, theme: "cream", backTheme: "dark",
    eyebrow: "Minigolf · Scorekarte",
    headline: ["Minigolf.", "<em>Ohne Zettel.</em>"],
    hl: 8.4, sub: "Code scannen, Namen eintippen, losspielen. Alle Schläge auf einem Handy.",
    phones: [{ s: "30-minigolf-home", side: "l" }, { s: "31-minigolf-ergebnis" }],
    points: [{ i: ICON.friends, t: "Mit Freunden" }, { i: ICON.cube, t: "Bahnen in 3D" }, { i: ICON.chart, t: "Auswertung" }],
  },
  {
    id: "lernen", W: 50, H: 155, theme: "gold", backTheme: "cream",
    eyebrow: "Golf lernen",
    headline: ["Platzreife.", "Range.", "<em>Erste Runde.</em>"],
    hl: 6.2, sub: "",
    phones: [{ s: "22-platzreife-uebersicht" }],
    points: [{ i: ICON.book, t: "Platzreife" }, { i: ICON.target, t: "Driving Range" }, { i: ICON.flag, t: "Erste Runde" }],
  },
];

const css = (W, H, b, t) => `
  * { margin:0; padding:0; box-sizing:border-box; }
  @page { size:${W + 2 * b}cm ${H + 2 * b}cm; margin:0; }
  html, body { width:${W + 2 * b}cm; height:${H + 2 * b}cm; }
  body { font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,"Helvetica Neue",sans-serif; -webkit-font-smoothing:antialiased; color:${t.fg}; background:${t.bg}; }
  .page { position:relative; width:${W + 2 * b}cm; height:${H + 2 * b}cm; overflow:hidden; }
  .safe { position:absolute; left:${b + W * 0.1}cm; right:${b + W * 0.1}cm; top:${b}cm; bottom:${b}cm; }
  em { font-style:normal; color:${t.accent}; }
  .logo { border-radius:22%; overflow:hidden; box-shadow:inset 0 0 0 0.1cm ${t.logoRing}; }
  .logo img { width:100%; height:100%; display:block; }
  .qr { background:#fff; border-radius:1.2cm; padding:0.9cm; }
  .qr img { width:100%; height:100%; display:block; }
  .phone { position:absolute; aspect-ratio:1320/2868; background:#050c08; border-radius:3.6cm; padding:0.6cm; box-shadow:inset 0 0 0 0.22cm #3a4a40; }
  .phone img { width:100%; height:100%; display:block; border-radius:3cm; }
`;

function front(m, b, qr) {
  const t = THEMES[m.theme];
  const { W, H } = m;
  const fold = H / 2;
  // Greifhöhe: QR-Unterkante 12 cm über dem Falz
  const qrSize = Math.min(W * 0.36, 21);
  const qrTop = fold - 12 - qrSize;
  const inner = W * 0.8;
  const grassTop = H - 26;
  const phoneW = m.phones.length > 1 ? inner * 0.54 : inner * 0.7;
  const phoneTop = qrTop + qrSize + 1.2 + (m.phoneGap ?? 5);
  const phoneH = phoneW * 2868 / 1320;
  const phonesHtml = m.phones.map((p, i) => {
    const isSide = p.side === "l";
    const w = isSide ? phoneW * 0.86 : phoneW;
    const left = isSide ? -W * 0.02 : m.phones.length > 1 ? inner - phoneW + W * 0.02 : (inner - phoneW) / 2;
    const top = isSide ? phoneTop + 5 : phoneTop;
    const rot = isSide ? -8 : m.phones.length > 1 ? 4 : 0;
    return `<div class="phone" style="width:${w}cm;left:${left}cm;top:${top}cm;transform:rotate(${rot}deg)"><img src="data:image/png;base64,${shot(p.s)}"></div>`;
  }).join("");
  const grassColor = m.theme === "dark" ? "#28824B" : C.bg;
  return `<!doctype html><html><head><meta charset="utf-8"><style>${css(W, H, b, t)}
  .head { position:absolute; left:0; right:0; top:6cm; display:flex; align-items:center; gap:1.6cm; }
  .head .logo { width:${W * 0.14}cm; height:${W * 0.14}cm; }
  .brand { font-size:${W * 0.075}cm; font-weight:800; letter-spacing:-0.1cm; }
  .eyebrow { position:absolute; left:0; right:0; top:${6 + W * 0.14 + 6}cm; font-size:${W * 0.033}cm; font-weight:800; letter-spacing:0.3cm; text-transform:uppercase; color:${t.accent}; }
  .hl { position:absolute; left:0; right:-${W * 0.08}cm; top:${6 + W * 0.14 + 10}cm; font-size:${m.hl}cm; font-weight:800; line-height:.98; letter-spacing:-0.32cm; }
  .sub { font-size:${W * 0.036}cm; font-weight:500; line-height:1.32; color:${t.sub}; margin-top:2.4cm; letter-spacing:0; }
  .cta { position:absolute; left:-${W * 0.04}cm; right:-${W * 0.04}cm; top:${qrTop - 1.2}cm; display:flex; gap:1.8cm; align-items:center;
         background:${t.card}; border-radius:2.2cm; padding:1.2cm; box-shadow:inset 0 0 0 0.18cm ${t.cardLine}; }
  .cta .qr { width:${qrSize}cm; height:${qrSize}cm; flex:0 0 auto; }
  .cta-t { color:${m.theme === "gold" ? "#fff" : t.fg}; }
  .cta-e { font-size:${W * 0.028}cm; font-weight:800; letter-spacing:0.2cm; text-transform:uppercase; color:${m.theme === "gold" ? C.gold : t.accent}; }
  .cta-h { margin-top:0.7cm; font-size:${W * 0.05}cm; font-weight:800; line-height:1.04; letter-spacing:-0.1cm; }
  .cta-n { margin-top:1cm; font-size:${W * 0.024}cm; font-weight:600; opacity:.65; line-height:1.3; }
  .grass { position:absolute; left:-${W}cm; right:-${W}cm; top:${grassTop + b}cm; bottom:0; background:${grassColor};
           border-radius:50% 50% 0 0 / 3cm 3cm 0 0; box-shadow:inset 0 0.35cm 0 ${C.gold}; }
  .points { position:absolute; left:-${W * 0.04}cm; right:-${W * 0.04}cm; top:${grassTop + 5}cm; display:flex; justify-content:space-between; gap:1cm; }
  .pt { flex:1 1 0; display:flex; flex-direction:column; align-items:center; gap:0.8cm; color:#fff; text-align:center; }
  .pt-i { width:${W * 0.12}cm; height:${W * 0.12}cm; border-radius:1.6cm; background:rgba(255,255,255,.12); color:${C.gold}; display:flex; align-items:center; justify-content:center; box-shadow:inset 0 0 0 0.12cm ${C.gold}66; }
  .pt-i svg { width:58%; height:58%; }
  .pt-t { font-size:${W * 0.028}cm; font-weight:800; line-height:1.1; }
  .url { position:absolute; left:0; right:0; bottom:4.5cm; text-align:center; font-size:${W * 0.03}cm; font-weight:700; color:rgba(255,255,255,.7); letter-spacing:0.05cm; }
  .phones { position:absolute; left:0; right:0; top:0; height:${grassTop + 3}cm; overflow:hidden; margin:0 -${W * 0.1}cm; padding:0 ${W * 0.1}cm; }
  .phones-in { position:relative; height:100%; }
</style></head><body><div class="page">
  <div class="grass"></div>
  <div class="safe">
    <div class="phones"><div class="phones-in">${phonesHtml}</div></div>
    <div class="head"><div class="logo"><img src="data:image/png;base64,${logoB64}"></div><div class="brand">GolfTrack</div></div>
    <div class="eyebrow">${m.eyebrow}</div>
    <div class="hl">${m.headline.join("<br>")}${m.sub ? `<div class="sub">${m.sub}</div>` : ""}</div>
    <div class="cta"><div class="qr"><img src="${qr}"></div>
      <div class="cta-t"><div class="cta-e">Kostenlos</div><div class="cta-h">Scannen &amp;<br>loslegen.</div><div class="cta-n">iPhone · Apple Watch<br>Android</div></div></div>
    <div class="points">${m.points.map((p) => `<div class="pt"><div class="pt-i">${p.i}</div><div class="pt-t">${p.t}</div></div>`).join("")}</div>
    <div class="url">golftrack.app</div>
  </div>
</div></body></html>`;
}

// Rückseite: Fernwirkung – Logo, Claim, QR auf Greifhöhe über dem Falz,
// darunter der Schriftzug senkrecht (von unten nach oben lesbar) wie bei den Flyeralarm-Mustern.
function back(m, b, qr) {
  const t = THEMES[m.backTheme];
  const { W, H } = m;
  const fold = H / 2;
  const qrSize = Math.min(W * 0.36, 21);
  const wTop = fold + 3, wBot = H - 7;
  const len = wBot - wTop;
  const F = Math.min(len / 4.75, W * 0.4);
  return `<!doctype html><html><head><meta charset="utf-8"><style>${css(W, H, b, t)}
  .logo.big { position:absolute; left:50%; transform:translateX(-50%); top:7cm; width:${W * 0.3}cm; height:${W * 0.3}cm; }
  .claim { position:absolute; left:-${W * 0.05}cm; right:-${W * 0.05}cm; top:${7 + W * 0.3 + 5}cm; text-align:center; font-size:${W * 0.072}cm; font-weight:800; line-height:1.04; letter-spacing:-0.12cm; color:${t.fg}; }
  .claim em { display:block; }
  .qrbox { position:absolute; left:50%; transform:translateX(-50%); top:${fold - 12 - qrSize}cm; display:flex; flex-direction:column; align-items:center; gap:1.1cm; }
  .qrbox .qr { width:${qrSize}cm; height:${qrSize}cm; box-shadow:0 0 0 0.25cm ${t.accent}; }
  .qr-l { font-size:${W * 0.036}cm; font-weight:800; color:${t.fg}; }
  .qr-u { font-size:${W * 0.03}cm; font-weight:700; color:${t.sub}; margin-top:-0.6cm; }
  .word { position:absolute; left:50%; top:${b + (wTop + wBot) / 2}cm; width:${len}cm; transform:translate(-50%,-50%) rotate(-90deg);
          text-align:center; font-size:${F}cm; font-weight:900; letter-spacing:-0.05em; line-height:1; white-space:nowrap; color:${t.fg}; }
  .word em { color:${t.accent}; }
</style></head><body><div class="page">
  <div class="word">Golf<em>Track</em></div>
  <div class="safe">
    <div class="logo big"><img src="data:image/png;base64,${logoB64}"></div>
    <div class="claim">Golf &amp; Minigolf.<em>Jeder Schlag gezählt.</em></div>
    <div class="qrbox"><div class="qr"><img src="${qr}"></div><div class="qr-l">App kostenlos laden</div><div class="qr-u">golftrack.app</div></div>
  </div>
</div></body></html>`;
}

const outDir = path.join(__dirname, "out", "ellipsensaeule");
fs.mkdirSync(path.join(outDir, "tex"), { recursive: true });
const qrFor = (dark) => QRCode.toDataURL(DOWNLOAD, { errorCorrectionLevel: "Q", margin: 1, width: 1400, color: { dark, light: "#FFFFFF" } });
const qr = await qrFor(C.ink);

const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox", "--force-color-profile=srgb"] });
const CM = 96 / 2.54;
for (const m of MOTIFS.filter((x) => !ONLY || x.id === ONLY)) {
  for (const [side, fn] of [["vorne", front], ["hinten", back]]) {
    const b = BLEED_MM / 10;
    const page = await browser.newPage();
    // PDF (Druckdaten)
    await page.setContent(fn(m, b, qr), { waitUntil: "networkidle0" });
    const pdf = path.join(outDir, `GolfTrack-Saeule-${m.id}-${m.W}x${m.H}-${side}${b ? "-Beschnitt" : ""}.pdf`);
    await page.pdf({ path: pdf, preferCSSPageSize: true, printBackground: true, pageRanges: "1" });
    // Textur fürs 3D-Modell (immer ohne Beschnitt)
    await page.close();
    const tex = await browser.newPage();
    await tex.setViewport({ width: Math.ceil(m.W * CM), height: Math.ceil(m.H * CM), deviceScaleFactor: PX_PER_CM / CM });
    await tex.setContent(fn(m, 0, qr), { waitUntil: "load" });
    await (await tex.$(".page")).screenshot({ path: path.join(outDir, "tex", `${m.id}-${side}.png`) });
    await tex.close();
    console.log("OK ->", path.basename(pdf));
  }
}
await browser.close();
