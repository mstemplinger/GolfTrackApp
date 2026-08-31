#!/bin/sh
# Erzeugt deploy/courses-seed.json aus den eingebauten Plaetzen der iOS-App.
# Auf dem Mac auszufuehren (braucht die Swift-Werkzeuge aus Xcode).
#
# Aufruf:  sh deploy/extract-courses.sh
set -eu

HERE=$(cd "$(dirname "$0")/.." && pwd)
APP=$(cd "$HERE/.." && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT

xcrun swiftc -O -o "$BUILD/extract" \
  "$APP/GolfTrackApp/Data/BundledCourses.swift" \
  "$APP/GolfTrackApp/Data/MinigolfCourses.swift" \
  "$APP/GolfTrackApp/Shared/MinigolfDeepLink.swift" \
  "$HERE/deploy/extract-courses/main.swift"

"$BUILD/extract" > "$HERE/deploy/courses-seed.json"
echo "→ deploy/courses-seed.json geschrieben ($(grep -c '"name"' "$HERE/deploy/courses-seed.json") Plaetze)"
