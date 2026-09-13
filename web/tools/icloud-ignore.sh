#!/bin/sh
# Hält .next und node_modules aus der iCloud-Synchronisierung heraus.
#
# Das Repo liegt unter ~/Documents, und dieser Ordner wird von iCloud
# synchronisiert. iCloud legt dabei Konfliktkopien an – Dateien wie
# `routes.d 2.ts` neben `routes.d.ts`. TypeScript liest sie mit und bricht dann
# mit Fehlern ab, die nichts mit dem Quelltext zu tun haben:
#
#   .next/types/routes.d 2.ts(84,8): error TS2300: Duplicate identifier
#
# Das erweiterte Attribut `com.apple.fileprovider.ignore#P` sagt iCloud, dass es
# einen Ordner in Ruhe lassen soll. Es hängt am Ordner selbst, verschwindet also
# mit ihm – deshalb ruft `npm run dev` und `npm run build` dieses Skript vorher
# auf (siehe `predev`/`prebuild` in der package.json).
#
# Auf dem Server (Linux) gibt es weder iCloud noch `xattr`; dort tut das Skript
# nichts und meldet Erfolg, damit der Bau nicht daran scheitert.

[ "$(uname)" = "Darwin" ] || exit 0
command -v xattr >/dev/null 2>&1 || exit 0

for ordner in .next node_modules; do
    mkdir -p "$ordner"
    xattr -w "com.apple.fileprovider.ignore#P" 1 "$ordner" 2>/dev/null || true
done
exit 0
