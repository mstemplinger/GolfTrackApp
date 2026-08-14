#!/usr/bin/env node
// GolfTrack – Instagram-Carousel-Generator (1080x1350, 4:5) im App-Stil (AppTheme.swift)
//
// Erzeugt die Slides für einen Feed-Post. Diagramme sind bewusst als Diagramme
// gezeichnet, nicht als Fake-Screenshots – echte Screenshots kommen in shots/
// und werden in einen Telefonrahmen gesetzt.
//
// Aufruf (puppeteer liegt beim Story-Generator, deshalb NODE_PATH):
//   NODE_PATH=../instagram-story/node_modules node generate.mjs [out-Verzeichnis]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outDir = process.argv[2] || path.join(__dirname, "out");
fs.mkdirSync(outDir, { recursive: true });

const W = 1080, H = 1350;

// Muss zum tatsächlichen Store-Stand passen. Vor der Freigabe: "kommt".
// Nach der Freigabe hier auf "ist da" umstellen und neu rendern.
const RELEASE_LINE = process.env.RELEASED
  ? "Update 2.2 ist im App Store."
  : "Update 2.2 kommt in den nächsten Tagen.";

// AppTheme-Farben (Shared/AppTheme.swift)
const C = {
  bg: "#0E2718",
  card: "#163421",
  cardAlt: "#1C4129",
  cardDark: "#112D1C",
  gold: "#C9A035",
  green: "#28824B",
  greenMid: "#1C6138",
};

const logoB64 = fs.readFileSync(path.join(__dirname, "logo.png")).toString("base64");
const shot = (name) => {
  const p = path.join(__dirname, "shots", name);
  return fs.existsSync(p) ? fs.readFileSync(p).toString("base64") : null;
};

const esc = (s = "") =>
  String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

// ── Diagramme ────────────────────────────────────────────────────────────────
// Alles wird aus EINER Mittellinie abgeleitet, damit Fairway, Laufspur und
// Korridor zwangsläufig zusammenpassen.

const AXIS = { from: [250, 930], to: [740, 300] };

/** Einheitsvektoren der Achse und quer dazu. */
const AX = (() => {
  const dx = AXIS.to[0] - AXIS.from[0], dy = AXIS.to[1] - AXIS.from[1];
  const len = Math.hypot(dx, dy);
  return { dir: [dx / len, dy / len], nrm: [-dy / len, dx / len], len };
})();

/** Mittellinie des Lochs: Dogleg nach rechts, quer zur Achse versetzt. */
const CENTER = Array.from({ length: 25 }, (_, i) => {
  const t = i / 24;
  const bend = Math.sin(t * Math.PI) * 95;
  return [
    AXIS.from[0] + AX.dir[0] * AX.len * t + AX.nrm[0] * bend,
    AXIS.from[1] + AX.dir[1] * AX.len * t + AX.nrm[1] * bend,
  ];
});

const TEE = CENTER[0], GREEN = CENTER[CENTER.length - 1];

/** Lokale Normale an Stützpunkt i (aus den Nachbarpunkten). */
function normalAt(pts, i) {
  const a = pts[Math.max(0, i - 1)], b = pts[Math.min(pts.length - 1, i + 1)];
  const dx = b[0] - a[0], dy = b[1] - a[1], len = Math.hypot(dx, dy) || 1;
  return [-dy / len, dx / len];
}

/** Mittellinie seitlich versetzen; `amount(i)` in SVG-Einheiten. */
function offset(pts, amount) {
  return pts.map((p, i) => {
    const n = normalAt(pts, i);
    const a = amount(i / (pts.length - 1), i);
    return [p[0] + n[0] * a, p[1] + n[1] * a];
  });
}

