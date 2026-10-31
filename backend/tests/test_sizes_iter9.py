# Iteration 9: My Sizes feature — worker self-service, admin edit + notifications, sandbox isolation, cascade delete
import os
import uuid
import pytest
import requests

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL").rstrip("/")
API = f"{BASE_URL}/api"
LOVE_ID = "2ccdb3b8-6f97-459c-9cc9-ebf49917c90d"


def login(email, pw):
    r = requests.post(f"{API}/auth/login", json={"email": email, "password": pw})
    if r.status_code != 200:
        pytest.skip(f"login failed for {email}: {r.status_code}")
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture(scope="module")
def admin_h():
    return login("admin@loveworks.com", "admin123")


@pytest.fixture(scope="module")
def love_h():
    return login("lovetest@loveworks.com", "Love123!")


@pytest.fixture(scope="module")
def throwaway(admin_h):
    """Throwaway worker used for self-service & destructive tests."""
    email = f"test_sizes_{uuid.uuid4().hex[:8]}@example.com"
    r = requests.post(f"{API}/workers", json={"email": email, "password": "Passw0rd!x", "name": "TEST Sizes Worker"}, headers=admin_h)
    assert r.status_code in (200, 201), r.text
    w = r.json()
    wid = w.get("id") or w.get("user", {}).get("id")
    h = login(email, "Passw0rd!x")
    yield {"id": wid, "h": h, "email": email}
    requests.delete(f"{API}/workers/{wid}", headers=admin_h)


def notif_list(h):
    r = requests.get(f"{API}/notifications", headers=h)
    assert r.status_code == 200
    d = r.json()
    return d.get("items", d.get("notifications", d)) if isinstance(d, dict) else d


# --- Worker self-service ---
class TestMySizes:
    def test_unauth(self):
        assert requests.get(f"{API}/sizes/me").status_code == 401

    def test_default_doc(self, throwaway):
        r = requests.get(f"{API}/sizes/me", headers=throwaway["h"])
        assert r.status_code == 200
        d = r.json()
        assert d["fit"] is None and d["units"] == "imperial" and d["values"] == {} and d["updated_at"] is None

    def test_put_and_changes(self, throwaway):
        body = {"fit": "mens", "units": "imperial", "values": {"height": 180.34, "waist": 86.36, "shoe_us": 10, "gloves": "L", "top": "M", "bogus": "x"}}
        r = requests.put(f"{API}/sizes/me", json=body, headers=throwaway["h"])
        assert r.status_code == 200, r.text
        d = r.json()
        assert "bogus" not in d["sizes"]["values"]
        assert set(d["sizes"]["values"].keys()) == {"height", "waist", "shoe_us", "gloves", "top"}
        ch = {c["key"]: c for c in d["changes"]}
        assert set(ch) == {"fit", "height", "waist", "shoe_us", "gloves", "top"}
        assert ch["height"]["old"] == "—" and ch["height"]["new"] == "71 in"
        assert ch["shoe_us"]["new"] == "US 10"
        assert d["sizes"]["updated_by"]["role"] == "worker"
        assert d["sizes"]["updated_by"]["id"] == throwaway["id"]
        g = requests.get(f"{API}/sizes/me", headers=throwaway["h"]).json()
        assert g["values"]["height"] == 180.34 and g["fit"] == "mens"

    @pytest.mark.parametrize("body,msg", [
        ({"fit": "alien"}, "Invalid fit"),
        ({"units": "furlongs"}, "units"),
        ({"values": {"height": "abc"}}, "Height must be a number"),
        ({"values": {"height": 5000}}, "out of range"),
    ])
    def test_validation(self, throwaway, body, msg):
        r = requests.put(f"{API}/sizes/me", json=body, headers=throwaway["h"])
        assert r.status_code == 400
        assert msg in r.json().get("detail", "")

    def test_units_persist(self, throwaway):
        r = requests.put(f"{API}/sizes/me", json={"fit": "mens", "units": "metric", "values": {"height": 180.34}}, headers=throwaway["h"])
        assert r.status_code == 200
        assert requests.get(f"{API}/sizes/me", headers=throwaway["h"]).json()["units"] == "metric"
        r = requests.put(f"{API}/sizes/me", json={"values": {"height": 180.34}}, headers=throwaway["h"])
        assert r.json()["sizes"]["units"] == "metric"

    def test_delete_keeps_units(self, throwaway):
        r = requests.delete(f"{API}/sizes/me", headers=throwaway["h"])
        assert r.status_code == 200
        g = requests.get(f"{API}/sizes/me", headers=throwaway["h"]).json()
        assert g["values"] == {} and g["fit"] is None and g["units"] == "metric"


