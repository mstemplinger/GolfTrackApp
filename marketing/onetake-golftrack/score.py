#!/usr/bin/env python3
"""score.py — the GolfTrack film's sound: events from comp.html's __events(), the synthesised palette in one room,
the user's track „Mechanism Pilot“ (Tonebox, 110 BPM) from the first frame: pads of its breakdown (track 67.78), the
kick at film 2.0 (track 69.78), 32 beats of build under the Lernrunde, its drop (87.234) on the first drive (film 19.45),
and on the end card a cut on a bar line into the track's calm outro (314.162, 416 beats after the drop). Ducked under the hits, mastered to −16 LUFS / −4 dBTP with ffmpeg.

    python score.py            → events.json, sfx.wav, mix.wav
"""
import asyncio, json, os, subprocess, sys
import numpy as np
from playwright.async_api import async_playwright
sys.path.insert(0, os.path.expanduser("~/.claude/skills/onetake/scripts"))
from sfx_palette import SR, Score, air, glass, wood, sub, bubble, lp, hp, bp, sat, _rng

HERE = os.path.dirname(os.path.abspath(__file__))
MUSIC = os.path.join(HERE, "music", "mechanism-pilot.mp3")
DUR, DROP, TRACK_DROP, MUSIC_IN, OUTRO = 60.0, 19.45, 87.234, 0.0, 314.162   # film 0 = track 67.784 (pads), kick in at film 2.0
SPLICE = None                                      # film time of the cut into the outro: B(53), read from the comp


async def dump():
    async with async_playwright() as p:
        b = await p.chromium.launch(); pg = await (await b.new_context(viewport={"width": 1080, "height": 1920})).new_page()
        await pg.goto("file://" + os.path.join(HERE, "comp.html")); await pg.evaluate("window.__ready")
        ev = await pg.evaluate("""() => __events().map(e => { const c = camAt(e.t), V = OM.view(c, {W:1080, H:1920}), b = ballAt(e.t);
                                   const p = OM.project(V, b.x, b.y); return {...e, pan: Math.max(-1, Math.min(1, (p[0] - 540) / 540))}; })""")
        global SPLICE, PUTT_T0, CUP_T; SPLICE, PUTT_T0, CUP_T = await pg.evaluate("[B(53), PUTT.t0, CUPT]")
        await b.close(); return ev


def noise(n): return _rng.standard_normal(n)
def env(n, a, d):
    t = np.arange(n) / SR; return np.minimum(1, t / max(a, 1e-4)) * np.exp(-t * d)

def strike():                    # club on ball: a hard, bright click with a woody body and a felt thump
    n = int(SR * 0.5); t = np.arange(n) / SR
    click = hp(noise(n), 2500) * np.exp(-t * 300)
    body = wood(1150, 0.09); thump = sub(85, 0.4)
    ring = glass(2900, 0.25, 0.4)
    x = np.zeros(n); x[:len(body)] += body * 0.9; x[:len(thump)] += thump * 0.6; x[:len(ring)] += ring * 0.25; x += click * 0.9
    return sat(x, 1.4)
def turf():                      # ball landing on grass
    n = int(SR * 0.35); t = np.arange(n) / SR
    return lp(noise(n), 700) * np.exp(-t * 26) * 0.9 + np.pad(sub(52, 0.3), (0, max(0, n - int(SR * 0.3))))[:n] * 0.5
def cup():                       # ball rattling into the cup
    x = np.zeros(int(SR * 0.8))
    for i, (f, g) in enumerate([(720, .7), (560, .9), (480, .6), (380, .5)]):
        s = wood(f, 0.08) * g; a = int(SR * (0.03 * i + 0.012 * i * i)); x[a:a + len(s)] += s
    s = sub(58, 0.5) * 0.7; a = int(SR * 0.12); x[a:a + len(s)] += s
    return x
def chord(fs, dur=1.4, bright=0.8): return sum(glass(f, dur, bright) for f in fs) / len(fs)

PENT = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.7, 1318.5, 1568.0, 1760.0]


def score(events):
    s = Score(dur=DUR, T60=1.0)
    hits = 0
    for e in events:
        t, k, g, pan = e["t"], e["kind"], e["g"], e["pan"] * 0.55
        if k == "pop":    s.place(bubble(640, 0.2), t, 0.55 * g, pan, 0.35); s.place(glass(1318.5, 0.5, 0.5), t, 0.12 * g, pan, 0.5)
        elif k == "word": s.place(wood(210, 0.1), t, 0.35 * g, pan, 0.3)
        elif k == "tick": s.place(glass(1760, 0.35, 0.6), t, 0.22 * g, pan, 0.4)
        elif k == "key":  s.place(wood(float(_rng.uniform(900, 1300)), 0.05), t, 0.16 * g * float(_rng.uniform(.6, 1)), pan, 0.15)
        elif k == "card": s.place(bubble(420, 0.22), t, 0.3 * g, pan, 0.3); s.place(air(0.28, 300, 1800, 1.2, 0.3), t - 0.05, 0.12 * g, pan, 0.4)
        elif k == "swell": s.place(air(0.7, 200, 1600, 1.0, 0.7), t - 0.45, 0.25 * g, pan, 0.6)
        elif k == "right": s.place(chord([1046.5, 1318.5, 1568.0], 1.3), t, 0.42 * g, pan, 0.5)
        elif k == "press": s.place(wood(170, 0.12), t, 0.5 * g, pan, 0.2); s.place(sub(90, 0.25), t, 0.25 * g, pan, 0.1)
        elif k == "hit":
            f = PENT[hits % len(PENT)]; hits += 1
            s.place(glass(f, 0.5, 0.7), t, 0.24 * g, pan, 0.35); s.place(sub(72, 0.3), t, 0.35 * g, pan, 0.1)
        elif k == "curl": s.place(air(1.0, 300, 2400, 1.3, 0.6), t, 0.3 * g, pan, 0.6)
        elif k == "thud": s.place(sub(55, 0.9), t, 0.8 * g, 0, 0.3); s.place(wood(120, 0.15), t, 0.35 * g, 0, 0.3)
        elif k == "suck": s.place(air(0.45, 2400, 300, 1.4, 0.85), t, 0.3 * g, pan, 0.5)
        elif k == "land": s.place(sub(60, 0.5), t, 0.6 * g, pan, 0.2); s.place(wood(150, 0.12), t, 0.4 * g, pan, 0.2)
        elif k == "swish": s.place(air(0.26, 500, 4200, 1.6, 0.8), t, 0.5 * g, -0.3, 0.3)
        elif k == "strike": s.place(strike(), t, 0.9 * g, pan, 0.35)
        elif k == "turf": s.place(turf(), t, 0.6 * g, pan, 0.3)
        elif k == "swoosh": s.place(air(0.9, 250, 2600, 1.2, 0.5), t - 0.1, 0.35 * g, -0.4, 0.5, pan_to=0.4)
        elif k == "putt": s.place(wood(950, 0.06), t, 0.35 * g, pan, 0.2)
        elif k == "cup":  s.place(cup(), t - 0.03, 0.75 * g, pan, 0.35)
        elif k == "chime": s.place(chord([523.25, 783.99, 1046.5, 1318.5], 2.4, 0.6), t, 0.55 * g, 0, 0.6)
    return s


