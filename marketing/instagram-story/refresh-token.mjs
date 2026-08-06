#!/usr/bin/env node
// Frischt den langlebigen Instagram-Token auf (verlängert um 60 Tage).
// Voraussetzung: Token ist gültig und mind. 24h alt. Läuft täglich harmlos mit.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const cfgPath = path.join(__dirname, "instagram.local.json");
const cfg = JSON.parse(fs.readFileSync(cfgPath, "utf8"));
if (!cfg.accessToken) { console.error("kein accessToken vorhanden"); process.exit(2); }

const url = "https://graph.instagram.com/refresh_access_token?grant_type=ig_refresh_token&access_token=" +
  encodeURIComponent(cfg.accessToken);
const j = await (await fetch(url)).json();

if (j.access_token) {
  cfg.accessToken = j.access_token;
  fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2) + "\n");
  console.log("Token erneuert, gültig noch ~" + Math.round((j.expires_in || 0) / 86400) + " Tage.");
} else {
  // Nicht fatal: z.B. wenn Token <24h alt ist, klappt Refresh noch nicht.
  console.error("Refresh übersprungen:", JSON.stringify(j));
  process.exit(1);
}
