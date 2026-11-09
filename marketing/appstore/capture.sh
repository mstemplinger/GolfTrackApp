#!/bin/bash
# Nimmt die Rohbilder für die Store-Bilder im iPhone 17 Pro Max (6,9 Zoll) auf –
# ohne Tippen, über die DEBUG-Schalter GOLFTRACK_OPEN / GOLFTRACK_DEEPLINK.
#
#   ./marketing/appstore/capture.sh <udid> <app-pfad> <de|en> <name> [KEY=WERT …]
#
# Jeder Aufruf startet die App frisch mit Demo-Daten, wartet und fotografiert.
# Bilder landen in marketing/screenshots/<sprache>-69/<name>.png.

set -euo pipefail
UDID="$1"; APP="$2"; LANG_CODE="$3"; NAME="$4"; shift 4
BUNDLE=com.TobiasAufschlaeger.GolfTrackandwatch
DIR="$(cd "$(dirname "$0")/.." && pwd)"

case "$LANG_CODE" in
  de) LANGARGS=(-AppleLanguages '(de-DE)' -AppleLocale de_DE) ;;
  en) LANGARGS=(-AppleLanguages '(en-GB)' -AppleLocale en_GB) ;;
esac

xcrun simctl status_bar "$UDID" override --time "9:41" --dataNetwork wifi --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true

ENVS=()
for kv in "$@"; do ENVS+=("SIMCTL_CHILD_$kv"); done
env "${ENVS[@]+"${ENVS[@]}"}" xcrun simctl launch "$UDID" "$BUNDLE" -seedDemoData YES -unlockAll \
  "${LANGARGS[@]}" >/dev/null
sleep "${WAIT:-7}"
"$DIR/shoot.sh" "$UDID" "$DIR/screenshots/$LANG_CODE-69" "$NAME"
