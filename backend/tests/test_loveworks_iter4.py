"""LoveWorks iter4 regression: PWA smoke + Trips + Essentials + Peers + Concurrent clocks.

Scope: verify the newly added features from the review request against the deployed
REACT_APP_BACKEND_URL. All test-created data uses the TEST_ prefix and is cleaned up
via class-scoped teardown fixtures.
"""
import os
import uuid
import pytest
import requests

BASE = os.environ.get("REACT_APP_BACKEND_URL", "").rstrip("/")
assert BASE, "REACT_APP_BACKEND_URL is required"

ADMIN = {"email": "admin@clockwork.com", "password": "admin123"}
WORKER = {"email": "lovetest@loveworks.com", "password": "Love123!"}


def _login(creds):
    r = requests.post(f"{BASE}/api/auth/login", json=creds, timeout=15)
    assert r.status_code == 200, f"login failed {r.status_code} {r.text}"
    data = r.json()
    tok = data.get("access_token") or data.get("token")
    assert tok, f"no token in {data}"
    return tok, data.get("user", {})


@pytest.fixture(scope="session")
def admin_token():
    tok, _ = _login(ADMIN)
    return tok


@pytest.fixture(scope="session")
def worker_ctx():
    tok, user = _login(WORKER)
    # Ensure clean clock state
    try:
        requests.post(f"{BASE}/api/time/clock-out", headers={"Authorization": f"Bearer {tok}"}, timeout=15)
    except Exception:
        pass
    return {"token": tok, "user": user}


def _h(tok):
    return {"Authorization": f"Bearer {tok}"}


# --- PWA static assets ---
class TestPWA:
    def test_manifest(self):
        r = requests.get(f"{BASE}/manifest.json", timeout=15)
        assert r.status_code == 200
        j = r.json()
        assert j["short_name"] == "LoveWorks"
        assert j["start_url"] == "/"
        assert any(i["sizes"] == "192x192" for i in j["icons"])
        assert any(i["sizes"] == "512x512" for i in j["icons"])

    @pytest.mark.parametrize("path", ["/sw.js", "/icon-192.png", "/icon-512.png", "/apple-touch-icon.png"])
    def test_static(self, path):
        r = requests.get(f"{BASE}{path}", timeout=15)
        assert r.status_code == 200, f"{path} -> {r.status_code}"
        assert int(r.headers.get("content-length", len(r.content))) > 100


# --- Auth regression ---
class TestAuthRegression:
    def test_admin_login_and_me(self, admin_token):
        r = requests.get(f"{BASE}/api/auth/me", headers=_h(admin_token), timeout=15)
        assert r.status_code == 200
        assert r.json()["role"] == "admin"

    def test_worker_login_and_me(self, worker_ctx):
        r = requests.get(f"{BASE}/api/auth/me", headers=_h(worker_ctx["token"]), timeout=15)
        assert r.status_code == 200
        u = r.json()
        assert u["role"] == "worker"
        assert u["email"] == WORKER["email"]


# --- Concurrent clock-in / out ---
class TestConcurrentClocks:
    def test_two_concurrent_activities_then_close_all(self, worker_ctx):
        tok = worker_ctx["token"]
        # ensure clean
        requests.post(f"{BASE}/api/time/clock-out", headers=_h(tok), timeout=15)

        r1 = requests.post(f"{BASE}/api/time/clock-in", json={"activity": "working"}, headers=_h(tok), timeout=15)
        assert r1.status_code == 200, r1.text
        assert r1.json()["activity"] == "working"

        r2 = requests.post(f"{BASE}/api/time/clock-in", json={"activity": "self_care"}, headers=_h(tok), timeout=15)
        assert r2.status_code == 200, r2.text
        assert r2.json()["activity"] == "self_care"

        active = requests.get(f"{BASE}/api/time/active", headers=_h(tok), timeout=15).json()
        activities = {e["activity"] for e in active}
        assert {"working", "self_care"}.issubset(activities), f"missing concurrent, got {activities}"

        # Duplicate same activity must be rejected
        dup = requests.post(f"{BASE}/api/time/clock-in", json={"activity": "working"}, headers=_h(tok), timeout=15)
        assert dup.status_code == 400, dup.text

        # Close all
        out = requests.post(f"{BASE}/api/time/clock-out", headers=_h(tok), timeout=15)
        assert out.status_code == 200, out.text
        j = out.json()
        assert ("count" in j and j["count"] >= 2) or ("clock_out" in j)

        after = requests.get(f"{BASE}/api/time/active", headers=_h(tok), timeout=15).json()
        assert after == [] or len(after) == 0


