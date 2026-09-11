#!/usr/bin/env python3
"""Setzt die Abo-Preise in App Store Connect – weltweit, ausgehend von Deutschland.

    python3 marketing/asc-prices.py --issuer <UUID>            # Probelauf
    python3 marketing/asc-prices.py --issuer <UUID> --apply    # schreiben

Der Preis wird für Deutschland gewählt; für die übrigen Länder übernimmt das
Skript die Entsprechungen, die Apple selbst vorschlägt (`equalizations`) – genau
das, was die Oberfläche von App Store Connect beim „Preis für alle Länder
festlegen" tut. Ein Land einzeln umzustellen und 174 auf dem alten Stand zu
lassen, wäre schlimmer als gar nichts zu tun.

`preserveCurrentPrice` steuert, was mit Bestandskunden passiert:

    False  – der neue Preis gilt auch für sie. Apple fragt sie vorher um
             Zustimmung; wer nicht zustimmt, dessen Abo endet zur nächsten
             Verlängerung.
    True   – Bestandskunden behalten ihren Preis unbefristet.

Bei einem laufenden Abo ist ein Startdatum Pflicht – ohne gilt der Aufruf als
Erstpreis und Apple weist ihn ab.

Das Skript ist wiederholbar: Länder, für die der Zielpreis schon gilt **oder
geplant ist**, werden übersprungen. Ein Abbruch mitten im Lauf lässt sich also
einfach fortsetzen.
"""

from __future__ import annotations

import argparse
import sys

from asc_api import APP_ID, ASC, APIError

BASIS_LAND = "DEU"

# Produkt-ID → Zielpreis in Euro
ZIELE = {
    "Caddy_abo":           10.00,
    "Trainingsvideos_abo": 10.00,
    "GolfTrackPro_abo":    15.00,
}

# Bestandskunden auf den neuen Preis (mit Apples Zustimmungsabfrage).
BESTAND_BEHAELT_PREIS = False

# Ab wann der neue Preis gilt. **Pflicht bei laufenden Abos**: Ohne Datum gilt
# der Aufruf als Erstpreis, und den weist Apple nach der Freigabe zurück
# („Initial price cannot be created again after subscription is approved").
# Bestandskunden bekommen Apples Zustimmungsabfrage unabhängig davon, mit
# Apples eigener Vorlauffrist.
START_DATUM = "2026-09-12"


def abos(asc: ASC) -> dict[str, str]:
    gefunden: dict[str, str] = {}
    for gruppe in asc.get_all(f"/v1/apps/{APP_ID}/subscriptionGroups?limit=20"):
        for abo in asc.get_all(f"/v1/subscriptionGroups/{gruppe['id']}/subscriptions?limit=50"):
            gefunden[abo["attributes"]["productId"]] = abo["id"]
    return gefunden


def basis_preispunkt(asc: ASC, abo_id: str, ziel: float) -> dict:
    punkte = asc.get_all(
        f"/v1/subscriptions/{abo_id}/pricePoints?filter[territory]={BASIS_LAND}&limit=200"
    )
    treffer = [p for p in punkte
               if abs(float(p["attributes"]["customerPrice"]) - ziel) < 0.005]
    if not treffer:
        nah = sorted(punkte, key=lambda p: abs(float(p["attributes"]["customerPrice"]) - ziel))[:3]
        raise SystemExit(
            f"Kein Preispunkt {ziel:.2f} € für {BASIS_LAND}. Am nächsten: "
            + ", ".join(f"{p['attributes']['customerPrice']} €" for p in nah)
        )
    return treffer[0]


def aktuelle_preise(asc: ASC, abo_id: str) -> dict[str, set[float]]:
    """Land → alle hinterlegten Preise, **auch die erst geplanten**.

    Nur so erkennt ein zweiter Lauf, dass die Änderung schon eingetragen ist:
    Bis zum Starttag steht als geltender Preis weiterhin der alte.
    """
    stand: dict[str, set[float]] = {}
    pfad = f"/v1/subscriptions/{abo_id}/prices?include=subscriptionPricePoint,territory&limit=200"
    while pfad:
        seite = asc.get(pfad)
        punkte = {i["id"]: i["attributes"] for i in seite.get("included", [])
                  if i["type"] == "subscriptionPricePoints"}
        for eintrag in seite.get("data", []):
            rel = eintrag.get("relationships", {})
            pp_id = (rel.get("subscriptionPricePoint", {}).get("data") or {}).get("id")
            land = (rel.get("territory", {}).get("data") or {}).get("id")
            if pp_id in punkte and land:
                stand.setdefault(land, set()).add(float(punkte[pp_id]["customerPrice"]))
        pfad = seite.get("links", {}).get("next", "")
    return stand


