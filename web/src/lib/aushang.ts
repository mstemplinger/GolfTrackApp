import "server-only";

/**
 * Der Aushang für Gäste: wie GolfTrack geht, in den Sprachen, die der
 * Betreiber auswählt, plus QR-Code. Ergebnis ist ein HTML-Dokument mit festen
 * Seitenmaßen, aus dem `app/qr/[slug]/aushang` ein PDF druckt.
 *
 * Aufteilung:
 * - eine Sprache: A4 hochkant, eine Seite;
 * - zwei oder drei: A4 quer, Sprachen untereinander neben dem Code;
 * - mehr: so viele Querblätter wie nötig, gleichmäßig verteilt (4 → 2+2,
 *   5 → 3+2, 7 → 3+2+2). Jedes Blatt trägt den Code, damit jedes für sich
 *   aufgehängt werden kann.
 */

export const SPRACHEN = ["de", "en", "it", "fr", "es", "pl", "cz"] as const;
export type Sprache = (typeof SPRACHEN)[number];

/** Höchstens so viele Sprachen passen lesbar auf ein Querblatt. */
const PRO_BLATT = 3;

type Art = "minigolf" | "golf";

interface Texte {
  code: string;
  titel: string;
  schritte: (art: Art) => [string, string, string];
  scannen: string;
  untertitel: string;
  gratis: string;
  fuss: string;
  bahnen: (art: Art) => string;
}

const TEXTE: Record<Sprache, Texte> = {
  de: {
    code: "DE",
    titel: "So funktioniert GolfTrack",
    schritte: (art) => [
      "QR-Code mit der Kamera scannen.",
      "GolfTrack öffnen: auf dem iPhone ohne Installation, auf Android im Browser.",
      `Spieler eintragen und Schläge ${art === "golf" ? "Loch für Loch" : "Bahn für Bahn"} antippen. Die Rangliste rechnet sich selbst.`,
    ],
    scannen: "Scannen",
    untertitel: "Digitale Zählkarte",
    gratis: "KOSTENLOS",
    fuss: "Kein Zettel, kein Bleistift",
    bahnen: (art) => (art === "golf" ? "Löcher" : "Bahnen"),
  },
  en: {
    code: "EN",
    titel: "How GolfTrack works",
    schritte: () => [
      "Point your camera at the QR code.",
      "Open GolfTrack: no install needed on iPhone, in the browser on Android.",
      "Add the players and tap in your strokes hole by hole. The leaderboard adds itself up.",
    ],
    scannen: "Scan",
    untertitel: "Digital scorecard",
    gratis: "FREE",
    fuss: "No paper, no pencil",
    bahnen: () => "holes",
  },
  it: {
    code: "IT",
    titel: "Come funziona GolfTrack",
    schritte: () => [
      "Inquadra il codice QR con la fotocamera.",
      "Apri GolfTrack: su iPhone senza installare nulla, su Android nel browser.",
      "Inserisci i giocatori e segna i colpi buca per buca. La classifica si calcola da sola.",
    ],
    scannen: "Scansiona",
    untertitel: "Scorecard digitale",
    gratis: "GRATIS",
    fuss: "Niente carta, niente matita",
    bahnen: () => "buche",
  },
  fr: {
    code: "FR",
    titel: "Comment fonctionne GolfTrack",
    schritte: () => [
      "Scannez le code QR avec l’appareil photo.",
      "Ouvrez GolfTrack : sans installation sur iPhone, dans le navigateur sur Android.",
      "Ajoutez les joueurs et notez les coups trou par trou. Le classement se calcule tout seul.",
    ],
    scannen: "Scanner",
    untertitel: "Carte de score numérique",
    gratis: "GRATUIT",
    fuss: "Ni papier, ni crayon",
    bahnen: () => "trous",
  },
  es: {
    code: "ES",
    titel: "Cómo funciona GolfTrack",
    schritte: () => [
      "Escanea el código QR con la cámara.",
      "Abre GolfTrack: sin instalar nada en iPhone, en el navegador en Android.",
      "Añade a los jugadores y anota los golpes hoyo a hoyo. La clasificación se calcula sola.",
    ],
    scannen: "Escanear",
    untertitel: "Tarjeta de puntuación digital",
    gratis: "GRATIS",
    fuss: "Sin papel, sin lápiz",
    bahnen: () => "hoyos",
  },
  pl: {
    code: "PL",
    titel: "Jak działa GolfTrack",
    schritte: (art) => [
      "Zeskanuj kod QR aparatem.",
      "Otwórz GolfTrack: na iPhonie bez instalacji, na Androidzie w przeglądarce.",
      `Dodaj graczy i wpisuj uderzenia ${art === "golf" ? "dołek po dołku" : "tor po torze"}. Ranking liczy się sam.`,
    ],
    scannen: "Zeskanuj",
    untertitel: "Cyfrowa karta wyników",
    gratis: "ZA DARMO",
    fuss: "Bez kartki, bez ołówka",
    bahnen: (art) => (art === "golf" ? "dołków" : "torów"),
  },
  cz: {
    code: "CZ",
    titel: "Jak funguje GolfTrack",
    schritte: (art) => [
      "Naskenujte QR kód fotoaparátem.",
      "Otevřete GolfTrack: na iPhonu bez instalace, na Androidu v prohlížeči.",
      `Přidejte hráče a zapisujte údery ${art === "golf" ? "jamku po jamce" : "dráhu po dráze"}. Pořadí se spočítá samo.`,
    ],
    scannen: "Naskenujte",
    untertitel: "Digitální skórkarta",
    gratis: "ZDARMA",
    fuss: "Bez papíru, bez tužky",
    bahnen: (art) => (art === "golf" ? "jamek" : "drah"),
  },
};

