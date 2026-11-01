#!/usr/bin/env python3
"""Legt das Jahresabo „Training jährlich" in App Store Connect an.

    python3 marketing/asc-training-yearly.py --issuer <UUID>                       # Probelauf
    python3 marketing/asc-training-yearly.py --issuer <UUID> --apply               # schreiben
    python3 marketing/asc-training-yearly.py --issuer <UUID> --apply --screenshot bild.png

Produkt-ID wie in `SubscriptionManager.trainingYearlyProductID`:
`Trainingsvideos_abo_jahr`, 1 Jahr, 100,00 € in Deutschland, übrige Länder nach
Apples Entsprechungen (`equalizations`, wie `asc-prices.py`). Gleiche Gruppe und
gleiche Stufe wie das Monatsabo `Trainingsvideos_abo` – so wechselt Apple
zwischen Monat und Jahr ohne doppelte Abbuchung. Dazu die 3-Tage-Testphase wie
beim Monatsabo (Einführungsangebot je Land, siehe `asc-trial.py`).

Wiederholbar: Was schon steht (Abo, Stufe, Sprachen, Preise, Verfügbarkeit,
Testphase, Prüfbild), wird übersprungen.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from asc_api import APP_ID, ASC, APIError, md5_hex

PRODUCT_ID = "Trainingsvideos_abo_jahr"
MONATS_ID = "Trainingsvideos_abo"
REFERENZNAME = "Training jährlich"
PREIS_EUR = 100.00
BASIS_LAND = "DEU"

# Anzeigename höchstens 30, Beschreibung höchstens 45 Zeichen.
SPRACHEN = {
    "de-DE": ("GolfTrack Pro – Training Jahr", "Alle Trainingslektionen, jährlich bezahlt"),
    "en-US": ("Training – yearly", "All training lessons, billed yearly"),
    "fr-FR": ("Entraînement – annuel", "Toutes les leçons, facturé chaque année"),
    "it": ("Allenamento – annuale", "Tutte le lezioni, pagamento annuale"),
    "es-ES": ("Entrenamiento – anual", "Todas las lecciones, pago anual"),
}

PRUEF_NOTIZ = (
    "Yearly variant of the existing monthly Training subscription (Trainingsvideos_abo), same "
    "access: all audio training lessons in the Training tab. Same subscription group and level, "
    "so users can switch between monthly and yearly. 3-day free trial like the monthly plan. "
    "To see the purchase screen: Training tab → tap any lesson with a crown → choose 'Jährlich'."
)


def abos(asc: ASC) -> tuple[str, dict[str, dict]]:
    gruppen = asc.get_all(f"/v1/apps/{APP_ID}/subscriptionGroups?limit=20")
    for gruppe in gruppen:
        alle = {a["attributes"]["productId"]: a
                for a in asc.get_all(f"/v1/subscriptionGroups/{gruppe['id']}/subscriptions?limit=50")}
        if MONATS_ID in alle:
            return gruppe["id"], alle
    raise SystemExit(f"Gruppe mit {MONATS_ID} nicht gefunden")


def anlegen(asc: ASC) -> str | None:
    gruppe_id, alle = abos(asc)
    monat = alle[MONATS_ID]
    stufe = monat["attributes"]["groupLevel"]
    jahr = alle.get(PRODUCT_ID)
    if jahr is None:
        print(f"  Lege {PRODUCT_ID} an (ONE_YEAR) in Gruppe {gruppe_id}")
        antwort = asc.post("/v1/subscriptions", {
            "data": {
                "type": "subscriptions",
                "attributes": {
                    "name": REFERENZNAME,
                    "productId": PRODUCT_ID,
                    "subscriptionPeriod": "ONE_YEAR",
                    "familySharable": False,
                    "reviewNote": PRUEF_NOTIZ,
                },
                "relationships": {"group": {"data": {"type": "subscriptionGroups", "id": gruppe_id}}},
            }
        })
        if not antwort:
            return None
        jahr = antwort["data"]
    else:
        print(f"  Abo steht schon: {jahr['id']}")
    if jahr["attributes"].get("groupLevel") != stufe:
        print(f"  Stufe {jahr['attributes'].get('groupLevel')} → {stufe} (wie Monatsabo)")
        asc.patch(f"/v1/subscriptions/{jahr['id']}", {
            "data": {"type": "subscriptions", "id": jahr["id"], "attributes": {"groupLevel": stufe}}
        })
    return jahr["id"]


def sprachen(asc: ASC, abo_id: str) -> None:
    vorhanden = {l["attributes"]["locale"]
                 for l in asc.get_all(f"/v1/subscriptions/{abo_id}/subscriptionLocalizations?limit=50")}
    for locale, (name, beschreibung) in SPRACHEN.items():
        assert len(name) <= 30 and len(beschreibung) <= 45, (locale, name, beschreibung)
        if locale in vorhanden:
            print(f"  Sprache {locale} steht schon")
            continue
        print(f"  Sprache {locale}: {name} – {beschreibung}")
        asc.post("/v1/subscriptionLocalizations", {
            "data": {
                "type": "subscriptionLocalizations",
                "attributes": {"locale": locale, "name": name, "description": beschreibung},
                "relationships": {"subscription": {"data": {"type": "subscriptions", "id": abo_id}}},
            }
        })


def verfuegbarkeit(asc: ASC, abo_id: str) -> None:
    try:
        if asc.get(f"/v1/subscriptions/{abo_id}/subscriptionAvailability").get("data"):
            print("  Verfügbarkeit steht schon")
            return
    except APIError as e:
        if e.status != 404:
            raise
    laender = [t["id"] for t in asc.get_all("/v1/territories?limit=200")]
    print(f"  Verfügbar in {len(laender)} Ländern und künftigen")
    asc.post("/v1/subscriptionAvailabilities", {
        "data": {
            "type": "subscriptionAvailabilities",
            "attributes": {"availableInNewTerritories": True},
            "relationships": {
                "subscription": {"data": {"type": "subscriptions", "id": abo_id}},
                "availableTerritories": {"data": [{"type": "territories", "id": t} for t in laender]},
            },
        }
    })


def preise(asc: ASC, abo_id: str) -> list[str]:
    """Erstpreis je Land (ohne Startdatum). Gibt die Länder mit Preis zurück."""
    stand: set[str] = set()
    pfad = f"/v1/subscriptions/{abo_id}/prices?include=territory&limit=200"
    while pfad:
        seite = asc.get(pfad)
        for e in seite.get("data", []):
            land = (e.get("relationships", {}).get("territory", {}).get("data") or {}).get("id")
            if land:
                stand.add(land)
        pfad = seite.get("links", {}).get("next", "")

    punkte = asc.get_all(f"/v1/subscriptions/{abo_id}/pricePoints?filter[territory]={BASIS_LAND}&limit=200")
    treffer = [p for p in punkte if abs(float(p["attributes"]["customerPrice"]) - PREIS_EUR) < 0.005]
    if not treffer:
        raise SystemExit(f"Kein Preispunkt {PREIS_EUR:.2f} € für {BASIS_LAND}")
    basis = treffer[0]
    plan = [basis] + asc.get_all(
        f"/v1/subscriptionPricePoints/{basis['id']}/equalizations?include=territory&limit=200")

    def land_von(p: dict) -> str | None:
        rel = p.get("relationships", {}).get("territory", {}).get("data")
        return rel["id"] if rel else BASIS_LAND if p is basis else None

    offen = [p for p in plan if land_von(p) not in stand]
    print(f"  Preise: {len(plan)} Länder, {len(stand)} stehen, {len(offen)} offen "
          f"({PREIS_EUR:.2f} € in {BASIS_LAND}, Erlös {basis['attributes']['proceeds']} €)")
    fehler = []
    for i, p in enumerate(offen, 1):
        try:
            asc.post("/v1/subscriptionPrices", {
                "data": {
                    "type": "subscriptionPrices",
                    "attributes": {"preserveCurrentPrice": False},
                    "relationships": {
                        "subscription": {"data": {"type": "subscriptions", "id": abo_id}},
                        "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": p["id"]}},
                    },
                }
            })
            if land_von(p):
                stand.add(land_von(p))
        except APIError as e:
            fehler.append(f"{land_von(p)}: {e.detail[:90]}")
        if asc.apply and (i % 25 == 0 or i == len(offen)):
            print(f"   … {i}/{len(offen)}")
    for f in fehler[:5]:
        print(f"   ✗ {f}")
    return sorted(stand)


def testphase(asc: ASC, abo_id: str, laender: list[str]) -> None:
    vorhanden: set[str] = set()
    pfad = f"/v1/subscriptions/{abo_id}/introductoryOffers?include=territory&limit=200"
    while pfad:
        seite = asc.get(pfad)
        for e in seite.get("data", []):
            land = (e.get("relationships", {}).get("territory", {}).get("data") or {}).get("id")
            if land:
                vorhanden.add(land)
        pfad = seite.get("links", {}).get("next", "")
    offen = [l for l in laender if l not in vorhanden]
    print(f"  Testphase 3 Tage: {len(vorhanden)} stehen, {len(offen)} offen")
    fehler = []
    for i, land in enumerate(offen, 1):
        try:
            asc.post("/v1/subscriptionIntroductoryOffers", {
                "data": {
                    "type": "subscriptionIntroductoryOffers",
                    "attributes": {"duration": "THREE_DAYS", "offerMode": "FREE_TRIAL", "numberOfPeriods": 1},
                    "relationships": {
                        "subscription": {"data": {"type": "subscriptions", "id": abo_id}},
                        "territory": {"data": {"type": "territories", "id": land}},
                    },
                }
            })
        except APIError as e:
            fehler.append(f"{land}: {e.detail[:90]}")
        if asc.apply and (i % 25 == 0 or i == len(offen)):
            print(f"   … {i}/{len(offen)}")
    for f in fehler[:5]:
        print(f"   ✗ {f}")


def pruefbild(asc: ASC, abo_id: str, pfad: Path) -> None:
    try:
        if asc.get(f"/v1/subscriptions/{abo_id}/appStoreReviewScreenshot").get("data"):
            print("  Prüfbild steht schon")
            return
    except APIError as e:
        if e.status != 404:
            raise
    blob = pfad.read_bytes()
    print(f"  Prüfbild {pfad.name} ({len(blob)} Bytes)")
    antwort = asc.post("/v1/subscriptionAppStoreReviewScreenshots", {
        "data": {
            "type": "subscriptionAppStoreReviewScreenshots",
            "attributes": {"fileName": pfad.name, "fileSize": len(blob)},
            "relationships": {"subscription": {"data": {"type": "subscriptions", "id": abo_id}}},
        }
    })
    if not antwort:
        return
    bild = antwort["data"]
    asc.upload(bild["attributes"]["uploadOperations"], blob)
    asc.patch(f"/v1/subscriptionAppStoreReviewScreenshots/{bild['id']}", {
        "data": {
            "type": "subscriptionAppStoreReviewScreenshots",
            "id": bild["id"],
            "attributes": {"uploaded": True, "sourceFileChecksum": md5_hex(blob)},
        }
    })


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--issuer", required=True)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--screenshot", type=Path, help="Bildschirmfoto der Kaufseite für die Prüfung")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    asc = ASC(args.issuer, apply=args.apply, verbose=args.verbose)
    abo_id = anlegen(asc)
    if not abo_id:
        print("  (Probelauf – ohne Abo keine weiteren Schritte)")
        return
    sprachen(asc, abo_id)
    verfuegbarkeit(asc, abo_id)
    laender = preise(asc, abo_id)
    testphase(asc, abo_id, laender)
    if args.screenshot:
        pruefbild(asc, abo_id, args.screenshot)
    print("Fertig." if args.apply else "Probelauf – nichts geschrieben.")


if __name__ == "__main__":
    main()
