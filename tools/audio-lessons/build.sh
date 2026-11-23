#!/bin/sh
# Wandelt die Audio-Lektionen (masters/*.mp3) in AAC um und verteilt sie:
#
#   - Lektion 01 (gratis) kommt ins App-Paket, damit sie direkt nach der
#     Installation auch ohne Netz spielt.
#   - Alle anderen landen in web/public/audio/lessons/<VERSION>/ und werden
#     von golftrack.app ausgeliefert. Die App lädt sie nach dem ersten Start
#     im Hintergrund (AudioLessonStore.swift).
#
# Sprache in Mono braucht keine 128 kbit/s: AAC mit 64 kbit/s klingt gleich
# und ist halb so groß.
#
# Wird eine Lektion inhaltlich ersetzt, VERSION hochzählen und denselben Wert
# in AudioLessonStore.remoteVersion eintragen. Sonst behalten Geräte, die die
# alte Fassung schon geladen haben, diese für immer.
#
# Aufruf aus dem Repo-Root:  sh tools/audio-lessons/build.sh
set -eu

VERSION=v1
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BUNDLE="$ROOT/GolfTrackApp/Resources/Audio"
WEB="$ROOT/web/public/audio/lessons/$VERSION"
BUNDLED="01_grundlagen_griff"

mkdir -p "$BUNDLE" "$WEB"

for src in "$HERE"/masters/*.mp3; do
  name=$(basename "$src" .mp3)
  if [ "$name" = "$BUNDLED" ]; then
    out="$BUNDLE/$name.m4a"
  else
    out="$WEB/$name.m4a"
  fi
  afconvert -f m4af -d aac -b 64000 -c 1 "$src" "$out"
  printf '%-36s %6s KB\n' "$name" "$(($(stat -f %z "$out") / 1024))"
done

echo
du -sh "$BUNDLE" "$WEB"
