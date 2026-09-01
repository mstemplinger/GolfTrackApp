#!/usr/bin/env python3
"""Zeigt den Ist-Zustand der App in App Store Connect. Ändert nichts.

    python3 marketing/asc-inspect.py --issuer <ISSUER-UUID>

Beantwortet drei Fragen:
  1. Welche Versionen gibt es und in welchem Zustand sind sie?
  2. Welche Screenshot-Slots (Display-Typen) sind pro Sprache gefüllt, welche leer?
  3. Gibt es schon benutzerdefinierte Produktseiten, und wie sehen sie aus?

Alle Abfragen sind GETs. Endpunkte, die die API nicht kennt oder für die der
Key keine Rechte hat, werden gemeldet statt das Skript abzubrechen.
"""

from __future__ import annotations

import argparse

from asc_api import APP_ID, ASC, APIError


def probe(asc: ASC, path: str, label: str) -> list[dict]:
    """GET, das bei 403/404 nicht abbricht – wir tasten hier bewusst ab."""
    try:
        return asc.get_all(path)
    except APIError as e:
        if e.status in (403, 404):
            print(f"    ⚠ {label}: HTTP {e.status} – {e.detail}")
            return []
        raise


def show_screenshot_sets(asc: ASC, loc_id: str, indent: str) -> None:
    sets = probe(asc, f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets",
                 "Screenshot-Sets")
    if not sets:
        print(f"{indent}(keine Screenshot-Sets)")
        return
    for s in sets:
        display = s["attributes"].get("screenshotDisplayType") or "?"
        shots = probe(asc, f"/v1/appScreenshotSets/{s['id']}/appScreenshots", "Screenshots")
        sizes = []
        for shot in shots:
            a = shot["attributes"]
            state = (a.get("assetDeliveryState") or {}).get("state", "?")
            sizes.append(f"{a.get('imageAsset', {}).get('width', '?')}"
                         f"×{a.get('imageAsset', {}).get('height', '?')} [{state}]")
        print(f"{indent}{display}: {len(shots)} Bild(er)")
        for size in sizes:
            print(f"{indent}  · {size}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--issuer", required=True, help="Issuer-ID aus App Store Connect")
    ap.add_argument("--screenshots", action="store_true",
                    help="auch die Screenshot-Sets je Sprache auflisten (viele Aufrufe)")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    asc = ASC(args.issuer, apply=False, verbose=args.verbose)

    print("═" * 70)
    print("APP")
    print("═" * 70)
    app = asc.get(f"/v1/apps/{APP_ID}")["data"]
    a = app["attributes"]
    print(f"  {a.get('name')}  ({a.get('bundleId')})")
    print(f"  Primäre Sprache: {a.get('primaryLocale')}   SKU: {a.get('sku')}")

    print()
    print("═" * 70)
    print("APP-STORE-VERSIONEN")
    print("═" * 70)
    versions = probe(asc, f"/v1/apps/{APP_ID}/appStoreVersions?limit=10", "Versionen")
    for v in versions:
        va = v["attributes"]
        print(f"\n  {va.get('versionString')}  –  {va.get('appStoreState')}"
              f"  (Release: {va.get('releaseType')})")
        locs = probe(asc, f"/v1/appStoreVersions/{v['id']}/appStoreVersionLocalizations",
                     "Lokalisierungen")
        codes = sorted(l["attributes"].get("locale", "?") for l in locs)
        print(f"    Sprachen ({len(codes)}): {', '.join(codes)}")
        if args.screenshots:
            for loc in locs:
                print(f"    ── {loc['attributes'].get('locale')}")
                show_screenshot_sets(asc, loc["id"], "       ")

    print()
    print("═" * 70)
    print("BENUTZERDEFINIERTE PRODUKTSEITEN")
    print("═" * 70)
    pages = probe(asc, f"/v1/apps/{APP_ID}/appCustomProductPages", "Produktseiten")
    if not pages:
        print("  Keine vorhanden. (Kontingent: 35 pro App)")
    for p in pages:
        pa = p["attributes"]
        print(f"\n  „{pa.get('name')}\"   sichtbar={pa.get('visible')}   id={p['id']}")
        pvs = probe(asc, f"/v1/appCustomProductPages/{p['id']}/appCustomProductPageVersions",
                    "Seiten-Versionen")
        for pv in pvs:
            pva = pv["attributes"]
            print(f"    Version {pva.get('version')}  –  {pva.get('state')}"
                  f"  deepLink={pva.get('deepLink')}")
            plocs = probe(
                asc,
                f"/v1/appCustomProductPageVersions/{pv['id']}/appCustomProductPageLocalizations",
                "Seiten-Lokalisierungen")
            for pl in plocs:
                pla = pl["attributes"]
                text = (pla.get("promotionalText") or "").replace("\n", " ")
                print(f"      {pla.get('locale')}: {text[:60] or '(kein Werbetext)'}")

    print()
    print("Fertig. Es wurde nichts geändert.")


if __name__ == "__main__":
    main()
