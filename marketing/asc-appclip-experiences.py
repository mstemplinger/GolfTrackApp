#!/usr/bin/env python3
"""Advanced App Clip Experiences abgleichen.

Ohne einen solchen Eintrag zeigt iOS beim Scannen des QR-Codes **keine**
App-Clip-Karte, egal wie richtig alles andere ist.

**Ein Eintrag genügt.** Zugeordnet wird über den Präfix-Vergleich, und alle
gedruckten Codes tragen seit dem 12.9.2026 die Kurzform
`https://play.golftrack.app/p/<kennung>`. Ein Eintrag auf
`https://play.golftrack.app/p/` deckt damit jeden Platz ab – vorher wäre je
Adresse einer nötig gewesen.

    # nachsehen, was vorhanden ist
    python3 marketing/asc-appclip-experiences.py --issuer <ISSUER-UUID>

    # je Anlage einen eigenen Eintrag prüfen (eigenes Kartenbild pro Betreiber)
    python3 marketing/asc-appclip-experiences.py --issuer <ISSUER-UUID> --pro-anlage

Die Anlagen für `--pro-anlage` kommen aus dem öffentlichen Verzeichnis der
Website, damit hier keine zweite Liste gepflegt werden muss.

**Anlegen geht nur von Hand** – siehe den Kommentar in `create_experience()`.
Am 12.9.2026 noch einmal mit fünf weiteren Kennungsformaten geprüft, Apple
weist jedes ab. Dieses Skript ist deshalb in erster Linie zum Nachsehen da.

**Reihenfolge beachten:** Die App-Clip-Ressource entsteht in App Store Connect
erst, wenn eine App-Version mit dem Clip hochgeladen wurde. Vorher meldet das
Skript „kein App Clip gefunden" – das ist dann kein Fehler, sondern der
Hinweis, dass zuerst ein Build hochmuss.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import sys
import urllib.error
import urllib.request
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from asc_api import APP_ID, ASC, APIError, ssl_context  # noqa: E402

COURSES_URL = "https://golftrack.app/api/v1/courses?kind=minigolf"
SITE = "https://golftrack.app"
# Die Adresse auf den gedruckten Codes. Der Schrägstrich am Ende gehört dazu:
# verglichen wird als Präfix.
PREFIX_LINK = "https://play.golftrack.app/p/"
PREFIX_TITLE = "GolfTrack"
PREFIX_SUBTITLE = "Runde starten und mitzählen"

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
        try:
            with urllib.request.urlopen(req, timeout=180, context=asc.ssl):
                pass
        except urllib.error.HTTPError as e:
            body = e.read().decode(errors="replace")
            # Apple erkennt gleiche Bilder am Inhalt wieder und nennt in der
            # Absage die Kennung der vorhandenen Fassung. Genau die wollen wir –
            # sonst bliebe ein zweiter Anlauf nach einem Abbruch für immer
            # hängen.
            match = re.search(r"already exists with id\s*-\s*([0-9a-fA-F-]{36})", body)
            if match:
                return match.group(1)
            raise APIError(e.code, op["method"], op["url"], body) from None

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
    # ACHTUNG – hier klemmt es (Stand 1.9.2026, erneut geprüft am 12.9.2026).
    #
    # Die Übersetzung muss mitgeschickt werden, die Beziehung `localizations`
    # ist Pflicht (ohne sie: „missing a required relationship"). Der Eintrag
    # unter `included` braucht eine Kennung – und Apple weist jedes Format ab,
    # das wir gefunden haben:
    #
    #   'DE', 'de', 'de-DE', 'DE-DE', '1', '0', <UUID> in Groß- und
    #   Kleinschreibung, UUID ohne Bindestriche, '<clipId>_DE', die Kennung des
    #   Clips selbst, ein kurzes Wort wie 'loc1'
    #     → „The provided included entity id '…' has invalid format"
    #
    # Die Dokumentation nennt das Feld nur „opaque resource ID" und als
    # optional; weglassen geht aber nicht, weil die Beziehung darauf zeigt.
    # Die Sprache selbst ist richtig: 'DE' steht so im Enum
    # AppClipAdvancedExperienceLanguage.
    #
    # Der Weg heraus: **eine** Experience von Hand in App Store Connect
    # anlegen, dann mit `--show-localization-ids` die Kennung auslesen, die
    # Apple selbst vergibt – daran lässt sich das Format ablesen und hier
    # eintragen. Bis dahin ist nur der lesende Teil dieses Skripts nutzbar.
    loc_id = str(uuid.uuid4()).upper()
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
                    "data": [{"type": "appClipAdvancedExperienceLocalizations", "id": loc_id}]
                },
            },
        },
        "included": [
            {
                "type": "appClipAdvancedExperienceLocalizations",
                "id": loc_id,
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
    ap.add_argument("--pro-anlage", action="store_true",
                    help="je Anlage einen eigenen Eintrag statt des einen Präfixes")
    ap.add_argument("--only", help="nur diese Anlage (Kennung, mit --pro-anlage)")
    ap.add_argument("--show-localization-ids", action="store_true",
                    help="Kennungen der Übersetzungen vorhandener Erlebnisse zeigen")
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

    # Was soll es geben: der eine Eintrag auf das Präfix – oder je Anlage einer.
    if args.pro_anlage:
        courses = minigolf_courses()
        if args.only:
            courses = [c for c in courses if c["id"] == args.only]
        if not courses:
            print("Keine Anlagen gefunden.")
            return 1
        soll = [(f"{SITE}/minigolf/{c['id']}", *card_texts(c)) for c in courses]
    else:
        soll = [(PREFIX_LINK, PREFIX_TITLE, PREFIX_SUBTITLE)]

    if args.show_localization_ids:
        found = False
        for entry in asc.get_all(f"/v1/appClips/{clip_id}/appClipAdvancedExperiences?limit=200"):
            for loc in asc.get_all(
                f"/v1/appClipAdvancedExperiences/{entry['id']}/localizations?limit=50"
            ):
                found = True
                print(f"  {entry['attributes'].get('link','?')}")
                print(f"      Kennung: {loc['id']}")
                print(f"      Sprache: {loc['attributes'].get('language')}")
        if not found:
            print("Keine Übersetzungen vorhanden – erst eine Experience von Hand anlegen.")
        return 0

    have = existing_links(asc, clip_id)
    print(f"{len(soll)} gewünscht, {len(have)} vorhanden\n")

    for link, _, _ in soll:
        if link in have:
            print(f"  ✓ {link} – {have[link]['attributes'].get('status', '?')}")

    fehlen = [eintrag for eintrag in soll if eintrag[0] not in have]
    for link, entry in have.items():
        if link not in {s[0] for s in soll}:
            print(f"  · zusätzlich vorhanden: {link}")

    if not fehlen:
        print("\nNichts zu tun.")
        return 0

    print(f"\nEs fehlen {len(fehlen)}:")
    for link, title, subtitle in fehlen:
        print(f"  + {link}")
        print(f"      Titel: {title}  |  Unterzeile: {subtitle}")

    print()
    print("Anlegen kann dieses Skript nicht – Apple weist über die API jede")
    print("Kennung für die Übersetzung ab (siehe create_experience()). Also in")
    print("App Store Connect unter App Clip → Advanced App Clip Experiences")
    print("von Hand eintragen, mit diesen Werten:")
    for link, title, subtitle in fehlen:
        print(f"    Adresse:   {link}")
        print(f"    Titel:     {title}")
        print(f"    Unterzeile: {subtitle}")
        print(f"    Aktion:    {args.action}")
        print(f"    Sprache:   {args.language}")
        print( "    Kartenbild: marketing/appclip/appclip-karte.png (3000×2000)")
    print()
    print("Danach `--show-localization-ids` aufrufen: daran lässt sich das")
    print("Kennungsformat ablesen, das Apple selbst vergibt – dann ließe sich")
    print("create_experience() reparieren.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
