"""ClockWork end-to-end backend tests.
Covers auth, workers, tasks, time entries, payroll.
"""
import os
import time
import pytest
import requests

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL", "https://labor-admin-hub.preview.emergentagent.com").rstrip("/")
API = f"{BASE_URL}/api"

ADMIN_EMAIL = "admin@clockwork.com"
ADMIN_PASSWORD = "admin123"

# Use unique worker email per test session to avoid collisions
WORKER_EMAIL = f"test_worker_{int(time.time())}@clockwork.com"
WORKER_PASSWORD = "worker123"
WORKER_NAME = "Test Worker"


@pytest.fixture(scope="session")
def admin_session():
    s = requests.Session()
    r = s.post(f"{API}/auth/login", json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD})
    assert r.status_code == 200, f"Admin login failed: {r.status_code} {r.text}"
    data = r.json()
    s.headers.update({"Authorization": f"Bearer {data['access_token']}"})
    return s


@pytest.fixture(scope="session")
def worker_creds(admin_session):
    # Create worker
    r = admin_session.post(f"{API}/workers", json={
        "email": WORKER_EMAIL,
        "password": WORKER_PASSWORD,
        "name": WORKER_NAME,
    })
    assert r.status_code in (200, 201), f"Worker create failed: {r.status_code} {r.text}"
    data = r.json()
    return {"id": data["id"], "email": WORKER_EMAIL, "password": WORKER_PASSWORD, "name": data["name"]}


@pytest.fixture(scope="session")
def worker_session(worker_creds):
    s = requests.Session()
    r = s.post(f"{API}/auth/login", json={"email": worker_creds["email"], "password": worker_creds["password"]})
    assert r.status_code == 200, f"Worker login failed: {r.status_code} {r.text}"
    s.headers.update({"Authorization": f"Bearer {r.json()['access_token']}"})
    return s


# --- Health ---
class TestHealth:
    def test_api_root(self):
        r = requests.get(f"{API}/")
        assert r.status_code == 200
        assert r.json().get("ok") is True


# --- Auth ---
class TestAuth:
    def test_me_unauthenticated_returns_401(self):
        r = requests.get(f"{API}/auth/me")
        assert r.status_code == 401

    def test_admin_login_returns_user_and_token(self):
        r = requests.post(f"{API}/auth/login", json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD})
        assert r.status_code == 200
        data = r.json()
        assert "access_token" in data and isinstance(data["access_token"], str)
        assert data["user"]["email"] == ADMIN_EMAIL
        assert data["user"]["role"] == "admin"

    def test_login_invalid_credentials(self):
        r = requests.post(f"{API}/auth/login", json={"email": "nouser@example.com", "password": "wrongpwd"})
        assert r.status_code == 401

    def test_me_authenticated(self, admin_session):
        r = admin_session.get(f"{API}/auth/me")
        assert r.status_code == 200
        assert r.json()["role"] == "admin"


# --- Workers ---
class TestWorkers:
    def test_worker_creation_and_listing(self, admin_session, worker_creds):
        r = admin_session.get(f"{API}/workers")
        assert r.status_code == 200
        workers = r.json()
        assert any(w["id"] == worker_creds["id"] for w in workers)
        # password_hash must not be exposed
        for w in workers:
            assert "password_hash" not in w

    def test_duplicate_worker_email_rejected(self, admin_session, worker_creds):
        r = admin_session.post(f"{API}/workers", json={
            "email": worker_creds["email"], "password": "x123456", "name": "Dup"
        })
        assert r.status_code == 400

    def test_non_admin_cannot_create_worker(self, worker_session):
        r = worker_session.post(f"{API}/workers", json={
            "email": f"forbidden_{int(time.time())}@x.com", "password": "abc123", "name": "Nope"
        })
        assert r.status_code == 403


# --- Tasks ---
@pytest.fixture(scope="session")
def created_task(admin_session, worker_creds):
    r = admin_session.post(f"{API}/tasks", json={
        "title": "TEST_Install fixture",
        "description": "Test desc",
        "price": 100.0,
        "assignee_id": worker_creds["id"],
    })
    assert r.status_code == 200, f"Create task failed: {r.status_code} {r.text}"
    return r.json()


