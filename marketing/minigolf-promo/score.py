#!/usr/bin/env python3
"""
GolfTrack · Minigolf-Werbefilm — Tonspur.

Komplett synthetisiert (numpy/scipy), damit keine Lizenzfrage entsteht und
jedes Ereignis exakt auf dem Bildschnitt sitzt. Die Zeiten unten sind aus
engine.js abgelesen, nicht geschaetzt.

    python3 score.py [out.wav]

Aufbau
  Bed      – Akkordflaeche, wechselt mit dem Farbbogen des Films
             Am (Papier, warm/dumpf) -> F (Marke) -> C (Bedienung) -> G (System) -> Am (Finale)
  Puls     – Achtel ab dem Marken-Snap, faellt im Finale weg
  Impacts  – auf jedem harten Schnitt
  Ticks    – Tippgeraeusche synchron zu den getippten Zeichen
  Snap     – heller Transient auf dem Wortmarken-Snap (5,22 s)
  Riser    – vor den beiden grossen Schnitten
"""
import sys
import wave

import numpy as np
from scipy import ndimage, signal

SR = 48_000
DUR = 20.0
N = int(SR * DUR)
T = np.arange(N) / SR

rng = np.random.default_rng(7)          # fest, damit der Render reproduzierbar ist

L = np.zeros(N)
R = np.zeros(N)


# ── Helfer ────────────────────────────────────────────────────────────────
def idx(t):
    return int(round(t * SR))


def add(buf_l, buf_r, t0, sig, pan=0.0, gain=1.0):
    """Signal ab t0 einmischen. pan -1 = links, +1 = rechts."""
    i = idx(t0)
    if i >= N:
        return
    s = sig[: N - i]
    gl = gain * np.sqrt(0.5 * (1.0 - pan))
    gr = gain * np.sqrt(0.5 * (1.0 + pan))
    buf_l[i : i + len(s)] += s * gl
    buf_r[i : i + len(s)] += s * gr


def env(n, a, d, s_lvl, r, sustain_n=None):
    """ADSR ueber n Samples (a/d/r in Sekunden)."""
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    if sustain_n is None:
        sustain_n = max(0, n - a_n - d_n - r_n)
    parts = [
        np.linspace(0, 1, max(1, a_n)),
        np.linspace(1, s_lvl, max(1, d_n)),
        np.full(max(0, sustain_n), s_lvl),
        np.linspace(s_lvl, 0, max(1, r_n)),
    ]
    e = np.concatenate(parts)
    return np.resize(e, n) if len(e) < n else e[:n]


def lp(x, f, order=2):
    b, a = signal.butter(order, min(0.99, f / (SR / 2)), btype="low")
    return signal.lfilter(b, a, x)


def hp(x, f, order=2):
    b, a = signal.butter(order, min(0.99, f / (SR / 2)), btype="high")
    return signal.lfilter(b, a, x)


def bp(x, f1, f2, order=2):
    b, a = signal.butter(order, [max(1e-4, f1 / (SR / 2)), min(0.99, f2 / (SR / 2))], btype="band")
    return signal.lfilter(b, a, x)


def noise(dur):
    return rng.standard_normal(int(dur * SR))


# ── Bausteine ─────────────────────────────────────────────────────────────
def pad(freqs, dur, cutoff=1400, detune=0.004, a=0.55, r=1.1, level=1.0):
    """Warme Akkordflaeche: Grundton + Obertoene, leicht verstimmt, tiefpassgefiltert."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for k, f in enumerate(freqs):
        for h, amp in ((1, 1.0), (2, 0.32), (3, 0.16), (4, 0.08)):
            for det in (-detune, 0.0, detune):
                ph = rng.uniform(0, 2 * np.pi)
                out += amp * np.sin(2 * np.pi * f * h * (1 + det) * t + ph) / (k + 1.6)
    out /= np.max(np.abs(out)) + 1e-9
    out = lp(out, cutoff)
    # langsames Atmen, damit die Flaeche nicht steht
    out *= 0.82 + 0.18 * np.sin(2 * np.pi * 0.23 * t + 1.1)
    return out * env(n, a, 0.8, 0.85, r) * level


def sub(f0, f1, dur, level=1.0):
    """Sub-Bass mit Tonhoehenabfall — der Koerper eines Impacts."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = f1 + (f0 - f1) * np.exp(-t * 9.0)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 4.2) * level


