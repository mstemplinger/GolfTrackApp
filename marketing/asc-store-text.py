#!/usr/bin/env python3
"""Spielt `marketing/app-store-text.md` in App Store Connect ein.

    python3 marketing/asc-store-text.py --issuer <ISSUER-UUID>            # Probelauf
    python3 marketing/asc-store-text.py --issuer <ISSUER-UUID> --apply    # schreiben

Geschrieben werden Untertitel, Werbetext, Schlüsselwörter und Beschreibung –
alle vier hängen an `appStoreVersionLocalizations`, also ein PATCH je Sprache.
Die Release Notes bleiben unangetastet; dafür gibt es `asc-fill-metadata.py`.

Ohne `--apply` wird **nichts** geschrieben: Das Skript zeigt je Sprache und Feld,
was dort steht und was hinkäme. Erst wer den Vergleich gesehen hat, sollte
schreiben.

Die Issuer-ID kommt als Argument herein, der private Schlüssel liegt unter
~/.appstoreconnect/private_keys/ – siehe `asc_api.py`.
"""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from pathlib import Path

from asc_api import APP_ID, ASC, APIError

TEXT_DATEI = Path(__file__).parent / "app-store-text.md"

# Feldname in der API → (Überschriften im Markdown, Grenze von Apple)
FELDER: dict[str, tuple[tuple[str, ...], int]] = {
    "subtitle": (("untertitel", "subtitle", "sous-titre", "sottotitolo", "subtítulo"), 30),
    "promotionalText": (("werbetext", "promotional text", "texte promotionnel",
                         "testo promozionale", "texto promocional"), 170),
    "keywords": (("schlüsselwörter", "keywords", "mots-clés", "parole chiave",
                  "palabras clave"), 100),
    "description": (("beschreibung", "description", "descrizione", "descripción"), 4000),
}

# Sprachkürzel im Markdown → Präfix, mit dem die Locales in ASC beginnen.
# en-US und en-GB bekommen beide den englischen Abschnitt.
SPRACHE_ZU_PRAEFIX = {"de": "de", "en": "en", "fr": "fr", "it": "it", "es": "es"}


def laenge(text: str) -> int:
    """App Store Connect zählt Unicode-Zeichen, nicht Bytes."""
    return len(unicodedata.normalize("NFC", text))


def lies_texte(pfad: Path) -> dict[str, dict[str, str]]:
    """Markdown → {Sprachpräfix: {API-Feld: Text}}. Prüft dabei die Grenzen."""
    roh = pfad.read_text(encoding="utf-8")
    ergebnis: dict[str, dict[str, str]] = {}
    probleme: list[str] = []

    for block in re.split(r"^## ", roh, flags=re.M)[1:]:
        kopf = block.splitlines()[0].strip()
        # „Deutsch (de-DE)" → de
        treffer = re.search(r"\(([a-z]{2})", kopf)
        if not treffer:
            continue
        praefix = SPRACHE_ZU_PRAEFIX.get(treffer.group(1))
        if praefix is None:
            continue

        felder: dict[str, str] = {}
        for abschnitt in re.finditer(r"^### (.+?)\n(.*?)(?=\n### |\Z)", block, flags=re.M | re.S):
            titel = abschnitt.group(1).strip().lower()
            inhalt = abschnitt.group(2).strip()
            for api_feld, (titel_varianten, grenze) in FELDER.items():
                if titel in titel_varianten:
                    if laenge(inhalt) > grenze:
                        probleme.append(
                            f"{kopf} · {api_feld}: {laenge(inhalt)} Zeichen, erlaubt sind {grenze}"
                        )
                    felder[api_feld] = inhalt
                    break
        if felder:
            ergebnis[praefix] = felder

    if probleme:
        raise SystemExit("Abbruch, Text zu lang:\n  " + "\n  ".join(probleme))
    return ergebnis