class TestTasks:
    def test_create_task(self, created_task, worker_creds):
        assert created_task["title"] == "TEST_Install fixture"
        assert created_task["price"] == 100.0
        assert created_task["assignee_id"] == worker_creds["id"]
        assert created_task["status"] == "assigned"

    def test_create_task_invalid_worker(self, admin_session):
        r = admin_session.post(f"{API}/tasks", json={
            "title": "Bad", "description": "", "price": 5.0, "assignee_id": "non-existent"
        })
        assert r.status_code == 404

    def test_admin_lists_tasks_with_assignee_name(self, admin_session, created_task):
        r = admin_session.get(f"{API}/tasks")
        assert r.status_code == 200
        tasks = r.json()
        match = next((t for t in tasks if t["id"] == created_task["id"]), None)
        assert match is not None
        assert "assignee_name" in match

    def test_admin_can_patch_price(self, admin_session, created_task):
        r = admin_session.patch(f"{API}/tasks/{created_task['id']}", json={"price": 125.50})
        assert r.status_code == 200
        assert r.json()["price"] == 125.50
        # verify GET persists
        listing = admin_session.get(f"{API}/tasks").json()
        match = next(t for t in listing if t["id"] == created_task["id"])
        assert match["price"] == 125.50

    def test_worker_sees_only_own_tasks(self, worker_session, created_task, worker_creds):
        r = worker_session.get(f"{API}/tasks")
        assert r.status_code == 200
        for t in r.json():
            assert t["assignee_id"] == worker_creds["id"]

    def test_worker_can_set_in_progress(self, worker_session, created_task):
        r = worker_session.patch(f"{API}/tasks/{created_task['id']}", json={"status": "in_progress"})
        assert r.status_code == 200
        assert r.json()["status"] == "in_progress"

    def test_worker_cannot_change_price(self, worker_session, created_task):
        r = worker_session.patch(f"{API}/tasks/{created_task['id']}", json={"price": 999.0})
        # backend rejects because workers may only update status
        assert r.status_code == 400

    def test_worker_can_mark_completed(self, worker_session, created_task):
        r = worker_session.patch(f"{API}/tasks/{created_task['id']}", json={"status": "completed"})
        assert r.status_code == 200
        body = r.json()
        assert body["status"] == "completed"
        assert body.get("completed_at")

    def test_admin_can_delete_task(self, admin_session, worker_creds):
        # Create a fresh task to delete
        c = admin_session.post(f"{API}/tasks", json={
            "title": "TEST_to_delete", "description": "", "price": 5.0,
            "assignee_id": worker_creds["id"],
        })
        tid = c.json()["id"]
        d = admin_session.delete(f"{API}/tasks/{tid}")
        assert d.status_code == 200
        listing = admin_session.get(f"{API}/tasks").json()
        assert not any(t["id"] == tid for t in listing)


# --- Time / Clock ---
class TestTime:
    def test_clock_in_then_out(self, worker_session):
        # Ensure starting clean: clock-out if already in
        worker_session.post(f"{API}/time/clock-out")
        r = worker_session.post(f"{API}/time/clock-in")
        assert r.status_code == 200, r.text
        entry = r.json()
        assert entry["clock_out"] is None
        # active endpoint
        a = worker_session.get(f"{API}/time/active")
        assert a.status_code == 200
        assert a.json().get("id") == entry["id"]
        # cannot clock-in twice
        r2 = worker_session.post(f"{API}/time/clock-in")
        assert r2.status_code == 400
        time.sleep(1)
        out = worker_session.post(f"{API}/time/clock-out")
        assert out.status_code == 200
        body = out.json()
        assert body["clock_out"] is not None
        assert body["duration_seconds"] >= 1

    def test_clock_out_when_not_in(self, worker_session):
        # we just clocked out above
        r = worker_session.post(f"{API}/time/clock-out")
        assert r.status_code == 400

    def test_list_entries_worker(self, worker_session):
        r = worker_session.get(f"{API}/time/entries")
        assert r.status_code == 200
        entries = r.json()
        assert isinstance(entries, list)
        assert len(entries) >= 1


# --- Payroll ---
class TestPayroll:
    def test_admin_payroll(self, admin_session, worker_creds):
        r = admin_session.get(f"{API}/payroll")
        assert r.status_code == 200
        payroll = r.json()
        match = next((p for p in payroll if p["worker"]["id"] == worker_creds["id"]), None)
        assert match is not None
        # We completed one task with price 125.50
        assert match["tasks_completed"] >= 1
        assert match["tasks_earnings"] >= 125.50
        assert match["total_hours"] >= 0

    def test_worker_cannot_access_payroll(self, worker_session):
        r = worker_session.get(f"{API}/payroll")
        assert r.status_code == 403


# --- Logout ---
class TestLogout:
    def test_logout_succeeds(self):
        s = requests.Session()
        r = s.post(f"{API}/auth/login", json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD})
        assert r.status_code == 200
        token = r.json()["access_token"]
        s.headers.update({"Authorization": f"Bearer {token}"})
        out = s.post(f"{API}/auth/logout")
        assert out.status_code == 200


# --- Cleanup ---
@pytest.fixture(scope="session", autouse=True)
def cleanup(admin_session, worker_creds):
    yield
    # Delete the test worker (cascades tasks/time entries)
    try:
        admin_session.delete(f"{API}/workers/{worker_creds['id']}")
    except Exception:
        pass
