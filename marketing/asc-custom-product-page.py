#!/usr/bin/env python3
"""Legt benutzerdefinierte Produktseiten (Custom Product Pages) über die ASC-API an.

    # 1. Nur prüfen: Bildgrößen und Texte gegen Apples Regeln, ohne Netzzugriff
    python3 marketing/asc-custom-product-page.py --check-only

    # 2. Probelauf gegen die API: liest, zeigt was passieren würde, schreibt nichts
    python3 marketing/asc-custom-product-page.py --issuer <ISSUER-UUID>

    # 3. Anlegen
    python3 marketing/asc-custom-product-page.py --issuer <ISSUER-UUID> --apply

Quelle der Texte und Bildzuordnung ist marketing/cpp-pages.json, damit es keine
zweite Stelle gibt, die auseinanderlaufen kann. Die gestalteten Bilder einer Seite
("slides") baut vorher `marketing/appstore/cpp-shots.mjs` nach
marketing/appstore/out/cpp/<slug>/<sprache>/ – von dort lädt dieses Skript sie hoch.

Je Seite optional:
  "deepLink": "golftrack://platzreife"   – „Öffnen" auf der Seite springt dorthin
                                           (ab iOS 18; gilt erst nach Apples Freigabe)
Je Sprache optional, für weitere Geräteklassen neben dem Haupt-displayType:
  "extraScreenshots": {"APP_IPAD_PRO_3GEN_129": ["ipad/de/p1-….png", …]}

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
SLIDE_ROOT = Path(__file__).parent / "appstore" / "out" / "cpp"
CONFIG_PATH = Path(__file__).parent / "cpp-pages.json"
MAX_PAGES = 70          # Apples Obergrenze je App (früher 35)

PROMO_TEXT_LIMIT = 170
MAX_SCREENSHOTS_PER_SET = 10

# Von Apple akzeptierte Pixelmaße je Display-Typ (Hochformat).
ACCEPTED_SIZES = {
    "APP_IPHONE_69": [(1290, 2796), (1320, 2868)],
    # Der 6,9-Zoll-Slot heißt an der API APP_IPHONE_67 und nimmt auch 1320×2868.
    "APP_IPHONE_67": [(1290, 2796), (1320, 2868)],
    "APP_IPHONE_65": [(1242, 2688), (1284, 2778)],
    "APP_IPHONE_55": [(1242, 2208)],
    "APP_IPAD_PRO_3GEN_129": [(2048, 2732), (2064, 2752)],
    "APP_IPAD_PRO_129": [(2048, 2732)],
    "APP_WATCH_ULTRA": [(410, 502), (422, 514)],
}


# ── Prüfung ohne Netz ────────────────────────────────────────────────────────

def validate_shots(label: str, display: str, shots: list[Path]) -> list[str]:
    """Prüft einen Bildersatz gegen die Pixelmaße seines Display-Typs."""
    accepted = ACCEPTED_SIZES.get(display)
    if not accepted:
        return [f"{label}: unbekannter displayType „{display}\". "
                f"Bekannt: {', '.join(sorted(ACCEPTED_SIZES))}"]
    allowed = ", ".join(f"{w}×{h}" for w, h in accepted)
    problems: list[str] = []
    if not shots:
        problems.append(f"{label}: keine Screenshots für {display}.")
    if len(shots) > MAX_SCREENSHOTS_PER_SET:
        problems.append(f"{label}: {len(shots)} Screenshots für {display}, "
                        f"maximal {MAX_SCREENSHOTS_PER_SET}.")
    for path in shots:
        rel = path.relative_to(Path(__file__).parent)
        if not path.exists():
            problems.append(f"{label}: {rel} fehlt.")
            continue
        try:
            w, h = png_size(path)
        except ValueError as e:
            problems.append(f"{label}: {e}")
            continue
        if (w, h) not in accepted:
            problems.append(f"{label}: {rel} ist {w}×{h} – {display} "
                            f"akzeptiert nur {allowed}.")
    return problems


def validate(config: dict) -> list[str]:
    """Sammelt alle Probleme, statt beim ersten abzubrechen."""
    problems: list[str] = []
    display = config.get("displayType", "")
    if display not in ACCEPTED_SIZES:
        problems.append(f"Unbekannter displayType „{display}\". "
                        f"Bekannt: {', '.join(sorted(ACCEPTED_SIZES))}")
        return problems

    pages = config.get("pages", [])
    if not pages:
        problems.append("Keine Seiten in cpp-pages.json definiert.")
    if len(pages) > MAX_PAGES:
        problems.append(f"{len(pages)} Seiten – Apple erlaubt maximal {MAX_PAGES} pro App.")

    for page in pages:
        name = page.get("name") or "(ohne Namen)"
        if not page.get("locales"):
            problems.append(f"„{name}\": keine Sprachen definiert.")
        link = page.get("deepLink", "")
        if link and "://" not in link:
            problems.append(f"„{name}\": deepLink „{link}\" ist keine URL.")
        for locale, spec in page.get("locales", {}).items():
            label = f"„{name}\"/{locale}"
            text = spec.get("promotionalText", "")
            if len(text) > PROMO_TEXT_LIMIT:
                problems.append(f"{label}: Werbetext {len(text)} Zeichen, "
                                f"maximal {PROMO_TEXT_LIMIT}.")
            if spec.get("slides") and not page.get("slug"):
                problems.append(f"„{name}\": 'slides' brauchen einen 'slug' (Bildordner).")
                continue
            for set_display, shots in screenshot_sets(page, locale, display).items():
                problems += validate_shots(label, set_display, shots)
    return problems


def screenshot_sets(page: dict, locale: str, display: str) -> dict[str, list[Path]]:
    """Alle Bildersätze einer Sprache: Haupt-displayType plus extraScreenshots.

    Der Hauptsatz kommt aus den gestalteten Bildern ("slides", gebaut von
    cpp-shots.mjs) oder aus einer festen Liste ("screenshots").
    """
    spec = page["locales"][locale]
    if spec.get("slides"):
        folder = SLIDE_ROOT / page["slug"] / locale[:2]
        main = [folder / f"{i:02d}-{slide['shot']}.png"
                for i, slide in enumerate(spec["slides"], start=1)]
    else:
        main = [SCREENSHOT_ROOT / rel for rel in spec.get("screenshots", [])]
    extra = {d: [SCREENSHOT_ROOT / rel for rel in shots]
             for d, shots in spec.get("extraScreenshots", {}).items()}
    return {display: main, **extra}


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
    """Legt Seite, Version, Lokalisierungen und Screenshots an. Liefert die ppid.

    Apple verlangt Seite, erste Version und deren Sprachen in **einem** Aufruf
    ("included" mit Platzhalter-IDs) – einzeln angelegt lehnt die API ab:
    „You must provide a value for the relationship 'appCustomProductPageVersions'".
    """
    print(f"\n  ── „{name}\"")
    locales = list(spec.get("locales", {}))
    version_ref = "${version}"
    loc_ref = {locale: "${loc-%s}" % locale for locale in locales}

    version_inline: dict = {
        "type": "appCustomProductPageVersions",
        "id": version_ref,
        "relationships": {
            "appCustomProductPageLocalizations": {
                "data": [{"type": "appCustomProductPageLocalizations", "id": loc_ref[l]}
                         for l in locales]
            }
        },
    }
    if spec.get("deepLink"):
        version_inline["attributes"] = {"deepLink": spec["deepLink"]}
        print(f"    Deep Link: {spec['deepLink']}")

    page = asc.post("/v1/appCustomProductPages", {
        "data": {
            "type": "appCustomProductPages",
            # 'visible' darf beim Anlegen nicht mitkommen (409) – die Seite wird
            # mit Apples Freigabe sichtbar.
            "attributes": {"name": name},
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}},
                "appCustomProductPageVersions": {
                    "data": [{"type": "appCustomProductPageVersions", "id": version_ref}]
                },
            },
        },
        "included": [version_inline] + [
            {
                "type": "appCustomProductPageLocalizations",
                "id": loc_ref[locale],
                "attributes": {
                    "locale": locale,
                    "promotionalText": spec["locales"][locale].get("promotionalText", ""),
                },
            }
            for locale in locales
        ],
    })
    if not asc.apply:
        for locale in locales:
            for set_display, shots in screenshot_sets(spec, locale, display).items():
                print(f"    [Probelauf] {locale}/{set_display}: {len(shots)} Bilder")
        return None

    page_id = page["data"]["id"]
    print(f"    Seite angelegt: {page_id}")
    versions = asc.get_all(f"/v1/appCustomProductPages/{page_id}/appCustomProductPageVersions")
    version_id = versions[0]["id"]
    print(f"    Version: {version_id} ({versions[0]['attributes'].get('state')})")
    localizations = asc.get_all(
        f"/v1/appCustomProductPageVersions/{version_id}/appCustomProductPageLocalizations")
    loc_ids = {l["attributes"]["locale"]: l["id"] for l in localizations}

    for locale in locales:
        print(f"    ── {locale}")
        upload_sets(asc, loc_ids[locale], screenshot_sets(spec, locale, display))
    return page_id


def upload_sets(asc: ASC, loc_id: str, sets: dict[str, list[Path]]) -> None:
    """Legt je Display-Typ einen Bildersatz an der Sprache an und lädt hoch."""
    for set_display, shots in sets.items():
        shot_set = asc.post("/v1/appScreenshotSets", {
            "data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": set_display},
                "relationships": {
                    "appCustomProductPageLocalization": {
                        "data": {"type": "appCustomProductPageLocalizations", "id": loc_id}
                    }
                },
            }
        })
        set_id = shot_set.get("data", {}).get("id", "<neu>")
        print(f"      Screenshot-Set {set_display}: {set_id}")
        for path in shots:
            upload_screenshot(asc, set_id, path)


def fill_missing_sets(asc: ASC, name: str, page_id: str, spec: dict, display: str) -> None:
    """Ergänzt an einer vorhandenen Seite die Bildersätze, die noch fehlen.

    Fasst nur Entwürfe an (PREPARE_FOR_SUBMISSION) und löscht nie etwas: ein
    Display-Typ, der schon einen Satz hat, bleibt wie er ist.
    """
    versions = asc.get_all(f"/v1/appCustomProductPages/{page_id}/appCustomProductPageVersions")
    draft = next((v for v in versions
                  if v["attributes"].get("state") == "PREPARE_FOR_SUBMISSION"), None)
    if not draft:
        print(f"\n  ── „{name}\" existiert schon ({page_id}), kein Entwurf offen – übersprungen.")
        return
    print(f"\n  ── „{name}\" existiert schon ({page_id})")
    localizations = asc.get_all(
        f"/v1/appCustomProductPageVersions/{draft['id']}/appCustomProductPageLocalizations")
    for loc in localizations:
        locale = loc["attributes"]["locale"]
        if locale not in spec.get("locales", {}):
            continue
        present = {s["attributes"]["screenshotDisplayType"] for s in asc.get_all(
            f"/v1/appCustomProductPageLocalizations/{loc['id']}/appScreenshotSets")}
        missing = {d: shots for d, shots in screenshot_sets(spec, locale, display).items()
                   if d not in present}
        if not missing:
            print(f"    {locale}: alle Bildersätze vorhanden.")
            continue
        print(f"    ── {locale}: ergänze {', '.join(missing)}")
        upload_sets(asc, loc["id"], missing)


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
    if args.only:
        # Nur die gewählte Seite prüfen – Bildprobleme anderer Seiten blockieren sie nicht.
        config["pages"] = [p for p in config["pages"] if p.get("name") == args.only]
        if not config["pages"]:
            raise SystemExit(f"Keine Seite „{args.only}\" in {args.config}.")

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
            fill_missing_sets(asc, name, known[name], page, display)
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