def impact(level=1.0, bright=1.0):
    """Schnitt-Impact: Sub-Boom + kurzer Rauschtransient."""
    body = sub(150, 42, 1.4, 1.0)
    tr = noise(0.28)
    tr = bp(tr, 700, 6500) * np.exp(-np.arange(len(tr)) / SR * 26) * 0.55 * bright
    out = body
    out[: len(tr)] += tr
    return out * level


def whoosh(dur=0.9, up=True, level=1.0, f_lo=250, f_hi=5200):
    """Rauschsweep. Zeitvariabel ueber Bloecke, sonst klingt es wie ein Standfilter."""
    n = int(dur * SR)
    x = rng.standard_normal(n)
    out = np.zeros(n)
    blocks = 60
    edges = np.linspace(0, n, blocks + 1).astype(int)
    for i in range(blocks):
        p = i / (blocks - 1)
        if not up:
            p = 1 - p
        c = f_lo * (f_hi / f_lo) ** p
        seg = x[edges[i] : edges[i + 1]]
        if len(seg) < 12:
            continue
        out[edges[i] : edges[i + 1]] = bp(seg, c * 0.55, min(c * 1.9, SR / 2 * 0.95))
    shape = np.sin(np.linspace(0, np.pi, n)) ** 1.5
    return out / (np.max(np.abs(out)) + 1e-9) * shape * level


def tick(level=1.0, f=2600):
    """Kurzer UI-Klick fuer getippte Zeichen."""
    n = int(0.035 * SR)
    x = rng.standard_normal(n)
    x = bp(x, f * 0.6, f * 2.1)
    x += 0.5 * np.sin(2 * np.pi * f * np.arange(n) / SR)
    return x * np.exp(-np.arange(n) / SR * 190) * level


def snap(level=1.0):
    """Heller Transient — der Wortmarken-Snap."""
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    x = hp(rng.standard_normal(n), 1800) * np.exp(-t * 42) * 0.9
    x += np.sin(2 * np.pi * 1760 * t) * np.exp(-t * 26) * 0.35
    x += np.sin(2 * np.pi * 2637 * t) * np.exp(-t * 30) * 0.22
    x += sub(220, 60, 0.5, 0.7)[:n]
    return x * level


def ding(f=1318.5, level=1.0):
    """Weicher Bestaetigungston (Haekchen)."""
    n = int(0.75 * SR)
    t = np.arange(n) / SR
    x = (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2 * t)
         + 0.18 * np.sin(2 * np.pi * f * 3.01 * t))
    return x * np.exp(-t * 7.5) * level


def riser(dur, level=1.0):
    """Anstieg vor einem Schnitt: Rauschsweep + steigender Ton, Crescendo."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    p = t / dur
    x = whoosh(dur, up=True, level=1.0, f_lo=300, f_hi=8000)
    f = 220 * (2 ** (2.2 * p))
    x += 0.45 * np.sin(2 * np.pi * np.cumsum(f) / SR) * p
    return x * (p ** 2.1) * level


def pulse_click(level=1.0, accent=False):
    n = int(0.12 * SR)
    t = np.arange(n) / SR
    x = bp(rng.standard_normal(n), 900 if accent else 1500, 4200)
    x *= np.exp(-t * (60 if accent else 95))
    x += sub(110 if accent else 90, 48, 0.12, 0.55 if accent else 0.3)[:n]
    return x * level


def shimmer(freqs, dur, level=1.0):
    """Hohe Klangwolke fuer den Kachelring / das Finale."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for i, f in enumerate(freqs):
        out += np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) / (i + 2)
    out *= np.sin(np.linspace(0, np.pi, n)) ** 1.2
    return out * level


# ── Zeiten aus engine.js ─────────────────────────────────────────────────
CUTS = [4.20, 7.40, 11.60, 15.60]
SNAP_T = 5.22
PILLS = [7.40, 8.80, 10.20]
PILL_TEXT = ["Bahn 7 · 3 Schläge", "8 Spieler, 1 Karte", "Sieger steht fest"]
MORPH_T = 17.42