def bearbeitbare_version(asc: ASC) -> tuple[str, str, str]:
    """Die Version, in die geschrieben wird – Apple erlaubt das nur im Entwurf."""
    versionen = asc.get_all(f"/v1/apps/{APP_ID}/appStoreVersions?limit=20")
    offen = [
        v for v in versionen
        if v["attributes"]["appStoreState"] in {
            "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
            "METADATA_REJECTED", "INVALID_BINARY", "WAITING_FOR_REVIEW",
        }
    ]
    if not offen:
        zustaende = ", ".join(
            f"{v['attributes']['versionString']} = {v['attributes']['appStoreState']}"
            for v in versionen[:5]
        )
        raise SystemExit(
            "Keine bearbeitbare Version gefunden. Vorhanden: " + zustaende +
            "\nEine veröffentlichte Version lässt sich nicht ändern – dafür in App Store "
            "Connect eine neue Version anlegen."
        )
    v = offen[0]
    return v["id"], v["attributes"]["versionString"], v["attributes"]["appStoreState"]


def kurz(text: str, breite: int = 62) -> str:
    einzeilig = " ".join(text.split())
    return einzeilig if len(einzeilig) <= breite else einzeilig[: breite - 1] + "…"


def main() -> None:
    parser = argparse.ArgumentParser(description="Produktseitentexte nach App Store Connect")
    parser.add_argument("--issuer", required=True, help="Issuer-UUID aus App Store Connect")
    parser.add_argument("--apply", action="store_true", help="wirklich schreiben")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    texte = lies_texte(TEXT_DATEI)
    print(f"{TEXT_DATEI.name}: {len(texte)} Sprachen gelesen, alle Felder innerhalb der Grenzen.\n")

    asc = ASC(args.issuer, apply=args.apply, verbose=args.verbose)

    version_id, version, zustand = bearbeitbare_version(asc)
    print(f"Version {version} ({zustand})\n")

    lokalisierungen = asc.get_all(
        f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=50"
    )
    if not lokalisierungen:
        raise SystemExit("Diese Version hat keine Sprachen – in App Store Connect anlegen.")

    geaendert = 0
    for loc in sorted(lokalisierungen, key=lambda x: x["attributes"]["locale"]):
        locale = loc["attributes"]["locale"]
        praefix = locale.split("-")[0]
        neu = texte.get(praefix)
        if neu is None:
            print(f"{locale:8} übersprungen – kein Abschnitt für {praefix!r} in der Textdatei")
            continue

        aenderungen = {
            feld: wert for feld, wert in neu.items()
            if (loc["attributes"].get(feld) or "") != wert
        }
        print(f"{locale}")
        for feld in FELDER:
            if feld not in neu:
                continue
            alt = loc["attributes"].get(feld) or ""
            if feld in aenderungen:
                print(f"  {feld:16} alt  {kurz(alt) if alt else '— leer —'}")
                print(f"  {'':16} neu  {kurz(neu[feld])}  [{laenge(neu[feld])} Zeichen]")
            else:
                print(f"  {feld:16} unverändert")

        if not aenderungen:
            print("  nichts zu tun\n")
            continue

        try:
            asc.patch(f"/v1/appStoreVersionLocalizations/{loc['id']}", {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": loc["id"],
                    "attributes": aenderungen,
                }
            })
        except APIError as e:
            print(f"  ✗ {locale}: {e.detail}\n")
            continue
        geaendert += 1
        print(f"  {'✓ geschrieben' if args.apply else '↑ im Probelauf nicht geschrieben'}\n")

    if args.apply:
        print(f"Fertig: {geaendert} Sprachen geschrieben.")
        print("Zur Kontrolle: python3 marketing/asc-inspect.py --issuer <UUID>")
    else:
        print(f"Probelauf: {geaendert} Sprachen würden geändert.")
        print("Zum Schreiben dasselbe Kommando noch einmal mit --apply.")


if __name__ == "__main__":
    try:
        main()
    except APIError as e:
        sys.exit(str(e))
