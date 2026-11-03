#!/usr/bin/env python3
"""Legt die Driving-Range-Erfolge und die Bestenliste „Längster Drive“ in Game Center an.

    python3 marketing/asc-gamecenter-range.py --issuer <ISSUER-UUID>          # Probelauf
    python3 marketing/asc-gamecenter-range.py --issuer <ISSUER-UUID> --apply  # wirklich anlegen

Was schon existiert (gleiche vendorIdentifier bzw. Lokalisierung), wird übersprungen –
das Skript kann also nach einem Abbruch einfach noch einmal laufen. Bilder liegen
unter marketing/gamecenter/ (1024 × 1024, mit ElevenLabs im Stil der alten Erfolge).
"""

from __future__ import annotations

import argparse
from pathlib import Path

from asc_api import ASC, APP_ID, APIError, png_size

PREFIX = "com.TobiasAufschlaeger.GolfTrackappnew."
IMAGES = Path(__file__).parent / "gamecenter"

# vendor-Suffix, Punkte, Bild, {locale: (Name, vorher, nachher)}
ACHIEVEMENTS = [
    ("firstRangeSession", 10, "01-firstRangeSession.png", {
        "de-DE": ("Erste Range-Einheit",
                  "Schließe deine erste Einheit auf der Driving Range ab.",
                  "Du hast deine erste Range-Einheit mit GolfTrack trainiert!"),
        "en-US": ("First Range Session",
                  "Finish your first session on the driving range.",
                  "You finished your first range session with GolfTrack!")}),
    ("rangeSessions10", 25, "02-rangeSessions10.png", {
        "de-DE": ("Range-Stammgast",
                  "Schließe 10 Einheiten auf der Driving Range ab.",
                  "10 Einheiten auf der Range – Training zahlt sich aus!"),
        "en-US": ("Range Regular",
                  "Finish 10 sessions on the driving range.",
                  "10 range sessions – practice pays off!")}),
    ("rangeShots100", 10, "03-rangeShots100.png", {
        "de-DE": ("100 Range-Bälle",
                  "Trage 100 Schläge auf der Driving Range ein.",
                  "Du hast 100 Bälle auf der Range geschlagen!"),
        "en-US": ("100 Range Balls",
                  "Log 100 shots on the driving range.",
                  "You hit 100 balls on the range!")}),
    ("rangeShots1000", 40, "04-rangeShots1000.png", {
        "de-DE": ("1000 Range-Bälle",
                  "Trage 1000 Schläge auf der Driving Range ein.",
                  "1000 Bälle auf der Range – echtes Fleißtraining!"),
        "en-US": ("1000 Range Balls",
                  "Log 1000 shots on the driving range.",
                  "1000 balls on the range – true dedication!")}),
    ("drive200", 20, "05-drive200.png", {
        "de-DE": ("200-m-Drive",
                  "Schlage den Driver auf der Range mindestens 200 m weit.",
                  "Dein Drive flog 200 m oder weiter!"),
        "en-US": ("200 m Drive",
                  "Hit your driver at least 200 m on the range.",
                  "Your drive flew 200 m or more!")}),
    ("drive250", 40, "06-drive250.png", {
        "de-DE": ("250-m-Drive",
                  "Schlage den Driver auf der Range mindestens 250 m weit.",
                  "250 m mit dem Driver – du gehörst zu den Longhittern!"),
        "en-US": ("250 m Drive",
                  "Hit your driver at least 250 m on the range.",
                  "250 m with the driver – you're a long hitter!")}),
    ("rangeFullBag", 20, "07-rangeFullBag.png", {
        "de-DE": ("Ganzes Bag",
                  "Schlage 10 verschiedene Schläger auf der Driving Range.",
                  "Du hast mit 10 verschiedenen Schlägern trainiert!"),
        "en-US": ("Full Bag",
                  "Hit 10 different clubs on the driving range.",
                  "You practised with 10 different clubs!")}),
    ("rangePersonalBest", 15, "08-rangePersonalBest.png", {
        "de-DE": ("Neue Bestweite",
                  "Übertriff auf der Range deine Bestweite mit einem Schläger.",
                  "Neue Bestweite – du schlägst weiter als je zuvor!"),
        "en-US": ("New Personal Best",
                  "Beat your best distance with a club on the range.",
                  "New personal best – you hit it further than ever!")}),
]

LEADERBOARD = {
    "vendor": PREFIX + "longestDrive",
    "referenceName": "Längster Drive",
    "localizations": {
        "de-DE": ("Längster Drive", "m", "m",
                  "Dein weitester Driver-Schlag auf der Driving Range in Metern."),
        "en-US": ("Longest Drive", "m", "m",
                  "Your longest driver shot on the driving range, in metres."),
    },
}


def rel(kind: str, id_: str) -> dict:
    return {"data": {"type": kind, "id": id_}}


def has_image(asc: ASC, localization_id: str) -> bool:
    """Ein fertig übernommenes Bild; eine hängende Reservierung wird entfernt."""
    try:
        image = asc.get(f"/v1/gameCenterAchievementLocalizations/{localization_id}"
                        "/gameCenterAchievementImage").get("data")
    except APIError as e:
        if e.status == 404:
            return False
        raise
    if not image:
        return False
    state = (image["attributes"].get("assetDeliveryState") or {}).get("state")
    if state in ("COMPLETE", "UPLOAD_COMPLETE"):
        return True
    asc.delete(f"/v1/gameCenterAchievementImages/{image['id']}")
    return False


