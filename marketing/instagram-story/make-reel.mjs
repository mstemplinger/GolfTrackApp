#!/usr/bin/env node
// Erzeugt aus einem Story-PNG ein Reel-taugliches MP4 (1080x1920, ~7s, sanfter Zoom, H.264).
// Audio: nimmt automatisch music.mp3/music.m4a/music.wav/beat.wav aus dem Ordner (in dieser
// Reihenfolge); ist keine Datei da, wird eine stille Tonspur eingefügt.
// Aufruf: node make-reel.mjs <bild.png> <out.mp4>
import { spawn } from "node:child_process";
import ffmpegPath from "ffmpeg-static";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const [, , inPng, outMp4] = process.argv;
if (!inPng || !outMp4) { console.error("Aufruf: node make-reel.mjs <bild.png> <out.mp4>"); process.exit(1); }
if (!fs.existsSync(inPng)) { console.error("Bild fehlt: " + inPng); process.exit(1); }

const DUR = 7, FPS = 30, frames = DUR * FPS;
const vf = `scale=1080:1920,zoompan=z='min(zoom+0.0007,1.08)':d=${frames}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1920:fps=${FPS},format=yuv420p`;
const vcodec = ["-c:v", "libx264", "-profile:v", "high", "-preset", "medium", "-crf", "20"];

const audio = ["music.mp3", "music.m4a", "music.wav", "beat.wav"]
  .map((f) => path.join(__dirname, f))
  .find((f) => fs.existsSync(f));

let args;
if (audio) {
  console.error("Audio: " + path.basename(audio));
  args = [
    "-y",
    "-loop", "1", "-i", inPng,
    "-stream_loop", "-1", "-i", audio,
    "-t", String(DUR),
    "-vf", vf, "-r", String(FPS),
    "-af", `afade=t=out:st=${(DUR - 1.2).toFixed(2)}:d=1.2`,
    ...vcodec,
    "-c:a", "aac", "-b:a", "128k", "-ac", "2",
    "-shortest", "-movflags", "+faststart",
    outMp4,
  ];
} else {
  console.error("Audio: (stille Tonspur)");
  args = [
    "-y",
    "-loop", "1", "-i", inPng,
    "-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
    "-t", String(DUR),
    "-vf", vf, "-r", String(FPS),
    ...vcodec,
    "-c:a", "aac", "-b:a", "128k",
    "-shortest", "-movflags", "+faststart",
    outMp4,
  ];
}

spawn(ffmpegPath, args, { stdio: ["ignore", "ignore", "inherit"] }).on("close", (code) => {
  if (code === 0) console.log("Reel-Video OK -> " + outMp4);
  else { console.error("ffmpeg-Fehler, code " + code); process.exit(1); }
});
