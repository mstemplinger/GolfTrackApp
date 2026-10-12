#!/usr/bin/env python3
"""Setzt die Adressen, die im App Store neben der App stehen.

    python3 marketing/asc-legal-urls.py --issuer <ISSUER-UUID>          # Probelauf
    python3 marketing/asc-legal-urls.py --issuer <ISSUER-UUID> --apply  # schreiben

Warum es das gibt: Die Datenschutzadresse zeigte noch auf
`mstemplinger.github.io/GolfTrackApp` – eine alte GitHub-Pages-Seite, die
inzwischen nur noch weiterleitet. Das ist der Link, den Nutzer **vor** dem
Laden sehen; er gehört auf golftrack.app, genauso wie die Hilfeadresse.

Die Felder liegen an zwei Ressourcen, und Apple ist da streng (dieselbe Falle
wie beim Untertitel in `asc-store-text.py`):

  privacyPolicyUrl  → appInfoLocalizations          (App-Informationen)
  supportUrl        → appStoreVersionLocalizations  (die bearbeitbare Version)
  marketingUrl      → appStoreVersionLocalizations

Geschrieben wird nur, was abweicht. Ohne `--apply` passiert nichts.

⚠️ **Alle drei Felder brauchen eine Version im Entwurf.** Am 2026-09-14 war 2.3
veröffentlicht und sonst nichts offen; die API lehnte jedes PATCH ab:

    privacyPolicyUrl: „The field … can not be modified in the current state."
    supportUrl / marketingUrl: „Attribute … cannot be edited at this time"

Ohne Entwurf bleiben zwei Wege: in App Store Connect eine neue Version anlegen
(dann setzt dieses Skript alles) oder die Datenschutzadresse von Hand in der
Weboberfläche unter *App-Datenschutz* ändern – die gilt dort für die ganze App
und nicht für eine einzelne Version.
"""

from __future__ import annotations

import argparse

from asc_api import APP_ID, ASC, APIError

# Deutsch liegt auf der Wurzel, alles andere unter /en – so wie die Website
# gebaut ist. Französisch, Italienisch und Spanisch gibt es dort nicht.
DE = {
    "privacyPolicyUrl": "https://golftrack.app/datenschutz",
    "supportUrl": "https://golftrack.app/support",
    "marketingUrl": "https://golftrack.app",
}
EN = {
    "privacyPolicyUrl": "https://golftrack.app/en/privacy",
    "supportUrl": "https://golftrack.app/en/support",
    "marketingUrl": "https://golftrack.app/en",
}
ZIELE = {"de": DE, "en": EN, "fr": EN, "it": EN, "es": EN}


def ziel_fuer(locale: str) -> dict[str, str]:
    return ZIELE.get(locale.split("-")[0], EN)


def zielversion(asc: ASC) -> tuple[str, str]:
    """Version, an der Hilfe- und Marketingadresse hängen.

    Bevorzugt ein Entwurf. Gibt es keinen, wird die jüngste veröffentlichte
    genommen – der Versuch kostet nichts und die API lehnt sauber ab. Erwartbar
    ist dann „cannot be edited at this time"; geändert wird erst wieder an einer
    Version im Entwurf.
    """
    versionen = asc.get_all(f"/v1/apps/{APP_ID}/appStoreVersions?limit=20")
    if not versionen:
        raise SystemExit("Keine Version gefunden.")
    entwurf = [
        v for v in versionen
        if v["attributes"]["appStoreState"] in {
            "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
            "METADATA_REJECTED", "INVALID_BINARY", "WAITING_FOR_REVIEW",
        }
    ]
    v = (entwurf or versionen)[0]
    zustand = v["attributes"]["appStoreState"]
    if not entwurf:
        print(f"    (kein Entwurf vorhanden – arbeite an {v['attributes']['versionString']}, {zustand})")
    return v["id"], v["attributes"]["versionString"]