def upload_image(asc: ASC, localization_id: str, path: Path) -> None:
    blob = path.read_bytes()
    w, h = png_size(path)
    assert (w, h) == (1024, 1024), f"{path.name}: {w}×{h}"
    res = asc.post("/v1/gameCenterAchievementImages", {"data": {
        "type": "gameCenterAchievementImages",
        "attributes": {"fileName": path.name, "fileSize": len(blob)},
        "relationships": {"gameCenterAchievementLocalization":
                          rel("gameCenterAchievementLocalizations", localization_id)},
    }})
    if not asc.apply:
        return
    image = res["data"]
    asc.upload(image["attributes"]["uploadOperations"], blob)
    asc.patch(f"/v1/gameCenterAchievementImages/{image['id']}", {"data": {
        "type": "gameCenterAchievementImages", "id": image["id"],
        "attributes": {"uploaded": True},
    }})


def ensure_achievements(asc: ASC, detail_id: str) -> None:
    existing = {a["attributes"]["vendorIdentifier"]: a for a in
                asc.get_all(f"/v1/gameCenterDetails/{detail_id}/gameCenterAchievements?limit=200")}
    used = sum(a["attributes"]["points"] for a in existing.values())
    print(f"Punkte vergeben: {used}, neu: {sum(p for _, p, _, _ in ACHIEVEMENTS)}, Grenze 1000")

    for suffix, points, image, locs in ACHIEVEMENTS:
        vendor = PREFIX + suffix
        if vendor in existing:
            ach_id = existing[vendor]["id"]
            print(f"✓ {vendor} vorhanden")
        else:
            print(f"+ {vendor} ({points} Punkte)")
            res = asc.post("/v1/gameCenterAchievements", {"data": {
                "type": "gameCenterAchievements",
                "attributes": {"referenceName": locs["de-DE"][0], "vendorIdentifier": vendor,
                               "points": points, "showBeforeEarned": True, "repeatable": False},
                "relationships": {"gameCenterDetail": rel("gameCenterDetails", detail_id)},
            }})
            ach_id = res.get("data", {}).get("id")

        have = {} if not ach_id or vendor not in existing else {
            l["attributes"]["locale"]: l for l in
            asc.get_all(f"/v1/gameCenterAchievements/{ach_id}/localizations")}
        for locale, (name, before, after) in locs.items():
            if locale in have:
                loc_id = have[locale]["id"]
                if has_image(asc, loc_id):
                    print(f"    ✓ {locale}")
                else:
                    print(f"    ✓ {locale}, Bild fehlt – lade nach")
                    upload_image(asc, loc_id, IMAGES / image)
                continue
            print(f"    + {locale}: {name}")
            res = asc.post("/v1/gameCenterAchievementLocalizations", {"data": {
                "type": "gameCenterAchievementLocalizations",
                "attributes": {"locale": locale, "name": name,
                               "beforeEarnedDescription": before,
                               "afterEarnedDescription": after},
                "relationships": {"gameCenterAchievement": rel("gameCenterAchievements", ach_id or "?")},
            }})
            loc_id = res.get("data", {}).get("id")
            upload_image(asc, loc_id or "?", IMAGES / image)


def ensure_leaderboard(asc: ASC, detail_id: str) -> None:
    existing = {b["attributes"]["vendorIdentifier"]: b for b in
                asc.get_all(f"/v1/gameCenterDetails/{detail_id}/gameCenterLeaderboards")}
    vendor = LEADERBOARD["vendor"]
    if vendor in existing:
        board_id = existing[vendor]["id"]
        print(f"✓ {vendor} vorhanden")
        have = {l["attributes"]["locale"] for l in
                asc.get_all(f"/v1/gameCenterLeaderboards/{board_id}/localizations")}
    else:
        print(f"+ {vendor}")
        res = asc.post("/v1/gameCenterLeaderboards", {"data": {
            "type": "gameCenterLeaderboards",
            "attributes": {"referenceName": LEADERBOARD["referenceName"], "vendorIdentifier": vendor,
                           "defaultFormatter": "INTEGER", "submissionType": "BEST_SCORE",
                           "scoreSortType": "DESC", "scoreRangeStart": "1", "scoreRangeEnd": "500",
                           "visibility": "SHOW_FOR_ALL"},
            "relationships": {"gameCenterDetail": rel("gameCenterDetails", detail_id)},
        }})
        board_id = res.get("data", {}).get("id", "?")
        have = set()
    for locale, (name, suffix, singular, description) in LEADERBOARD["localizations"].items():
        if locale in have:
            print(f"    ✓ {locale}")
            continue
        print(f"    + {locale}: {name}")
        asc.post("/v1/gameCenterLeaderboardLocalizations", {"data": {
            "type": "gameCenterLeaderboardLocalizations",
            "attributes": {"locale": locale, "name": name, "formatterSuffix": suffix,
                           "formatterSuffixSingular": singular, "description": description},
            "relationships": {"gameCenterLeaderboard": rel("gameCenterLeaderboards", board_id)},
        }})


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--issuer", required=True)
    ap.add_argument("--apply", action="store_true", help="wirklich anlegen (sonst Probelauf)")
    args = ap.parse_args()

    asc = ASC(args.issuer, apply=args.apply)
    detail_id = asc.get(f"/v1/apps/{APP_ID}/gameCenterDetail")["data"]["id"]
    ensure_achievements(asc, detail_id)
    ensure_leaderboard(asc, detail_id)
    if not args.apply:
        print("\nProbelauf – nichts geändert. Mit --apply anlegen.")


if __name__ == "__main__":
    main()