/** Liest die gewählten Sprachen aus der Adresse, in fester Reihenfolge des Formulars. */
export function spracheAusListe(werte: string[]): Sprache[] {
  const gewaehlt = new Set(
    werte.flatMap((wert) => wert.split(",")).map((wert) => wert.trim().toLowerCase()),
  );
  // „cs“ ist der ISO-Code, „cz“ das, was auf dem Blatt steht – beides gilt.
  if (gewaehlt.has("cs")) gewaehlt.add("cz");
  return SPRACHEN.filter((sprache) => gewaehlt.has(sprache));
}

/** Vorauswahl: Landessprache der Anlage, dazu Deutsch und Englisch. */
export function vorauswahl(land: string): Sprache[] {
  const landessprache: Record<string, Sprache> = {
    DE: "de", AT: "de", CH: "de", IT: "it", FR: "fr", ES: "es", PL: "pl", CZ: "cz",
    GB: "en", IE: "en", US: "en",
  };
  const erste = landessprache[land.toUpperCase()];
  return spracheAusListe([erste, "de", "en"].filter(Boolean) as string[]).sort((a, b) =>
    a === erste ? -1 : b === erste ? 1 : 0,
  );
}

/** Verteilt n Sprachen gleichmäßig auf so wenige Blätter wie möglich. */
export function blaetter(sprachen: Sprache[]): Sprache[][] {
  const anzahl = Math.max(1, Math.ceil(sprachen.length / PRO_BLATT));
  const basis = Math.floor(sprachen.length / anzahl);
  const rest = sprachen.length % anzahl;
  const ergebnis: Sprache[][] = [];
  let start = 0;
  for (let i = 0; i < anzahl; i += 1) {
    const groesse = basis + (i < rest ? 1 : 0);
    ergebnis.push(sprachen.slice(start, start + groesse));
    start += groesse;
  }
  return ergebnis;
}

/* ── Flaggen ─────────────────────────────────────────────────────────── */