# A-Moll-Bogen, passend zum Farbbogen des Films
CHORDS = [
    (0.00, 4.55, [55.00, 110.00, 130.81, 164.81], 900,  0.58),   # Am, dumpf = das Alte
    (4.20, 3.65, [43.65, 87.31, 110.00, 130.81], 1500, 0.64),    # F
    (7.40, 4.50, [65.41, 130.81, 164.81, 196.00], 2100, 0.60),   # C
    (11.60, 4.35, [49.00, 98.00, 123.47, 146.83], 1900, 0.64),   # G
    (15.60, 4.40, [55.00, 110.00, 164.81, 246.94], 2400, 0.74),  # Am, aufgeloest
]

for t0, d, freqs, cut, lvl in CHORDS:
    p = pad(freqs, d, cutoff=cut, a=0.30 if t0 else 0.9, r=0.9, level=lvl)
    add(L, R, t0, p, pan=-0.12, gain=1.0)
    add(L, R, t0, pad(freqs, d, cutoff=cut * 1.15, detune=0.007, a=0.34 if t0 else 1.0,
                      r=0.9, level=lvl * 0.7), pan=0.14)

# ── Szene 1: Tippen ──────────────────────────────────────────────────────
def type_ticks(text, t_start, t_end, level, f):
    per = (t_end - t_start) / (len(text) + 0.6)
    for i, ch in enumerate(text):
        if ch == " ":
            continue
        add(L, R, t_start + i * per, tick(level, f), pan=rng.uniform(-0.25, 0.25))


type_ticks("ZETTEL.", 0.34, 1.16, 0.40, 2300)
type_ticks("BLEISTIFT.", 1.34, 2.30, 0.40, 2500)

# "Das war einmal." — kleiner, warmer Anschub
add(L, R, 2.62, ding(659.3, 0.10) , pan=0.0)

# Riser in den ersten Schnitt
add(L, R, 3.30, riser(0.90, 0.34), pan=0.0)

# ── Schnitte ─────────────────────────────────────────────────────────────
IMPACT_LVL = {4.20: 0.62, 7.40: 0.46, 11.60: 0.58, 15.60: 0.74}
for c in CUTS:
    add(L, R, c, impact(IMPACT_LVL[c], bright=1.0 if c != 7.40 else 0.7))
    add(L, R, max(0.0, c - 0.34), whoosh(0.70, up=True, level=0.26), pan=-0.2)
    add(L, R, c, whoosh(0.85, up=False, level=0.22), pan=0.2)

# Wortmarken-Snap
add(L, R, SNAP_T, snap(0.55))

# ── Puls: Achtel ab dem Snap bis zum Finale ──────────────────────────────
STEP = 0.20                      # 150 BPM, Achtel — jeder Schnitt faellt auf ein Raster
t = 5.40
k = 0
while t < 15.60:
    ramp = min(1.0, (t - 5.40) / 1.6)
    fade = 1.0 if t < 15.0 else max(0.0, (15.60 - t) / 0.6)
    accent = (k % 4 == 0)
    add(L, R, t, pulse_click(0.30 * ramp * fade, accent), pan=0.0 if accent else (0.18 if k % 2 else -0.18))
    t += STEP
    k += 1

# ── Szene 3: Pills ───────────────────────────────────────────────────────
for i, p0 in enumerate(PILLS):
    add(L, R, p0 - 0.10, whoosh(0.45, up=True, level=0.20), pan=-0.15 + i * 0.15)
    type_ticks(PILL_TEXT[i], p0 + 0.112, p0 + 0.784, 0.24, 3100)
    add(L, R, p0 + 0.86, ding([1046.5, 1318.5, 1568.0][i], 0.16), pan=0.22)

# ── Szene 4: Kachelring oeffnet sich ─────────────────────────────────────
add(L, R, 11.60, shimmer([392.0, 493.9, 587.3, 784.0, 987.8], 2.6, 0.16), pan=0.0)
for i in range(8):                                     # acht Kacheln, aufsteigend
    f = [392.0, 440.0, 493.9, 587.3, 659.3, 784.0, 880.0, 987.8][i]
    add(L, R, 11.75 + i * 0.20, ding(f, 0.075), pan=(i / 7 - 0.5) * 0.7)

# Riser in das Finale
add(L, R, 14.55, riser(1.05, 0.42), pan=0.0)

