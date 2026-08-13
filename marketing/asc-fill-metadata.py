#!/usr/bin/env python3
"""Füllt die Metadaten einer App-Store-Connect-Version über die API.

Liest die Texte aus marketing/release-notes-<version>.md – eine Quelle, kein
Copy-Paste. Schreibt pro Sprache die "Neue Funktionen"-Notizen, die Notizen für
die App-Review und stellt die Veröffentlichung auf manuell.

Es wird NICHT zur Prüfung eingereicht. Das bleibt bewusst ein Klick im Browser.

Aufruf:
    # erst ansehen, was passieren würde (schreibt nichts):
    python3 marketing/asc-fill-metadata.py --issuer <ISSUER-UUID>

    # dann tatsächlich schreiben:
    python3 marketing/asc-fill-metadata.py --issuer <ISSUER-UUID> --apply

Die Issuer-ID steht in App Store Connect unter
Benutzer und Zugriff → Integrationen → App Store Connect API.
"""
from __future__ import annotations

import argparse
import base64
import json
import re
import ssl
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, utils as asym_utils

APP_ID = "6767996957"          # GolfTrack im App Store
KEY_ID = "9CR8JBB4GT"
KEY_PATH = Path.home() / ".appstoreconnect" / "private_keys" / f"AuthKey_{KEY_ID}.p8"
API = "https://api.appstoreconnect.apple.com"

# Sprachpräfix im Markdown → ASC-Locales, die damit gefüllt werden
LOCALE_PREFIX = {"de": "de", "en": "en", "fr": "fr", "it": "it", "es": "es"}

WHATS_NEW_LIMIT = 4000
REVIEW_NOTES_LIMIT = 4000


def ssl_context() -> ssl.SSLContext:
    """Die python.org-Installation bringt keine CA-Zertifikate mit – certifi nutzen,
    damit das Skript ohne Eingriff in die Python-Installation läuft."""
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        return ssl.create_default_context()


# ── JWT ──────────────────────────────────────────────────────────────────────

def b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def make_token(issuer: str) -> str:
    """ES256-JWT für die App-Store-Connect-API (20 Minuten gültig)."""
    key = serialization.load_pem_private_key(KEY_PATH.read_bytes(), password=None)
    header = {"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}
    now = int(time.time())
    payload = {"iss": issuer, "iat": now, "exp": now + 20 * 60, "aud": "appstoreconnect-v1"}
    signing_input = f"{b64(json.dumps(header).encode())}.{b64(json.dumps(payload).encode())}"
    der = key.sign(signing_input.encode(), ec.ECDSA(hashes.SHA256()))
    r, s = asym_utils.decode_dss_signature(der)
    raw = r.to_bytes(32, "big") + s.to_bytes(32, "big")   # JOSE erwartet R||S, nicht DER
    return f"{signing_input}.{b64(raw)}"


# ── HTTP ─────────────────────────────────────────────────────────────────────

class ASC:
    def __init__(self, issuer: str, apply: bool):
        self.token = make_token(issuer)
        self.apply = apply
        self.ssl = ssl_context()

    def _request(self, method: str, path: str, body: dict | None = None) -> dict:
        url = path if path.startswith("http") else f"{API}{path}"
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", f"Bearer {self.token}")
        if data:
            req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, timeout=60, context=self.ssl) as resp:
                raw = resp.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            detail = e.read().decode(errors="replace")
            try:
                errors = json.loads(detail).get("errors", [])
                detail = "; ".join(f"{x.get('title')}: {x.get('detail')}" for x in errors) or detail
            except json.JSONDecodeError:
                pass
            raise SystemExit(f"API-Fehler {e.code} bei {method} {url}\n  {detail}")

    def get(self, path: str) -> dict:
        return self._request("GET", path)

    def patch(self, path: str, body: dict) -> dict:
        if not self.apply:
            print(f"    [Probelauf] PATCH {path}")
            return {}
        return self._request("PATCH", path, body)

    def post(self, path: str, body: dict) -> dict:
        if not self.apply:
            print(f"    [Probelauf] POST {path}")
            return {}
        return self._request("POST", path, body)


