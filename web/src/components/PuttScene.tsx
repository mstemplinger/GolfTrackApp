/**
 * Kleine Endlosschleife für die Wartezeit: Putter holt aus, der Ball (mit
 * Augen) rollt übers Grün, fällt ins Loch, die Fahne hüpft, und von vorn.
 * Reines SVG mit CSS-Animation – kein Skript. Bei „weniger Bewegung" steht
 * die Szene still, der Ball liegt dann vor dem Loch.
 */
export function PuttScene({ label }: { label: string }) {
  return (
    <svg viewBox="0 0 320 170" role="img" aria-label={label} className="putt mx-auto w-full max-w-[26rem]">
      <defs>
        <radialGradient id="putt-green" cx="50%" cy="35%" r="65%">
          <stop offset="0%" stopColor="#3a9d5f" />
          <stop offset="70%" stopColor="#28824b" />
          <stop offset="100%" stopColor="#1c5e36" />
        </radialGradient>
        <radialGradient id="putt-ball" cx="38%" cy="32%" r="70%">
          <stop offset="0%" stopColor="#ffffff" />
          <stop offset="75%" stopColor="#f2ede3" />
          <stop offset="100%" stopColor="#cfc6b2" />
        </radialGradient>
      </defs>

      {/* Schatten und Grün */}
      <ellipse cx="160" cy="138" rx="150" ry="26" fill="#000" opacity=".28" />
      <ellipse cx="160" cy="130" rx="150" ry="28" fill="url(#putt-green)" />
      <ellipse cx="160" cy="130" rx="150" ry="28" fill="none" stroke="#e0c583" strokeOpacity=".25" />
      {/* Mähstreifen */}
      <path d="M40 120 Q160 112 280 120" stroke="#fff" strokeOpacity=".06" strokeWidth="9" fill="none" />
      <path d="M30 136 Q160 128 290 136" stroke="#fff" strokeOpacity=".06" strokeWidth="9" fill="none" />

      {/* Loch */}
      <ellipse cx="236" cy="128" rx="13" ry="4.5" fill="#06120b" />
      <ellipse cx="236" cy="127" rx="13" ry="4.5" fill="none" stroke="#000" strokeOpacity=".4" />

      {/* Fahne */}
      <g className="putt-flag">
        <line x1="236" y1="127" x2="236" y2="34" stroke="#f2ede3" strokeWidth="2.4" strokeLinecap="round" />
        <path className="putt-cloth" d="M237 35 L272 44 L237 54 Z" fill="#c9a035" />
      </g>

      {/* Funken beim Einlochen */}
      <g className="putt-sparks" stroke="#e0c583" strokeWidth="2.2" strokeLinecap="round">
        <line x1="236" y1="112" x2="236" y2="104" />
        <line x1="222" y1="116" x2="216" y2="110" />
        <line x1="250" y1="116" x2="256" y2="110" />
        <line x1="214" y1="124" x2="206" y2="122" />
        <line x1="258" y1="124" x2="266" y2="122" />
      </g>

      {/* Ball: außen die Fahrt, innen das Rollen; die Augen rollen nicht mit. */}
      <g className="putt-ball">
        <ellipse cx="70" cy="131" rx="8" ry="2.4" fill="#000" opacity=".3" className="putt-ballshadow" />
        <g className="putt-roll">
          <circle cx="70" cy="120" r="9.5" fill="url(#putt-ball)" />
          <circle cx="66" cy="116" r="1" fill="#000" opacity=".08" />
          <circle cx="74" cy="124" r="1" fill="#000" opacity=".08" />
          <circle cx="73" cy="115" r="1" fill="#000" opacity=".08" />
          <circle cx="65" cy="124" r="1" fill="#000" opacity=".08" />
        </g>
        <g className="putt-eyes" fill="#17251c">
          <ellipse cx="72" cy="118.5" rx="1.25" ry="1.9" />
          <ellipse cx="76.5" cy="118.5" rx="1.25" ry="1.9" />
        </g>
        <path d="M71.5 122.6 Q74.2 124.6 77 122.6" stroke="#17251c" strokeWidth="1" fill="none" strokeLinecap="round" />
        <circle cx="69" cy="121.5" r="1.4" fill="#e89a8a" opacity=".55" />
      </g>

      {/* Putter */}
      <g className="putt-club">
        <line x1="38" y1="22" x2="52" y2="124" stroke="#a9bcae" strokeWidth="3" strokeLinecap="round" />
        <line x1="38" y1="22" x2="40.5" y2="42" stroke="#17251c" strokeWidth="5" strokeLinecap="round" />
        <rect x="46" y="121" width="13" height="7" rx="2" fill="#c9a035" />
      </g>
    </svg>
  );
}
