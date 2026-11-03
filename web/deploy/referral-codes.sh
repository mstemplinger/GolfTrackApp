#!/bin/sh
# Laedt Apple-Einmalcodes „2 Wochen Pro“ in den Vorrat der Weiterempfehlung
# (Tabelle referral_reward_codes, siehe src/lib/referral.ts). Auf dem Mac auszufuehren.
#
# Die Codes kommen aus: python3.12 marketing/asc-referral-codes.py --issuer … --export codes.txt
# Sie sind einloesbare Gutscheine – die Datei gehoert nicht ins Repository.
#
# Aufruf:  sh deploy/referral-codes.sh codes.txt
# Wiederholbar: schon geladene Codes werden uebersprungen.
set -eu

FILE="${1:?Datei mit Codes angeben}"
REMOTE="${REMOTE:-root@178.104.241.202}"

# Nur die erste Spalte (Apple liefert „CODE,Einloese-Link“), nur gueltige Zeichen.
CODES=$(cut -d, -f1 "$FILE" | tr -cd 'A-Za-z0-9\n' | grep -v '^$' || true)
COUNT=$(printf '%s\n' "$CODES" | grep -c . || true)
[ "$COUNT" -gt 0 ] || { echo "Keine Codes in $FILE"; exit 1; }

echo "→ lade $COUNT Codes nach $REMOTE"
{
  echo "CREATE TEMP TABLE incoming (code text);"
  echo "COPY incoming FROM STDIN;"
  printf '%s\n' "$CODES"
  echo '\.'
  echo "INSERT INTO referral_reward_codes (code) SELECT DISTINCT code FROM incoming ON CONFLICT DO NOTHING;"
  echo "SELECT count(*) FILTER (WHERE assigned_to IS NULL) AS frei, count(*) AS gesamt FROM referral_reward_codes;"
} | ssh "$REMOTE" "sudo -u postgres psql -q -v ON_ERROR_STOP=1 golftrack"
