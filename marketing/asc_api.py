"""Gemeinsame App-Store-Connect-Bausteine: ES256-JWT, SSL-Context, HTTP-Client.

Bewusst als eigenes Modul und nicht als Import aus asc-fill-metadata.py: dessen
Dateiname enthält Bindestriche und ist damit nicht importierbar. Das Release-Skript
bleibt unangetastet, weil es funktioniert und beim Veröffentlichen im Weg stünde,
wenn ein Refactoring es kaputtmacht.

Die Issuer-ID steht absichtlich nicht hier drin – sie kommt als Argument herein.
"""

from __future__ import annotations

import base64
import hashlib
import json
import ssl
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


def ssl_context() -> ssl.SSLContext:
    """Die python.org-Installation bringt keine CA-Zertifikate mit – certifi nutzen."""
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        return ssl.create_default_context()


def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def make_token(issuer: str) -> str:
    """ES256-JWT für die App-Store-Connect-API (20 Minuten gültig)."""
    key = serialization.load_pem_private_key(KEY_PATH.read_bytes(), password=None)
    header = {"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}
    now = int(time.time())
    payload = {"iss": issuer, "iat": now, "exp": now + 20 * 60, "aud": "appstoreconnect-v1"}
    signing_input = f"{_b64(json.dumps(header).encode())}.{_b64(json.dumps(payload).encode())}"
    der = key.sign(signing_input.encode(), ec.ECDSA(hashes.SHA256()))
    r, s = asym_utils.decode_dss_signature(der)
    raw = r.to_bytes(32, "big") + s.to_bytes(32, "big")   # JOSE erwartet R||S, nicht DER
    return f"{signing_input}.{_b64(raw)}"


class APIError(RuntimeError):
    """Fehler der ASC-API. Trägt den Status-Code, damit Aufrufer 404 tolerieren können."""

    def __init__(self, status: int, method: str, url: str, detail: str):
        super().__init__(f"API-Fehler {status} bei {method} {url}\n  {detail}")
        self.status = status
        self.detail = detail


class ASC:
    """Dünner Client. `apply=False` unterdrückt alle schreibenden Aufrufe."""

    def __init__(self, issuer: str, apply: bool = False, verbose: bool = False):
        self.token = make_token(issuer)
        self.apply = apply
        self.verbose = verbose
        self.ssl = ssl_context()

    # ── HTTP ─────────────────────────────────────────────────────────────────

    def _request(self, method: str, path: str, body: dict | None = None) -> dict:
        url = path if path.startswith("http") else f"{API}{path}"
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", f"Bearer {self.token}")
        if data:
            req.add_header("Content-Type", "application/json")
        if self.verbose:
            print(f"    → {method} {url}")
        try:
            with urllib.request.urlopen(req, timeout=90, context=self.ssl) as resp:
                raw = resp.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            detail = e.read().decode(errors="replace")
            try:
                errors = json.loads(detail).get("errors", [])
                detail = "; ".join(
                    f"{x.get('title')}: {x.get('detail')}" for x in errors
                ) or detail
            except json.JSONDecodeError:
                pass
            raise APIError(e.code, method, url, detail) from None

    def get(self, path: str) -> dict:
        return self._request("GET", path)

    def get_all(self, path: str) -> list[dict]:
        """Folgt der Paginierung und liefert alle `data`-Einträge."""
        out: list[dict] = []
        while path:
            page = self._request("GET", path)
            out.extend(page.get("data", []))
            path = page.get("links", {}).get("next", "")
        return out

    def post(self, path: str, body: dict) -> dict:
        if not self.apply:
            print(f"    [Probelauf] POST {path}")
            return {}
        return self._request("POST", path, body)

    def patch(self, path: str, body: dict) -> dict:
        if not self.apply:
            print(f"    [Probelauf] PATCH {path}")
            return {}
        return self._request("PATCH", path, body)

    def delete(self, path: str) -> dict:
        if not self.apply:
            print(f"    [Probelauf] DELETE {path}")
            return {}
        return self._request("DELETE", path)

    # ── Asset-Upload ─────────────────────────────────────────────────────────

    def upload(self, operations: list[dict], blob: bytes) -> None:
        """Spielt die von Apple vorgegebenen uploadOperations ab (je ein PUT-Stück)."""
        for op in operations:
            chunk = blob[op["offset"]:op["offset"] + op["length"]]
            req = urllib.request.Request(op["url"], data=chunk, method=op["method"])
            for header in op.get("requestHeaders", []):
                req.add_header(header["name"], header["value"])
            with urllib.request.urlopen(req, timeout=300, context=self.ssl) as resp:
                if resp.status not in (200, 201, 204):
                    raise RuntimeError(f"Upload-Stück fehlgeschlagen: HTTP {resp.status}")


def md5_hex(blob: bytes) -> str:
    """Apple verlangt die MD5-Summe beim Commit eines Assets."""
    return hashlib.md5(blob).hexdigest()


def png_size(path: Path) -> tuple[int, int]:
    """Breite/Höhe aus dem PNG-Header, ohne Pillow als Abhängigkeit."""
    import struct
    head = path.read_bytes()[:33]
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path.name} ist kein PNG")
    return struct.unpack(">II", head[16:24])
