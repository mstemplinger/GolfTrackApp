#!/usr/bin/env node
// Postet ein PNG als Instagram-STORY via offizieller Graph API.
// Aufruf:  node post-instagram.mjs <bild.png>
// Liest Zugangsdaten aus instagram.local.json (gitignored).
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const imgPath = process.argv[2];
if (!imgPath) { console.error("Aufruf: node post-instagram.mjs <bild.png>"); process.exit(1); }

const cfgPath = path.join(__dirname, "instagram.local.json");
if (!fs.existsSync(cfgPath)) { console.error("FEHLT: instagram.local.json"); process.exit(2); }
const cfg = JSON.parse(fs.readFileSync(cfgPath, "utf8"));
const { graphBase = "https://graph.instagram.com/v21.0", igUserId, accessToken, imgbbKey } = cfg;
if (!igUserId || !accessToken) {
  console.error("instagram.local.json unvollständig (igUserId / accessToken fehlen).");
  process.exit(2);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// 1) Bild auf öffentlichen Host laden (IG holt das Bild per URL).
//    Mit imgbb-Key -> imgbb (Auto-Ablauf nach 1h), sonst -> catbox.moe (ohne Anmeldung).
async function uploadImage(file) {
  if (imgbbKey) {
    const b64 = fs.readFileSync(file).toString("base64");
    const body = new URLSearchParams({ key: imgbbKey, image: b64, expiration: "3600" });
    const res = await fetch("https://api.imgbb.com/1/upload", { method: "POST", body });
    const j = await res.json();
    if (!j.success) throw new Error("imgbb-Upload fehlgeschlagen: " + JSON.stringify(j));
    return j.data.url;
  }
  const form = new FormData();
  form.append("reqtype", "fileupload");
  form.append("fileToUpload", new Blob([fs.readFileSync(file)]), path.basename(file));
  const res = await fetch("https://catbox.moe/user/api.php", { method: "POST", body: form });
  const url = (await res.text()).trim();
  if (!url.startsWith("http")) throw new Error("catbox-Upload fehlgeschlagen: " + url);
  return url;
}

async function graph(endpoint, params) {
  const res = await fetch(`${graphBase}/${endpoint}`, {
    method: "POST",
    body: new URLSearchParams({ ...params, access_token: accessToken }),
  });
  const j = await res.json();
  if (j.error) throw new Error("Graph-API: " + JSON.stringify(j.error));
  return j;
}

try {
  console.log("1/4 Bild hochladen…");
  const imageUrl = await uploadImage(imgPath);
  console.log("    URL:", imageUrl);

  console.log("2/4 Story-Container anlegen…");
  const { id: creationId } = await graph(`${igUserId}/media`, {
    image_url: imageUrl,
    media_type: "STORIES",
  });

  console.log("3/4 Auf Verarbeitung warten…");
  for (let i = 0; i < 12; i++) {
    const res = await fetch(`${graphBase}/${creationId}?fields=status_code&access_token=${accessToken}`);
    const j = await res.json();
    if (j.status_code === "FINISHED") break;
    if (j.status_code === "ERROR") throw new Error("Container-Fehler: " + JSON.stringify(j));
    await sleep(2000);
  }

  console.log("4/4 Veröffentlichen…");
  const { id: mediaId } = await graph(`${igUserId}/media_publish`, { creation_id: creationId });
  console.log("Instagram OK -> media_id", mediaId);
} catch (e) {
  console.error("FEHLER:", e.message);
  process.exit(1);
}
