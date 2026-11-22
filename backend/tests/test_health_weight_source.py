from datetime import datetime, timezone

import requests
import creds as C  # noqa: E402
TMP_PW = C.new_password()

API = C.BASE_URL + "/api"


def _token(email, password):
    r = requests.post(f"{API}/auth/login", json={"email": email, "password": password}, timeout=20)
    r.raise_for_status()
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _today():
    return datetime.now(timezone.utc).date().isoformat()


def test_bluetooth_scale_weight_source_round_trip():
    h = _token(C.WORKER["email"], C.WORKER["password"])
    body = {"date": _today(), "active_kcal": 0, "total_kcal": 0, "weight_kg": 80.25, "weight_source": "scale_bluetooth"}
    assert requests.post(f"{API}/health/daily", json=body, headers=h, timeout=20).json() == {"ok": True}
    day = requests.get(f"{API}/health/me?days=1", headers=h, timeout=20).json()["days"][0]
    assert day["weight_kg"] == 80.2 or day["weight_kg"] == 80.3
    assert day["weight_source"] == "scale_bluetooth"


def test_unknown_weight_source_falls_back_to_apple_health():
    h = _token(C.WORKER["email"], C.WORKER["password"])
    body = {"date": _today(), "active_kcal": 0, "total_kcal": 0, "weight_kg": 81.0, "weight_source": "bogus"}
    requests.post(f"{API}/health/daily", json=body, headers=h, timeout=20).raise_for_status()
    day = requests.get(f"{API}/health/me?days=1", headers=h, timeout=20).json()["days"][0]
    assert day["weight_source"] == "apple_health"


def test_weight_only_upload_keeps_calories():
    h = _token(C.WORKER["email"], C.WORKER["password"])
    requests.post(f"{API}/health/daily", json={"date": _today(), "active_kcal": 200, "total_kcal": 900}, headers=h, timeout=20).raise_for_status()
    requests.post(f"{API}/health/daily", json={"date": _today(), "active_kcal": 0, "total_kcal": 0, "weight_kg": 81.3,
                                               "weight_source": "scale_bluetooth"}, headers=h, timeout=20).raise_for_status()
    day = requests.get(f"{API}/health/me?days=1", headers=h, timeout=20).json()["days"][0]
    assert day["active_kcal"] >= 200 and day["total_kcal"] >= 900
    assert day["weight_source"] == "scale_bluetooth"


def _admin_health(admin_headers, worker_email):
    rows = requests.get(f"{API}/admin/worker-status", headers=admin_headers, timeout=20).json()
    rows = rows if isinstance(rows, list) else rows.get("workers", rows)
    return next(r["health"] for r in rows if r["worker"]["email"] == worker_email)


def test_new_worker_shares_by_default_and_can_turn_off():
    admin = _token(C.ADMIN["email"], C.ADMIN["password"])
    email = f"test_share_{datetime.now(timezone.utc).strftime('%H%M%S%f')}@loveworks.com"
    r = requests.post(f"{API}/workers", json={"email": email, "password": TMP_PW, "name": "Share Test"}, headers=admin, timeout=20)
    r.raise_for_status()
    wid = r.json()["id"]
    try:
        h = _token(email, TMP_PW)
        assert requests.get(f"{API}/health/me?days=1", headers=h, timeout=20).json()["share_with_admin"] is True
        requests.post(f"{API}/health/daily", json={"date": _today(), "active_kcal": 50, "total_kcal": 70, "weight_kg": 70,
                                                   "weight_source": "scale_bluetooth"}, headers=h, timeout=20).raise_for_status()
        shared = _admin_health(admin, email)
        assert shared["shared"] is True and shared["weight_kg"] == 70 and shared["weight_source"] == "scale_bluetooth"
        requests.patch(f"{API}/health/sharing", json={"share": False}, headers=h, timeout=20).raise_for_status()
        assert requests.get(f"{API}/health/me?days=1", headers=h, timeout=20).json()["share_with_admin"] is False
        assert _admin_health(admin, email) == {"shared": False}
    finally:
        requests.delete(f"{API}/workers/{wid}", headers=admin, timeout=20)


def test_undo_weight_clears_only_weight():
    h = _token(C.WORKER["email"], C.WORKER["password"])
    requests.post(f"{API}/health/daily", json={"date": _today(), "active_kcal": 300, "total_kcal": 1000, "weight_kg": 90,
                                               "weight_source": "scale_bluetooth"}, headers=h, timeout=20).raise_for_status()
    assert requests.delete(f"{API}/health/daily/{_today()}/weight", headers=h, timeout=20).json() == {"ok": True}
    day = requests.get(f"{API}/health/me?days=1", headers=h, timeout=20).json()["days"][0]
    assert day["weight_kg"] is None and day["weight_source"] is None
    assert day["active_kcal"] >= 300
    requests.post(f"{API}/health/daily", json={"date": _today(), "active_kcal": 0, "total_kcal": 0, "weight_kg": 81.3,
                                               "weight_source": "scale_bluetooth"}, headers=h, timeout=20).raise_for_status()
