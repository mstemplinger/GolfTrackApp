#!/usr/bin/env python3
"""Spielt `marketing/app-store-text.md` in App Store Connect ein.

    python3 marketing/asc-store-text.py --issuer <ISSUER-UUID>            # Probelauf
    python3 marketing/asc-store-text.py --issuer <ISSUER-UUID> --apply    # schreiben

Geschrieben werden Untertitel, Werbetext, Schlüsselwörter und Beschreibung –
alle vier hängen an `appStoreVersionLocalizations`, also ein PATCH je Sprache.
Sprachen, die es dort noch nicht gibt, werden angelegt: am 11.09.2026 stand die
Produktseite nur auf Deutsch, alle übrigen Storefronts zeigten denselben Text.
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
#
# Die vier Felder liegen an **zwei** Ressourcen, und Apple ist da streng:
# Beschreibung, Schlüsselwörter und Werbetext hängen an der Version
# (`appStoreVersionLocalizations`), der Untertitel dagegen an den
# App-Informationen (`appInfoLocalizations`, zusammen mit Name und
# Datenschutzadresse). Wer den Untertitel an die Version schickt, bekommt
# „'subtitle' is not an attribute on the resource".
FELDER: dict[str, tuple[tuple[str, ...], int]] = {
    "promotionalText": (("werbetext", "promotional text", "texte promotionnel",
                         "testo promozionale", "texto promocional"), 170),
    "keywords": (("schlüsselwörter", "keywords", "mots-clés", "parole chiave",
                  "palabras clave"), 100),
    "description": (("beschreibung", "description", "descrizione", "descripción"), 4000),
}

INFO_FELDER: dict[str, tuple[tuple[str, ...], int]] = {
    "subtitle": (("untertitel", "subtitle", "sous-titre", "sottotitolo", "subtítulo"), 30),
}

ALLE_FELDER = {**FELDER, **INFO_FELDER}

# Sprachkürzel im Markdown → Präfix, mit dem die Locales in ASC beginnen.
# en-US und en-GB bekommen beide den englischen Abschnitt.
SPRACHE_ZU_PRAEFIX = {"de": "de", "en": "en", "fr": "fr", "it": "it", "es": "es"}

# Welche Sprachen die Produktseite haben soll. Fehlt eine, wird sie angelegt –
# am 11.09.2026 gab es nur de-DE, alle anderen Storefronts zeigten den
# deutschen Text. Die Schreibweisen sind die von Apple (Italienisch ohne Land).
ZIEL_LOCALES = {"de": "de-DE", "en": "en-US", "fr": "fr-FR", "it": "it", "es": "es-ES"}


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
            for api_feld, (titel_varianten, grenze) in ALLE_FELDER.items():
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


def schreibe_untertitel(asc: ASC, texte: dict[str, dict[str, str]], apply: bool) -> int:
    """Der Untertitel hängt an den App-Informationen, nicht an der Version."""
    infos = asc.get_all(f"/v1/apps/{APP_ID}/appInfos?limit=10")
    offen = [i for i in infos
             if i["attributes"].get("appStoreState") not in {"READY_FOR_SALE", "REPLACED_WITH_NEW_INFO"}]
    if not offen:
        print("\nUntertitel übersprungen – keine bearbeitbaren App-Informationen.")
        return 0
    info_id = offen[0]["id"]

    print("\n═══ Untertitel (App-Informationen) ═══")
    lokal = asc.get_all(f"/v1/appInfos/{info_id}/appInfoLocalizations?limit=50")
    vorhanden = {l["attributes"]["locale"].split("-")[0]: l for l in lokal}
    anzahl = 0

    for praefix, felder in sorted(texte.items()):
        untertitel = felder.get("subtitle")
        if untertitel is None:
            continue
        loc = vorhanden.get(praefix)
        if loc is not None:
            alt_wert = loc["attributes"].get("subtitle") or ""
            if alt_wert == untertitel:
                print(f"{loc['attributes']['locale']:8} unverändert")
                continue
            print(f"{loc['attributes']['locale']:8} alt  {alt_wert or '— leer —'}")
            print(f"{'':8} neu  {untertitel}")
            ziel = f"/v1/appInfoLocalizations/{loc['id']}"
            body = {"data": {"type": "appInfoLocalizations", "id": loc["id"],
                             "attributes": {"subtitle": untertitel}}}
            try:
                asc.patch(ziel, body)
            except APIError as e:
                print(f"  ✗ {e.detail}")
                continue
        else:
            locale = ZIEL_LOCALES[praefix]
            print(f"{locale:8} wird angelegt mit  {untertitel}")
            body = {"data": {"type": "appInfoLocalizations",
                             "attributes": {"locale": locale, "subtitle": untertitel},
                             "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info_id}}}}}
            try:
                asc.post("/v1/appInfoLocalizations", body)
            except APIError as e:
                print(f"  ✗ {e.detail}")
                continue
        anzahl += 1
    return anzahl


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
            if feld in FELDER and (loc["attributes"].get(feld) or "") != wert
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

    # Fehlende Sprachen anlegen – sonst bliebe es beim deutschen Text für alle.
    vorhanden = {loc["attributes"]["locale"].split("-")[0] for loc in lokalisierungen}
    for praefix, locale in sorted(ZIEL_LOCALES.items()):
        if praefix in vorhanden or praefix not in texte:
            continue
        print(f"{locale} – noch nicht vorhanden, wird angelegt")
        for feld, wert in texte[praefix].items():
            print(f"  {feld:16} {kurz(wert)}  [{laenge(wert)} Zeichen]")
        try:
            asc.post("/v1/appStoreVersionLocalizations", {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": {
                        "locale": locale,
                        **{f: w for f, w in texte[praefix].items() if f in FELDER},
                    },
                    "relationships": {
                        "appStoreVersion": {
                            "data": {"type": "appStoreVersions", "id": version_id}
                        }
                    },
                }
            })
        except APIError as e:
            print(f"  ✗ {locale}: {e.detail}\n")
            continue
        geaendert += 1
        print(f"  {'✓ angelegt' if args.apply else '↑ im Probelauf nicht angelegt'}\n")

    geaendert += schreibe_untertitel(asc, texte, args.apply)

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
