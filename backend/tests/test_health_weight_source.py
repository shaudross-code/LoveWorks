import os
from datetime import datetime, timezone

import requests

API = os.environ["REACT_APP_BACKEND_URL"].rstrip("/") + "/api"


def _token(email, password):
    r = requests.post(f"{API}/auth/login", json={"email": email, "password": password}, timeout=20)
    r.raise_for_status()
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _today():
    return datetime.now(timezone.utc).date().isoformat()


def test_bluetooth_scale_weight_source_round_trip():
    h = _token("lovetest@loveworks.com", "Love123!")
    body = {"date": _today(), "active_kcal": 0, "total_kcal": 0, "weight_kg": 80.25, "weight_source": "scale_bluetooth"}
    assert requests.post(f"{API}/health/daily", json=body, headers=h, timeout=20).json() == {"ok": True}
    day = requests.get(f"{API}/health/me?days=1", headers=h, timeout=20).json()["days"][0]
    assert day["weight_kg"] == 80.2 or day["weight_kg"] == 80.3
    assert day["weight_source"] == "scale_bluetooth"


def test_unknown_weight_source_falls_back_to_apple_health():
    h = _token("lovetest@loveworks.com", "Love123!")
    body = {"date": _today(), "active_kcal": 0, "total_kcal": 0, "weight_kg": 81.0, "weight_source": "bogus"}
    requests.post(f"{API}/health/daily", json=body, headers=h, timeout=20).raise_for_status()
    day = requests.get(f"{API}/health/me?days=1", headers=h, timeout=20).json()["days"][0]
    assert day["weight_source"] == "apple_health"


def test_weight_only_upload_keeps_calories():
    h = _token("lovetest@loveworks.com", "Love123!")
    requests.post(f"{API}/health/daily", json={"date": _today(), "active_kcal": 200, "total_kcal": 900}, headers=h, timeout=20).raise_for_status()
    requests.post(f"{API}/health/daily", json={"date": _today(), "active_kcal": 0, "total_kcal": 0, "weight_kg": 81.3,
                                               "weight_source": "scale_bluetooth"}, headers=h, timeout=20).raise_for_status()
    day = requests.get(f"{API}/health/me?days=1", headers=h, timeout=20).json()["days"][0]
    assert day["active_kcal"] >= 200 and day["total_kcal"] >= 900
    assert day["weight_source"] == "scale_bluetooth"
