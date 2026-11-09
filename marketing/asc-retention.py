#!/usr/bin/env python3
"""Legt die Retention-Nachricht für GolfTrack Pro samt Halte-Angeboten an.

    python3.12 marketing/asc-retention.py --issuer <UUID>                   # Probelauf
    python3.12 marketing/asc-retention.py --issuer <UUID> --apply           # anlegen
    python3.12 marketing/asc-retention.py --issuer <UUID> --apply --submit  # + zur Prüfung

Die Nachricht erscheint, wenn jemand in den iOS-Einstellungen beginnt, Pro zu kündigen
(also *vor* der Kündigung, im Unterschied zum Win-back-Angebot danach). Wer berechtigt
ist, sieht statt des Bildes ein Halte-Angebot:

- Monatsabo: 3 Monate je 2,99 € (statt 5 €), ab 2 bezahlten Monaten
- Jahresabo: nächstes Jahr 39,99 € (statt 50 €), ab 1 bezahltem Monat

Dasselbe Angebot frühestens nach 12 Monaten wieder, damit Kündigen-Anklicken kein
Dauerrabatt wird. Übrige Länder nach Apples Entsprechungen zum deutschen Preis.
Die App braucht dafür keinen Code – Apple zeigt und verrechnet das Angebot selbst.

Apples Regeln für den Text: Überschrift ≤ 66, Text ≤ 144 Zeichen, **keine Preise,
Rabatte oder Angebote** im Text (sehen auch Nicht-Berechtigte → sonst Ablehnung).
Erlaubt sind sachliche Aussagen darüber, was ohne Abo wegfällt.

Wiederholbar: Vorhandene Angebote (gleiche offerId), Nachricht (gleicher
Referenzname) und Sprachen werden übernommen bzw. nur angeglichen. Eine Version lässt
sich nach dem Anlegen weder ändern noch löschen – nur ihre Texte, solange sie nicht
APPROVED ist. Für geänderte Texte nach der Freigabe legt das Skript eine neue Version an.
"""

from __future__ import annotations

import argparse

from asc_api import APP_ID, ASC, APIError

BASIS_LAND = "DEU"
REFERENZNAME = "Pro behalten"

ANGEBOTE = [
    # Produkt-ID, offerId, Referenzname, Preis DE, Dauer, Perioden, bezahlte Monate
    ("GolfTrackPro_abo", "pro_retention_monat_299", "Halten Pro monatlich 3x 2,99 EUR",
     2.99, "ONE_MONTH", 3, 2),
    ("GolfTrackPro_abo_jahr", "pro_retention_jahr_3999", "Halten Pro jaehrlich 39,99 EUR",
     39.99, "ONE_YEAR", 1, 1),
]
WARTEN_MONATE = 12

# Überschrift ≤ 66, Text ≤ 144 Zeichen. Begriffe wie in der App-Kaufseite.
TEXTE = {
    "de-DE": ("Bleib bei GolfTrack Pro",
              "Ohne Pro fallen die Audio-Trainings und die vollständigen Tipps weg, "
              "und in der App erscheint wieder Werbung."),
    "en-US": ("Stay with GolfTrack Pro",
              "Without Pro you lose the audio trainings and the full tips, "
              "and ads come back in the app."),
    "en-GB": ("Stay with GolfTrack Pro",
              "Without Pro you lose the audio trainings and the full tips, "
              "and ads come back in the app."),
    "fr-FR": ("Restez avec GolfTrack Pro",
              "Sans Pro, vous perdez les entraînements audio et les conseils complets, "
              "et la publicité revient dans l’app."),
    "it": ("Resta con GolfTrack Pro",
           "Senza Pro perdi gli allenamenti audio e i consigli completi, "
           "e nell’app torna la pubblicità."),
    "es-ES": ("Quédate con GolfTrack Pro",
              "Sin Pro pierdes los entrenamientos de audio y los consejos completos, "
              "y vuelven los anuncios a la app."),
    "pl": ("Zostań z GolfTrack Pro",
           "Bez Pro tracisz treningi audio i pełne porady, "
           "a w aplikacji znów pojawią się reklamy."),
    "cs": ("Zůstaňte s GolfTrack Pro",
           "Bez Pro přijdete o audio tréninky a úplné tipy "
           "a v aplikaci se znovu zobrazí reklamy."),
}