const poly = (pts) => pts.map((p) => `${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");
const svg = (inner) =>
  `<svg viewBox="120 220 780 790" width="100%" height="100%">${inner}</svg>`;

/** Fairway-Fläche, Grün mit Fahne, Abschlagsmarkierung. */
function holeBase(opacity = 1) {
  return `
  <polyline points="${poly(CENTER)}" fill="none" stroke="${C.greenMid}" stroke-width="164"
            stroke-linecap="round" stroke-linejoin="round" opacity="${0.5 * opacity}"/>
  <polyline points="${poly(CENTER)}" fill="none" stroke="${C.green}" stroke-width="126"
            stroke-linecap="round" stroke-linejoin="round" opacity="${0.45 * opacity}"/>
  <circle cx="${GREEN[0]}" cy="${GREEN[1]}" r="56" fill="#3E9C5F" opacity="${0.9 * opacity}"/>
  <circle cx="${GREEN[0]}" cy="${GREEN[1]}" r="7" fill="${C.bg}"/>
  <rect x="${GREEN[0] + 5}" y="${GREEN[1] - 62}" width="4" height="62" fill="#fff" opacity=".9"/>
  <path d="M ${GREEN[0] + 9} ${GREEN[1] - 62} l 36 12 l -36 12 z" fill="#E4574F"/>
  <rect x="${TEE[0] - 36}" y="${TEE[1] - 13}" width="72" height="26" rx="13"
        fill="${C.cardAlt}" stroke="rgba(255,255,255,.28)"/>`;
}

/** Gelaufene Spur: Mittellinie mit Wackeln, weil man zum Ball läuft. */
const WALK = offset(CENTER, (t, i) =>
  Math.sin(i * 0.85) * 30 + Math.sin(i * 0.31) * 16);

/** Slide 2 / Cover: die aufgezeichnete Laufspur. */
const diagramWalk = ({ labels = true } = {}) => svg(`
  ${holeBase()}
  <polyline points="${poly(WALK)}" fill="none" stroke="${C.gold}" stroke-width="2.5" opacity=".4"/>
  ${WALK.map(([x, y]) => `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="6.5" fill="${C.gold}"/>`).join("")}
  <circle cx="${TEE[0]}" cy="${TEE[1]}" r="15" fill="${C.gold}"/>
  <circle cx="${GREEN[0]}" cy="${GREEN[1]}" r="15" fill="${C.gold}"/>
  ${labels ? `
  <text x="${TEE[0] + 54}" y="${TEE[1] + 12}" fill="rgba(255,255,255,.92)" font-size="38" font-weight="700">Start</text>
  <text x="${GREEN[0] - 150}" y="${GREEN[1] - 46}" fill="rgba(255,255,255,.92)" font-size="38" font-weight="700">Ende</text>
  <text x="170" y="560" fill="${C.gold}" font-size="34" font-weight="700">alle paar Meter</text>
  <text x="170" y="604" fill="rgba(255,255,255,.55)" font-size="30">ein Punkt</text>` : ""}`);

/** Slide 3: Stillstand am Abschlag und am Grün. */
const diagramStops = () => svg(`
  ${holeBase(0.55)}
  <polyline points="${poly(WALK)}" fill="none" stroke="rgba(255,255,255,.3)" stroke-width="4"
            stroke-dasharray="14 12"/>
  ${[[TEE, "#4C9BE8"], [GREEN, "#E4574F"]].map(([[cx, cy], col]) => `
    <circle cx="${cx}" cy="${cy}" r="92" fill="${col}" opacity=".12"/>
    <circle cx="${cx}" cy="${cy}" r="60" fill="${col}" opacity=".2"/>
    <circle cx="${cx}" cy="${cy}" r="30" fill="${col}" opacity=".92"/>`).join("")}
  <text x="${TEE[0] + 118}" y="${TEE[1] - 4}" fill="#8CC4F5" font-size="36" font-weight="700">1. Stillstand</text>
  <text x="${TEE[0] + 118}" y="${TEE[1] + 42}" fill="rgba(255,255,255,.62)" font-size="31">= Abschlag</text>
  <text x="${GREEN[0] - 336}" y="${GREEN[1] - 24}" fill="#F09A94" font-size="36" font-weight="700">letzter Stillstand</text>
  <text x="${GREEN[0] - 336}" y="${GREEN[1] + 22}" fill="rgba(255,255,255,.62)" font-size="31">= Grün</text>`);

/** Slide 5: Korridor aus Median und Perzentilen entlang derselben Mittellinie. */
const diagramCorridor = () => {
  const width = (t) => 56 + Math.sin(t * Math.PI) * 30;
  const leftEdge  = offset(CENTER, (t) => -width(t));
  const rightEdge = offset(CENTER, (t) =>  width(t));
  const ticks = CENTER.map((_, i) => i).filter((i) => i % 4 === 2);
  return svg(`
  ${holeBase(0.3)}
  <line x1="${TEE[0]}" y1="${TEE[1]}" x2="${GREEN[0]}" y2="${GREEN[1]}"
        stroke="rgba(255,255,255,.4)" stroke-width="3" stroke-dasharray="12 10"/>
  <polygon points="${poly(leftEdge)} ${poly([...rightEdge].reverse())}"
           fill="${C.gold}" opacity=".26" stroke="${C.gold}" stroke-opacity=".7" stroke-width="3"/>
  ${ticks.map((i) => `<line x1="${leftEdge[i][0].toFixed(1)}" y1="${leftEdge[i][1].toFixed(1)}"
        x2="${rightEdge[i][0].toFixed(1)}" y2="${rightEdge[i][1].toFixed(1)}"
        stroke="#fff" stroke-opacity=".28" stroke-width="2"/>`).join("")}
  <polyline points="${poly(CENTER)}" fill="none" stroke="${C.gold}" stroke-width="7"
            stroke-linecap="round"/>
  <text x="170" y="430" fill="${C.gold}" font-size="34" font-weight="700">Mittellinie</text>
  <text x="170" y="474" fill="rgba(255,255,255,.55)" font-size="29">Median je 10-m-Abschnitt</text>
  <text x="170" y="792" fill="rgba(255,255,255,.85)" font-size="34" font-weight="700">Korridor</text>
  <text x="170" y="836" fill="rgba(255,255,255,.55)" font-size="29">10.–90. Perzentil</text>
  <text x="410" y="686" text-anchor="end" fill="rgba(255,255,255,.5)" font-size="28">Luftlinie</text>`);
};

// ── Slides ───────────────────────────────────────────────────────────────────

const slides = [
  {
    kind: "cover",
    kicker: "Update 2.2",
    title: "Dein Weg über<br>den Platz",
    body: "GolfTrack zeichnet auf Wunsch auf, wo du während der Runde unterwegs warst – und lernt daraus, wie die Löcher liegen.",
  },
  {
    kind: "diagram",
    n: 1,
    kicker: "Laufspur",
    title: "Die Runde wird mitgeschrieben",
    diagram: diagramWalk(),
    body: "Während der Runde speichert die App alle paar Meter deine Position. Danach siehst du deinen Weg über den Platz auf der Karte, Loch für Loch.",
  },
  {
    kind: "diagram",
    n: 2,
    kicker: "Abschlag & Grün",
    title: "Wo stehst du still?",
    diagram: diagramStops(),
    body: "Am Abschlag wartest du, am Grün puttest du – dazwischen bewegst du dich. Aus dem ersten und letzten längeren Stillstand pro Loch schätzt die App Abschlag und Grün. Danach steht die Entfernung zur Fahne von selbst da, ohne dass du den Pin setzen musst.",
  },
  {
    kind: "shot",
    n: 3,
    kicker: "Deine Entscheidung",
    title: "Freiwillig – und bleibt<br>auf deinem iPhone",
    file: "positions-tracking.png",
    body: "Standardmäßig aus. Du schaltest die Aufzeichnung selbst ein, sie läuft nur während einer Runde, die Daten werden nicht übertragen – und du kannst sie hier jederzeit löschen.",
  },
  {
    kind: "diagram",
    n: 4,
    kicker: "Fairway-Verlauf",
    title: "Wo verläuft das Fairway?",
    diagram: diagramCorridor(),
    body: "Alle Messpunkte werden auf die Achse Abschlag→Grün projiziert und in 10-m-Abschnitte geteilt. Der Median ergibt die Mittellinie, das 10.–90. Perzentil den Korridor. Doglegs kommen dabei von selbst heraus.",
    note: "Eine Schätzung, kein Platzplan – je mehr Runden, desto genauer.",
  },
  {
    kind: "cta",
    kicker: "Version 2.2",
    title: "Alles drei, ab jetzt",
    recap: [
      { t: "Laufspur", s: "Dein Weg über den Platz auf der Karte" },
      { t: "Abschlag & Grün", s: "Werden pro Loch selbst erkannt" },
      { t: "Fairway-Verlauf", s: "Geschätzter Korridor inklusive Doglegs" },
    ],
    body: `${RELEASE_LINE} Tracking bleibt freiwillig: Du schaltest es in Profil → Positions-Tracking ein, es läuft nur während einer Runde und die Daten verlassen dein iPhone nicht.`,
  },
];

// ── HTML ─────────────────────────────────────────────────────────────────────

function slideHtml(s, index, total) {
  const header = `
    <div class="header">
      <div class="badge"><img src="data:image/png;base64,${logoB64}"></div>
      <div class="wordmark"><div class="name">GolfTrack</div>
        <div class="sub">${esc(s.kicker)}</div></div>
      <div class="pager">${index + 1}/${total}</div>
    </div>`;

  let middle = "";
  if (s.kind === "diagram") {
    middle = `<div class="stage">${s.diagram}</div>`;
  } else if (s.kind === "shot") {
    const b64 = shot(s.file);
    middle = b64
      ? `<div class="stage"><div class="phone"><img src="data:image/png;base64,${b64}"></div></div>`
      : `<div class="stage"><div class="missing">Screenshot fehlt: ${esc(s.file)}</div></div>`;
  } else if (s.kind === "cover") {
    middle = `<div class="stage cover-art">${diagramWalk({ labels: false })}</div>`;
  } else {
    // Kein nachgebautes App-Store-Badge – Apple erlaubt nur das offizielle Asset.
    middle = `<div class="stage recap">
        ${(s.recap || []).map((r) => `
          <div class="recap-row">
            <div class="recap-dot"></div>
            <div><div class="recap-title">${esc(r.t)}</div>
                 <div class="recap-sub">${esc(r.s)}</div></div>
          </div>`).join("")}
      </div>`;
  }

  return `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html,body { width:${W}px; height:${H}px; }
  body {
    font-family:-apple-system,"SF Pro Display","SF Pro Text",BlinkMacSystemFont,sans-serif;
    color:#fff; -webkit-font-smoothing:antialiased;
    background:
      radial-gradient(120% 55% at 50% -10%, ${C.gold}22 0%, transparent 55%),
      radial-gradient(90% 45% at 50% 110%, ${C.green}26 0%, transparent 55%),
      linear-gradient(180deg, ${C.card} 0%, ${C.bg} 44%, ${C.bg} 100%);
  }
  .frame { position:absolute; inset:0; display:flex; flex-direction:column;
           padding:64px 72px 72px; }
  .header { display:flex; align-items:center; gap:20px; }
  .badge { width:76px; height:76px; border-radius:18px; overflow:hidden; flex:0 0 auto;
           box-shadow:0 10px 30px rgba(0,0,0,.45), inset 0 0 0 1px rgba(255,255,255,.10); }
  .badge img { width:100%; height:100%; object-fit:cover; display:block; }
  .wordmark .name { font-size:36px; font-weight:800; letter-spacing:-.3px; }
  .wordmark .sub { font-size:22px; font-weight:600; color:${C.gold}; margin-top:2px; }
  .pager { margin-left:auto; font-size:22px; font-weight:700;
           color:rgba(255,255,255,.42); letter-spacing:.5px; }

  h1 { font-size:${s.kind === "cover" ? 84 : 58}px; font-weight:800; line-height:1.06;
       letter-spacing:-1.2px; margin-top:${s.kind === "cover" ? 44 : 34}px; }
  .stage { flex:1; display:flex; align-items:center; justify-content:center;
           margin:22px 0 10px; min-height:0; }
  .stage svg { max-height:100%; }
  .cover-art { opacity:.9; }

  .phone { height:100%; aspect-ratio:1284/2778; border-radius:44px; overflow:hidden;
           border:7px solid rgba(255,255,255,.14);
           box-shadow:0 30px 70px rgba(0,0,0,.55); background:${C.bg}; }
  .phone img { width:100%; height:100%; object-fit:cover; object-position:top; display:block; }
  .missing { color:#E4574F; font-size:30px; }

  .recap { flex-direction:column; justify-content:center; gap:26px; align-items:stretch; }
  .recap-row { display:flex; align-items:flex-start; gap:22px;
               background:${C.card}; border-radius:22px; padding:30px 32px;
               box-shadow:inset 0 0 0 1px rgba(255,255,255,.05); }
  .recap-dot { width:16px; height:16px; border-radius:50%; background:${C.gold};
               margin-top:10px; flex:0 0 auto; }
  .recap-title { font-size:34px; font-weight:700; }
  .recap-sub { font-size:27px; color:rgba(255,255,255,.6); margin-top:6px; line-height:1.35; }

  .body { font-size:30px; line-height:1.42; color:rgba(255,255,255,.78); }
  .note { margin-top:14px; font-size:25px; line-height:1.4; color:${C.gold}; }
  .swipe { margin-top:18px; font-size:26px; font-weight:700; color:rgba(255,255,255,.5); }
</style></head><body><div class="frame">
  ${header}
  <h1>${s.title}</h1>
  ${middle}
  <div class="body">${esc(s.body)}</div>
  ${s.note ? `<div class="note">${esc(s.note)}</div>` : ""}
  ${s.kind === "cover" ? `<div class="swipe">Wisch für die Details →</div>` : ""}
</div></body></html>`;
}

// ── Rendern ──────────────────────────────────────────────────────────────────

const browser = await puppeteer.launch({
  args: ["--no-sandbox", "--font-render-hinting=none"],
});
const page = await browser.newPage();
await page.setViewport({ width: W, height: H, deviceScaleFactor: 1 });

for (const [i, s] of slides.entries()) {
  // networkidle0 wartet bei großen data:-URIs ins Timeout – domcontentloaded plus
  // Warten auf die Fonts reicht und ist deutlich schneller.
  await page.setContent(slideHtml(s, i, slides.length), { waitUntil: "domcontentloaded" });
  await page.evaluate(() => document.fonts.ready);
  const file = path.join(outDir, `slide-${String(i + 1).padStart(2, "0")}.png`);
  await page.screenshot({ path: file, type: "png" });
  console.log(`✓ ${path.basename(file)}  ${s.kicker}`);
}
await browser.close();
console.log(`\n${slides.length} Slides in ${outDir}`);
