#!/usr/bin/env python3
"""Lädt Kopfzeile + Suchergebnis-Bild in die Asset-Bibliothek und setzt sie an eine Version.

    python3.12 marketing/asc-header.py --issuer <UUID> --version 2.9            # Probelauf
    python3.12 marketing/asc-header.py --issuer <UUID> --version 2.9 --apply

Bilder kommen aus `marketing/appstore/out/header/` (Generator `appstore/header.mjs`):
- Kopfzeile  `header-<de|en>-5244x2950.png` – Apples „universelles“ 16:9-Format,
  der App Store schneidet daraus das 21:9-Band der Produktseite.
- Suche      `search-<de|en>-3840x2560.png` – eigenes 3:2-Bild. Das universelle Bild
  taugt dort nicht: Die Suche zeigt nur einen flachen Streifen (~3:1, ~330 pt breit),
  drei kleine Geräte waren darin unlesbar (Gerätevorschau in ASC, 2026-11-09).

de-DE bekommt die deutsche Oberfläche, alle übrigen Sprachen der Version die englische.
Je Sprache und Platz ist nur ein Bild erlaubt; ein anderes ersetzt das Skript
(Platzierung löschen, neue anlegen). Die Bilder gehen mit der Version zur Prüfung.
Schon hochgeladene Dateien erkennt es an Dateiname + Größe und lädt sie nicht erneut.

Ablauf der API: Bild reservieren (POST appAssetLibraryImages, Kategorie CREATIVE_ASSETS)
→ Bytes per uploadOperations → PATCH uploaded=true → warten bis PREPARE_FOR_SUBMISSION
(kann über 5 Minuten dauern) → POST appAssetLibraryPlacements je Sprache und Platz.
"""

from __future__ import annotations

import argparse
import time
from pathlib import Path

from asc_api import APP_ID, ASC

ORDNER = Path(__file__).parent / "appstore" / "out" / "header"
PLAETZE = {
    "PRODUCT_PAGE_HEADER_ASSET": "header-{lang}-5244x2950.png",
    "APP_STORE_SEARCH_RESULTS_ASSET": "search-{lang}-3840x2560.png",
}
SPRACHEN = ("de", "en")
GRUPPE = "DEFAULT_PROFILE"


def sprache_bild(locale: str) -> str:
    return "de" if locale.startswith("de") else "en"


def hochladen(asc: ASC, bibliothek: str, vorhanden: list[dict], datei: Path) -> str | None:
    blob = datei.read_bytes()
    for b in vorhanden:
        at = b["attributes"]
        if (at.get("fileName"), at.get("fileSize")) == (datei.name, len(blob)) \
                and at.get("state") not in ("FAILED", "AWAITING_UPLOAD"):
            print(f"   {datei.name}: steht schon in der Bibliothek ({at['state']})")
            return b["id"]
    print(f"   {datei.name}: hochladen ({len(blob) // 1024} KB)")
    antwort = asc.post("/v1/appAssetLibraryImages", {
        "data": {
            "type": "appAssetLibraryImages",
            "attributes": {"fileName": datei.name, "fileSize": len(blob),
                           "category": "CREATIVE_ASSETS", "referenceName": datei.stem},
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
            groesse = at.get("imageAsset") or {}
            print(f"   {at['fileName']}: {at['state']}, {groesse.get('width')}×{groesse.get('height')}")
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
    dateien = {(platz, lang): ORDNER / muster.format(lang=lang)
               for platz, muster in PLAETZE.items() for lang in SPRACHEN}
    for p in dateien.values():
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
    vorhanden = asc.get_all(f"/v1/appAssetLibraries/{bibliothek}/images?filter[category]=CREATIVE_ASSETS&limit=200")
    bilder = {schluessel: hochladen(asc, bibliothek, vorhanden, datei) for schluessel, datei in dateien.items()}
    if args.apply:
        for b in set(bilder.values()):
            warten(asc, b)

    print("── Platzierungen ──")
    for lok in asc.get_all(f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations"):
        locale = lok["attributes"]["locale"]
        lang = sprache_bild(locale)
        gesetzt = asc.get_all(f"/v1/appStoreVersionLocalizations/{lok['id']}/placements?include=image&limit=50")
        for platz in PLAETZE:
            neu = bilder[(platz, lang)]
            alt = [p for p in gesetzt if p["attributes"]["placementType"] == platz]
            bild_alt = [(p.get("relationships", {}).get("image", {}).get("data") or {}).get("id") for p in alt]
            if neu and bild_alt == [neu]:
                print(f"   {locale:6} {platz}: schon gesetzt")
                continue
            for p in alt:
                print(f"   {locale:6} {platz}: altes Bild entfernen")
                asc.delete(f"/v1/appAssetLibraryPlacements/{p['id']}")
            print(f"   {locale:6} {platz}: {dateien[(platz, lang)].name}")
            asc.post("/v1/appAssetLibraryPlacements", {
                "data": {
                    "type": "appAssetLibraryPlacements",
                    "attributes": {"placementType": platz, "placementGroup": GRUPPE},
                    "relationships": {
                        "image": {"data": {"type": "appAssetLibraryImages", "id": neu or "?"}},
                        "appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": lok["id"]}},
                    },
                }
            })
    if not args.apply:
        print("\nProbelauf – nichts geschrieben. Zum Anlegen dasselbe Kommando mit --apply.")


if __name__ == "__main__":
    main()
