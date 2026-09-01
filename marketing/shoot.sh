#!/bin/bash
# Nimmt einen Screenshot aus dem Simulator ab und prüft die Pixelmaße direkt.
#
#   ./marketing/shoot.sh <udid> <zielordner> <name>
#
# Bricht ab, wenn die Größe nicht zu einem App-Store-Slot passt – dann merkt man
# es hier und nicht erst beim Upload.

set -euo pipefail

UDID="$1"
OUTDIR="$2"
NAME="$3"
OUT="$OUTDIR/$NAME.png"

mkdir -p "$OUTDIR"
xcrun simctl io "$UDID" screenshot --type=png "$OUT" >/dev/null 2>&1

SIZE=$(python3 -c "
import struct,sys
d=open('$OUT','rb').read(33)
w,h=struct.unpack('>II',d[16:24])
print(f'{w}x{h}')")

case "$SIZE" in
  1320x2868|1290x2796) echo "  ✓ $NAME  ($SIZE)" ;;
  *) echo "  ✗ $NAME hat $SIZE – kein gültiger iPhone-Slot!"; exit 1 ;;
esac
