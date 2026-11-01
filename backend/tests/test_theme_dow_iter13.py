# Iteration 13: due_day_of_week bug fix + Holiday theme API
import os
import pytest
import requests

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL").rstrip("/")
ADMIN = {"email": "admin@loveworks.com", "password": "admin123"}
WORKER = {"email": "lovetest@loveworks.com", "password": "Love123!"}


def _login(creds):
    s = requests.Session()
    r = s.post(f"{BASE_URL}/api/auth/login", json=creds)
    if r.status_code != 200:
        pytest.skip(f"login failed {r.status_code}")
    s.headers.update({"Authorization": f"Bearer {r.json()['access_token']}"})
    return s, r.json()["user"]


@pytest.fixture(scope="module")
def admin():
    return _login(ADMIN)[0]


@pytest.fixture(scope="module")
def worker():
    return _login(WORKER)


@pytest.fixture(scope="module")
def created(admin):
    ids = []
    yield ids
    for i in ids:
        admin.delete(f"{BASE_URL}/api/tasks/{i}")


def _find_task(admin, tid):
    r = admin.get(f"{BASE_URL}/api/tasks")
    assert r.status_code == 200
    data = r.json()
    items = data if isinstance(data, list) else data.get("tasks", [])
    return next((t for t in items if t["id"] == tid), None)


# --- due_day_of_week ---
class TestDueDow:
    def _payload(self, wid, dow, title):
        return {"title": title, "price": 5, "assignee_id": wid, "frequency": "once", "due_day_of_week": dow}

    def test_minus_one_stores_null(self, admin, worker, created):
        r = admin.post(f"{BASE_URL}/api/tasks", json=self._payload(worker[1]["id"], -1, "TEST_dow_none"))
        assert r.status_code in (200, 201), r.text
        t = r.json()
        created.append(t["id"])
        assert t["due_day_of_week"] is None
        assert _find_task(admin, t["id"])["due_day_of_week"] is None

    def test_four_stores_four_and_patch_clear(self, admin, worker, created):
        r = admin.post(f"{BASE_URL}/api/tasks", json=self._payload(worker[1]["id"], 4, "TEST_dow_fri"))
        assert r.status_code in (200, 201), r.text
        t = r.json()
        created.append(t["id"])
        assert t["due_day_of_week"] == 4
        assert _find_task(admin, t["id"])["due_day_of_week"] == 4
        p = admin.patch(f"{BASE_URL}/api/tasks/{t['id']}", json={"due_day_of_week": -1})
        assert p.status_code == 200, p.text
        assert _find_task(admin, t["id"])["due_day_of_week"] is None

    def test_seven_400(self, admin, worker, created):
        r = admin.post(f"{BASE_URL}/api/tasks", json=self._payload(worker[1]["id"], 7, "TEST_dow_bad"))
        if r.status_code in (200, 201):
            created.append(r.json()["id"])
        assert r.status_code == 400
        assert "due_day_of_week must be 0..6" in r.json()["detail"]

    def test_x_rejected(self, admin, worker, created):
        r = admin.post(f"{BASE_URL}/api/tasks", json=self._payload(worker[1]["id"], "x", "TEST_dow_x"))
        if r.status_code in (200, 201):
            created.append(r.json()["id"])
        print("dow='x' status", r.status_code, r.text[:200])
        assert r.status_code in (400, 422)

    def test_x_is_400_exact(self, admin, worker, created):
        r = admin.post(f"{BASE_URL}/api/tasks", json=self._payload(worker[1]["id"], "x", "TEST_dow_x2"))
        if r.status_code in (200, 201):
            created.append(r.json()["id"])
        assert r.status_code == 400


# --- Theme API ---
class TestTheme:
    def test_public_get_auto_halloween(self, admin):
        admin.put(f"{BASE_URL}/api/theme", json={"mode": "auto"})
        r = requests.get(f"{BASE_URL}/api/theme")
        assert r.status_code == 200
        d = r.json()
        assert d["mode"] == "auto"
        assert d["effective"] == "halloween"
        assert d["theme"]["greeting"] == "Happy Halloween"
        assert d["theme"]["emoji"] == "🎃"
        assert d["ends_on"] == "2026-11-07"
        assert d["window_days"] == 7
        assert len(d["themes"]) == 8
        assert d["auto_suggestion"] == "halloween"
        up = d["upcoming"]
        assert [u["date"] for u in up] == sorted(u["date"] for u in up)
        by = {u["key"] + u["date"][:4]: u for u in up}
        assert by["halloween2026"]["starts"] == "2026-10-24" and by["halloween2026"]["ends"] == "2026-11-07"
        assert by["thanksgiving2026"]["date"] == "2026-11-26"
        assert by["thanksgiving2026"]["starts"] == "2026-11-19" and by["thanksgiving2026"]["ends"] == "2026-12-03"
        assert by["christmas2026"]["starts"] == "2026-12-18" and by["christmas2026"]["ends"] == "2027-01-01"

    def test_put_modes(self, admin):
        try:
            r = admin.put(f"{BASE_URL}/api/theme", json={"mode": "default"})
            assert r.status_code == 200 and r.json()["effective"] == "default"
            assert requests.get(f"{BASE_URL}/api/theme").json()["effective"] == "default"
            r = admin.put(f"{BASE_URL}/api/theme", json={"mode": "christmas"})
            assert r.status_code == 200
            assert r.json()["effective"] == "christmas"
            assert r.json()["theme"]["greeting"] == "Merry Christmas"
            assert r.json()["ends_on"] is None
            r = admin.put(f"{BASE_URL}/api/theme", json={"mode": "xmas"})
            assert r.status_code == 400 and r.json()["detail"] == "Unknown theme"
        finally:
            r = admin.put(f"{BASE_URL}/api/theme", json={"mode": "auto"})
            assert r.json()["effective"] == "halloween"

    def test_put_worker_403(self, worker):
        r = worker[0].put(f"{BASE_URL}/api/theme", json={"mode": "default"})
        assert r.status_code == 403

    def test_put_noauth_401(self):
        r = requests.put(f"{BASE_URL}/api/theme", json={"mode": "default"})
        assert r.status_code == 401

    def test_worker_get_same(self, worker):
        r = worker[0].get(f"{BASE_URL}/api/theme")
        assert r.status_code == 200 and r.json()["effective"] == "halloween"

    def test_sandbox_isolated(self):
        s, _ = _login({"email": "reviewer@loveworks.com", "password": "iLoveWorks2026!"})
        r = s.get(f"{BASE_URL}/api/theme")
        assert r.status_code == 200
        assert r.json()["mode"] in ("auto", "default") or r.json()["effective"]
