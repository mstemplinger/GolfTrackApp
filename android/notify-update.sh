#!/bin/sh
# Schickt die Update-Mail zur gerade veröffentlichten APK an alle Eingetragenen.
# Reihenfolge: versionCode erhöhen → sh release.sh → web/deploy/deploy.sh → dieses Skript.
#
#   sh notify-update.sh "Neu: Laufspur im Hintergrund" "Behoben: Absturz beim Scan"
#
# Jede Fassung geht je Adresse nur einmal raus – ein zweiter Aufruf schickt nichts doppelt.
set -eu
NOTES=$(python3 -c 'import json,sys; print(json.dumps({"notes": sys.argv[1:]}))' "$@")
ssh root@178.104.241.202 "TOKEN=\$(grep '^ADMIN_API_TOKEN=' /var/www/golftrack/.env.production | cut -d= -f2-); curl -s -X POST http://127.0.0.1:3200/api/admin/android-update -H \"Authorization: Bearer \$TOKEN\" -H 'content-type: application/json' -d '$NOTES'"
echo
