#!/usr/bin/env python3
"""Prüft, ob Website und Store-Text dieselben Zahlen nennen wie der App-Code.

    python3 tools/check-facts.py

Hintergrund: Platzzahl und Zahl der Spielformen standen an drei Stellen von
Hand – im App-Code, in `web/src/i18n/content.ts` und in
`marketing/app-store-text.md`. Bei jeder Änderung lief eine davon weg; zuletzt
warb die Website mit 19 Spielformen, von denen nur 14 auswählbar waren.

Maßgeblich ist immer der Code. Das Skript zählt dort und meldet jede Stelle,
die etwas anderes behauptet. Exit-Code 1, wenn etwas nicht zusammenpasst –
`web/deploy/deploy.sh` und `marketing/asc-store-text.py` rufen es deshalb auf,
bevor Zahlen nach außen gehen.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

WURZEL = Path(__file__).resolve().parent.parent
BUNDLED = WURZEL / "GolfTrackApp/Data/BundledCourses.swift"
GAMEMODE = WURZEL / "GolfTrackApp/Models/GameMode.swift"
WEBSITE = WURZEL / "web/src/i18n/content.ts"
STORE = WURZEL / "marketing/app-store-text.md"


def zaehle_plaetze() -> int:
    """Einträge in `BundledCourses.all` – jeder beginnt mit `.init(name: "…`."""
    return len(re.findall(r'^\s*\.init\(name: "', BUNDLED.read_text(encoding="utf-8"), re.M))


def zaehle_spielformen() -> int:
    """Fälle, die `GameMode.isAvailable` mit `true` beantwortet.

    Gezählt werden die Fälle des `case …:`-Zweigs vor `return true`; die
    übrigen fallen unter `default` und sind in der App nicht wählbar.
    """
    quelle = GAMEMODE.read_text(encoding="utf-8")
    block = re.search(r"var isAvailable: Bool \{(.*?)\n    \}", quelle, re.S)
    if block is None:
        raise SystemExit("check-facts: isAvailable nicht gefunden – Skript anpassen.")
    wahr = re.search(r"case (.*?):\s*\n\s*return true", block.group(1), re.S)
    if wahr is None:
        raise SystemExit("check-facts: kein `return true`-Zweig in isAvailable.")
    return len(re.findall(r"\.\w+", wahr.group(1)))


def pruefe(text: str, quelle: str, muster: str, erwartet: int, was: str) -> list[str]:
    """Jede Zahl, die vor `muster` steht, muss `erwartet` sein."""
    fehler = []
    for treffer in re.finditer(r"(\d+)\s*" + muster, text):
        gefunden = int(treffer.group(1))
        if gefunden != erwartet:
            zeile = text[: treffer.start()].count("\n") + 1
            fehler.append(f"{quelle}:{zeile}  {was}: {gefunden} statt {erwartet}"
                          f"  ({treffer.group(0).strip()})")
    return fehler


def main() -> int:
    plaetze = zaehle_plaetze()
    formen = zaehle_spielformen()
    print(f"Code: {plaetze} eingebaute Plätze, {formen} spielbare Spielformen")

    website = WEBSITE.read_text(encoding="utf-8")
    store = STORE.read_text(encoding="utf-8")
    fehler: list[str] = []

    # Website
    fehler += pruefe(website, "web/src/i18n/content.ts",
                     r"(?:Golfplätze|Plätze sind eingebaut|courses are built in|courses)",
                     plaetze, "Platzzahl")
    fehler += pruefe(website, "web/src/i18n/content.ts",
                     r"(?:Spielformen|game formats)", formen, "Spielformen")

    # Die Liste auf der Website muss so viele Einträge haben, wie es Formen gibt.
    for sprache, anfang in (("de", website.find("modeGroups")),
                            ("en", website.rfind("modeGroups"))):
        ende = website.find("modesFooter", anfang)
        eintraege = len(re.findall(r'^\s*\["', website[anfang:ende], re.M))
        if eintraege != formen:
            fehler.append(f"web/src/i18n/content.ts  modeGroups ({sprache}): "
                          f"{eintraege} Einträge statt {formen}")

    # Store-Text, alle fünf Sprachen
    fehler += pruefe(store, "marketing/app-store-text.md",
                     r"(?:Golfplätze|courses built in|parcours intégrés|campi già inclusi|campos incluidos)",
                     plaetze, "Platzzahl")
    fehler += pruefe(store, "marketing/app-store-text.md",
                     r"(?:Spielformen|formats:|formules|formule|modalidades)",
                     formen, "Spielformen")

    if fehler:
        print("\nDiese Angaben passen nicht zum Code:")
        for zeile in fehler:
            print("  ✗", zeile)
        print("\nEntweder die Texte anpassen oder – falls der Code sich geändert hat –"
              "\ndie Zahl überall nachziehen. Maßgeblich ist der Code.")
        return 1

    print("Website und Store-Text stimmen mit dem Code überein.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