# ── Release Notes einlesen ───────────────────────────────────────────────────

def parse_release_notes(path: Path) -> tuple[dict[str, str], str]:
    """Liefert {Sprachpräfix: Text} und die Review-Notizen aus dem Blockquote."""
    text = path.read_text(encoding="utf-8")
    sections = re.split(r"^## ", text, flags=re.MULTILINE)[1:]

    per_language: dict[str, str] = {}
    review_notes = ""

    for section in sections:
        head, _, body = section.partition("\n")
        body = body.strip().rstrip("-").strip()
        code = re.search(r"\(([a-z]{2})\)\s*$", head.strip())
        if code:
            per_language[code.group(1)] = body
        elif "Einreichung" in head:
            quote = [ln[2:].strip() for ln in body.splitlines() if ln.startswith("> ")]
            review_notes = " ".join(quote).strip()

    if not per_language:
        raise SystemExit(f"Keine Sprachabschnitte in {path} gefunden.")
    return per_language, review_notes


# ── Ablauf ───────────────────────────────────────────────────────────────────

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--issuer", required=True, help="Issuer-ID aus App Store Connect")
    ap.add_argument("--version", default="2.2")
    ap.add_argument("--apply", action="store_true", help="tatsächlich schreiben")
    ap.add_argument("--notes-file", default=None)
    ap.add_argument("--version-id", default=None,
                    help="ASC-ID der Version, falls der Name mehrdeutig ist")
    args = ap.parse_args()

    notes_path = Path(args.notes_file or f"marketing/release-notes-{args.version}.md")
    if not notes_path.exists():
        raise SystemExit(f"{notes_path} fehlt.")
    if not KEY_PATH.exists():
        raise SystemExit(f"API-Key nicht gefunden: {KEY_PATH}")

    per_language, review_notes = parse_release_notes(notes_path)
    print(f"Texte aus {notes_path}: {', '.join(sorted(per_language))}"
          f" | Review-Notizen: {len(review_notes)} Zeichen")
    if not args.apply:
        print("PROBELAUF – es wird nichts geschrieben. Mit --apply ausführen.\n")

    asc = ASC(args.issuer, args.apply)

    # 1) Version finden. Der Versionsname in App Store Connect kann von der
    #    reinen Nummer abweichen (z. B. "2.2 - Titel"), deshalb auch Präfix-Treffer.
    all_versions = asc.get(f"/v1/apps/{APP_ID}/appStoreVersions?limit=50").get("data", [])
    if args.version_id:
        matches = [v for v in all_versions if v["id"] == args.version_id]
    else:
        exact = [v for v in all_versions if v["attributes"]["versionString"] == args.version]
        matches = exact or [v for v in all_versions
                            if v["attributes"]["versionString"].startswith(args.version)]
    if not matches:
        print(f"Keine Version passend zu '{args.version}'. Vorhanden:")
        for v in all_versions[:10]:
            print(f'  {v["attributes"]["versionString"]!r}  {v["attributes"].get("appStoreState")}')
        raise SystemExit(1)
    if len(matches) > 1:
        print(f"Mehrere Versionen passen zu '{args.version}':")
        for v in matches:
            print(f'  id={v["id"]}  {v["attributes"]["versionString"]!r}')
        raise SystemExit("Mit --version-id eindeutig auswählen.")

    version = matches[0]
    version_id = version["id"]
    version_string = version["attributes"]["versionString"]
    state = version["attributes"].get("appStoreState") or version["attributes"].get("state")
    print(f"Version {version_string!r}: id={version_id}, Status={state}")

    if not re.fullmatch(r"\d+(\.\d+){0,2}", version_string):
        print(f"  ACHTUNG: {version_string!r} ist keine reine Versionsnummer. Apple erwartet "
              f"maximal drei durch Punkte getrennte Zahlen – das fällt bei der Einreichung auf.")

    editable = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
                "METADATA_REJECTED", "WAITING_FOR_REVIEW", "READY_FOR_REVIEW"}
    if state not in editable:
        raise SystemExit(f"Status {state} ist nicht bearbeitbar – hier wird nichts angefasst.")

    # 2) "Neue Funktionen" pro Sprache
    locs = asc.get(f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=50")
    existing = {item["attributes"]["locale"]: item["id"] for item in locs.get("data", [])}
    print(f"\nSprachen in dieser Version: {', '.join(sorted(existing)) or '(keine)'}")

    written = skipped = 0
    for locale, loc_id in sorted(existing.items()):
        prefix = locale.split("-")[0]
        text = per_language.get(prefix)
        if text is None:
            print(f"  {locale:8} übersprungen – kein Abschnitt für '{prefix}' in den Notes")
            skipped += 1
            continue
        if len(text) > WHATS_NEW_LIMIT:
            raise SystemExit(f"{locale}: Text zu lang ({len(text)} > {WHATS_NEW_LIMIT}).")
        print(f"  {locale:8} whatsNew ← {len(text)} Zeichen  «{text.splitlines()[0][:52]}…»")
        asc.patch(f"/v1/appStoreVersionLocalizations/{loc_id}", {
            "data": {"type": "appStoreVersionLocalizations", "id": loc_id,
                     "attributes": {"whatsNew": text}}})
        written += 1

    # 3) Notizen für die App-Review
    if review_notes:
        detail = asc.get(f"/v1/appStoreVersions/{version_id}/appStoreReviewDetail")
        detail_data = detail.get("data")
        print(f"\nReview-Notizen ← {len(review_notes)} Zeichen")
        if detail_data:
            asc.patch(f"/v1/appStoreReviewDetails/{detail_data['id']}", {
                "data": {"type": "appStoreReviewDetails", "id": detail_data["id"],
                         "attributes": {"notes": review_notes}}})
        else:
            asc.post("/v1/appStoreReviewDetails", {
                "data": {"type": "appStoreReviewDetails",
                         "attributes": {"notes": review_notes},
                         "relationships": {"appStoreVersion": {
                             "data": {"type": "appStoreVersions", "id": version_id}}}}})

    # 4) Veröffentlichung auf manuell – die Freigabe bleibt beim Nutzer
    print("releaseType ← MANUAL (Freigabe erfolgt von Hand)")
    asc.patch(f"/v1/appStoreVersions/{version_id}", {
        "data": {"type": "appStoreVersions", "id": version_id,
                 "attributes": {"releaseType": "MANUAL"}}})

    # 5) Gegenprobe
    if args.apply:
        print("\n── Gegenprobe (gelesen von der API) ──")
        check = asc.get(f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=50")
        for item in sorted(check.get("data", []), key=lambda x: x["attributes"]["locale"]):
            attrs = item["attributes"]
            value = (attrs.get("whatsNew") or "").splitlines()
            print(f"  {attrs['locale']:8} {'✓' if value else '— leer'} {value[0][:56] if value else ''}")
        detail = asc.get(f"/v1/appStoreVersions/{version_id}/appStoreReviewDetail")
        notes = (detail.get("data") or {}).get("attributes", {}).get("notes") or ""
        print(f"  Review-Notizen: {'✓ ' + str(len(notes)) + ' Zeichen' if notes else '— leer'}")
        ver = asc.get(f"/v1/appStoreVersions/{version_id}")
        print(f"  releaseType:    {ver['data']['attributes'].get('releaseType')}")

    print(f"\nFertig. {written} Sprachen geschrieben, {skipped} übersprungen.")
    print("Nicht eingereicht – 'Zur Prüfung freigeben' bleibt dein Klick.")


if __name__ == "__main__":
    main()
