#!/usr/bin/env python3
"""Legt den Einmalkauf „Werbefrei" in App Store Connect an.

    python3 marketing/asc-adfree-iap.py --issuer <UUID>                       # Probelauf
    python3 marketing/asc-adfree-iap.py --issuer <UUID> --apply               # schreiben
    python3 marketing/asc-adfree-iap.py --issuer <UUID> --apply --screenshot bild.png

Produkt-ID wie in `SubscriptionManager.adFreeProductID`: `GolfTrack_werbefrei`,
nicht verbrauchbar (Non-Consumable), 4,99 € in Deutschland, für die übrigen
Länder Apples eigene Entsprechungen (Preisplan mit Basisland DEU – Apple
rechnet die anderen Länder selbst nach, solange dort kein Preis von Hand steht).

Wiederholbar: Was schon steht (Produkt, Sprachen, Preis, Verfügbarkeit,
Prüfbild), wird übersprungen.

Danach von Hand in der Weboberfläche: Der **erste** In-App-Kauf einer App muss
zusammen mit einer App-Version eingereicht werden – auf der Versionsseite unter
„In-App-Käufe und Abonnements" auswählen.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from asc_api import APP_ID, ASC, APIError, md5_hex

PRODUCT_ID = "GolfTrack_werbefrei"
REFERENZNAME = "Werbefrei"
PREIS_EUR = "4.99"
BASIS_LAND = "DEU"

# Anzeigename höchstens 30, Beschreibung höchstens 45 Zeichen.
SPRACHEN = {
    "de-DE": ("Werbefrei", "Keine Anzeigen mehr in den Zählkarten"),
    "en-US": ("Ad-free", "No more ads on your scorecards"),
    "fr-FR": ("Sans publicité", "Plus de publicité sur vos cartes de score"),
    "it": ("Senza pubblicità", "Niente pubblicità nelle schede segnapunti"),
    "es-ES": ("Sin anuncios", "Sin anuncios en tus tarjetas de juego"),
}

PRUEF_NOTIZ = (
    "Non-consumable purchase that hides the ad slot on the scorecards (golf and mini golf). "
    "To see the purchase screen: Profile tab → 'Werbung entfernen', or long-press an ad on the "
    "scorecard → 'Werbung entfernen'. Ads are served by our own server (golftrack.app), no ad "
    "network or SDK. Course notes (toilets, shelter) are not ads and stay visible after purchase."
)


def produkt(asc: ASC) -> str | None:
    for iap in asc.get_all(f"/v1/apps/{APP_ID}/inAppPurchasesV2?limit=50"):
        if iap["attributes"]["productId"] == PRODUCT_ID:
            return iap["id"]
    return None


def anlegen(asc: ASC) -> str | None:
    iap_id = produkt(asc)
    if iap_id:
        print(f"  Produkt steht schon: {iap_id}")
        return iap_id
    print(f"  Lege {PRODUCT_ID} an (NON_CONSUMABLE)")
    antwort = asc.post("/v2/inAppPurchases", {
        "data": {
            "type": "inAppPurchases",
            "attributes": {
                "name": REFERENZNAME,
                "productId": PRODUCT_ID,
                "inAppPurchaseType": "NON_CONSUMABLE",
                "reviewNote": PRUEF_NOTIZ,
                "familySharable": True,
            },
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    return antwort.get("data", {}).get("id")


def sprachen(asc: ASC, iap_id: str) -> None:
    vorhanden = {
        loc["attributes"]["locale"]
        for loc in asc.get_all(f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations?limit=50")
    }
    for locale, (name, beschreibung) in SPRACHEN.items():
        assert len(name) <= 30 and len(beschreibung) <= 45, (locale, name, beschreibung)
        if locale in vorhanden:
            print(f"  Sprache {locale} steht schon")
            continue
        print(f"  Sprache {locale}: {name} – {beschreibung}")
        asc.post("/v1/inAppPurchaseLocalizations", {
            "data": {
                "type": "inAppPurchaseLocalizations",
                "attributes": {"locale": locale, "name": name, "description": beschreibung},
                "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}},
            }
        })


def preis(asc: ASC, iap_id: str) -> None:
    try:
        plan = asc.get(f"/v2/inAppPurchases/{iap_id}/iapPriceSchedule?include=manualPrices")
        if plan.get("included"):
            print("  Preisplan steht schon")
            return
    except APIError as e:
        if e.status != 404:
            raise

    punkte = asc.get_all(
        f"/v2/inAppPurchases/{iap_id}/pricePoints?filter[territory]={BASIS_LAND}&limit=200"
    )
    treffer = [p for p in punkte if p["attributes"]["customerPrice"] == PREIS_EUR]
    if not treffer:
        sys.exit(f"Kein Preispunkt {PREIS_EUR} € in {BASIS_LAND} gefunden")
    punkt_id = treffer[0]["id"]
    print(f"  Preis {PREIS_EUR} € ({BASIS_LAND}), Rest der Welt nach Apple")
    asc.post("/v1/inAppPurchasePriceSchedules", {
        "data": {
            "type": "inAppPurchasePriceSchedules",
            "relationships": {
                "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                "baseTerritory": {"data": {"type": "territories", "id": BASIS_LAND}},
                "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": "${preis}"}]},
            },
        },
        "included": [{
            "type": "inAppPurchasePrices",
            "id": "${preis}",
            "attributes": {"startDate": None},
            "relationships": {
                "inAppPurchasePricePoint": {"data": {"type": "inAppPurchasePricePoints", "id": punkt_id}},
            },
        }],
    })


def verfuegbarkeit(asc: ASC, iap_id: str) -> None:
    try:
        asc.get(f"/v2/inAppPurchases/{iap_id}/inAppPurchaseAvailability")
        print("  Verfügbarkeit steht schon")
        return
    except APIError as e:
        if e.status != 404:
            raise
    laender = [t["id"] for t in asc.get_all("/v1/territories?limit=200")]
    print(f"  Verfügbar in {len(laender)} Ländern und künftigen")
    asc.post("/v1/inAppPurchaseAvailabilities", {
        "data": {
            "type": "inAppPurchaseAvailabilities",
            "attributes": {"availableInNewTerritories": True},
            "relationships": {
                "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                "availableTerritories": {"data": [{"type": "territories", "id": t} for t in laender]},
            },
        }
    })


def pruefbild(asc: ASC, iap_id: str, pfad: Path) -> None:
    try:
        vorhanden = asc.get(f"/v2/inAppPurchases/{iap_id}/appStoreReviewScreenshot")
        if vorhanden.get("data"):
            print("  Prüfbild steht schon")
            return
    except APIError as e:
        if e.status != 404:
            raise
    blob = pfad.read_bytes()
    print(f"  Prüfbild {pfad.name} ({len(blob)} Bytes)")
    antwort = asc.post("/v1/inAppPurchaseAppStoreReviewScreenshots", {
        "data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots",
            "attributes": {"fileName": pfad.name, "fileSize": len(blob)},
            "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}},
        }
    })
    if not antwort:
        return
    bild = antwort["data"]
    asc.upload(bild["attributes"]["uploadOperations"], blob)
    asc.patch(f"/v1/inAppPurchaseAppStoreReviewScreenshots/{bild['id']}", {
        "data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots",
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
    iap_id = anlegen(asc)
    if not iap_id:
        print("  (Probelauf – ohne Produkt keine weiteren Schritte)")
        return
    sprachen(asc, iap_id)
    preis(asc, iap_id)
    verfuegbarkeit(asc, iap_id)
    if args.screenshot:
        pruefbild(asc, iap_id, args.screenshot)
    print("Fertig." if args.apply else "Probelauf – nichts geschrieben.")


if __name__ == "__main__":
    main()
