#!/bin/sh
# Hält erzeugte Ordner aus der iCloud-Synchronisierung heraus.
#
# Das Repo liegt unter ~/Documents, und dieser Ordner wird von iCloud
# synchronisiert. Bei Ordnern, in denen tausende Dateien in Sekunden entstehen,
# legt iCloud dabei Konfliktkopien an – Dateien wie `routes.d 2.ts` neben
# `routes.d.ts`. Werkzeuge lesen sie mit und brechen dann mit Fehlern ab, die
# nichts mit dem Quelltext zu tun haben:
#
#   .next/types/routes.d 2.ts(84,8): error TS2300: Duplicate identifier
#
# Das erweiterte Attribut `com.apple.fileprovider.ignore#P` sagt iCloud, dass es
# einen Ordner in Ruhe lassen soll. Es hängt am Ordner selbst, verschwindet also
# mit ihm – nach einem `rm -rf` muss es neu gesetzt werden. Deshalb ruft die
# Web-Seite das Skript vor jedem `npm run dev` und `npm run build` auf, wo genau
# das mit `.next` regelmäßig passiert.
#
# Aufruf ohne Angaben: alle bekannten Ordner des Repos. Mit Angaben: genau die
# genannten Ordner, relativ zum Arbeitsverzeichnis.
#
#   sh tools/icloud-ignore.sh
#   sh tools/icloud-ignore.sh .next node_modules
#
# Ausserhalb von macOS (etwa auf dem Server) gibt es weder iCloud noch `xattr`;
# dort tut das Skript nichts und meldet Erfolg, damit kein Bau daran scheitert.

[ "$(uname)" = "Darwin" ] || exit 0
command -v xattr >/dev/null 2>&1 || exit 0

markieren() {
    # Nur vorhandene Ordner. Ein fehlender ist kein Fehler: er entsteht erst
    # beim naechsten Lauf, und dann setzt der naechste Aufruf das Attribut.
    [ -d "$1" ] || return 0
    xattr -w "com.apple.fileprovider.ignore#P" 1 "$1" 2>/dev/null || true
}

if [ "$#" -gt 0 ]; then
    for ordner in "$@"; do markieren "$ordner"; done
    exit 0
fi

WURZEL=$(cd "$(dirname "$0")/.." && pwd)

# Die Web-Seite: `.next` entsteht bei jedem Bau neu, `node_modules` bei jedem
# `npm install`. Beide werden angelegt, falls sie fehlen – so traegt das
# Attribut schon, bevor die erste Datei darin landet.
for ordner in "$WURZEL/web/.next" "$WURZEL/web/node_modules"; do
    mkdir -p "$ordner"
    markieren "$ordner"
done

# Das Marketing: Abhaengigkeiten, erzeugte Bilder und Videos, Pythons Zwischen-
# stand. Die Generatoren legen ihre Ordner selbst an, deshalb hier nur
# markieren, was schon da ist.
markieren "$WURZEL/marketing/__pycache__"
for ordner in "$WURZEL"/marketing/*/; do
    markieren "$ordner/node_modules"
    markieren "$ordner/out"
done

exit 0