def schreibe(asc: ASC, pfad: str, typ: str, id_: str, aenderungen: dict[str, str]) -> bool:
    body = {"data": {"type": typ, "id": id_, "attributes": aenderungen}}
    try:
        asc.patch(f"{pfad}/{id_}", body)
        return True
    except APIError as e:
        print(f"    ✗ {e.detail}")
        return False


def felder(asc: ASC, lokalisierungen: list[dict], namen: tuple[str, ...],
           pfad: str, typ: str) -> int:
    """Vergleicht die gewünschten Werte mit dem Ist-Zustand und schreibt Abweichungen."""
    anzahl = 0
    for loc in sorted(lokalisierungen, key=lambda l: l["attributes"]["locale"]):
        locale = loc["attributes"]["locale"]
        soll = ziel_fuer(locale)
        aenderungen = {}
        for name in namen:
            ist = loc["attributes"].get(name) or ""
            if ist != soll[name]:
                print(f"{locale:8} {name}")
                print(f"{'':8}   alt  {ist or '— leer —'}")
                print(f"{'':8}   neu  {soll[name]}")
                aenderungen[name] = soll[name]
        if not aenderungen:
            print(f"{locale:8} unverändert")
            continue
        if schreibe(asc, pfad, typ, loc["id"], aenderungen):
            anzahl += len(aenderungen)
    return anzahl


def main() -> None:
    parser = argparse.ArgumentParser(description="Datenschutz-, Hilfe- und Marketingadresse")
    parser.add_argument("--issuer", required=True, help="Issuer-UUID aus App Store Connect")
    parser.add_argument("--apply", action="store_true", help="wirklich schreiben")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    asc = ASC(args.issuer, apply=args.apply, verbose=args.verbose)
    if not args.apply:
        print("Probelauf – es wird nichts geschrieben. Mit --apply ernst machen.\n")

    print("═══ Datenschutzadresse (App-Informationen) ═══")
    # Steht nur ein `appInfo` da (der Normalfall bei einer laufenden App), wird
    # das genommen. Ohne Entwurfsversion lehnt die API das PATCH ab – siehe oben.
    infos = asc.get_all(f"/v1/apps/{APP_ID}/appInfos?limit=10")
    if not infos:
        print("übersprungen – keine App-Informationen gefunden.")
        geaendert = 0
    else:
        entwurf = [i for i in infos
                   if i["attributes"].get("appStoreState") not in {"READY_FOR_SALE", "REPLACED_WITH_NEW_INFO"}]
        info = (entwurf or infos)[0]
        if not entwurf:
            print(f"    (kein Entwurf vorhanden – arbeite an {info['attributes'].get('appStoreState')})")
        lokal = asc.get_all(f"/v1/appInfos/{info['id']}/appInfoLocalizations?limit=50")
        geaendert = felder(asc, lokal, ("privacyPolicyUrl",),
                           "/v1/appInfoLocalizations", "appInfoLocalizations")

    version_id, version = zielversion(asc)
    print(f"\n═══ Hilfe- und Marketingadresse (Version {version}) ═══")
    lokal = asc.get_all(f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=50")
    geaendert += felder(asc, lokal, ("supportUrl", "marketingUrl"),
                        "/v1/appStoreVersionLocalizations", "appStoreVersionLocalizations")

    print(f"\n{geaendert} Feld(er) {'geschrieben' if args.apply else 'zu ändern'}.")
    if not args.apply and geaendert:
        print("Noch einmal mit --apply aufrufen.")
    if args.apply and geaendert == 0:
        print(
            "Nichts geschrieben. Wenn oben „cannot be edited at this time\" steht,\n"
            "fehlt eine Version im Entwurf – in App Store Connect eine neue anlegen\n"
            "und das Skript danach erneut aufrufen. Die Datenschutzadresse allein\n"
            "geht auch von Hand: App Store Connect → App-Datenschutz →\n"
            "Datenschutzrichtlinien-URL bearbeiten."
        )


if __name__ == "__main__":
    main()
