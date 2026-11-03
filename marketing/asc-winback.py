#!/usr/bin/env python3
"""Legt die Rückkehr-Angebote (Win-back) für GolfTrack Pro an.

    python3 marketing/asc-winback.py --issuer <UUID>             # Probelauf
    python3 marketing/asc-winback.py --issuer <UUID> --apply     # schreiben

Wer Pro gekündigt hat, bekommt beim Wiederabschließen monatlich 4 € (statt 5 €,
12 Monate lang) bzw. jährlich 40 € (statt 50 €, erstes Jahr). Übrige Länder nach
Apples Entsprechungen zum deutschen Preis.

Apples Regeln: Win-back gilt nur für Kunden, die mindestens einen Monat bezahlt
haben – wer nur die 3 Gratistage hatte, ist nicht berechtigt. Abstand zur
letzten Kündigung 1 bis 24 Monate; dasselbe Angebot frühestens nach 12 Monaten
erneut, damit Kündigen-und-Zurückkommen kein Dauerrabatt wird. Die App zeigt den
Rückkehrpreis an, wenn StoreKit das Angebot für den Kunden freigibt
(`SubscriptionManager.winBackOffer(for:)`).

Wiederholbar: Steht ein Angebot mit derselben offerId schon, wird es übersprungen.
"""

from __future__ import annotations

import argparse
import datetime as dt

from asc_api import APP_ID, ASC

BASIS_LAND = "DEU"

ANGEBOTE = [
    # Produkt-ID, offerId, Referenzname, Preis DE, Dauer, Perioden
    ("GolfTrackPro_abo", "pro_winback_monat_4", "Rueckkehr Pro monatlich 4 EUR", 4.00, "ONE_MONTH", 12),
    ("GolfTrackPro_abo_jahr", "pro_winback_jahr_40", "Rueckkehr Pro jaehrlich 40 EUR", 40.00, "ONE_YEAR", 1),
]


def abos(asc: ASC) -> dict[str, str]:
    out: dict[str, str] = {}
    for gruppe in asc.get_all(f"/v1/apps/{APP_ID}/subscriptionGroups?limit=20"):
        for abo in asc.get_all(f"/v1/subscriptionGroups/{gruppe['id']}/subscriptions?limit=50"):
            out[abo["attributes"]["productId"]] = abo["id"]
    return out


def preis_laender(asc: ASC, abo_id: str) -> set[str]:
    laender: set[str] = set()
    for p in asc.get_all(f"/v1/subscriptions/{abo_id}/prices?include=territory&limit=200"):
        land = (p.get("relationships", {}).get("territory", {}).get("data") or {}).get("id")
        if land:
            laender.add(land)
    return laender


def preispunkte(asc: ASC, abo_id: str, ziel: float, laender: set[str]) -> dict[str, str]:
    """Land → Preispunkt-ID: deutscher Punkt für `ziel` plus Apples Entsprechungen."""
    basis = next(
        (p for p in asc.get_all(f"/v1/subscriptions/{abo_id}/pricePoints?filter[territory]={BASIS_LAND}&limit=200")
         if abs(float(p["attributes"]["customerPrice"]) - ziel) < 0.001),
        None,
    )
    if basis is None:
        raise SystemExit(f"Kein Preispunkt {ziel} € in {BASIS_LAND}")
    out = {BASIS_LAND: basis["id"]}
    pfad = f"/v1/subscriptionPricePoints/{basis['id']}/equalizations?include=territory&limit=200"
    while pfad:
        seite = asc.get(pfad)
        for p in seite.get("data", []):
            land = (p.get("relationships", {}).get("territory", {}).get("data") or {}).get("id")
            if land in laender:
                out[land] = p["id"]
        pfad = seite.get("links", {}).get("next", "")
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--issuer", required=True)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    asc = ASC(args.issuer, apply=args.apply)

    alle = abos(asc)
    start = (dt.date.today() + dt.timedelta(days=2)).isoformat()
    for produkt, offer_id, name, preis, dauer, perioden in ANGEBOTE:
        abo_id = alle[produkt]
        print(f"── {produkt} ──")
        vorhanden = {w["attributes"]["offerId"] for w in asc.get_all(f"/v1/subscriptions/{abo_id}/winBackOffers?limit=50")}
        if offer_id in vorhanden:
            print(f"   {offer_id} steht schon")
            continue
        punkte = preispunkte(asc, abo_id, preis, preis_laender(asc, abo_id))
        print(f"   {offer_id}: {preis:.2f} € in DE, {len(punkte)} Länder, {perioden}× {dauer}, ab {start}")
        if not args.apply:
            continue
        included = [
            {
                "type": "winBackOfferPrices",
                "id": f"${{p{i}}}",
                "relationships": {
                    "territory": {"data": {"type": "territories", "id": land}},
                    "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": punkt}},
                },
            }
            for i, (land, punkt) in enumerate(sorted(punkte.items()))
        ]
        asc.post("/v1/winBackOffers", {
            "data": {
                "type": "winBackOffers",
                "attributes": {
                    "referenceName": name,
                    "offerId": offer_id,
                    "duration": dauer,
                    "offerMode": "PAY_AS_YOU_GO",
                    "periodCount": perioden,
                    "customerEligibilityPaidSubscriptionDurationInMonths": 1,
                    "customerEligibilityTimeSinceLastSubscribedInMonths": {"minimum": 1, "maximum": 24},
                    "customerEligibilityWaitBetweenOffersInMonths": 12,
                    "startDate": start,
                    "priority": "HIGH",
                    "promotionIntent": "USE_AUTO_GENERATED_ASSETS",
                },
                "relationships": {
                    "subscription": {"data": {"type": "subscriptions", "id": abo_id}},
                    "prices": {"data": [{"type": "winBackOfferPrices", "id": e["id"]} for e in included]},
                },
            },
            "included": included,
        })
        print("   ✓ angelegt")
    if not args.apply:
        print("\nProbelauf – nichts geschrieben. Zum Anlegen dasselbe Kommando mit --apply.")


if __name__ == "__main__":
    main()
