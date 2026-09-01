#!/usr/bin/env python3
"""Advanced App Clip Experiences abgleichen – eine je Minigolfanlage.

Ohne einen solchen Eintrag zeigt iOS beim Scannen des QR-Codes **keine**
App-Clip-Karte. Und er gilt je Adresse: `…/minigolf/sankt-englmar` und
`…/minigolf/bad-koetzting` brauchen zwei Einträge. Von Hand ist das ab einer
Handvoll Anlagen nicht mehr zu machen – deshalb dieses Skript.

    # nur nachsehen, nichts ändern
    python3 marketing/asc-appclip-experiences.py --issuer <ISSUER-UUID>

    # anlegen, was fehlt
    python3 marketing/asc-appclip-experiences.py --issuer <ISSUER-UUID> \\
        --image marketing/appclip-karte.png --apply

Die Anlagen kommen aus dem öffentlichen Verzeichnis der Website, damit hier
keine zweite Liste gepflegt werden muss.

**Reihenfolge beachten:** Die App-Clip-Ressource entsteht in App Store Connect
erst, wenn eine App-Version mit dem Clip hochgeladen wurde. Vorher meldet das
Skript „kein App Clip gefunden" – das ist dann kein Fehler, sondern der
Hinweis, dass zuerst ein Build hochmuss.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from asc_api import APP_ID, ASC, APIError, ssl_context  # noqa: E402

COURSES_URL = "https://golftrack.app/api/v1/courses?kind=minigolf"
SITE = "https://golftrack.app"

# Apple erwartet die Karte in 3000 × 2000. Kleinere Bilder weist die API ab.
IMAGE_SIZE = (3000, 2000)

# Fürs Kartenlayout: mehr Zeichen schneidet Apple ab.
TITLE_MAX = 60
SUBTITLE_MAX = 60


# ── Anlagen ──────────────────────────────────────────────────────────────────

def minigolf_courses() -> list[dict]:
    """Freigegebene Minigolfanlagen von golftrack.app."""
    with urllib.request.urlopen(COURSES_URL, timeout=30, context=ssl_context()) as resp:
        feed = json.loads(resp.read())
    return [c for c in feed.get("courses", []) if c.get("kind") == "minigolf"]


def card_texts(course: dict) -> tuple[str, str]:
    """Titel und Unterzeile der App-Clip-Karte."""
    title = course["name"][:TITLE_MAX]
    location = (course.get("location") or "").split(",")[0].strip()
    subtitle = f"Runde starten · {location}" if location else "Minigolfrunde starten"
    return title, subtitle[:SUBTITLE_MAX]


# ── Bild ─────────────────────────────────────────────────────────────────────

def png_size(path: Path) -> tuple[int, int] | None:
    """Breite und Höhe aus dem IHDR-Block. Nur PNG – sonst None."""
    data = path.read_bytes()[:33]
    if not data.startswith(b"\x89PNG\r\n\x1a\n") or data[12:16] != b"IHDR":
        return None
    return struct.unpack(">II", data[16:24])


def upload_image(asc: ASC, path: Path) -> str:
    """Lädt die Karte hoch und liefert ihre Kennung.

    Drei Schritte, wie bei allen Medien der ASC-API: Platz reservieren, Bytes
    hinschieben, Ergebnis bestätigen.
    """
    payload = path.read_bytes()
    created = asc.post(
        "/v1/appClipAdvancedExperienceImages",
        {
            "data": {
                "type": "appClipAdvancedExperienceImages",
                "attributes": {"fileSize": len(payload), "fileName": path.name},
            }
        },
    )
    if not created:                      # Probelauf
        return "<Bild-Kennung nach dem Hochladen>"

    image = created["data"]
    for op in image["attributes"]["uploadOperations"]:
        req = urllib.request.Request(op["url"], data=payload[op["offset"]:op["offset"] + op["length"]],
                                     method=op["method"])
        for header in op.get("requestHeaders", []):
            req.add_header(header["name"], header["value"])
        with urllib.request.urlopen(req, timeout=180, context=asc.ssl):
            pass

    asc.patch(
        f"/v1/appClipAdvancedExperienceImages/{image['id']}",
        {
            "data": {
                "type": "appClipAdvancedExperienceImages",
                "id": image["id"],
                "attributes": {
                    "uploaded": True,
                    "sourceFileChecksum": hashlib.md5(payload).hexdigest(),
                },
            }
        },
    )
    return image["id"]


# ── App Clip in App Store Connect ────────────────────────────────────────────

def find_app_clip(asc: ASC) -> dict | None:
    """Die App-Clip-Ressource der App. Es gibt sie erst nach dem ersten Build."""
    clips = asc.get_all(f"/v1/apps/{APP_ID}/appClips?limit=200")
    if not clips:
        return None
    # Bei mehreren gewinnt die Kennung, die auf .Clip endet.
    for clip in clips:
        if str(clip["attributes"].get("bundleId", "")).endswith(".Clip"):
            return clip
    return clips[0]


def existing_links(asc: ASC, clip_id: str) -> dict[str, dict]:
    """Vorhandene Erlebnisse, nach Adresse."""
    entries = asc.get_all(
        f"/v1/appClips/{clip_id}/appClipAdvancedExperiences"
        "?limit=200&fields[appClipAdvancedExperiences]=link,status,action,businessCategory"
    )
    return {e["attributes"].get("link", ""): e for e in entries}


def create_experience(asc: ASC, clip_id: str, link: str, title: str, subtitle: str,
                      image_id: str, language: str, category: str, action: str) -> dict:
    body = {
        "data": {
            "type": "appClipAdvancedExperiences",
            "attributes": {
                "link": link,
                "action": action,
                "businessCategory": category,
                "defaultLanguage": language,
                "isPoweredBy": False,
            },
            "relationships": {
                "appClip": {"data": {"type": "appClips", "id": clip_id}},
                "headerImage": {
                    "data": {"type": "appClipAdvancedExperienceImages", "id": image_id}
                },
                "localizations": {
                    "data": [{"type": "appClipAdvancedExperienceLocalizations", "id": language}]
                },
            },
        },
        # Die Übersetzung muss mitgeschickt werden; die Kennung ist der
        # Sprachcode und muss oben und hier gleich lauten.
        "included": [
            {
                "type": "appClipAdvancedExperienceLocalizations",
                "id": language,
                "attributes": {"language": language, "title": title, "subtitle": subtitle},
            }
        ],
    }
    return asc.post("/v1/appClipAdvancedExperiences", body)


# ── Ablauf ───────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--issuer", required=True, help="Issuer-ID aus App Store Connect")
    ap.add_argument("--apply", action="store_true", help="wirklich anlegen (sonst Probelauf)")
    ap.add_argument("--image", type=Path, help=f"Karte, PNG {IMAGE_SIZE[0]}×{IMAGE_SIZE[1]}")
    ap.add_argument("--language", default="DE", help="Sprache der Karte (Vorgabe DE)")
    ap.add_argument("--category", default="ENTERTAINMENT",
                    help="Geschäftsfeld, z. B. ENTERTAINMENT, FITNESS, FOOD_AND_DRINK")
    ap.add_argument("--action", default="OPEN", choices=["OPEN", "VIEW", "PLAY"],
                    help="Aufschrift des Knopfs auf der Karte")
    ap.add_argument("--only", help="nur diese Anlage (Kennung)")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    if args.image:
        if not args.image.is_file():
            print(f"Bild nicht gefunden: {args.image}")
            return 1
        size = png_size(args.image)
        if size and size != IMAGE_SIZE:
            print(f"Warnung: Bild ist {size[0]}×{size[1]}, Apple erwartet "
                  f"{IMAGE_SIZE[0]}×{IMAGE_SIZE[1]} – die API weist es womöglich ab.")

    asc = ASC(args.issuer, apply=args.apply, verbose=args.verbose)

    clip = find_app_clip(asc)
    if clip is None:
        print("Kein App Clip in App Store Connect gefunden.")
        print("Die Ressource entsteht erst, wenn eine App-Version mit dem Clip")
        print("hochgeladen wurde. Also zuerst archivieren und hochladen.")
        return 2

    clip_id = clip["id"]
    print(f"App Clip: {clip['attributes'].get('bundleId', clip_id)}")

    courses = minigolf_courses()
    if args.only:
        courses = [c for c in courses if c["id"] == args.only]
    if not courses:
        print("Keine Anlagen gefunden.")
        return 1

    have = existing_links(asc, clip_id)
    print(f"{len(courses)} Anlage(n), {len(have)} Erlebnis(se) vorhanden\n")

    missing = [c for c in courses if f"{SITE}/minigolf/{c['id']}" not in have]

    for course in courses:
        link = f"{SITE}/minigolf/{course['id']}"
        if link in have:
            print(f"  ✓ {course['name']} – {have[link]['attributes'].get('status', '?')}")

    if not missing:
        print("\nNichts zu tun.")
        return 0

    print(f"\nEs fehlen {len(missing)}:")
    for course in missing:
        title, subtitle = card_texts(course)
        print(f"  + {course['name']}")
        print(f"      {SITE}/minigolf/{course['id']}")
        print(f"      Titel: {title}  |  Unterzeile: {subtitle}")

    if not args.apply:
        print("\nProbelauf – nichts geändert. Mit --apply und --image anlegen.")
        return 0

    if not args.image:
        print("\n--image fehlt. Ohne Karte nimmt Apple kein Erlebnis an.")
        return 1

    angelegt = 0
    for course in missing:
        title, subtitle = card_texts(course)
        link = f"{SITE}/minigolf/{course['id']}"
        try:
            # Jedes Erlebnis braucht sein eigenes Bild – dieselbe Kennung
            # lässt sich nicht zweimal verwenden.
            image_id = upload_image(asc, args.image)
            create_experience(asc, clip_id, link, title, subtitle,
                              image_id, args.language, args.category, args.action)
            print(f"  angelegt: {course['name']}")
            angelegt += 1
        except APIError as e:
            print(f"  FEHLER bei {course['name']}: {e}")

    print(f"\n{angelegt} von {len(missing)} angelegt.")
    return 0 if angelegt == len(missing) else 1


if __name__ == "__main__":
    raise SystemExit(main())
