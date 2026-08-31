#!/bin/sh
# Bringt golftrack.app auf den Server. Auf dem Mac auszufuehren.
#
# Gebaut wird auf dem Server: Next.js bindet beim Bauen die Umgebung ein, und
# ein auf dem Mac erzeugtes Ergebnis passt nicht zwingend zur Linux-Maschine.
#
# Aufruf:  sh deploy/deploy.sh
set -eu

REMOTE="${REMOTE:-root@178.104.241.202}"
TARGET="${TARGET:-/var/www/golftrack}"
HERE=$(cd "$(dirname "$0")/.." && pwd)

echo "→ uebertrage nach $REMOTE:$TARGET"
ssh "$REMOTE" "mkdir -p $TARGET"

# Quellen, Konfiguration und Abhaengigkeitsliste. Alles Erzeugte bleibt hier:
# node_modules und .next entstehen drueben neu.
rsync -az --delete \
  --exclude node_modules \
  --exclude .next \
  --exclude .pglite \
  --exclude .env.local \
  --exclude .env.production \
  --exclude .git \
  "$HERE/src" "$HERE/public" "$HERE/deploy" \
  "$HERE/package.json" "$HERE/package-lock.json" \
  "$HERE/next.config.ts" "$HERE/tsconfig.json" "$HERE/postcss.config.mjs" \
  "$REMOTE:$TARGET/"

if ! ssh "$REMOTE" "test -f $TARGET/.env.production"; then
  echo
  echo "Abbruch: $TARGET/.env.production fehlt. Einmalig auf dem Server anlegen:"
  echo "  DATABASE_URL, ADMIN_PASSWORD, ADMIN_SECRET, NEXT_PUBLIC_SITE_URL, PORT"
  exit 1
fi

echo "→ installieren und bauen"
# Bewusst `npm install` statt `npm ci`: die Bildbibliothek sharp bringt je
# Betriebssystem andere Binaerpakete mit, und ein auf dem Mac erzeugtes
# Lockfile kennt die Linux-Varianten nicht. Die Fassungen der eigentlichen
# Abhaengigkeiten stehen trotzdem im Lockfile fest.
#
# Mit Entwicklungsabhaengigkeiten: Tailwind und TypeScript werden beim Bauen
# gebraucht. Sie bleiben liegen, damit der naechste Durchlauf schneller ist.
# .next wird verworfen: ein abgebrochener Durchlauf hinterlaesst dort einen
# Zwischenstand, an dem sich der naechste Build verschluckt.
ssh "$REMOTE" "cd $TARGET && npm install --include=dev --no-audit --no-fund && rm -rf .next && npm run build"

echo "→ starten"
ssh "$REMOTE" "cd $TARGET && (pm2 reload golftrack --update-env || pm2 start $TARGET/deploy/ecosystem.config.js) && pm2 save"

echo "→ Probe"
ssh "$REMOTE" "sleep 2; curl -fsS http://127.0.0.1:3200/api/v1/courses | head -c 120; echo"
echo "fertig."
