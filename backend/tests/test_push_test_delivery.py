import base64
import os

import requests
import creds as C  # noqa: E402
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec

API = C.BASE_URL + "/api"


def _auth():
    r = requests.post(f"{API}/auth/login", json=dict(C.WORKER), timeout=20)
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _b64(b):
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def test_public_key_available():
    d = requests.get(f"{API}/push/public-key", timeout=20).json()
    assert d["available"] is True and d["key"]


def test_unknown_endpoint_reports_not_signed_up():
    d = requests.post(f"{API}/push/test", json={"endpoint": "https://web.push.apple.com/not-registered"}, headers=_auth(), timeout=20).json()
    assert d["ok"] is False and "isn't signed up" in d["message"]


def test_vapid_signing_reaches_push_service():
    h = _auth()
    pub = ec.generate_private_key(ec.SECP256R1()).public_key().public_bytes(
        serialization.Encoding.X962, serialization.PublicFormat.UncompressedPoint)
    ep = "https://fcm.googleapis.com/fcm/send/pytest-fake-endpoint"
    sub = {"endpoint": ep, "keys": {"p256dh": _b64(pub), "auth": _b64(os.urandom(16))}}
    requests.post(f"{API}/push/subscribe", json={"subscription": sub}, headers=h, timeout=20).raise_for_status()
    try:
        d = requests.post(f"{API}/push/test", json={"endpoint": ep}, headers=h, timeout=30).json()
        assert d["web"]["configured"] is True and d["web"]["devices"] == 1
        # the key loaded and the request was signed + sent: the only error is the push service's answer for a fake endpoint
        assert d["web"]["errors"] and d["web"]["errors"][0][:3] in ("400", "403", "404", "410"), d
        assert "deserialize" not in d["web"]["errors"][0]
    finally:
        requests.post(f"{API}/push/unsubscribe", json={"subscription": sub}, headers=h, timeout=20)
