#!/usr/bin/env python3
"""Lädt Kopfzeile + Suchergebnis-Bild in die Asset-Bibliothek und setzt sie an eine Version.

    python3.12 marketing/asc-header.py --issuer <UUID> --version 2.9            # Probelauf
    python3.12 marketing/asc-header.py --issuer <UUID> --version 2.9 --apply

Bilder kommen aus `marketing/appstore/out/header/header-<de|en>-5244x2950.png`
(Generator `appstore/header.mjs`). 5244×2950 ist Apples „universelles“ Format: ein
Bild passt für PRODUCT_PAGE_HEADER_ASSET (21:9-Ausschnitt), APP_STORE_SEARCH_RESULTS_ASSET
(3:2-Ausschnitt) und RETENTION_MESSAGE_ASSET.

de-DE bekommt die deutsche Oberfläche, alle übrigen Sprachen der Version die englische.
Je Sprache und Platz ist nur ein Bild erlaubt; ein vorhandenes ersetzt das Skript
(Platzierung löschen, neue anlegen). Die Bilder gehen mit der Version zur Prüfung.

Ablauf der API: Bild reservieren (POST appAssetLibraryImages, Kategorie CREATIVE_ASSETS)
→ Bytes per uploadOperations → PATCH uploaded=true → warten bis PREPARE_FOR_SUBMISSION
→ POST appAssetLibraryPlacements je Sprache und Platz.
"""

from __future__ import annotations

import argparse
import time
from pathlib import Path

from asc_api import APP_ID, ASC

HIER = Path(__file__).parent
BILDER = {lang: HIER / "appstore" / "out" / "header" / f"header-{lang}-5244x2950.png" for lang in ("de", "en")}
PLAETZE = ["PRODUCT_PAGE_HEADER_ASSET", "APP_STORE_SEARCH_RESULTS_ASSET"]
GRUPPE = "DEFAULT_PROFILE"


def sprache_bild(locale: str) -> str:
    return "de" if locale.startswith("de") else "en"


def hochladen(asc: ASC, bibliothek: str, lang: str) -> str | None:
    datei = BILDER[lang]
    name = f"Kopfzeile {lang} ({datei.stat().st_mtime_ns // 10**9})"
    for b in asc.get_all(f"/v1/appAssetLibraries/{bibliothek}/images?filter[category]=CREATIVE_ASSETS&limit=200"):
        if b["attributes"].get("referenceName") == name and b["attributes"].get("state") not in ("FAILED", "AWAITING_UPLOAD"):
            print(f"   {lang}: steht schon in der Bibliothek ({b['id']}, {b['attributes']['state']})")
            return b["id"]
    blob = datei.read_bytes()
    print(f"   {lang}: {datei.name} hochladen ({len(blob) // 1024} KB)")
    antwort = asc.post("/v1/appAssetLibraryImages", {
        "data": {
            "type": "appAssetLibraryImages",
            "attributes": {"fileName": datei.name, "fileSize": len(blob),
                           "category": "CREATIVE_ASSETS", "referenceName": name},
            "relationships": {"assetLibrary": {"data": {"type": "appAssetLibraries", "id": bibliothek}}},
        }
    })
    if not antwort:
        return None
    bild = antwort["data"]
    asc.upload(bild["attributes"]["uploadOperations"], blob)
    asc.patch(f"/v1/appAssetLibraryImages/{bild['id']}", {
        "data": {"type": "appAssetLibraryImages", "id": bild["id"], "attributes": {"uploaded": True}}
    })
    return bild["id"]


def warten(asc: ASC, bild_id: str) -> None:
    for _ in range(110):
        at = asc.get(f"/v1/appAssetLibraryImages/{bild_id}")["data"]["attributes"]
        if at["state"] in ("PREPARE_FOR_SUBMISSION", "APPROVED", "READY_FOR_REVIEW", "WAITING_FOR_REVIEW"):
            print(f"   {bild_id}: {at['state']}, {at.get('imageAsset', {}).get('width')}×{at.get('imageAsset', {}).get('height')}")
            return
        if at["state"] == "FAILED":
            raise SystemExit(f"Verarbeitung fehlgeschlagen: {at.get('stateDetails')}")
        time.sleep(5)
    raise SystemExit(f"{bild_id} nach 9 Minuten noch nicht verarbeitet")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--issuer", required=True)
    ap.add_argument("--version", required=True)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    for lang, p in BILDER.items():
        if not p.exists():
            raise SystemExit(f"{p} fehlt – erst `node ../appstore/header.mjs all` in marketing/flyer")
    asc = ASC(args.issuer, apply=args.apply)

    version = next((v for v in asc.get_all(f"/v1/apps/{APP_ID}/appStoreVersions?limit=20")
                    if v["attributes"]["versionString"] == args.version), None)
    if not version:
        raise SystemExit(f"Version {args.version} nicht gefunden")
    print(f"Version {args.version}: {version['attributes']['appStoreState']}")
    bibliothek = asc.get(f"/v1/apps/{APP_ID}/assetLibrary")["data"]["id"]

    print("── Bibliothek ──")
    bilder = {lang: hochladen(asc, bibliothek, lang) for lang in BILDER}
    if args.apply:
        for b in bilder.values():
            warten(asc, b)

    print("── Platzierungen ──")
    for lok in asc.get_all(f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations"):
        locale = lok["attributes"]["locale"]
        lang = sprache_bild(locale)
        vorhanden = asc.get_all(f"/v1/appStoreVersionLocalizations/{lok['id']}/placements?include=image&limit=50")
        for platz in PLAETZE:
            alt = [p for p in vorhanden if p["attributes"]["placementType"] == platz]
            bild_alt = [(p.get("relationships", {}).get("image", {}).get("data") or {}).get("id") for p in alt]
            if bilder[lang] and bild_alt == [bilder[lang]]:
                print(f"   {locale:6} {platz}: schon gesetzt")
                continue
            for p in alt:
                print(f"   {locale:6} {platz}: altes Bild entfernen")
                asc.delete(f"/v1/appAssetLibraryPlacements/{p['id']}")
            print(f"   {locale:6} {platz}: Bild {lang}")
            asc.post("/v1/appAssetLibraryPlacements", {
                "data": {
                    "type": "appAssetLibraryPlacements",
                    "attributes": {"placementType": platz, "placementGroup": GRUPPE},
                    "relationships": {
                        "image": {"data": {"type": "appAssetLibraryImages", "id": bilder[lang] or "?"}},
                        "appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": lok["id"]}},
                    },
                }
            })
    if not args.apply:
        print("\nProbelauf – nichts geschrieben. Zum Anlegen dasselbe Kommando mit --apply.")


if __name__ == "__main__":
    main()
