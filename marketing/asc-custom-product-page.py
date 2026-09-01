#!/usr/bin/env python3
"""Legt benutzerdefinierte Produktseiten (Custom Product Pages) über die ASC-API an.

    # 1. Nur prüfen: Bildgrößen und Texte gegen Apples Regeln, ohne Netzzugriff
    python3 marketing/asc-custom-product-page.py --check-only

    # 2. Probelauf gegen die API: liest, zeigt was passieren würde, schreibt nichts
    python3 marketing/asc-custom-product-page.py --issuer <ISSUER-UUID>

    # 3. Anlegen
    python3 marketing/asc-custom-product-page.py --issuer <ISSUER-UUID> --apply

Quelle der Texte und Bildzuordnung ist marketing/cpp-pages.json, damit es keine
zweite Stelle gibt, die auseinanderlaufen kann.

Absichtlich NICHT enthalten: das Einreichen zur Prüfung. Wie beim Release-Skript
bleibt „Zur Prüfung freigeben" ein bewusster Klick im Browser. Bis dahin sind die
Seiten Entwürfe und nach außen unsichtbar.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from asc_api import APP_ID, ASC, APIError, md5_hex, png_size

SCREENSHOT_ROOT = Path(__file__).parent / "screenshots"
CONFIG_PATH = Path(__file__).parent / "cpp-pages.json"

PROMO_TEXT_LIMIT = 170
MAX_SCREENSHOTS_PER_SET = 10

# Von Apple akzeptierte Pixelmaße je Display-Typ (Hochformat).
ACCEPTED_SIZES = {
    "APP_IPHONE_69": [(1290, 2796), (1320, 2868)],
    "APP_IPHONE_67": [(1290, 2796)],
    "APP_IPHONE_65": [(1242, 2688), (1284, 2778)],
    "APP_IPHONE_55": [(1242, 2208)],
    "APP_IPAD_PRO_3GEN_129": [(2048, 2732), (2064, 2752)],
    "APP_IPAD_PRO_129": [(2048, 2732)],
    "APP_WATCH_ULTRA": [(410, 502), (422, 514)],
}


# ── Prüfung ohne Netz ────────────────────────────────────────────────────────

def validate(config: dict) -> list[str]:
    """Sammelt alle Probleme, statt beim ersten abzubrechen."""
    problems: list[str] = []
    display = config.get("displayType", "")
    accepted = ACCEPTED_SIZES.get(display)
    if not accepted:
        problems.append(f"Unbekannter displayType „{display}\". "
                        f"Bekannt: {', '.join(sorted(ACCEPTED_SIZES))}")
        return problems

    allowed = ", ".join(f"{w}×{h}" for w, h in accepted)
    pages = config.get("pages", [])
    if not pages:
        problems.append("Keine Seiten in cpp-pages.json definiert.")
    if len(pages) > 35:
        problems.append(f"{len(pages)} Seiten – Apple erlaubt maximal 35 pro App.")

    for page in pages:
        name = page.get("name") or "(ohne Namen)"
        if not page.get("locales"):
            problems.append(f"„{name}\": keine Sprachen definiert.")
        for locale, spec in page.get("locales", {}).items():
            text = spec.get("promotionalText", "")
            if len(text) > PROMO_TEXT_LIMIT:
                problems.append(f"„{name}\"/{locale}: Werbetext {len(text)} Zeichen, "
                                f"maximal {PROMO_TEXT_LIMIT}.")
            shots = spec.get("screenshots", [])
            if not shots:
                problems.append(f"„{name}\"/{locale}: keine Screenshots.")
            if len(shots) > MAX_SCREENSHOTS_PER_SET:
                problems.append(f"„{name}\"/{locale}: {len(shots)} Screenshots, "
                                f"maximal {MAX_SCREENSHOTS_PER_SET}.")
            for rel in shots:
                path = SCREENSHOT_ROOT / rel
                if not path.exists():
                    problems.append(f"„{name}\"/{locale}: {rel} fehlt.")
                    continue
                try:
                    w, h = png_size(path)
                except ValueError as e:
                    problems.append(f"„{name}\"/{locale}: {e}")
                    continue
                if (w, h) not in accepted:
                    problems.append(
                        f"„{name}\"/{locale}: {rel} ist {w}×{h} – {display} "
                        f"akzeptiert nur {allowed}.")
    return problems


# ── Anlegen ──────────────────────────────────────────────────────────────────

def upload_screenshot(asc: ASC, set_id: str, path: Path) -> None:
    blob = path.read_bytes()
    created = asc.post("/v1/appScreenshots", {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": path.name, "fileSize": len(blob)},
            "relationships": {
                "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}
            },
        }
    })
    if not asc.apply:
        print(f"        [Probelauf] {path.name} ({len(blob) // 1024} KB) würde hochgeladen")
        return

    shot = created["data"]
    asc.upload(shot["attributes"]["uploadOperations"], blob)
    asc.patch(f"/v1/appScreenshots/{shot['id']}", {
        "data": {
            "type": "appScreenshots",
            "id": shot["id"],
            "attributes": {"uploaded": True, "sourceFileChecksum": md5_hex(blob)},
        }
    })
    print(f"        ✓ {path.name}")


def existing_pages(asc: ASC) -> dict[str, str]:
    try:
        pages = asc.get_all(f"/v1/apps/{APP_ID}/appCustomProductPages?limit=200")
    except APIError as e:
        raise SystemExit(f"Konnte vorhandene Seiten nicht lesen: {e}")
    return {p["attributes"].get("name", ""): p["id"] for p in pages}


def create_page(asc: ASC, name: str, spec: dict, display: str) -> str | None:
    """Legt Seite, Version, Lokalisierungen und Screenshots an. Liefert die ppid."""
    print(f"\n  ── „{name}\"")
    page = asc.post("/v1/appCustomProductPages", {
        "data": {
            "type": "appCustomProductPages",
            "attributes": {"name": name, "visible": True},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    page_id = page.get("data", {}).get("id", "<neu>")
    print(f"    Seite angelegt: {page_id}")

    version = asc.post("/v1/appCustomProductPageVersions", {
        "data": {
            "type": "appCustomProductPageVersions",
            "relationships": {
                "appCustomProductPage": {
                    "data": {"type": "appCustomProductPages", "id": page_id}
                }
            },
        }
    })
    version_id = version.get("data", {}).get("id", "<neu>")
    print(f"    Version angelegt: {version_id}")

    for locale, loc_spec in spec.get("locales", {}).items():
        print(f"    ── {locale}")
        loc = asc.post("/v1/appCustomProductPageLocalizations", {
            "data": {
                "type": "appCustomProductPageLocalizations",
                "attributes": {
                    "locale": locale,
                    "promotionalText": loc_spec.get("promotionalText", ""),
                },
                "relationships": {
                    "appCustomProductPageVersion": {
                        "data": {"type": "appCustomProductPageVersions", "id": version_id}
                    }
                },
            }
        })
        loc_id = loc.get("data", {}).get("id", "<neu>")

        shot_set = asc.post("/v1/appScreenshotSets", {
            "data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": display},
                "relationships": {
                    "appCustomProductPageLocalization": {
                        "data": {
                            "type": "appCustomProductPageLocalizations",
                            "id": loc_id,
                        }
                    }
                },
            }
        })
        set_id = shot_set.get("data", {}).get("id", "<neu>")
        print(f"      Screenshot-Set {display}: {set_id}")

        for rel in loc_spec.get("screenshots", []):
            upload_screenshot(asc, set_id, SCREENSHOT_ROOT / rel)

    return page_id


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--issuer", help="Issuer-ID; bei --check-only nicht nötig")
    ap.add_argument("--apply", action="store_true", help="tatsächlich anlegen")
    ap.add_argument("--check-only", action="store_true",
                    help="nur die lokale Prüfung, kein Netzzugriff")
    ap.add_argument("--config", default=str(CONFIG_PATH))
    ap.add_argument("--only", help="nur diese Seite anlegen (Name aus cpp-pages.json)")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    config = json.loads(Path(args.config).read_text(encoding="utf-8"))

    print("PRÜFUNG")
    problems = validate(config)
    if problems:
        print(f"\n  {len(problems)} Problem(e):\n")
        for p in problems:
            print(f"    ✗ {p}")
        print("\nEs wurde nichts geschrieben. Bitte erst die Punkte oben beheben.")
        sys.exit(1)
    print("  ✓ Alle Bildgrößen und Texte in Ordnung.")

    if args.check_only:
        return
    if not args.issuer:
        raise SystemExit("--issuer wird gebraucht, sobald nicht --check-only läuft.")

    asc = ASC(args.issuer, apply=args.apply, verbose=args.verbose)
    if not args.apply:
        print("\nPROBELAUF – es wird nichts geschrieben. Mit --apply ausführen.")

    print("\nANLEGEN")
    known = existing_pages(asc)
    display = config["displayType"]
    created: dict[str, str] = {}

    for page in config["pages"]:
        name = page["name"]
        if args.only and name != args.only:
            continue
        if name in known:
            print(f"\n  ── „{name}\" existiert schon ({known[name]}) – übersprungen.")
            continue
        page_id = create_page(asc, name, page, display)
        if page_id:
            created[name] = page_id

    if created and args.apply:
        print("\n" + "═" * 70)
        print("URLS FÜR DIE KAMPAGNEN")
        print("═" * 70)
        for name, page_id in created.items():
            print(f"  {name}:")
            print(f"    https://apps.apple.com/de/app/id{APP_ID}?ppid={page_id}")
        print("\nDie Seiten sind Entwürfe. Zur Prüfung freigeben musst du in")
        print("App Store Connect – das macht dieses Skript absichtlich nicht.")


if __name__ == "__main__":
    main()
