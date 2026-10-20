#!/bin/sh
# Baut die signierte Release-APK und legt sie für die Website bereit.
#
#   sh release.sh            → APK nach web/public/downloads/, web/src/lib/android.ts neu
#   danach: cd ../web && sh deploy/deploy.sh
#
# Voraussetzung: keystore.properties + golftrack-release.jks in diesem Ordner
# (nicht im Repository – sichern! Ohne denselben Schlüssel lässt sich keine
# Update-APK über eine installierte Version spielen).
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
WEB="$HERE/../web"

test -f "$HERE/keystore.properties" || { echo "keystore.properties fehlt"; exit 1; }

./gradlew -q :app:assembleRelease

APK="$HERE/app/build/outputs/apk/release/app-release.apk"
NAME=$(sed -n 's/.*versionName = "\(.*\)".*/\1/p' app/build.gradle.kts)
CODE=$(sed -n 's/.*versionCode = \([0-9]*\).*/\1/p' app/build.gradle.kts)
FILE="golftrack-$NAME.apk"

mkdir -p "$WEB/public/downloads"
rm -f "$WEB/public/downloads/"*.apk
cp "$APK" "$WEB/public/downloads/$FILE"

SIZE=$(stat -f %z "$APK")
SHA=$(shasum -a 256 "$APK" | cut -d' ' -f1)
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

python3 - "$WEB/src/lib/android.ts" "$FILE" "$NAME" "$CODE" "$SIZE" "$SHA" "$NOW" <<'PY'
import re, sys
path, file, name, code, size, sha, now = sys.argv[1:]
s = open(path).read()
block = f'''= {{
  file: "{file}",
  versionName: "{name}",
  versionCode: {code},
  sizeBytes: {size},
  sha256: "{sha}",
  releasedAt: "{now}",
}};'''
s = re.sub(r"= \{\n  file:.*?\n\};", block, s, flags=re.S)
open(path, "w").write(s)
PY

echo "→ $FILE ($SIZE Bytes, sha256 $SHA)"
echo "Jetzt: cd ../web && sh deploy/deploy.sh"
