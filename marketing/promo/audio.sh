#!/bin/sh
# GolfTrack-Werbefilm – Tonspur, vollständig mit ffmpeg synthetisiert.
#
# Kein Sample, keine Bibliothek: Drone, Bass-Puls, Arpeggio, Impacts auf den
# Schnitten und Whooshes davor entstehen aus Sinus- und Rauschquellen. Das
# trägt den Film, ersetzt aber keine echte Produktion – der Zweck ist, dass
# Schnitt und Ton zusammenfallen.
#
# Aufruf:  sh audio.sh out.wav
set -eu
OUT="${1:-audio.wav}"
D=30

# Die Schnitte aus TIMELINE in engine.js. Ton und Bild müssen hier
# zusammenbleiben – ändert sich die Timeline, ändert sich diese Liste.
# 4.40  8.80  13.00  17.20  21.40  25.40

# --- Impacts: tiefer Boom je Schnitt, exponentiell abfallend ---------------
IMP=""
for c in 4.40 8.80 13.00 17.20 21.40 25.40; do
  IMP="${IMP}+gt(t,$c)*exp(-7*(t-$c))*sin(2*PI*62*(t-$c))"
done
# Der Wechsel zum Minigolf bekommt mehr Gewicht als die übrigen.
IMP="0.55*(${IMP#+})+0.45*gt(t,17.20)*exp(-4.5*(t-17.20))*sin(2*PI*44*(t-17.20))"

# --- Whooshes: gefiltertes Rauschen, das auf jeden Schnitt zuläuft ---------
WH=""
for c in 4.40 8.80 13.00 17.20 21.40 25.40; do
  WH="${WH}+between(t,$c-0.55,$c)*pow((t-($c-0.55))/0.55,3)"
done
WH="${WH#+}"

# --- Arpeggio in a-Moll, Achtel bei 120 bpm --------------------------------
# Die Tonhöhe springt mit dem Achtel; die kurze Hüllkurve verdeckt den
# Phasensprung, der dabei entsteht.
N='mod(floor(t/0.25),4)'
F="if(eq($N,0),220,if(eq($N,1),261.63,if(eq($N,2),329.63,392)))"
ARP="0.22*sin(2*PI*($F)*t)*exp(-7*mod(t,0.25))"

# --- Lautstärkeverlauf: sparsam beginnen, zum Wechsel öffnen ---------------
# 0–4.4 nur Drone, ab 4.4 Puls, ab 13 voll, ab 25.4 Ausklang.
DUCK="min(1,max(0.35,0.35+0.65*(t/13)))*(1-0.55*gt(t,28.6)*(t-28.6)/1.4)"

ffmpeg -y -hide_banner -loglevel error \
  -f lavfi -i "aevalsrc='0.34*sin(2*PI*55*t)+0.20*sin(2*PI*82.41*t)+0.11*sin(2*PI*110*t)+0.06*sin(2*PI*164.81*t)':d=$D:s=48000" \
  -f lavfi -i "aevalsrc='0.62*sin(2*PI*46*t)*exp(-10*mod(t,0.5))':d=$D:s=48000" \
  -f lavfi -i "aevalsrc='$ARP':d=$D:s=48000" \
  -f lavfi -i "aevalsrc='$IMP':d=$D:s=48000" \
  -f lavfi -i "anoisesrc=d=$D:c=pink:a=0.9:r=48000" \
  -filter_complex "
    [0:a]lowpass=f=420,volume=0.85,tremolo=f=0.35:d=0.25[drone];
    [1:a]lowpass=f=180,volume=eval=frame:volume='0.9*gt(t,4.4)*$DUCK'[kick];
    [2:a]highpass=f=180,lowpass=f=4200,aecho=0.7:0.55:330:0.28,
         volume=eval=frame:volume='0.75*gt(t,4.4)*$DUCK'[arp];
    [3:a]lowpass=f=260,volume=1.25[imp];
    [4:a]highpass=f=700,lowpass=f=7000,
         volume=eval=frame:volume='0.85*($WH)'[whoosh];
    [drone][kick][arp][imp][whoosh]amix=inputs=5:duration=first:normalize=0,
    afade=t=in:st=0:d=0.6,afade=t=out:st=29.0:d=1.0,
    alimiter=limit=0.94,aformat=sample_fmts=s16:channel_layouts=stereo
  " -t $D "$OUT"

echo "geschrieben: $OUT"
