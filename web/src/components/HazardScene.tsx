/**
 * Endlosschleife für die 404-Seite: ein ganzes Loch, schräg von vorn oben
 * gesehen – Abschlag vorn links, Grün mit Fahne hinten rechts. Der Golfer
 * schlägt ab, der Ball landet im Bunker; er läuft hin, schlägt weiter, und der
 * Ball fällt vor dem Grün ins Wasser. Reines SVG mit CSS-Animation
 * (globals.css, `.hazard`) – kein Skript. Bei „weniger Bewegung" steht die
 * Szene still: Golfer und Ball im Bunker.
 *
 * Der Boden ist im Grundriss gezeichnet und als Ganzes auf die halbe Höhe
 * gestaucht – so werden Kreise von selbst zu Ellipsen und das Fairway wird
 * dort schmaler, wo es quer zum Blick läuft. Alles, was steht oder fliegt
 * (Golfer, Fahne, Bäume, Ball), liegt ungestaucht darüber. Umrechnung:
 * Bildschirm-y = 40 + Grundriss-y / 2.
 *
 * Der Ballflug besteht aus zwei Gruppen: `hazard-ballpos` fährt den Punkt am
 * Boden gleichmäßig von A nach B (dort liegt auch der Schatten),
 * `hazard-ballup` hebt den Ball darüber an. Das ergibt in dieser Ansicht eine
 * echte Wurfparabel.
 */

/** Umriss der Scholle im Grundriss. */
const ISLAND =
  "M22 236 C8 320 70 384 168 384 C262 384 338 368 348 260 C356 168 352 60 300 24 C246 -12 150 20 98 80 C58 124 32 176 22 236 Z";

/** Baum: Schatten, Stamm, Krone. (x, y) ist der Fußpunkt am Boden. */
function Tree({ x, y, r = 9.5 }: { x: number; y: number; r?: number }) {
  return (
    <g>
      <ellipse cx={x + r * 0.45} cy={y + 1} rx={r} ry={r * 0.38} fill="#000" opacity=".22" />
      <line x1={x} y1={y} x2={x} y2={y - r * 0.6} stroke="#5d4521" strokeWidth="2" strokeLinecap="round" />
      <circle cx={x} cy={y - r * 1.15} r={r} fill="#124325" />
      <circle cx={x - r * 0.1} cy={y - r * 1.3} r={r * 0.84} fill="#25733f" />
      <circle cx={x - r * 0.32} cy={y - r * 1.55} r={r * 0.38} fill="#329152" />
    </g>
  );
}