def pruefe_texte() -> None:
    for sprache, (kopf, text) in TEXTE.items():
        if len(kopf) > 66 or len(text) > 144:
            raise SystemExit(f"{sprache}: zu lang ({len(kopf)}/66, {len(text)}/144)")
        if any(z in kopf + text for z in "€$%0123456789"):
            raise SystemExit(f"{sprache}: Preis/Zahl im Text – lehnt Apple ab")


def abos(asc: ASC) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for gruppe in asc.get_all(f"/v1/apps/{APP_ID}/subscriptionGroups?limit=20"):
        for abo in asc.get_all(f"/v1/subscriptionGroups/{gruppe['id']}/subscriptions?limit=50"):
            out[abo["attributes"]["productId"]] = abo
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


def angebot(asc: ASC, abo: dict, offer_id: str, name: str, preis: float, dauer: str,
            perioden: int, bezahlt: int) -> str | None:
    """Liefert die ID des (vorhandenen oder neuen) Halte-Angebots."""
    abo_id = abo["id"]
    for o in asc.get_all(f"/v1/subscriptions/{abo_id}/retentionOffers?limit=50"):
        if o["attributes"].get("offerId") == offer_id:
            print(f"   {offer_id} steht schon")
            return o["id"]
    punkte = preispunkte(asc, abo_id, preis, preis_laender(asc, abo_id))
    print(f"   {offer_id}: {preis:.2f} € in DE, {len(punkte)} Länder, {perioden}× {dauer}, "
          f"ab {bezahlt} bezahlten Monaten, alle {WARTEN_MONATE} Monate")
    included = [
        {
            "type": "retentionOfferPrices",
            "id": f"${{p{i}}}",
            "relationships": {
                "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": punkt}},
            },
        }
        for i, (_, punkt) in enumerate(sorted(punkte.items()))
    ]
    antwort = asc.post("/v1/retentionOffers", {
        "data": {
            "type": "retentionOffers",
            "attributes": {
                "referenceName": name,
                "offerId": offer_id,
                "duration": dauer,
                "offerMode": "PAY_AS_YOU_GO",
                "periodCount": perioden,
                "customerEligibilityPaidSubscriptionDurationInMonths": bezahlt,
                "customerEligibilityWaitBetweenOffersInMonths": WARTEN_MONATE,
            },
            "relationships": {
                "subscription": {"data": {"type": "subscriptions", "id": abo_id}},
                "prices": {"data": [{"type": "retentionOfferPrices", "id": e["id"]} for e in included]},
            },
        },
        "included": included,
    })
    if antwort:
        print("   ✓ Angebot angelegt")
    return (antwort.get("data") or {}).get("id")


