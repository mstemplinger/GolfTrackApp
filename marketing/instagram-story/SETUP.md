# Instagram-Automatik – Funktionsweise & neue Accounts einrichten

## 1. Wie das Posten technisch funktioniert

Automatisches Posten geht nur über die **offizielle Instagram Graph API** (Weg „Instagram-Login", Basis `https://graph.instagram.com/v21.0`).

**Wichtigste Eigenheit:** Die API nimmt **keine Dateien direkt** entgegen – sie lädt Bild/Video von einer **öffentlichen HTTPS-URL**. Deshalb wird jede Datei zuerst zu **catbox.moe** hochgeladen (kein Login nötig), und Instagram holt sie sich von dort.

Jeder Post läuft in **2 Schritten**: erst einen „Container" anlegen, dann veröffentlichen.

### Story (`post-instagram.mjs <bild.png>`)
1. PNG → catbox.moe hochladen → öffentliche URL.
2. Container: `POST {graphBase}/{igUserId}/media` mit `image_url=<url>`, `media_type=STORIES`, `access_token` → liefert `creation_id`.
3. Veröffentlichen: `POST {graphBase}/{igUserId}/media_publish` mit `creation_id`, `access_token` → liefert `media_id`. Fertig.

### Reel (`post-reel.mjs <video.mp4> [caption.txt]`)
1. PNG → MP4 (`make-reel.mjs`, via ffmpeg; Tonspur = `beat.wav` bzw. `music.mp3`).
2. MP4 → catbox.moe → URL.
3. Container: `POST .../media` mit `media_type=REELS`, `video_url=<url>`, `caption`, `share_to_feed=true`.
4. **Warten**, bis Video verarbeitet ist (`status_code=FINISHED` pollen – dauert 30–120 s).
5. Veröffentlichen: `POST .../media_publish`.

> Highlights & die Instagram-Musikbibliothek sind über die API **nicht** möglich (nur manuell in der App).

## 2. Zugangsdaten (`instagram.local.json`, gitignored)
```json
{ "graphBase": "https://graph.instagram.com/v21.0", "igUserId": "<ID>", "accessToken": "<Token>", "imgbbKey": "" }
```
- `igUserId` – IG-User-ID, kommt aus `GET https://graph.instagram.com/v21.0/me?fields=user_id&access_token=<Token>`.
- `accessToken` – Langzeit-Token (60 Tage), wird täglich von `refresh-token.mjs` um 60 Tage verlängert → läuft nie ab, solange die Routine läuft.
- Berechtigung: `instagram_business_content_publish`. Die Meta-App darf im **Entwicklungsmodus** bleiben – das genügt, um auf **eigene** Accounts zu posten, die in der App eine Rolle (Instagram-Tester/Admin) haben. Kein App-Review nötig.

## 3. Einen weiteren Account einrichten

### A) Instagram vorbereiten
Account auf **Business** oder **Creator** umstellen (IG-Einstellungen → Konto → Kontotyp).

### B) Im selben Meta-Dashboard (App „GolfTrack Posting API", developers.facebook.com)
1. **App-Rollen → Rollen → Instagram-Tester hinzufügen** → Benutzername des neuen Accounts → einladen.
2. Im **neuen** IG-Account annehmen: instagram.com → Einstellungen → **Apps und Websites → Tester-Einladungen → Annehmen**.
3. **Instagram → API-Einrichtung mit Instagram-Login → Zugriffstokens generieren → Konto hinzufügen** (mit dem neuen Account einloggen, alles erlauben) → **Token generieren** → kopieren.

### C) Eigener Ordner für den neuen Account (saubere Trennung, kein Clobbering)
```bash
cp -R marketing/instagram-story marketing/instagram-story-ACC2
cd marketing/instagram-story-ACC2
rm -rf out/* history.json            # frischer Verlauf
echo "[]" > history.json
# instagram.local.json: neuen accessToken eintragen, igUserId vorerst ""
# igUserId automatisch holen:
node -e "const c=require('./instagram.local.json');fetch('https://graph.instagram.com/v21.0/me?fields=user_id,username&access_token='+c.accessToken).then(r=>r.json()).then(j=>console.log(j))"
# die user_id in instagram.local.json eintragen
# logo.png ggf. durch das Logo der anderen Marke ersetzen
```
(node_modules wird mitkopiert; alternativ im neuen Ordner `npm i` ausführen.)

### D) Eigener Scheduled Task
Neuen Task anlegen mit eigenem Prompt: eigenes `ARBEITSVERZEICHNIS` (der neue Ordner), eigener `handle`, eigene Highlight-Namen, eigene Themen/Inhalte. Cron z. B. wieder `55 23 * * *`.

## 4. Telegram (optional)
Kann derselbe Bot/Chat sein (es ist nur eine Benachrichtigung an dich) – dann einfach `telegram.local.json` mitkopieren. Oder ein eigener Bot pro Account.

## Dateiübersicht
- `generate.mjs` – Story-PNG (1080×1920) im App-Stil rendern
- `make-beat.mjs` – lizenzfreien House-Beat erzeugen (`beat.wav`)
- `make-reel.mjs` – PNG → MP4 (mit Tonspur)
- `post-instagram.mjs` – Story posten
- `post-reel.mjs` – Reel posten
- `send.mjs` – per Telegram senden
- `refresh-token.mjs` – IG-Token verlängern
- `*.local.json` – Secrets (gitignored)
