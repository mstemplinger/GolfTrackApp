#!/usr/bin/env python3
"""Lädt die gestalteten 6,9-Zoll-Store-Bilder an eine bearbeitbare Version.

Nimmt die Ausgabe von `appstore/store-shots.mjs` (`appstore/out/<sprache>/NN-*.png`)
und ersetzt damit den 6,9-Zoll-Bildersatz (API: APP_IPHONE_67) der gewählten Sprache. Andere
Bildersätze (6,5 Zoll, iPad, Watch) bleiben unberührt. Die Reihenfolge folgt den
Dateinamen.

    python3.12 marketing/asc-store-screenshots.py --issuer <UUID> --version 2.9 \\
        --locale de-DE --dir marketing/appstore/out/de [--create-version] [--apply]

Ohne `--apply` nur Probelauf. `--create-version` legt die Version als Entwurf an,
falls es sie noch nicht gibt.
"""

from __future__ import annotations

import argparse
import time
from pathlib import Path

from asc_api import APP_ID, ASC, md5_hex, png_size

# Der 6,9-Zoll-Slot der Weboberfläche heißt in der API APP_IPHONE_67;
# APP_IPHONE_69 lehnt /v1/appScreenshotSets als ungültig ab.
DISPLAY = "APP_IPHONE_67"
SIZE = (1320, 2868)


def find_version(asc: ASC, version: str) -> dict | None:
    for v in asc.get_all(f"/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS"
                         f"&filter[versionString]={version}"):
        return v
    return None


def create_version(asc: ASC, version: str) -> dict | None:
    created = asc.post("/v1/appStoreVersions", {
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": version},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    return created.get("data")


def upload(asc: ASC, set_id: str, path: Path) -> str:
    blob = path.read_bytes()
    shot = asc.post("/v1/appScreenshots", {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": path.name, "fileSize": len(blob)},
            "relationships": {
                "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}
            },
        }
    })["data"]
    asc.upload(shot["attributes"]["uploadOperations"], blob)
    asc.patch(f"/v1/appScreenshots/{shot['id']}", {
        "data": {
            "type": "appScreenshots",
            "id": shot["id"],
            "attributes": {"uploaded": True, "sourceFileChecksum": md5_hex(blob)},
        }
    })
    print(f"    ✓ {path.name}")
    return shot["id"]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--issuer", required=True)
    ap.add_argument("--version", required=True)
    ap.add_argument("--locale", required=True)
    ap.add_argument("--dir", required=True, type=Path)
    ap.add_argument("--create-version", action="store_true")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    files = sorted(args.dir.glob("*.png"))
    if not 1 <= len(files) <= 10:
        raise SystemExit(f"{len(files)} Bilder in {args.dir} – Apple erlaubt 1 bis 10")
    for f in files:
        if png_size(f) != SIZE:
            raise SystemExit(f"{f.name} hat {png_size(f)}, verlangt sind {SIZE}")

    asc = ASC(args.issuer, apply=args.apply)
    version = find_version(asc, args.version)
    if version is None:
        if not args.create_version:
            raise SystemExit(f"Version {args.version} gibt es nicht (--create-version legt sie an)")
        print(f"Version {args.version} wird als Entwurf angelegt")
        version = create_version(asc, args.version)
        if version is None:   # Probelauf
            print(f"  [Probelauf] {len(files)} Bilder würden nach {args.locale}/{DISPLAY} gehen")
            return
    state = version["attributes"]["appStoreState"]
    print(f"Version {args.version}: {state}")
    if state not in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"):
        raise SystemExit("Version ist nicht bearbeitbar")

    locs = asc.get_all(f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations")
    loc = next((l for l in locs if l["attributes"]["locale"] == args.locale), None)
    if loc is None:
        raise SystemExit(f"Sprache {args.locale} fehlt an der Version "
                         f"(vorhanden: {[l['attributes']['locale'] for l in locs]})")

    sets = asc.get_all(f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")
    shot_set = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == DISPLAY), None)
    old = asc.get_all(f"/v1/appScreenshotSets/{shot_set['id']}/appScreenshots") if shot_set else []
    print(f"  {args.locale}/{DISPLAY}: {len(old)} alte Bilder ersetzen durch {len(files)} neue")
    if not args.apply:
        for f in files:
            print(f"    [Probelauf] {f.name}")
        return

    for s in old:
        asc.delete(f"/v1/appScreenshots/{s['id']}")
    if shot_set is None:
        shot_set = asc.post("/v1/appScreenshotSets", {
            "data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": DISPLAY},
                "relationships": {"appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}},
            }
        })["data"]

    ids = [upload(asc, shot_set["id"], f) for f in files]
    # Reihenfolge ausdrücklich setzen – die Anlegereihenfolge ist nicht garantiert.
    asc.patch(f"/v1/appScreenshotSets/{shot_set['id']}/relationships/appScreenshots",
              {"data": [{"type": "appScreenshots", "id": i} for i in ids]})

    # Apple verarbeitet die Bilder nach; erst COMPLETE heißt angenommen.
    for _ in range(30):
        shots = asc.get_all(f"/v1/appScreenshotSets/{shot_set['id']}/appScreenshots")
        states = [s["attributes"]["assetDeliveryState"]["state"] for s in shots]
        if all(st == "COMPLETE" for st in states):
            print(f"  alle {len(shots)} Bilder COMPLETE")
            return
        if "FAILED" in states:
            for s in shots:
                d = s["attributes"]["assetDeliveryState"]
                if d["state"] == "FAILED":
                    print(f"  ✗ {s['attributes']['fileName']}: {d.get('errors')}")
            raise SystemExit(1)
        time.sleep(5)
    print(f"  noch in Verarbeitung: {states}")


if __name__ == "__main__":
    main()