def nachricht(asc: ASC) -> str | None:
    for m in asc.get_all(f"/v1/apps/{APP_ID}/retentionMessages?limit=20"):
        if m["attributes"].get("referenceName") == REFERENZNAME:
            print(f"   Nachricht „{REFERENZNAME}“ steht schon ({m['id']})")
            return m["id"]
    print(f"   Nachricht „{REFERENZNAME}“ anlegen")
    antwort = asc.post("/v1/retentionMessages", {
        "data": {
            "type": "retentionMessages",
            "attributes": {"referenceName": REFERENZNAME},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    return (antwort.get("data") or {}).get("id")


def version(asc: ASC, nachricht_id: str | None) -> tuple[str | None, str]:
    """Bearbeitbare Version (vorhanden oder neu) und ihr Zustand."""
    if nachricht_id:
        versionen = asc.get_all(f"/v1/retentionMessages/{nachricht_id}/versions?limit=20")
        for v in versionen:
            zustand = v["attributes"].get("state", "?")
            if zustand in ("PREPARE_FOR_SUBMISSION", "READY_FOR_REVIEW", "WAITING_FOR_REVIEW",
                           "IN_REVIEW", "REJECTED", "DEVELOPER_REJECTED"):
                print(f"   Version {v['id']} ({zustand}) wird verwendet")
                return v["id"], zustand
        if versionen:
            print(f"   nur freigegebene Versionen ({', '.join(v['attributes'].get('state', '?') for v in versionen)})"
                  " – Texte werden nur geändert, wenn sie abweichen")
            return versionen[0]["id"], versionen[0]["attributes"].get("state", "?")
    print("   neue Version (nur Text, ohne Bild) anlegen")
    antwort = asc.post("/v1/retentionMessageVersions", {
        "data": {
            "type": "retentionMessageVersions",
            "relationships": {
                "retentionMessage": {"data": {"type": "retentionMessages", "id": nachricht_id or "?"}},
            },
        }
    })
    return (antwort.get("data") or {}).get("id"), "PREPARE_FOR_SUBMISSION"


def neue_version(asc: ASC, nachricht_id: str) -> str | None:
    antwort = asc.post("/v1/retentionMessageVersions", {
        "data": {
            "type": "retentionMessageVersions",
            "relationships": {"retentionMessage": {"data": {"type": "retentionMessages", "id": nachricht_id}}},
        }
    })
    return (antwort.get("data") or {}).get("id")


def texte(asc: ASC, nachricht_id: str | None, version_id: str | None, zustand: str) -> str | None:
    vorhanden = {}
    if version_id:
        try:
            vorhanden = {l["attributes"]["locale"]: l
                         for l in asc.get_all(f"/v1/retentionMessageVersions/{version_id}/localizations?limit=50")}
        except APIError as e:
            if e.status != 404:
                raise
    abweichend = [s for s, (k, t) in TEXTE.items()
                  if s not in vorhanden
                  or (vorhanden[s]["attributes"].get("header"), vorhanden[s]["attributes"].get("body")) != (k, t)]
    if not abweichend:
        print("   alle Texte aktuell")
        return version_id
    if zustand == "APPROVED" and nachricht_id:
        print(f"   Texte weichen ab ({', '.join(abweichend)}) – freigegebene Version, lege neue an")
        version_id, vorhanden = neue_version(asc, nachricht_id), {}
    for sprache in abweichend:
        kopf, text = TEXTE[sprache]
        if sprache in vorhanden:
            print(f"   {sprache}: Text angleichen")
            asc.patch(f"/v1/retentionMessageLocalizations/{vorhanden[sprache]['id']}", {
                "data": {"type": "retentionMessageLocalizations", "id": vorhanden[sprache]["id"],
                         "attributes": {"header": kopf, "body": text}}
            })
        else:
            print(f"   {sprache}: „{kopf}“ ({len(text)} Zeichen)")
            asc.post("/v1/retentionMessageLocalizations", {
                "data": {
                    "type": "retentionMessageLocalizations",
                    "attributes": {"locale": sprache, "header": kopf, "body": text},
                    "relationships": {"retentionMessageVersion": {
                        "data": {"type": "retentionMessageVersions", "id": version_id or "?"}}},
                }
            })
    return version_id


def zuordnen(asc: ASC, abo: dict, nachricht_id: str | None, angebot_id: str | None) -> None:
    abo_id = abo["id"]
    aktuell = None
    try:
        aktuell = (asc.get(f"/v1/subscriptions/{abo_id}/relationships/retentionMessage").get("data") or {}).get("id")
    except APIError as e:
        if e.status != 404:
            raise
    if nachricht_id and aktuell == nachricht_id:
        print("   Nachricht schon zugeordnet")
    else:
        print("   Nachricht zuordnen")
        asc.patch(f"/v1/subscriptions/{abo_id}/relationships/retentionMessage",
                  {"data": {"type": "retentionMessages", "id": nachricht_id or "?"}})
    if not angebot_id:
        if not asc.apply:
            print("   Angebot an die Nachricht hängen")
        return
    gezeigt = {d["id"] for d in asc.get_all(f"/v1/subscriptions/{abo_id}/relationships/retentionMessageOffers?limit=50")}
    if angebot_id in gezeigt:
        print("   Angebot hängt schon an der Nachricht")
        return
    print("   Angebot an die Nachricht hängen")
    asc.post(f"/v1/subscriptions/{abo_id}/relationships/retentionMessageOffers",
             {"data": [{"type": "retentionOffers", "id": angebot_id}]})


def einreichen(asc: ASC, version_id: str) -> None:
    zustand = asc.get(f"/v1/retentionMessageVersions/{version_id}")["data"]["attributes"].get("state")
    if zustand != "PREPARE_FOR_SUBMISSION":
        print(f"   Version ist {zustand} – nichts einzureichen")
        return
    # Einen leeren Entwurf weiterverwenden (API-Entwürfe lassen sich nicht löschen),
    # nie einen, in dem schon etwas anderes liegt – das würde mit eingereicht.
    entwurf = None
    for s in asc.get_all(f"/v1/reviewSubmissions?filter[app]={APP_ID}&filter[state]=READY_FOR_REVIEW&limit=20"):
        if not asc.get_all(f"/v1/reviewSubmissions/{s['id']}/items?limit=5"):
            entwurf = s["id"]
            print(f"   leeren Prüfentwurf {entwurf} weiterverwenden")
            break
    if entwurf is None:
        entwurf = asc.post("/v1/reviewSubmissions", {
            "data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                     "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}
        })["data"]["id"]
        print(f"   Prüfentwurf {entwurf} angelegt")
    asc.post("/v1/reviewSubmissionItems", {
        "data": {"type": "reviewSubmissionItems", "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": entwurf}},
            "retentionMessageVersion": {"data": {"type": "retentionMessageVersions", "id": version_id}},
        }}
    })
    asc.patch(f"/v1/reviewSubmissions/{entwurf}", {
        "data": {"type": "reviewSubmissions", "id": entwurf, "attributes": {"submitted": True}}
    })
    print(f"   ✓ eingereicht (Submission {entwurf})")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--issuer", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--submit", action="store_true", help="Version zur Prüfung einreichen (mit --apply)")
    args = ap.parse_args()
    pruefe_texte()
    asc = ASC(args.issuer, apply=args.apply)

    alle = abos(asc)
    angebote: dict[str, str | None] = {}
    print("── Halte-Angebote ──")
    for produkt, offer_id, name, preis, dauer, perioden, bezahlt in ANGEBOTE:
        abo = alle[produkt]
        print(f" {produkt} ({abo['attributes'].get('state')})")
        try:
            angebote[produkt] = angebot(asc, abo, offer_id, name, preis, dauer, perioden, bezahlt)
        except APIError as e:
            print(f"   ✗ {e.detail}")
            angebote[produkt] = None

    print("── Nachricht ──")
    nachricht_id = nachricht(asc)
    version_id, zustand = version(asc, nachricht_id)
    version_id = texte(asc, nachricht_id, version_id, zustand)

    print("── Zuordnung ──")
    for produkt, *_ in ANGEBOTE:
        print(f" {produkt}")
        try:
            zuordnen(asc, alle[produkt], nachricht_id, angebote.get(produkt))
        except APIError as e:
            print(f"   ✗ {e.detail}")

    if args.submit:
        print("── Prüfung ──")
        if not args.apply or not version_id:
            print("   [Probelauf] Version würde eingereicht")
        else:
            einreichen(asc, version_id)

    if not args.apply:
        print("\nProbelauf – nichts geschrieben. Zum Anlegen dasselbe Kommando mit --apply.")


if __name__ == "__main__":
    main()
