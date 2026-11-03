#!/usr/bin/env python3
"""Angebotscodes „2 Wochen Pro geschenkt“ für die Weiterempfehlung.

    python3 marketing/asc-referral-codes.py --issuer <UUID>                    # Probelauf
    python3 marketing/asc-referral-codes.py --issuer <UUID> --apply            # Angebot + Codes anlegen
    python3 marketing/asc-referral-codes.py --issuer <UUID> --export codes.txt # fertige Codes holen

Wer die App fünf Freunden empfohlen hat, bekommt von golftrack.app einen dieser
Einmalcodes (`web/src/lib/referral.ts`, Tabelle `referral_reward_codes`). Das
Angebot hängt am Monatsabo `GolfTrackPro_abo`: 2 Wochen gratis, danach **ohne**
Verlängerung (`autoRenewEnabled: false`) – geschenkt heißt, es wird nichts
abgebucht. Gilt für Neu-, Bestands- und frühere Kunden.

Apple erzeugt Einmalcodes im Hintergrund; `--export` holt sie, sobald sie fertig
sind, eine Zeile je Code. Danach auf den Server laden:
`web/deploy/referral-codes.sh codes.txt`.
"""

from __future__ import annotations

import argparse
import datetime as dt
import urllib.request

from asc_api import API, APP_ID, ASC

PRODUKT = "GolfTrackPro_abo"
NAME = "Weiterempfehlung 2 Wochen"
ANZAHL = 1000
# Einmalcodes laufen höchstens sechs Monate.
GUELTIG_TAGE = 180


def abo_id(asc: ASC) -> str:
    for gruppe in asc.get_all(f"/v1/apps/{APP_ID}/subscriptionGroups?limit=20"):
        for abo in asc.get_all(f"/v1/subscriptionGroups/{gruppe['id']}/subscriptions?limit=50"):
            if abo["attributes"]["productId"] == PRODUKT:
                return abo["id"]
    raise SystemExit(f"{PRODUKT} nicht gefunden")


def laender(asc: ASC, abo: str) -> list[str]:
    out: set[str] = set()
    for p in asc.get_all(f"/v1/subscriptions/{abo}/prices?include=territory&limit=200"):
        land = (p.get("relationships", {}).get("territory", {}).get("data") or {}).get("id")
        if land:
            out.add(land)
    return sorted(out)


def angebot(asc: ASC, abo: str) -> str | None:
    for o in asc.get_all(f"/v1/subscriptions/{abo}/offerCodes?limit=50"):
        if o["attributes"]["name"] == NAME:
            print(f"   Angebot steht schon: {o['id']}")
            return o["id"]
    land = laender(asc, abo)
    print(f"   Lege Angebot „{NAME}“ an: 2 Wochen gratis, ohne Verlängerung, {len(land)} Länder")
    included = [
        {
            "type": "subscriptionOfferCodePrices",
            "id": f"${{p{i}}}",
            "relationships": {"territory": {"data": {"type": "territories", "id": t}}},
        }
        for i, t in enumerate(land)
    ]
    antwort = asc.post("/v1/subscriptionOfferCodes", {
        "data": {
            "type": "subscriptionOfferCodes",
            "attributes": {
                "name": NAME,
                "customerEligibilities": ["NEW", "EXISTING", "EXPIRED"],
                "offerEligibility": "REPLACE_INTRO_OFFERS",
                "offerMode": "FREE_TRIAL",
                "duration": "TWO_WEEKS",
                "numberOfPeriods": 1,
                "autoRenewEnabled": False,
            },
            "relationships": {
                "subscription": {"data": {"type": "subscriptions", "id": abo}},
                "prices": {"data": [{"type": e["type"], "id": e["id"]} for e in included]},
            },
        },
        "included": included,
    })
    return antwort.get("data", {}).get("id")


def einmalcodes(asc: ASC, angebot_id: str) -> list[dict]:
    return asc.get_all(f"/v1/subscriptionOfferCodes/{angebot_id}/oneTimeUseCodes?limit=50")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--issuer", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--export", metavar="DATEI")
    args = ap.parse_args()
    asc = ASC(args.issuer, apply=args.apply)

    abo = abo_id(asc)
    angebot_id = angebot(asc, abo)
    if not angebot_id:
        print("\nProbelauf – nichts geschrieben. Zum Anlegen dasselbe Kommando mit --apply.")
        return

    stapel = einmalcodes(asc, angebot_id)
    for s in stapel:
        a = s["attributes"]
        print(f"   Stapel {s['id']}: {a.get('numberOfCodes')} Codes, bis {a.get('expirationDate')}, aktiv={a.get('active')}")

    if args.export:
        codes: list[str] = []
        for s in stapel:
            req = urllib.request.Request(f"{API}/v1/subscriptionOfferCodeOneTimeUseCodes/{s['id']}/values")
            req.add_header("Authorization", f"Bearer {asc.token}")
            req.add_header("Accept", "text/csv")
            with urllib.request.urlopen(req, timeout=90, context=asc.ssl) as resp:
                text = resp.read().decode()
            codes += [z.strip() for z in text.splitlines() if z.strip() and z.strip().lower() != "code"]
        with open(args.export, "w") as f:
            f.write("\n".join(codes) + "\n")
        print(f"   ✓ {len(codes)} Codes nach {args.export}")
        return

    if not stapel:
        bis = (dt.date.today() + dt.timedelta(days=GUELTIG_TAGE)).isoformat()
        print(f"   Lege {ANZAHL} Einmalcodes an, gültig bis {bis}")
        asc.post("/v1/subscriptionOfferCodeOneTimeUseCodes", {
            "data": {
                "type": "subscriptionOfferCodeOneTimeUseCodes",
                "attributes": {"numberOfCodes": ANZAHL, "expirationDate": bis},
                "relationships": {"offerCode": {"data": {"type": "subscriptionOfferCodes", "id": angebot_id}}},
            }
        })


if __name__ == "__main__":
    main()
