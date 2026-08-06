#!/usr/bin/env node
// Erzeugt einen lizenzfreien House-Beat (synthetisch, 120 BPM, 8s loopbar) als beat.wav.
// Kick (4/4) + Offbeat-Hi-Hat + Clap auf 2&4. Aufruf: node make-beat.mjs [out.wav]
import { spawn } from "node:child_process";
import ffmpegPath from "ffmpeg-static";

const out = process.argv[2] || "beat.wav";

// 120 BPM -> Beat alle 0.5s. Kommas in den Ausdrücken für den Filtergraph escapen (\,).
const kick = "0.9*sin(2*PI*50*t)*exp(-8*mod(t\\,0.5)) + 0.5*sin(2*PI*135*t)*exp(-55*mod(t\\,0.5))";
const hat  = "0.10*(random(0)*2-1)*exp(-45*mod(t+0.25\\,0.5))";
const clap = "0.22*(random(0)*2-1)*exp(-22*mod(t+0.5\\,1.0))";
const expr = `${kick} + ${hat} + ${clap}`;

const args = [
  "-y",
  "-f", "lavfi", "-i", `aevalsrc=${expr}:d=8:s=44100`,
  "-af", "alimiter=limit=0.92,lowpass=f=14000",
  "-ac", "2",
  out,
];

spawn(ffmpegPath, args, { stdio: ["ignore", "ignore", "inherit"] }).on("close", (c) => {
  if (c === 0) console.log("Beat OK -> " + out);
  else { console.error("ffmpeg-Fehler, code " + c); process.exit(1); }
});