def land_von(preispunkt: dict) -> str | None:
    rel = preispunkt.get("relationships", {}).get("territory", {}).get("data")
    return rel["id"] if rel else None


def main() -> None:
    parser = argparse.ArgumentParser(description="Abo-Preise setzen")
    parser.add_argument("--issuer", required=True)
    parser.add_argument("--apply", action="store_true", help="wirklich schreiben")
    args = parser.parse_args()

    asc = ASC(args.issuer, apply=args.apply)
    vorhanden = abos(asc)

    print("Bestandskunden: " + ("behalten ihren Preis" if BESTAND_BEHAELT_PREIS
                                else "kommen auf den neuen Preis (Apple fragt sie)") + "\n")

    for produkt, ziel in ZIELE.items():
        abo_id = vorhanden.get(produkt)
        if abo_id is None:
            print(f"{produkt}: nicht gefunden – übersprungen\n")
            continue

        basis = basis_preispunkt(asc, abo_id, ziel)
        stand = aktuelle_preise(asc, abo_id)
        alt = stand.get(BASIS_LAND, set())
        print(f"── {produkt} ──")
        print(f"   Deutschland {'/'.join(f'{p:.2f}' for p in sorted(alt)) or '?'} € "
              f"→ {ziel:.2f} € ab {START_DATUM} (Erlös {basis['attributes']['proceeds']} €)")

        # `include=territory` ist nötig, sonst kommen die Entsprechungen ohne
        # Länderkennung – dann ließe sich nicht erkennen, was schon gesetzt ist.
        entsprechungen = asc.get_all(
            f"/v1/subscriptionPricePoints/{basis['id']}/equalizations?include=territory&limit=200"
        )
        plan = [basis] + entsprechungen
        offen = []
        for punkt in plan:
            land = land_von(punkt)
            neu = float(punkt["attributes"]["customerPrice"])
            if land and any(abs(p - neu) < 0.005 for p in stand.get(land, ())):
                continue          # steht schon so oder ist schon geplant
            offen.append(punkt)

        print(f"   {len(plan)} Länder insgesamt · {len(offen)} zu ändern")
        if not offen:
            print("   nichts zu tun\n")
            continue

        if not args.apply:
            beispiele = ", ".join(
                f"{land_von(p) or '?'} {p['attributes']['customerPrice']}" for p in offen[:5]
            )
            print(f"   Probelauf, Beispiele: {beispiele} …\n")
            continue

        geschrieben, fehler = 0, []
        for i, punkt in enumerate(offen, 1):
            try:
                asc.post("/v1/subscriptionPrices", {
                    "data": {
                        "type": "subscriptionPrices",
                        "attributes": {
                            "startDate": START_DATUM,
                            "preserveCurrentPrice": BESTAND_BEHAELT_PREIS,
                        },
                        "relationships": {
                            "subscription": {"data": {"type": "subscriptions", "id": abo_id}},
                            "subscriptionPricePoint": {
                                "data": {"type": "subscriptionPricePoints", "id": punkt["id"]}
                            },
                        },
                    }
                })
                geschrieben += 1
            except APIError as e:
                fehler.append(f"{land_von(punkt) or punkt['id'][:12]}: {e.detail[:90]}")
            if i % 25 == 0 or i == len(offen):
                print(f"   … {i}/{len(offen)}")

        print(f"   ✓ {geschrieben} Länder gesetzt"
              + (f", {len(fehler)} Fehler" if fehler else ""))
        for f in fehler[:5]:
            print(f"     ✗ {f}")
        print()

    if not args.apply:
        print("Probelauf – nichts geschrieben. Zum Setzen dasselbe Kommando mit --apply.")


if __name__ == "__main__":
    try:
        main()
    except APIError as e:
        sys.exit(str(e))