export function HazardScene({ label }: { label: string }) {
  return (
    <svg viewBox="0 36 360 220" role="img" aria-label={label} className="hazard mx-auto w-full overflow-visible">
      <defs>
        <radialGradient id="hazard-rough" cx="55%" cy="45%" r="70%">
          <stop offset="0%" stopColor="#216c3e" />
          <stop offset="100%" stopColor="#17512e" />
        </radialGradient>
        <radialGradient id="hazard-sand" cx="50%" cy="60%" r="60%">
          <stop offset="0%" stopColor="#f1e4bd" />
          <stop offset="100%" stopColor="#d9c07f" />
        </radialGradient>
        <radialGradient id="hazard-water" cx="45%" cy="65%" r="65%">
          <stop offset="0%" stopColor="#4a9fb4" />
          <stop offset="100%" stopColor="#1c5f78" />
        </radialGradient>
      </defs>

      {/* Schatten unter der Scholle */}
      <ellipse cx="182" cy="238" rx="164" ry="15" fill="#000" opacity=".3" />

      {/* Boden – Grundriss, auf die halbe Höhe gestaucht */}
      <g transform="translate(0 40) scale(1 0.5)">
        <path d={ISLAND} transform="translate(0 20)" fill="#0b2f1c" />
        <path d={ISLAND} fill="url(#hazard-rough)" />
        <path d={ISLAND} fill="none" stroke="#e0c583" strokeOpacity=".22" vectorEffect="non-scaling-stroke" />

        {/* Fairway mit Vorgrün-Rand: vom Abschlag im Bogen zum Grün */}
        <g fill="none" strokeLinecap="round">
          <path d="M94 304 C136 318 172 310 194 256 C214 204 224 128 288 108" stroke="#1f6e3f" strokeWidth="60" />
          <path d="M94 304 C136 318 172 310 194 256 C214 204 224 128 288 108" stroke="#2b8a4f" strokeWidth="46" />
        </g>

        {/* Abschlag */}
        <circle cx="74" cy="300" r="27" fill="#1f6e3f" />
        <circle cx="74" cy="300" r="23" fill="#3a9d5f" />

        {/* Grün und Loch */}
        <circle cx="298" cy="100" r="41" fill="#2f9456" />
        <circle cx="298" cy="100" r="34" fill="#48b06d" />
        <circle cx="306" cy="96" r="4.6" fill="#06120b" />

        {/* Bunker: Kante, Sand, Schatten unter der hinteren Kante */}
        <circle cx="214" cy="320" r="33" fill="#164a2b" />
        <circle cx="214" cy="322" r="30" fill="url(#hazard-sand)" />
        <path d="M184 322 A30 30 0 0 1 244 322 A30 21 0 0 0 184 322 Z" fill="#6f5718" opacity=".3" />

        {/* Teich: Ufer, Wasser, Schatten unter dem hinteren Ufer */}
        <circle cx="270" cy="206" r="36" fill="#134426" />
        <circle cx="270" cy="208" r="33" fill="url(#hazard-water)" />
        <path d="M237 208 A33 33 0 0 1 303 208 A33 23 0 0 0 237 208 Z" fill="#082b3a" opacity=".38" />

        {/* Ringe auf dem Wasser */}
        <g fill="none" stroke="#d7eef3" strokeWidth="1.2">
          <circle className="hazard-ripple" cx="268" cy="212" r="7" />
          <circle className="hazard-ripple hazard-late" cx="268" cy="212" r="7" />
        </g>
      </g>

      {/* Lichtreflexe auf dem Teich */}
      <g className="hazard-glint" stroke="#fff" strokeOpacity=".3" strokeWidth="1.3" strokeLinecap="round">
        <line x1="250" y1="151" x2="259" y2="151" />
        <line x1="279" y1="153.5" x2="286" y2="153.5" />
        <line x1="284" y1="142" x2="291" y2="142" />
      </g>

      {/* Abschlagmarken */}
      <circle cx="83" cy="183.5" r="1.7" fill="#c9a035" />
      <circle cx="83" cy="197" r="1.7" fill="#c9a035" />

      {/* Bäume hinten */}
      <Tree x={150} y={90} r={9} />
      <Tree x={182} y={78} r={8} />
      <Tree x={118} y={112} />
      <Tree x={216} y={70} r={8.5} />
      <Tree x={88} y={138} r={10.5} />
      <Tree x={54} y={156} r={9} />
      <Tree x={330} y={150} r={8.5} />

      {/* Fahne */}
      <line x1="306" y1="88" x2="306" y2="58" stroke="#f2ede3" strokeWidth="1.8" strokeLinecap="round" />
      <path className="hazard-cloth" d="M306.8 58.6 L321 63.4 L306.8 68.4 Z" fill="#c9a035" />

      {/* Golfer – Fußpunkt bei (0, 0), die äußere Gruppe trägt ihn über den Platz */}
      <g className="hazard-golfer">
        <ellipse cx="1.5" cy="0.6" rx="7.5" ry="2.6" fill="#000" opacity=".28" />
        <g className="hazard-bob">
          <g className="hazard-legs-stand" stroke="#101c15" strokeWidth="2.8" strokeLinecap="round">
            <line x1="-1.7" y1="-10" x2="-2.8" y2="-0.6" />
            <line x1="1.7" y1="-10" x2="2.8" y2="-0.6" />
          </g>
          <g className="hazard-legs-walk" stroke="#101c15" strokeWidth="2.8" strokeLinecap="round">
            <line className="hazard-leg" x1="0" y1="-10" x2="0" y2="-0.6" />
            <line className="hazard-leg hazard-leg-b" x1="0" y1="-10" x2="0" y2="-0.6" />
          </g>
          {/* Oberkörper knickt in der Hüfte ein, wenn der Ball im Wasser ist */}
          <g className="hazard-upper">
            {/* Unsichtbares Quadrat um die Hüfte (0, −10): hält die Mitte der Gruppe dort, auch wenn der Schläger dreht. */}
            <rect x="-44" y="-54" width="88" height="88" fill="none" />
            <line x1="0" y1="-19" x2="0" y2="-11" stroke="#f2ede3" strokeWidth="6.4" strokeLinecap="round" />
            <circle cx="0" cy="-25.4" r="3.8" fill="#e9b995" />
            <path d="M-4 -26 A4 4 0 0 1 4 -26 Z" fill="#c9a035" />
            <line x1="3.4" y1="-26.1" x2="6.8" y2="-25.7" stroke="#c9a035" strokeWidth="1.6" strokeLinecap="round" />
            {/*
              Arme und Schläger drehen um die Schulter (0, −18,5). Das
              unsichtbare Quadrat ist um genau diesen Punkt gelegt, damit die
              Mitte der Gruppe der Drehpunkt ist – egal, wie der Schläger
              gezeichnet ist.
            */}
            <g className="hazard-swing">
              <rect x="-24" y="-42.5" width="48" height="48" fill="none" />
              <line x1="8.4" y1="-1.6" x2="3" y2="-10.6" stroke="#d5ddd7" strokeWidth="1.3" strokeLinecap="round" />
              <line x1="8.4" y1="-1.6" x2="10.4" y2="-1" stroke="#e0c583" strokeWidth="2.6" strokeLinecap="round" />
              <line x1="0" y1="-18.5" x2="3" y2="-10.6" stroke="#ded6c4" strokeWidth="2.6" strokeLinecap="round" />
              <circle cx="3" cy="-10.6" r="1.5" fill="#e9b995" />
            </g>
          </g>
          {/* Schreckstriche über dem Kopf */}
          <g className="hazard-emote" stroke="#e0c583" strokeWidth="1.4" strokeLinecap="round">
            <line x1="-4.5" y1="-32.5" x2="-6.8" y2="-35.8" />
            <line x1="0" y1="-33.5" x2="0" y2="-37.6" />
            <line x1="4.5" y1="-32.5" x2="6.8" y2="-35.8" />
          </g>
        </g>
      </g>

      {/* Ball: außen der Weg am Boden samt Schatten, innen die Flughöhe */}
      <g className="hazard-ballpos">
        <ellipse className="hazard-ballshadow" cx="0.6" cy="2.6" rx="3" ry="1.2" fill="#000" />
        <g className="hazard-ballup">
          <circle r="2.8" fill="#fffdf6" stroke="#cfc6b2" strokeWidth=".5" />
        </g>
      </g>

      {/* Sand spritzt: klein bei der Landung, groß beim Schlag aus dem Bunker */}
      <g className="hazard-sand" fill="#ecdcae">
        <rect x="194" y="174" width="52" height="52" fill="none" />
        <circle cx="212" cy="194" r="1.4" />
        <circle cx="216" cy="187" r="1.6" />
        <circle cx="222" cy="182" r="1.2" />
        <circle cx="228" cy="179" r="1.6" />
        <circle cx="234" cy="182" r="1.2" />
        <circle cx="239" cy="188" r="1.6" />
        <circle cx="242" cy="195" r="1.3" />
        <circle cx="225" cy="190" r="1.1" fill="#d9c07f" />
        <circle cx="232" cy="191" r="1.1" fill="#d9c07f" />
        <circle cx="219" cy="195" r="1" fill="#d9c07f" />
      </g>

      {/* Wasser spritzt */}
      <g className="hazard-splash">
        <rect x="244" y="122" width="48" height="48" fill="none" />
        <g fill="none" stroke="#d7eef3" strokeWidth="1.8" strokeLinecap="round">
          <path d="M264 146 Q262 136 257 132" />
          <path d="M272 146 Q274 136 279 132" />
          <path d="M268 146 L268 129" />
        </g>
        <g fill="#d7eef3">
          <circle cx="255" cy="128" r="1.5" />
          <circle cx="262" cy="125" r="1.2" />
          <circle cx="268" cy="124.5" r="1.6" />
          <circle cx="274" cy="125" r="1.2" />
          <circle cx="281" cy="128" r="1.5" />
        </g>
      </g>

      {/* Bäume vorn */}
      <Tree x={128} y={222} r={9} />
      <Tree x={292} y={212} r={9.5} />
    </svg>
  );
}
