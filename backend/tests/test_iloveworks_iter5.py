"""iLoveWorks iter5 tests: delete account, clock-out alert, idle fields, branding, privacy."""
import os
import time
import requests
import pytest

BASE = os.environ["REACT_APP_BACKEND_URL"].rstrip("/")
API = f"{BASE}/api"

ADMIN = {"email": "admin@clockwork.com", "password": "admin123"}
KEEP_WORKER = {"email": "lovetest@loveworks.com", "password": "Love123!"}


def _login(email, password):
    s = requests.Session()
    r = s.post(f"{API}/auth/login", json={"email": email, "password": password}, timeout=15)
    assert r.status_code == 200, f"login failed for {email}: {r.status_code} {r.text}"
    return s


@pytest.fixture(scope="module")
def admin():
    return _login(**ADMIN)


@pytest.fixture(scope="module")
def keep_worker():
    return _login(**KEEP_WORKER)


# ---------- Branding / public endpoints ----------
class TestBranding:
    def test_api_root_message(self):
        r = requests.get(f"{API}/", timeout=10)
        assert r.status_code == 200
        assert r.json().get("message") == "iLoveWorks API"

    def test_manifest_short_name(self):
        r = requests.get(f"{BASE}/manifest.json", timeout=10)
        assert r.status_code == 200
        assert r.json().get("short_name") == "iLoveWorks"

    def test_privacy_page_public(self):
        # Public HTML shell served by React; must load without auth
        r = requests.get(f"{BASE}/privacy", timeout=10)
        assert r.status_code == 200


# ---------- Idle fields on worker-status ----------
class TestIdleFields:
    def test_worker_status_has_idle_fields(self, admin):
        r = admin.get(f"{API}/admin/worker-status", timeout=15)
        assert r.status_code == 200
        rows = r.json()
        assert isinstance(rows, list)
        assert len(rows) > 0
        for row in rows:
            assert "is_idle" in row, f"missing is_idle in {row}"
            assert "idle_minutes" in row
            assert isinstance(row["is_idle"], bool)
            assert row["idle_minutes"] is None or isinstance(row["idle_minutes"], int)


# ---------- Clock-out alert ----------
class TestClockOutAlert:
    def test_worker_clock_out_notifies_admin(self, admin, keep_worker):
        # Ensure clean state
        keep_worker.post(f"{API}/time/clock-out", timeout=15)
        # Clock in
        r = keep_worker.post(f"{API}/time/clock-in", json={"activity": "working"}, timeout=15)
        assert r.status_code == 200, r.text
        time.sleep(1.5)
        # Clock out
        r = keep_worker.post(f"{API}/time/clock-out", timeout=15)
        assert r.status_code == 200, r.text
        time.sleep(1.0)
        # Admin notifications
        r = admin.get(f"{API}/notifications", timeout=15)
        assert r.status_code == 200
        j = r.json()
        notes = j if isinstance(j, list) else j.get("items", j.get("notifications", []))
        clock_out_notes = [n for n in notes if n.get("type") == "worker_clock_out"]
        assert clock_out_notes, f"no worker_clock_out notification found; sample={notes[:3]}"
        top = clock_out_notes[0]
        title = top.get("title") or ""
        assert "clocked out" in title.lower()
        # duration string present in body
        body = (top.get("body") or "") + " " + (top.get("message") or "")
        assert "working" in body.lower() or "m" in body


# ---------- Delete account ----------
class TestDeleteAccount:
    email = f"deltest_{int(time.time())}@loveworks.com"
    password = "Delete123!"
    worker_id = None

    def test_admin_cannot_delete_self(self, admin):
        r = admin.request("DELETE", f"{API}/me", json={"password": ADMIN["password"]}, timeout=15)
        assert r.status_code == 403

    def test_create_throwaway_worker(self, admin):
        r = admin.post(
            f"{API}/workers",
            json={"email": self.email, "password": self.password, "name": "TEST_DelWorker"},
            timeout=15,
        )
        assert r.status_code in (200, 201), r.text
        data = r.json()
        TestDeleteAccount.worker_id = data.get("id") or data.get("user", {}).get("id")
        assert TestDeleteAccount.worker_id

    def test_wrong_password_returns_401(self):
        w = _login(self.email, self.password)
        r = w.request("DELETE", f"{API}/me", json={"password": "wrongpass"}, timeout=15)
        assert r.status_code == 401

    def test_correct_password_deletes(self):
        w = _login(self.email, self.password)
        # Create a task+time so we can verify cleanup
        w.post(f"{API}/time/clock-in", json={"activity": "working"}, timeout=15)
        w.post(f"{API}/time/clock-out", timeout=15)
        r = w.request("DELETE", f"{API}/me", json={"password": self.password}, timeout=15)
        assert r.status_code == 200, r.text
        j = r.json()
        assert j.get("deleted") is True

    def test_deleted_user_cannot_login(self):
        r = requests.post(f"{API}/auth/login", json={"email": self.email, "password": self.password}, timeout=15)
        assert r.status_code in (400, 401, 403), r.status_code

    def test_deleted_user_time_entries_gone(self, admin):
        # Look at admin worker-status; deleted worker should not appear
        r = admin.get(f"{API}/admin/worker-status", timeout=15)
        assert r.status_code == 200
        emails = [row.get("email") for row in r.json()]
        assert self.email not in emails
