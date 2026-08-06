# GolfTrack – tägliche Instagram-Story

Erzeugt automatisch eine Instagram-Story (1080×1920) im exakten App-Stil und sendet sie per Telegram aufs Handy.

## Wochenplan (Story für den jeweils folgenden Tag, erstellt am Vorabend 20:00)
| Tag        | Thema                  | Akzent (AppTheme) |
|------------|------------------------|-------------------|
| Montag     | Golftipp des Tages     | Gold `#C9A035`    |
| Dienstag   | App-Feature            | Grün `#28824B`    |
| Mittwoch   | Motivation             | Hellgold `#FFBF4D`|
| Donnerstag | Golf-Fakt              | Hellgrün `#66D980`|
| Freitag    | Wochenend-Challenge    | Rot `#FF6666`     |

## Manuell rendern
```bash
node generate.mjs <config.json> out/story.png   # baut das Bild
node send.mjs out/story.png "Caption"           # sendet per Telegram
```
`config.json`: theme, accent, icon, dateLabel, headline, body, handle, cta, headlineSize(optional)

## Telegram einrichten (einmalig)
1. In Telegram **@BotFather** → `/newbot` → Token kopieren.
2. Eigenen neuen Bot öffnen und ihm **eine Nachricht** schreiben (sonst darf er nicht antworten).
3. `botToken` (+ `chatId`) in `telegram.local.json` eintragen.
   chatId ermitteln: `https://api.telegram.org/bot<TOKEN>/getUpdates` öffnen → `chat.id`.

## Geplante Ausführung
Lokaler Scheduled Task `daily-instagram-story`, cron `0 20 * * 0-4` (So–Do, 20:00).
Läuft, solange die Claude-App offen ist; sonst beim nächsten Start nach.

## Stilquelle
Farben/Logo aus `GolfTrackApp/Shared/AppTheme.swift` bzw. `Assets.xcassets/AppLogo`.
Rendering via Puppeteer/Chromium mit echtem SF-Pro (macOS `-apple-system`).
