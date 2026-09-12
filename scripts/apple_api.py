"""Apple API transport adapted from Tasks; credentials never appear in output."""
from __future__ import annotations
import base64
import json
import os
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Iterator
from pathlib import Path
from typing import Any

API_ROOT = "https://api.appstoreconnect.apple.com/v1"

class ReleaseError(RuntimeError):
    """A safe, actionable release failure."""

def base64url(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def read_der_length(payload: bytes, offset: int) -> tuple[int, int]:
    if offset >= len(payload):
        raise ReleaseError("invalid App Store Connect signature length")
    first = payload[offset]
    offset += 1
    if first < 0x80:
        return first, offset
    width = first & 0x7F
    if width == 0 or width > 2 or offset + width > len(payload):
        raise ReleaseError("invalid App Store Connect signature length")
    return int.from_bytes(payload[offset : offset + width], "big"), offset + width


def raw_es256_signature(der: bytes) -> bytes:
    offset = 0
    if not der or der[offset] != 0x30:
        raise ReleaseError("invalid App Store Connect signature")
    sequence_length, offset = read_der_length(der, offset + 1)
    if offset + sequence_length != len(der):
        raise ReleaseError("invalid App Store Connect signature sequence")

    values: list[bytes] = []
    for _ in range(2):
        if offset >= len(der) or der[offset] != 0x02:
            raise ReleaseError("invalid App Store Connect signature integer")
        length, offset = read_der_length(der, offset + 1)
        if length == 0 or offset + length > len(der):
            raise ReleaseError("invalid App Store Connect signature integer length")
        value = der[offset : offset + length]
        offset += length
        value = value.lstrip(b"\0") or b"\0"
        if len(value) > 32:
            raise ReleaseError("invalid App Store Connect signature width")
        values.append(value.rjust(32, b"\0"))
    if offset != len(der):
        raise ReleaseError("invalid App Store Connect signature trailer")
    return b"".join(values)


def create_token(key_id: str, issuer_id: str, private_key: str, now: int) -> tuple[str, int]:
    expires = now + 1_200
    header = base64url(
        json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}, separators=(",", ":")).encode()
    )
    claims = base64url(
        json.dumps(
            {"iss": issuer_id, "iat": now, "exp": expires, "aud": "appstoreconnect-v1"},
            separators=(",", ":"),
        ).encode()
    )
    signing_input = f"{header}.{claims}".encode("ascii")
    normalized_key = private_key.replace("\\n", "\n")
    key_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", prefix="asc-key-", suffix=".p8", delete=False
        ) as handle:
            handle.write(normalized_key)
            key_path = Path(handle.name)
        key_path.chmod(0o600)
        result = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", str(key_path)],
            input=signing_input,
            check=True,
            capture_output=True,
        )
    finally:
        if key_path is not None:
            key_path.unlink(missing_ok=True)
    return f"{header}.{claims}.{base64url(raw_es256_signature(result.stdout))}", expires


class AppStoreConnectClient:
    def __init__(self, key_id: str, issuer_id: str, private_key: str) -> None:
        self._key_id = key_id
        self._issuer_id = issuer_id
        self._private_key = private_key
        self._token = ""
        self._token_expires = 0

    def _authorization(self) -> str:
        now = int(time.time())
        if now >= self._token_expires - 120:
            self._token, self._token_expires = create_token(
                self._key_id,
                self._issuer_id,
                self._private_key,
                now,
            )
        return f"Bearer {self._token}"

    def request(
        self,
        method: str,
        path_or_url: str,
        *,
        query: dict[str, str] | None = None,
        body: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        url = (
            path_or_url
            if path_or_url.startswith("https://")
            else f"{API_ROOT}/{path_or_url.lstrip('/')}"
        )
        if query:
            url = f"{url}?{urllib.parse.urlencode(query)}"
        payload = None if body is None else json.dumps(body, separators=(",", ":")).encode()

        for attempt in range(6):
            request = urllib.request.Request(
                url,
                method=method,
                data=payload,
                headers={
                    "Authorization": self._authorization(),
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                },
            )
            try:
                with urllib.request.urlopen(request, timeout=30) as response:
                    content = response.read()
                return {} if not content else json.loads(content)
            except urllib.error.HTTPError as error:
                retryable = method == "GET" and (error.code == 429 or 500 <= error.code < 600)
                if retryable and attempt < 5:
                    time.sleep(min(2**attempt, 30))
                    continue
                detail = ""
                try:
                    errors = json.loads(error.read()).get("errors", [])
                    detail = "; ".join(
                        str(item.get("detail", "")) for item in errors if item.get("detail")
                    )
                except (json.JSONDecodeError, AttributeError):
                    pass
                suffix = f": {detail}" if detail else ""
                raise ReleaseError(
                    f"App Store Connect {method} failed with HTTP {error.code}{suffix}"
                ) from error
            except (urllib.error.URLError, TimeoutError) as error:
                if method == "GET" and attempt < 5:
                    time.sleep(min(2**attempt, 30))
                    continue
                detail = (
                    "after retries" if method == "GET" else "without retrying an ambiguous write"
                )
                raise ReleaseError(f"App Store Connect request failed {detail}") from error
        raise AssertionError("unreachable")

    def pages(self, path: str, query: dict[str, str]) -> Iterator[dict[str, Any]]:
        response = self.request("GET", path, query=query)
        while True:
            yield response
            next_url = response.get("links", {}).get("next")
            if not next_url:
                return
            response = self.request("GET", next_url)



def credentials() -> tuple[str, str, str]:
    names = ("APP_STORE_CONNECT_API_KEY_ID", "APP_STORE_CONNECT_ISSUER_ID", "APP_STORE_CONNECT_API_KEY_P8")
    if all(os.environ.get(name) for name in names):
        return tuple(os.environ[name] for name in names)
    prefix = os.environ.get("APPLE_CREDENTIAL_PREFIX", "/garden/ci")
    values = []
    for suffix in ("api-key-id", "issuer-id", "api-key-p8"):
        result = subprocess.run([
            "aws", "ssm", "get-parameter", "--name", f"{prefix}/app-store-connect-{suffix}",
            "--with-decryption", "--query", "Parameter.Value", "--output", "text"
        ], check=True, capture_output=True, text=True)
        values.append(result.stdout.strip())
    return tuple(values)
