#!/usr/bin/env python3
"""Legt die kostenlose Testphase (Einführungsangebot) für das Training-Abo an.

    python3 marketing/asc-trial.py --issuer <UUID>                # Probelauf
    python3 marketing/asc-trial.py --issuer <UUID> --apply        # schreiben
    python3 marketing/asc-trial.py --issuer <UUID> --apply --ersetzen

3 Tage gratis, danach der normale Monatspreis. Apple gewährt ein
Einführungsangebot je Abo-Gruppe nur einmal pro Apple-ID – wer schon einmal
getestet oder abonniert hat, bekommt es nicht erneut. Die App zeigt die
Testphase von selbst an (`SubscriptionManager.freeTrialLabel`), sobald StoreKit
sie liefert; dafür ist kein App-Update nötig.

Einführungsangebote gelten je Land, deshalb ein Eintrag pro Land, in dem das
Abo einen Preis hat. Wiederholbar: Länder, in denen die 3-Tage-Testphase schon
steht, werden übersprungen. Steht dort ein anderes Angebot (z. B. 1 Woche), wird
es nur mit `--ersetzen` gelöscht und neu angelegt.

Nur das Training-Abo: Pro enthält den KI-Caddy, dessen Gespräche bei
ElevenLabs Geld kosten – eine Gratisphase dort wäre ein offenes Scheunentor.
"""

from __future__ import annotations

import argparse
import sys

from asc_api import APP_ID, ASC, APIError

PRODUKTE = ["Trainingsvideos_abo"]
DAUER = "THREE_DAYS"
MODUS = "FREE_TRIAL"


def abos(asc: ASC) -> dict[str, str]:
    """Produkt-ID → ASC-ID aller Abos der App."""
    out: dict[str, str] = {}
    for gruppe in asc.get_all(f"/v1/apps/{APP_ID}/subscriptionGroups?limit=20"):
        for abo in asc.get_all(f"/v1/subscriptionGroups/{gruppe['id']}/subscriptions?limit=50"):
            out[abo["attributes"]["productId"]] = abo["id"]
    return out


def preis_laender(asc: ASC, abo_id: str) -> list[str]:
    """Alle Länder, in denen das Abo einen Preis hat – nur dort geht ein Angebot."""
    laender: set[str] = set()
    pfad = f"/v1/subscriptions/{abo_id}/prices?include=territory&limit=200"
    while pfad:
        seite = asc.get(pfad)
        for eintrag in seite.get("data", []):
            land = (eintrag.get("relationships", {}).get("territory", {}).get("data") or {}).get("id")
            if land:
                laender.add(land)
        pfad = seite.get("links", {}).get("next", "")
    return sorted(laender)


def bestehende_angebote(asc: ASC, abo_id: str) -> dict[str, dict]:
    """Land → vorhandenes Einführungsangebot (id, Dauer, Modus)."""
    out: dict[str, dict] = {}
    pfad = f"/v1/subscriptions/{abo_id}/introductoryOffers?include=territory&limit=200"
    while pfad:
        seite = asc.get(pfad)
        for eintrag in seite.get("data", []):
            land = (eintrag.get("relationships", {}).get("territory", {}).get("data") or {}).get("id")
            if land:
                out[land] = {"id": eintrag["id"], **eintrag["attributes"]}
        pfad = seite.get("links", {}).get("next", "")
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="3-Tage-Testphase anlegen")
    parser.add_argument("--issuer", required=True)
    parser.add_argument("--apply", action="store_true", help="wirklich schreiben")
    parser.add_argument("--ersetzen", action="store_true",
                        help="abweichende Angebote löschen und durch die Testphase ersetzen")
    args = parser.parse_args()

    asc = ASC(args.issuer, apply=args.apply)
    vorhanden = abos(asc)

    for produkt in PRODUKTE:
        abo_id = vorhanden.get(produkt)
        if abo_id is None:
            print(f"{produkt}: nicht gefunden – übersprungen\n")
            continue

        laender = preis_laender(asc, abo_id)
        angebote = bestehende_angebote(asc, abo_id)
        print(f"── {produkt} ──")
        print(f"   {len(laender)} Länder mit Preis · {len(angebote)} mit Einführungsangebot")

        fertig, abweichend, neu = [], [], []
        for land in laender:
            alt = angebote.get(land)
            if alt is None:
                neu.append(land)
            elif alt.get("duration") == DAUER and alt.get("offerMode") == MODUS:
                fertig.append(land)
            else:
                abweichend.append(land)

        print(f"   schon 3 Tage gratis: {len(fertig)} · neu: {len(neu)} · abweichend: {len(abweichend)}")
        for land in abweichend[:5]:
            a = angebote[land]
            print(f"     {land}: {a.get('offerMode')} {a.get('duration')} ×{a.get('numberOfPeriods')}")
        if abweichend and not args.ersetzen:
            print("   abweichende Länder bleiben, wie sie sind (--ersetzen zum Überschreiben)")

        offen = neu + (abweichend if args.ersetzen else [])
        if not offen:
            print("   nichts zu tun\n")
            continue
        if not args.apply:
            print(f"   Probelauf: würde {len(offen)} Länder anlegen, z. B. {', '.join(offen[:6])} …\n")
            continue

        geschrieben, fehler = 0, []
        for i, land in enumerate(offen, 1):
            try:
                if land in abweichend:
                    asc.delete(f"/v1/subscriptionIntroductoryOffers/{angebote[land]['id']}")
                asc.post("/v1/subscriptionIntroductoryOffers", {
                    "data": {
                        "type": "subscriptionIntroductoryOffers",
                        "attributes": {
                            "duration": DAUER,
                            "offerMode": MODUS,
                            "numberOfPeriods": 1,
                        },
                        "relationships": {
                            "subscription": {"data": {"type": "subscriptions", "id": abo_id}},
                            "territory": {"data": {"type": "territories", "id": land}},
                        },
                    }
                })
                geschrieben += 1
            except APIError as e:
                fehler.append(f"{land}: {e.detail[:110]}")
            if i % 25 == 0 or i == len(offen):
                print(f"   … {i}/{len(offen)}")

        print(f"   ✓ {geschrieben} Länder angelegt" + (f", {len(fehler)} Fehler" if fehler else ""))
        for f in fehler[:5]:
            print(f"     ✗ {f}")
        print()

    if not args.apply:
        print("Probelauf – nichts geschrieben. Zum Anlegen dasselbe Kommando mit --apply.")


if __name__ == "__main__":
    try:
        main()
    except APIError as e:
        sys.exit(str(e))