# --- Goals / Trips ---
class TestGoalsAndTrips:
    created = []

    def test_create_goal(self, worker_ctx):
        tok = worker_ctx["token"]
        title = f"TEST_goal_{uuid.uuid4().hex[:6]}"
        r = requests.post(f"{BASE}/api/goals", params={"title": title, "target_amount": 100}, headers=_h(tok), timeout=15)
        assert r.status_code == 200, r.text
        g = r.json()
        assert g["title"] == title
        assert g.get("kind", "goal") == "goal"
        TestGoalsAndTrips.created.append(("goal", g["id"], tok))

        # verify GET
        lst = requests.get(f"{BASE}/api/goals", headers=_h(tok), timeout=15).json()
        assert any(x["id"] == g["id"] for x in lst)

    def test_edit_goal(self, worker_ctx):
        tok = worker_ctx["token"]
        assert TestGoalsAndTrips.created, "need created goal"
        _, gid, _ = TestGoalsAndTrips.created[0]
        new_title = f"TEST_goal_edited_{uuid.uuid4().hex[:4]}"
        r = requests.patch(f"{BASE}/api/goals/{gid}", json={"title": new_title, "target_amount": 250}, headers=_h(tok), timeout=15)
        assert r.status_code == 200, r.text
        # verify
        g = next((x for x in requests.get(f"{BASE}/api/goals", headers=_h(tok)).json() if x["id"] == gid), None)
        assert g and g["title"] == new_title
        assert float(g.get("target_amount") or 0) == 250

    def test_create_trip(self, worker_ctx):
        tok = worker_ctx["token"]
        title = f"TEST_trip_{uuid.uuid4().hex[:6]}"
        r = requests.post(f"{BASE}/api/goals", params={"title": title, "kind": "trip"}, headers=_h(tok), timeout=15)
        assert r.status_code == 200, r.text
        t = r.json()
        assert t["kind"] == "trip"
        TestGoalsAndTrips.created.append(("trip", t["id"], tok))

        lst = requests.get(f"{BASE}/api/goals", params={"kind": "trip"}, headers=_h(tok), timeout=15).json()
        assert any(x["id"] == t["id"] for x in lst), f"trip {t['id']} not in trip list"

    def test_admin_sees_trip(self, admin_token, worker_ctx):
        # ensure at least one trip exists
        assert any(k == "trip" for k, _, _ in TestGoalsAndTrips.created)
        r = requests.get(f"{BASE}/api/goals", params={"kind": "trip"}, headers=_h(admin_token), timeout=15)
        assert r.status_code == 200
        ids = {x["id"] for x in r.json()}
        for kind, gid, _ in TestGoalsAndTrips.created:
            if kind == "trip":
                assert gid in ids, f"admin cannot see trip {gid}"

    @classmethod
    def teardown_class(cls):
        for _, gid, tok in cls.created:
            try:
                requests.delete(f"{BASE}/api/goals/{gid}", headers=_h(tok), timeout=15)
            except Exception:
                pass


# --- Essentials ---
class TestEssentials:
    created = []

    def test_create_and_toggle_purchased(self, worker_ctx):
        tok = worker_ctx["token"]
        title = f"TEST_ess_{uuid.uuid4().hex[:6]}"
        r = requests.post(
            f"{BASE}/api/essentials",
            params={"title": title, "price": 9.5, "quantity": 2, "category": "grocery"},
            headers=_h(tok), timeout=15,
        )
        assert r.status_code == 200, r.text
        e = r.json()
        assert e["title"] == title
        assert e["price"] == 9.5
        assert e["quantity"] == 2
        assert e["purchased"] is False
        TestEssentials.created.append((e["id"], tok))

        # toggle purchased
        p = requests.patch(f"{BASE}/api/essentials/{e['id']}", json={"purchased": True}, headers=_h(tok), timeout=15)
        assert p.status_code == 200, p.text
        assert p.json().get("purchased") is True

        # totals
        t = requests.get(f"{BASE}/api/essentials/totals", headers=_h(tok), timeout=15)
        assert t.status_code == 200

    def test_admin_sees_essentials(self, admin_token, worker_ctx):
        r = requests.get(f"{BASE}/api/essentials", params={"user_id": worker_ctx["user"]["id"]}, headers=_h(admin_token), timeout=15)
        assert r.status_code == 200
        ids = {x["id"] for x in r.json()}
        for eid, _ in TestEssentials.created:
            assert eid in ids

    @classmethod
    def teardown_class(cls):
        for eid, tok in cls.created:
            try:
                requests.delete(f"{BASE}/api/essentials/{eid}", headers=_h(tok), timeout=15)
            except Exception:
                pass


# --- Peers ---
class TestPeers:
    def test_peers_list(self, worker_ctx):
        r = requests.get(f"{BASE}/api/peers", headers=_h(worker_ctx["token"]), timeout=15)
        assert r.status_code == 200
        assert isinstance(r.json(), list)


# --- Payroll ---
class TestPayroll:
    def test_payroll_admin(self, admin_token):
        r = requests.get(f"{BASE}/api/payroll", headers=_h(admin_token), timeout=15)
        assert r.status_code == 200
        assert isinstance(r.json(), list)

    def test_payroll_forbidden_worker(self, worker_ctx):
        r = requests.get(f"{BASE}/api/payroll", headers=_h(worker_ctx["token"]), timeout=15)
        assert r.status_code in (401, 403)


# --- Admin task CRUD ---
class TestAdminTaskCRUD:
    def test_create_edit_delete(self, admin_token, worker_ctx):
        title = f"TEST_task_{uuid.uuid4().hex[:6]}"
        r = requests.post(
            f"{BASE}/api/tasks",
            json={"title": title, "description": "t", "price": 5.0, "assignee_id": worker_ctx["user"]["id"]},
            headers=_h(admin_token), timeout=15,
        )
        assert r.status_code in (200, 201), r.text
        task = r.json()
        tid = task["id"]
        assert task["price"] == 5.0

        upd = requests.patch(f"{BASE}/api/tasks/{tid}", json={"price": 12.5}, headers=_h(admin_token), timeout=15)
        assert upd.status_code == 200, upd.text
        assert float(upd.json()["price"]) == 12.5

        d = requests.delete(f"{BASE}/api/tasks/{tid}", headers=_h(admin_token), timeout=15)
        assert d.status_code in (200, 204)

        # verify gone
        after = requests.get(f"{BASE}/api/tasks", headers=_h(admin_token), timeout=15).json()
        assert not any(t["id"] == tid for t in after)