// Als SVG, nicht als Emoji: Emoji-Flaggen rendert Chromium im PDF nicht
// zuverlässig.
function flagge(sprache: Sprache): string {
  const streifenQuer = (farben: string[]) =>
    farben
      .map((farbe, i) => `<rect y="${(i * 20) / farben.length}" width="30" height="${20 / farben.length + 0.1}" fill="${farbe}"/>`)
      .join("");
  const streifenHoch = (farben: string[]) =>
    farben.map((farbe, i) => `<rect x="${i * 10}" width="10.1" height="20" fill="${farbe}"/>`).join("");

  const inhalt: Record<Sprache, string> = {
    de: streifenQuer(["#000000", "#DD0000", "#FFCE00"]),
    it: streifenHoch(["#009246", "#FFFFFF", "#CE2B37"]),
    fr: streifenHoch(["#0055A4", "#FFFFFF", "#EF4135"]),
    es: `<rect width="30" height="20" fill="#AA151B"/><rect y="5" width="30" height="10" fill="#F1BF00"/>`,
    pl: streifenQuer(["#FFFFFF", "#DC143C"]),
    cz: `${streifenQuer(["#FFFFFF", "#D7141A"])}<path d="M0 0L15 10L0 20Z" fill="#11457E"/>`,
    en: `<rect width="30" height="20" fill="#012169"/>
      <path d="M0 0L30 20M30 0L0 20" stroke="#fff" stroke-width="4"/>
      <path d="M0 0L30 20M30 0L0 20" stroke="#C8102E" stroke-width="1.4"/>
      <path d="M15 0V20M0 10H30" stroke="#fff" stroke-width="6"/>
      <path d="M15 0V20M0 10H30" stroke="#C8102E" stroke-width="3.4"/>`,
  };
  return `<svg class="flag" viewBox="0 0 30 20" preserveAspectRatio="none">${inhalt[sprache]}</svg>`;
}

/* ── Dokument ────────────────────────────────────────────────────────── */