def music():
    def read(start, dur):
        raw = subprocess.run(["ffmpeg", "-v", "error", "-ss", f"{start:.4f}", "-t", f"{dur:.4f}", "-i", MUSIC, "-ac", "2", "-ar", str(SR), "-f", "f32le", "-"],
                             capture_output=True, check=True).stdout
        return np.frombuffer(raw, np.float32).reshape(-1, 2).astype(np.float64)
    n = int(DUR * SR); out = np.zeros((n, 2)); off = TRACK_DROP - DROP           # track time = film time + off
    a, sp = int(MUSIC_IN * SR), int(SPLICE * SR); xf = int(0.04 * SR)
    m1 = read(MUSIC_IN + off, SPLICE - MUSIC_IN + 0.04); m1 = m1[: sp - a + xf]
    m2 = read(OUTRO, DUR - SPLICE + 0.1)
    out[a:a + len(m1)] += m1 * np.r_[np.ones(len(m1) - xf), np.linspace(1, 0, xf)][:, None]
    L = min(len(m2), n - sp); out[sp:sp + L] += m2[:L] * np.r_[np.linspace(0, 1, xf), np.ones(L - xf)][:, None]
    t = np.arange(n) / SR
    breath = 1 - np.clip((t - 18.9) / 0.08, 0, 1) * (1 - np.clip((t - DROP + 0.02) / 0.02, 0, 1))   # gap in the backswing, back on the strike
    gp0, gp1 = PUTT_T0 + 0.25, CUP_T - 0.02                                                   # the putt rolls in silence, the cup brings it back
    breath = breath * (1 - np.clip((t - gp0) / 0.25, 0, 1) * (1 - np.clip((t - gp1) / 0.02, 0, 1)))
    out *= (np.clip((t - MUSIC_IN) / 0.5, 0, 1) * (1 - np.clip((t - 58.0) / 1.2, 0, 1)) * breath)[:, None]
    return out


def duck(events, n):
    g = np.ones(n); t = np.arange(n) / SR
    for e in events:
        if e["kind"] in ("strike", "cup", "thud", "right", "chime"):
            d = 0.5 if e["kind"] == "strike" else 0.35
            g = np.minimum(g, 1 - d * np.clip((t - e["t"] + 0.03) / 0.03, 0, 1) * np.exp(-np.clip(t - e["t"], 0, None) / 0.45))
    return g


def main():
    ev = asyncio.run(dump()); json.dump(ev, open(os.path.join(HERE, "events.json"), "w"), indent=0)
    s = score(ev); sfx = s.mix(peak_db=-6.0)
    import wave
    m = music() * 0.42 * duck(ev, int(DUR * SR))[:, None]
    mix = m + sfx[: len(m)] * 0.9
    mix = np.tanh(mix * 1.1) / 1.1
    def wr(path, x):
        x = np.clip(x, -1, 1); w = wave.open(path, "wb"); w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes()); w.close()
    wr(os.path.join(HERE, "sfx.wav"), sfx); wr(os.path.join(HERE, "mix_raw.wav"), mix)
    # master: −16 LUFS integrated, −4 dBTP (two-pass loudnorm, linear)
    j = subprocess.run(["ffmpeg", "-hide_banner", "-i", os.path.join(HERE, "mix_raw.wav"), "-af", "loudnorm=I=-16:TP=-4:LRA=11:print_format=json", "-f", "null", "-"],
                       capture_output=True, text=True).stderr
    st = json.loads(j[j.rindex("{"):j.rindex("}") + 1])
    af = (f"loudnorm=I=-16:TP=-4:LRA=11:measured_I={st['input_i']}:measured_TP={st['input_tp']}:measured_LRA={st['input_lra']}"
          f":measured_thresh={st['input_thresh']}:offset={st['target_offset']}:linear=true,aresample=48000")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", os.path.join(HERE, "mix_raw.wav"), "-af", af, os.path.join(HERE, "mix.wav")], check=True)
    print("events", len(ev), "· in", st["input_i"], "LUFS →", os.path.join(HERE, "mix.wav"))


if __name__ == "__main__":
    main()
