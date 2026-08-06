#!/usr/bin/env node
// Sendet ein Bild per Telegram-Bot. Liest Zugangsdaten aus telegram.local.json
// Aufruf:  node send.mjs <bild.png> "<caption>"
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const [, , file, caption = ""] = process.argv;
const credPath = path.join(__dirname, "telegram.local.json");

if (!fs.existsSync(credPath)) {
  console.error("FEHLT: telegram.local.json (botToken + chatId). Bild NICHT gesendet:", file);
  process.exit(2);
}
const { botToken, chatId } = JSON.parse(fs.readFileSync(credPath, "utf8"));
if (!botToken || !chatId) {
  console.error("telegram.local.json unvollständig (botToken/chatId leer). Bild NICHT gesendet.");
  process.exit(2);
}

const form = new FormData();
form.append("chat_id", String(chatId));
form.append("caption", caption);
form.append("photo", new Blob([fs.readFileSync(file)], { type: "image/png" }), path.basename(file));

const res = await fetch(`https://api.telegram.org/bot${botToken}/sendPhoto`, {
  method: "POST",
  body: form,
});
const json = await res.json();
if (!json.ok) {
  console.error("Telegram-Fehler:", JSON.stringify(json));
  process.exit(1);
}
console.log("Telegram OK -> message_id", json.result.message_id);