# ── Szene 5: Finale ──────────────────────────────────────────────────────
add(L, R, 15.60, shimmer([440.0, 659.3, 880.0, 1318.5], 3.4, 0.20), pan=0.0)
add(L, R, MORPH_T, snap(0.30), pan=0.0)                # Karte wird zur Fahne
add(L, R, MORPH_T, shimmer([880.0, 1108.7, 1318.5, 1760.0], 1.8, 0.10))
add(L, R, 17.96, sub(120, 46, 1.6, 0.34))              # CTA setzt sich
add(L, R, 18.96, ding(880.0, 0.13), pan=0.0)           # Wortmarke

# ── Master ───────────────────────────────────────────────────────────────
# Ausklang: alles ist bei 20,0 s auf null, sonst schneidet der Encoder hart ab
tail = np.ones(N)
fade_from = idx(19.10)
tail[fade_from:] = np.linspace(1, 0, N - fade_from) ** 1.4
L *= tail
R *= tail
L[: idx(0.05)] *= np.linspace(0, 1, idx(0.05))
R[: idx(0.05)] *= np.linspace(0, 1, idx(0.05))


def truepeak_limit(l, r, ceiling_db=-1.5, gain_db=0.0, look_ms=2.0, rel_ms=90.0, os=4):
    """Look-ahead-Limiter, der auf dem UEBERABGETASTETEN Signal misst.

    Ein reiner Sample-Peak-Limiter reicht hier nicht: die Tick- und Klick-Anteile
    erzeugen Inter-Sample-Spitzen, die nach der D/A-Wandlung deutlich ueber dem
    Sample-Peak liegen (hier gemessen ~1,9 dB). Deshalb wird die noetige
    Pegelabsenkung bei 4-facher Abtastrate bestimmt.
    """
    g = 10 ** (gain_db / 20)
    l, r = l * g, r * g
    ceiling = 10 ** (ceiling_db / 20)

    st = np.stack([l, r], axis=1)
    up = signal.resample_poly(st, os, 1, axis=0)
    peak_up = np.max(np.abs(up), axis=1)

    need = np.minimum(1.0, ceiling / np.maximum(peak_up, 1e-9))

    # Look-ahead: laufendes Minimum ueber ein VORWAERTS gerichtetes Fenster,
    # damit die Absenkung schon vor der Spitze steht (negatives origin).
    w = max(3, int(look_ms / 1000 * SR * os)) | 1          # ungerade erzwingen
    need_min = ndimage.minimum_filter1d(need, size=w, origin=-(w // 2), mode='nearest')

    # Release glaetten, Attack bleibt hart: das elementweise Minimum mit
    # need_min sorgt dafuer, dass die Absenkung sofort greift und nur die
    # Rueckkehr auf 1.0 der Zeitkonstante folgt.
    a = np.exp(-1.0 / (rel_ms / 1000 * SR * os))
    smoothed = signal.lfilter([1 - a], [1, -a], need_min)
    env_g = np.minimum(need_min, smoothed)

    gain = signal.resample_poly(env_g, 1, os)[: len(l)]
    gain = np.minimum(gain, 1.0)
    return l * gain, r * gain


# gain_db so gewaehlt, dass die integrierte Lautheit bei rund -14 LUFS landet
# (Zielwert der gaengigen Social-Plattformen); der Limiter haelt -1.5 dBTP.
L, R = truepeak_limit(L, R, ceiling_db=-2.3, gain_db=3.0)

stereo = np.empty(N * 2)
stereo[0::2], stereo[1::2] = L, R
pcm = (stereo * 32767).astype("<i2")

out = sys.argv[1] if len(sys.argv) > 1 else "score.wav"
with wave.open(out, "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())

rms = np.sqrt(np.mean((L ** 2 + R ** 2) / 2))
sp = max(np.max(np.abs(L)), np.max(np.abs(R)))
tp = np.max(np.abs(signal.resample_poly(np.stack([L, R], axis=1), 8, 1, axis=0)))
print(f"{out}  {DUR:.2f}s  sample-peak {20*np.log10(sp):.2f} dBFS  "
      f"true-peak {20*np.log10(tp):.2f} dBTP  rms {20*np.log10(rms):.1f} dBFS")
