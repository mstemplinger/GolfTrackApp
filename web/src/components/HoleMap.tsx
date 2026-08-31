/**
 * Ein Loch von oben: Fairway, Laufspur und die vier Schläge dorthin.
 * Reines SVG – illustriert das Positions-Tracking ohne Screenshot.
 */
export function HoleMap({ label }: { label: string }) {
  const shots = [
    { x: 62, y: 236, r: 5 },
    { x: 96, y: 152, r: 4.5 },
    { x: 150, y: 96, r: 4 },
    { x: 186, y: 60, r: 3.5 },
  ];

  return (
    <svg
      viewBox="0 0 260 280"
      role="img"
      aria-label={label}
      className="h-auto w-full max-w-sm"
    >
      <defs>
        <linearGradient id="fairway" x1="0" y1="1" x2="1" y2="0">
          <stop offset="0%" stopColor="#28824b" stopOpacity="0.36" />
          <stop offset="100%" stopColor="#28824b" stopOpacity="0.14" />
        </linearGradient>
        <radialGradient id="green" cx="50%" cy="50%">
          <stop offset="0%" stopColor="#3da566" stopOpacity="0.65" />
          <stop offset="100%" stopColor="#3da566" stopOpacity="0.2" />
        </radialGradient>
      </defs>

      {/* Fairway mit Dogleg nach rechts */}
      <path
        d="M40 268 C 36 200, 62 150, 112 116 C 152 88, 186 74, 214 56 L 236 76 C 206 100, 168 116, 132 142 C 92 172, 70 214, 74 268 Z"
        fill="url(#fairway)"
        stroke="#28824b"
        strokeOpacity="0.35"
        strokeWidth="1"
      />

      {/* Grün */}
      <ellipse cx="222" cy="60" rx="30" ry="24" fill="url(#green)" stroke="#3da566" strokeOpacity="0.5" />

      {/* Bunker */}
      <ellipse cx="176" cy="98" rx="17" ry="11" fill="#c9a035" opacity="0.28" transform="rotate(-24 176 98)" />

      {/* Laufspur */}
      <path
        d="M60 240 C 74 206, 88 178, 100 156 C 118 126, 142 106, 158 94 C 176 80, 196 68, 216 60"
        fill="none"
        stroke="#e0c583"
        strokeOpacity="0.75"
        strokeWidth="1.6"
        strokeDasharray="1 5"
        strokeLinecap="round"
      />

      {/* Schlagpunkte */}
      {shots.map((shot, index) => (
        <g key={index}>
          <circle cx={shot.x} cy={shot.y} r={shot.r + 4} fill="#c9a035" opacity="0.12" />
          <circle cx={shot.x} cy={shot.y} r={shot.r} fill="#f2ede3" opacity="0.92" />
        </g>
      ))}

      {/* Abschlagsmarkierung */}
      <rect x="52" y="256" width="18" height="6" rx="3" fill="#f2ede3" opacity="0.5" />

      {/* Fahne */}
      <g>
        <line x1="222" y1="60" x2="222" y2="30" stroke="#f2ede3" strokeWidth="1.4" />
        <path d="M222 31 L238 37 L222 43 Z" fill="#c9a035" />
        <circle cx="222" cy="60" r="3" fill="#08180f" />
      </g>
    </svg>
  );
}