function esc(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

const FARBE = { bg: "#0E2718", card: "#163421", cardAlt: "#1C4129", gold: "#C9A035", dunkel: "#10220D" };

export interface AushangDaten {
  name: string;
  ort: string;
  bahnen: number;
  art: Art;
  link: string;
  qrDataUrl: string;
  logoDataUrl: string | null;
  sprachen: Sprache[];
  /** Druckknopf oben einblenden – nur für die HTML-Ausweichfassung. */
  druckknopf?: boolean;
}

export function aushangHtml(daten: AushangDaten): string {
  const hoch = daten.sprachen.length === 1;
  const seiten = blaetter(daten.sprachen);
  const linkKurz = daten.link.replace(/^https:\/\//, "");
  const [breite, hoehe] = hoch ? [210, 297] : [297, 210];

  const kopf = (texte: Texte[]) => {
    const meta = [daten.ort, daten.bahnen ? `${daten.bahnen} ${texte.map((t) => t.bahnen(daten.art)).filter((w, i, a) => a.indexOf(w) === i).join(" · ")}` : ""]
      .filter(Boolean)
      .join("  ·  ");
    return `
    <div class="header">
      <div class="badge-icon">${daten.logoDataUrl ? `<img src="${daten.logoDataUrl}">` : ""}</div>
      <div class="wordmark">
        <div class="name">GolfTrack</div>
        <div class="sub">${texte.map((t) => esc(t.untertitel)).join(" · ")}</div>
      </div>
      <div class="course">
        <div class="c-name">${esc(daten.name)}</div>
        ${meta ? `<div class="c-meta">${esc(meta)}</div>` : ""}
      </div>
    </div>`;
  };

  const karte = (sprache: Sprache) => {
    const t = TEXTE[sprache];
    return `
      <section class="lang">
        <div class="lang-head">${flagge(sprache)}<span class="lang-code">${t.code}</span><span class="lang-title">${esc(t.titel)}</span></div>
        <ol class="steps">
          ${t.schritte(daten.art).map((s, i) => `<li><span class="num">${i + 1}</span><span class="txt">${esc(s)}</span></li>`).join("")}
        </ol>
      </section>`;
  };

  const qrKarte = (texte: Texte[]) => `
      <div class="right">
        <div class="scan">${texte.map((t) => esc(t.scannen)).join('<span class="sep">·</span>')}</div>
        <div class="qr"><img src="${daten.qrDataUrl}"></div>
        <div class="free">${[...new Set(texte.map((t) => t.gratis))].map(esc).join(" · ")}</div>
        <div class="link">${esc(linkKurz)}</div>
      </div>`;

  const seite = (sprachen: Sprache[]) => {
    const texte = sprachen.map((s) => TEXTE[s]);
    return `
  <div class="page${sprachen.length === 2 ? " zwei" : ""}">
    <div class="frame">
      ${kopf(texte)}
      <div class="rule"></div>
      <div class="main">
        <div class="left">${sprachen.map(karte).join("")}</div>
        ${qrKarte(texte)}
      </div>
      <div class="footer">
        <span>${texte.map((t) => esc(t.fuss)).join(" · ")}</span>
        <span>golftrack.app</span>
      </div>
    </div>
  </div>`;
  };

  return `<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(daten.name)} · GolfTrack-Aushang</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  @page { size: ${breite}mm ${hoehe}mm; margin: 0; }
  html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  body {
    font-family: -apple-system, "SF Pro Text", "Helvetica Neue", "Liberation Sans", "DejaVu Sans", Arial, sans-serif;
    color:#fff; -webkit-font-smoothing:antialiased; background:#555;
  }
  .page {
    position:relative; width:${breite}mm; height:${hoehe}mm; overflow:hidden;
    break-after: page; page-break-after: always;
    /* Deckender Verlauf ohne Transparenz-Layer – sonst Banding im PDF. */
    background:linear-gradient(135deg, #1A3A26 0%, ${FARBE.bg} 50%, #0A1E12 100%);
  }
  .page:last-child { break-after: auto; page-break-after: auto; }
  .frame { position:absolute; inset:0; display:flex; flex-direction:column; padding:11mm 13mm 9mm; }

  .header { display:flex; align-items:center; gap:4.5mm; }
  .badge-icon { width:17mm; height:17mm; border-radius:4.2mm; overflow:hidden; flex:0 0 auto; }
  .badge-icon img { width:100%; height:100%; object-fit:cover; display:block; }
  .wordmark .name { font-size:10mm; font-weight:800; letter-spacing:-.35mm; line-height:1; }
  .wordmark .sub { font-size:3.9mm; font-weight:600; color:rgba(255,255,255,.6); margin-top:1.2mm; }
  .course { margin-left:auto; text-align:right; }
  .course .c-name { font-size:8.4mm; font-weight:800; letter-spacing:-.3mm; line-height:1.05; color:${FARBE.gold}; }
  .course .c-meta { font-size:3.8mm; font-weight:600; color:rgba(255,255,255,.66); margin-top:1.4mm; }

  .rule { height:.35mm; background:rgba(255,255,255,.12); margin:5mm 0; }

  .main { flex:1 1 auto; display:flex; gap:9mm; min-height:0; }
  .left { flex:1 1 0; display:flex; flex-direction:column; gap:4mm; }
  .lang { flex:1 1 0; display:flex; flex-direction:column; justify-content:center;
    background:${FARBE.card}; border-radius:4.6mm; padding:3.6mm 5mm 3.8mm;
    box-shadow:inset 0 0 0 .3mm rgba(255,255,255,.08); }
  .lang-head { display:flex; align-items:center; gap:2.6mm; }
  .flag { width:7.2mm; height:4.8mm; border-radius:.8mm; flex:0 0 auto; display:block;
    box-shadow:0 0 0 .25mm rgba(255,255,255,.35); }
  .lang-code { font-size:3.3mm; font-weight:800; letter-spacing:.4mm; color:${FARBE.gold}; }
  .lang-title { font-size:6mm; font-weight:800; letter-spacing:-.15mm; }
  .steps { list-style:none; margin-top:3.2mm; display:flex; gap:3.6mm; }
  .steps li { flex:1 1 0; display:flex; gap:2.2mm; align-items:flex-start; }
  .num { flex:0 0 auto; width:6.2mm; height:6.2mm; border-radius:50%; background:${FARBE.gold}; color:${FARBE.dunkel};
    font-size:3.4mm; font-weight:800; display:flex; align-items:center; justify-content:center; margin-top:.2mm; }
  .txt { font-size:4.15mm; font-weight:500; line-height:1.32; color:rgba(255,255,255,.9); }

  .right { flex:0 0 98mm; display:flex; flex-direction:column; align-items:center; justify-content:center;
    background:${FARBE.cardAlt}; border-radius:6mm; padding:6mm 7mm;
    box-shadow:inset 0 0 0 .5mm ${FARBE.gold}88; }
  .scan { font-size:6.4mm; font-weight:800; letter-spacing:-.2mm; text-align:center; line-height:1.15; }
  .scan .sep { color:${FARBE.gold}; font-weight:700; padding:0 1.2mm; }
  .qr { margin-top:4.6mm; width:76mm; height:76mm; background:#fff; border-radius:4mm; padding:3.2mm; }
  .qr img { width:100%; height:100%; display:block; image-rendering:pixelated; }
  .free { margin-top:4.6mm; background:${FARBE.gold}; color:${FARBE.dunkel}; padding:1.8mm 4.4mm;
    border-radius:100px; font-size:3.6mm; font-weight:800; letter-spacing:.25mm; text-align:center; }
  .link { margin-top:3mm; font-size:3.4mm; font-weight:600; color:rgba(255,255,255,.62); }
  .footer { margin-top:4.5mm; display:flex; justify-content:space-between; font-size:3.2mm; font-weight:500;
    color:rgba(255,255,255,.5); }

  /* Zwei Sprachen auf einem Querblatt: mehr Platz, größere Schrift. */
  .zwei .lang { padding:5mm 6mm; }
  .zwei .lang-title { font-size:7.2mm; }
  .zwei .steps { margin-top:4.5mm; gap:5mm; }
  .zwei .num { width:7.4mm; height:7.4mm; font-size:4mm; }
  .zwei .txt { font-size:5.1mm; }

  /* Hochformat mit einer Sprache: alles untereinander, der Code groß. */
  .hoch .header { flex-wrap:wrap; }
  .hoch .course { margin-left:0; text-align:left; flex:1 0 100%; margin-top:7mm; }
  .hoch .course .c-name { font-size:11mm; }
  .hoch .main { flex-direction:column; gap:7mm; }
  .hoch .left { flex:0 0 auto; }
  .hoch .lang { padding:6mm 7mm; }
  .hoch .lang-title { font-size:7mm; }
  .hoch .steps { flex-direction:column; gap:3.4mm; margin-top:5mm; }
  .hoch .txt { font-size:4.8mm; }
  .hoch .right { flex:1 1 auto; }
  .hoch .scan { font-size:8mm; }
  .hoch .qr { width:96mm; height:96mm; }

  .druck { position:fixed; top:12px; right:12px; z-index:9; font:600 15px/1 -apple-system, sans-serif;
    background:${FARBE.gold}; color:${FARBE.dunkel}; border:0; border-radius:999px; padding:12px 20px; cursor:pointer; }
  @media screen { .page { margin:16px auto; box-shadow:0 4px 24px rgba(0,0,0,.4); } }
  @media print { .druck { display:none; } body { background:none; } }
</style></head><body class="${hoch ? "hoch" : "quer"}">
${daten.druckknopf ? `<button class="druck" onclick="window.print()">Als PDF speichern</button>` : ""}
${seiten.map(seite).join("")}
</body></html>`;
}