# --- Admin view/edit + notifications ---
class TestAdminSizes:
    def test_get_worker_sizes(self, admin_h):
        r = requests.get(f"{API}/workers/{LOVE_ID}/sizes", headers=admin_h)
        assert r.status_code == 200
        d = r.json()
        assert d["worker"]["id"] == LOVE_ID and d["worker"]["name"] == "Love Tester"
        assert "values" in d["sizes"]
        assert "password_hash" not in d["worker"]

    def test_unknown_404(self, admin_h):
        assert requests.get(f"{API}/workers/{uuid.uuid4()}/sizes", headers=admin_h).status_code == 404

    def test_worker_forbidden(self, love_h):
        assert requests.get(f"{API}/workers/{LOVE_ID}/sizes", headers=love_h).status_code == 403

    def test_admin_put_notify_flow(self, admin_h, throwaway):
        wid, wh = throwaway["id"], throwaway["h"]
        # worker prefers metric (set by earlier tests); ensure it
        requests.put(f"{API}/sizes/me", json={"units": "metric", "values": {}}, headers=wh)
        before = len(notif_list(wh))
        body = {"fit": "mens", "units": "imperial", "values": {"height": 180.34, "weight": 80, "shoe_us": 10, "gloves": "XL", "top": "L", "waist": 86.36}}
        r = requests.put(f"{API}/workers/{wid}/sizes", json=body, headers=admin_h)
        assert r.status_code == 200, r.text
        d = r.json()
        assert d["notified"] is True and len(d["changes"]) == 7
        assert d["sizes"]["units"] == "metric", "admin edit must not change worker units"
        assert d["sizes"]["updated_by"]["role"] == "admin"
        ch = {c["key"]: c for c in d["changes"]}
        assert ch["height"]["new"] == "180.3 cm"
        assert ch["shoe_us"]["new"] == "EU 43"
        assert ch["weight"]["new"] == "80 kg"
        items = notif_list(wh)
        assert len(items) == before + 1
        n = [i for i in items if i["type"] == "sizes_updated"][0]
        assert n["title"] == "Administrator updated your sizes"
        assert "+3 more" in n["body"] and " → " in n["body"] and ", " in n["body"]
        assert n["link"].startswith("/worker/sizes?changed=") and "height" in n["link"]
        assert isinstance(n["meta"]["changes"], list) and len(n["meta"]["changes"]) == 7
        # same payload again -> no changes, no notif
        r2 = requests.put(f"{API}/workers/{wid}/sizes", json=body, headers=admin_h).json()
        assert r2["changes"] == [] and r2["notified"] is False
        assert len(notif_list(wh)) == before + 1
        # change with notify false
        body["values"]["gloves"] = "L"
        body["notify"] = False
        r3 = requests.put(f"{API}/workers/{wid}/sizes", json=body, headers=admin_h).json()
        assert len(r3["changes"]) == 1 and r3["notified"] is False
        assert r3["changes"][0]["old"] == "XL" and r3["changes"][0]["new"] == "L"
        assert len(notif_list(wh)) == before + 1

    def test_imperial_format(self, admin_h, throwaway):
        wid, wh = throwaway["id"], throwaway["h"]
        requests.put(f"{API}/sizes/me", json={"units": "imperial", "values": {}}, headers=wh)
        r = requests.put(f"{API}/workers/{wid}/sizes", json={"fit": "mens", "values": {"height": 180.34, "shoe_us": 10, "weight": 80}, "notify": False}, headers=admin_h).json()
        ch = {c["key"]: c for c in r["changes"]}
        assert ch["height"]["new"] == "71 in" and ch["shoe_us"]["new"] == "US 10" and ch["weight"]["new"].endswith(" lb")
        assert r["sizes"]["units"] == "imperial"


# --- Sandbox isolation ---
class TestSandbox:
    def test_reviewer_cannot_read_real(self):
        h = login("reviewer@loveworks.com", "iLoveWorks2026!")
        assert requests.get(f"{API}/workers/{LOVE_ID}/sizes", headers=h).status_code == 404
        assert requests.put(f"{API}/workers/{LOVE_ID}/sizes", json={"values": {}}, headers=h).status_code == 404

    def test_demo_seeded_and_isolated(self, admin_h):
        dh = login("demo@loveworks.com", "DemoWorker2026!")
        d = requests.get(f"{API}/sizes/me", headers=dh).json()
        assert d["fit"] == "mens" and d["values"].get("shoe_us") == 10.5 and len(d["values"]) >= 15
        demo_id = d["user_id"]
        assert requests.get(f"{API}/workers/{demo_id}/sizes", headers=admin_h).status_code == 404


# --- Cascade delete ---
class TestCascade:
    def test_delete_worker_removes_sizes(self, admin_h):
        email = f"test_cascade_{uuid.uuid4().hex[:8]}@example.com"
        r = requests.post(f"{API}/workers", json={"email": email, "password": "Passw0rd!x", "name": "TEST Cascade"}, headers=admin_h)
        assert r.status_code in (200, 201)
        wid = r.json().get("id") or r.json().get("user", {}).get("id")
        assert requests.put(f"{API}/workers/{wid}/sizes", json={"fit": "womens", "values": {"height": 160}}, headers=admin_h).status_code == 200
        assert requests.delete(f"{API}/workers/{wid}", headers=admin_h).status_code in (200, 204)
        assert requests.get(f"{API}/workers/{wid}/sizes", headers=admin_h).status_code == 404
