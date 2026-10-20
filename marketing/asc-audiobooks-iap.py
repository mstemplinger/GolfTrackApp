#!/usr/bin/env python3
"""Legt den Einmalkauf „Audiobooks für immer" in App Store Connect an.

    python3 marketing/asc-audiobooks-iap.py --issuer <UUID>                       # Probelauf
    python3 marketing/asc-audiobooks-iap.py --issuer <UUID> --apply               # schreiben
    python3 marketing/asc-audiobooks-iap.py --issuer <UUID> --apply --screenshot bild.png

Produkt-ID wie in `SubscriptionManager.audiobooksLifetimeProductID`:
`Audiobooks_lifetime`, nicht verbrauchbar (Non-Consumable), 100,00 € in
Deutschland, für die übrigen
Länder Apples eigene Entsprechungen (Preisplan mit Basisland DEU – Apple
rechnet die anderen Länder selbst nach, solange dort kein Preis von Hand steht).

Wiederholbar: Was schon steht (Produkt, Sprachen, Preis, Verfügbarkeit,
Prüfbild), wird übersprungen.

Danach von Hand in der Weboberfläche: Version per „Zur Prüfung hinzufügen" in
den Entwurf, dann auf der IAP-Seite „Zur Prüfung hinzufügen ▾" →
„iOS-Übermittlungsentwurf" und gemeinsam übermitteln. Die App-Version mit der
neuen Kaufseite muss mit eingereicht werden – ältere Builds kennen das Produkt nicht.

Aufgebaut wie `asc-adfree-iap.py`; nur Produkt, Preis und Texte unterscheiden sich.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from asc_api import APP_ID, ASC, APIError, md5_hex

PRODUCT_ID = "Audiobooks_lifetime"
REFERENZNAME = "Audiobooks für immer"
PREIS_EUR = 100.00
BASIS_LAND = "DEU"

# Anzeigename höchstens 30, Beschreibung höchstens 45 Zeichen.
SPRACHEN = {
    "de-DE": ("Audiobooks für immer", "Alle Audiobooks, auch künftige, ohne Abo"),
    "en-US": ("Audiobooks forever", "All audiobooks, future ones too, no sub"),
    "fr-FR": ("Livres audio à vie", "Tous les livres audio, même futurs"),
    "it": ("Audiolibri per sempre", "Tutti gli audiolibri, anche futuri"),
    "es-ES": ("Audiolibros para siempre", "Todos los audiolibros, también futuros"),
}

PRUEF_NOTIZ = (
    "Non-consumable purchase that permanently unlocks all audio training lessons (audiobooks) "
    "in the Training tab, including lessons added in future app updates. It grants the same "
    "access as the monthly Training subscription, without expiry. To see the purchase screen: "
    "Training tab → tap any lesson with a crown (or 'Pro freischalten') → tab 'Für immer'. "
    "The audio files ship inside the app bundle; no server is involved."
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
    treffer = [p for p in punkte if abs(float(p["attributes"]["customerPrice"]) - PREIS_EUR) < 0.005]
    if not treffer:
        nah = sorted(punkte, key=lambda p: abs(float(p["attributes"]["customerPrice"]) - PREIS_EUR))[:3]
        sys.exit(f"Kein Preispunkt {PREIS_EUR:.2f} € in {BASIS_LAND} – nächste: "
                 + ", ".join(f"{p['attributes']['customerPrice']} €" for p in nah))
    punkt_id = treffer[0]["id"]
    print(f"  Preis {PREIS_EUR:.2f} € ({BASIS_LAND}), Rest der Welt nach Apple")
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
