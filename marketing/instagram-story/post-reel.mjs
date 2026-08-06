#!/usr/bin/env node
// Postet ein MP4 als Instagram-REEL via Graph API (mit Caption + share_to_feed).
// Aufruf: node post-reel.mjs <video.mp4> [caption.txt]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const [, , videoPath, captionPath] = process.argv;
if (!videoPath) { console.error("Aufruf: node post-reel.mjs <video.mp4> [caption.txt]"); process.exit(1); }

const cfg = JSON.parse(fs.readFileSync(path.join(__dirname, "instagram.local.json"), "utf8"));
const { graphBase = "https://graph.instagram.com/v21.0", igUserId, accessToken } = cfg;
if (!igUserId || !accessToken) { console.error("instagram.local.json unvollständig (igUserId/accessToken)."); process.exit(2); }
const caption = captionPath && fs.existsSync(captionPath) ? fs.readFileSync(captionPath, "utf8").trim() : "";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function uploadToCatbox(file) {
  const form = new FormData();
  form.append("reqtype", "fileupload");
  form.append("fileToUpload", new Blob([fs.readFileSync(file)]), path.basename(file));
  const url = (await (await fetch("https://catbox.moe/user/api.php", { method: "POST", body: form })).text()).trim();
  if (!url.startsWith("http")) throw new Error("catbox-Upload fehlgeschlagen: " + url);
  return url;
}
async function graph(endpoint, params) {
  const j = await (await fetch(`${graphBase}/${endpoint}`, { method: "POST", body: new URLSearchParams({ ...params, access_token: accessToken }) })).json();
  if (j.error) throw new Error("Graph-API: " + JSON.stringify(j.error));
  return j;
}

try {
  console.log("1/4 Video hochladen…");
  const videoUrl = await uploadToCatbox(videoPath);
  console.log("    URL: " + videoUrl);

  console.log("2/4 Reel-Container anlegen…");
  const { id: creationId } = await graph(`${igUserId}/media`, {
    media_type: "REELS", video_url: videoUrl, caption, share_to_feed: "true",
  });

  console.log("3/4 Auf Video-Verarbeitung warten…");
  let ok = false;
  for (let i = 0; i < 36; i++) {
    await sleep(5000);
    const j = await (await fetch(`${graphBase}/${creationId}?fields=status_code,status&access_token=${encodeURIComponent(accessToken)}`)).json();
    if (j.status_code === "FINISHED") { ok = true; break; }
    if (j.status_code === "ERROR") throw new Error("Container-Fehler: " + JSON.stringify(j));
    process.stdout.write(".");
  }
  process.stdout.write("\n");
  if (!ok) throw new Error("Timeout bei der Video-Verarbeitung (>3 Min).");

  console.log("4/4 Veröffentlichen…");
  const { id: mediaId } = await graph(`${igUserId}/media_publish`, { creation_id: creationId });
  console.log("Reel OK -> media_id " + mediaId);
} catch (e) {
  console.error("FEHLER: " + e.message);
  process.exit(1);
}
