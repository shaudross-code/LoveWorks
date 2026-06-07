"""ClockWork notifications, push, and reminder backend tests.

Covers:
- Notifications regression (task_assigned on task creation)
- task_updated notifications when admin edits price/due_time/due_at/due_day_of_week
- Reassignment notifications (task_assigned to new + task_updated to old)
- Worker status-only patches do NOT spawn task_updated
- goal_assigned notifications (admin -> worker) + 403 when worker tries
- /api/push/public-key, /api/push/subscribe (upsert), /api/push/unsubscribe
- reminder_loop fires task_due_soon with dedup via last_reminder_date
"""
import os
import time
import datetime as dt
import pytest
import requests
from pymongo import MongoClient

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL", "").rstrip("/")
API = f"{BASE_URL}/api"

ADMIN_EMAIL = "admin@clockwork.com"
ADMIN_PASSWORD = "admin123"

WORKER1_EMAIL = f"notif_w1_{int(time.time())}@clockwork.com"
WORKER2_EMAIL = f"notif_w2_{int(time.time())}@clockwork.com"
WORKER_PASSWORD = "worker123"


# ----- DB helpers (used only for reminder dedup reset + scheduling a near-future task) -----
MONGO_URL = os.environ.get("MONGO_URL", "mongodb://localhost:27017")
DB_NAME = os.environ.get("DB_NAME", "clockwork_db")
_mongo = MongoClient(MONGO_URL)
_db = _mongo[DB_NAME]


@pytest.fixture(scope="module")
def admin_session():
    s = requests.Session()
    r = s.post(f"{API}/auth/login", json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD})
    assert r.status_code == 200, f"admin login failed: {r.status_code} {r.text}"
    s.headers.update({"Authorization": f"Bearer {r.json()['access_token']}"})
    return s


def _create_worker(admin_session, email):
    r = admin_session.post(f"{API}/workers", json={
        "email": email, "password": WORKER_PASSWORD, "name": email.split("@")[0]
    })
    assert r.status_code in (200, 201), f"create worker failed: {r.text}"
    return r.json()


@pytest.fixture(scope="module")
def worker1(admin_session):
    return _create_worker(admin_session, WORKER1_EMAIL)


@pytest.fixture(scope="module")
def worker2(admin_session):
    return _create_worker(admin_session, WORKER2_EMAIL)


@pytest.fixture(scope="module")
def worker1_session(worker1):
    s = requests.Session()
    r = s.post(f"{API}/auth/login", json={"email": worker1["email"], "password": WORKER_PASSWORD})
    assert r.status_code == 200
    s.headers.update({"Authorization": f"Bearer {r.json()['access_token']}"})
    return s


@pytest.fixture(scope="module")
def worker2_session(worker2):
    s = requests.Session()
    r = s.post(f"{API}/auth/login", json={"email": worker2["email"], "password": WORKER_PASSWORD})
    assert r.status_code == 200
    s.headers.update({"Authorization": f"Bearer {r.json()['access_token']}"})
    return s


def _list_notifs(session):
    r = session.get(f"{API}/notifications")
    assert r.status_code == 200
    data = r.json()
    # response shape: {items, unread}
    return data.get("items") if isinstance(data, dict) else data


# --- Regression: task_assigned on task creation ---
class TestTaskAssignedNotification:
    def test_task_assigned_notif_created(self, admin_session, worker1, worker1_session):
        r = admin_session.post(f"{API}/tasks", json={
            "title": "TEST_NotifTask1",
            "description": "x",
            "price": 50.0,
            "assignee_id": worker1["id"],
        })
        assert r.status_code == 200
        task = r.json()
        notifs = _list_notifs(worker1_session)
        match = next((n for n in notifs if n["type"] == "task_assigned" and n.get("meta", {}).get("task_id") == task["id"]), None)
        assert match is not None, "No task_assigned notification found"
        assert "TEST_NotifTask1" in match["title"]


# --- task_updated notifications when admin patches ---
class TestTaskUpdatedNotification:
    @pytest.fixture
    def task(self, admin_session, worker1):
        r = admin_session.post(f"{API}/tasks", json={
            "title": "TEST_UpdatableTask",
            "description": "x",
            "price": 80.0,
            "assignee_id": worker1["id"],
            "due_time": "10:00",
            "due_day_of_week": 1,
        })
        assert r.status_code == 200
        return r.json()

    def _latest_task_updated_for(self, session, task_id):
        notifs = _list_notifs(session)
        for n in notifs:
            if n["type"] == "task_updated" and n.get("meta", {}).get("task_id") == task_id:
                return n
        return None

    def test_price_change_creates_task_updated_with_price(self, admin_session, worker1_session, task):
        r = admin_session.patch(f"{API}/tasks/{task['id']}", json={"price": 175.5})
        assert r.status_code == 200
        n = self._latest_task_updated_for(worker1_session, task["id"])
        assert n is not None, "No task_updated notification"
        assert "price → $175.50" in n["body"], f"body was: {n['body']}"

    def test_due_time_change_creates_task_updated(self, admin_session, worker1_session, task):
        r = admin_session.patch(f"{API}/tasks/{task['id']}", json={"due_time": "14:30"})
        assert r.status_code == 200
        n = self._latest_task_updated_for(worker1_session, task["id"])
        assert n is not None
        assert "due time → 14:30" in n["body"], f"body was: {n['body']}"

    def test_due_at_change_creates_task_updated(self, admin_session, worker1_session, task):
        future = (dt.datetime.utcnow() + dt.timedelta(days=5)).date().isoformat()
        r = admin_session.patch(f"{API}/tasks/{task['id']}", json={"due_at": future})
        assert r.status_code == 200, r.text
        n = self._latest_task_updated_for(worker1_session, task["id"])
        assert n is not None
        assert "deadline →" in n["body"], f"body was: {n['body']}"

    def test_due_day_change_creates_task_updated(self, admin_session, worker1_session, task):
        # original was Tue (1); change to Fri (4)
        r = admin_session.patch(f"{API}/tasks/{task['id']}", json={"due_day_of_week": 4})
        assert r.status_code == 200
        n = self._latest_task_updated_for(worker1_session, task["id"])
        assert n is not None
        assert "day → Fri" in n["body"], f"body was: {n['body']}"

    def test_worker_status_only_does_not_create_task_updated(
        self, admin_session, worker1, worker1_session, worker2_session
    ):
        # Create a fresh task to isolate
        c = admin_session.post(f"{API}/tasks", json={
            "title": "TEST_WorkerOnlyStatus",
            "description": "x", "price": 10.0,
            "assignee_id": worker1["id"],
        })
        tid = c.json()["id"]
        # baseline: count task_updated notifs for this task
        before = _list_notifs(worker1_session)
        before_count = sum(1 for n in before if n["type"] == "task_updated" and n.get("meta", {}).get("task_id") == tid)
        # worker patches own status
        r = worker1_session.patch(f"{API}/tasks/{tid}", json={"status": "in_progress"})
        assert r.status_code == 200
        after = _list_notifs(worker1_session)
        after_count = sum(1 for n in after if n["type"] == "task_updated" and n.get("meta", {}).get("task_id") == tid)
        assert after_count == before_count, "Worker status update spawned a task_updated notification"


# --- Reassignment ---
class TestReassignment:
    def test_reassign_notifies_both_old_and_new(self, admin_session, worker1, worker2, worker1_session, worker2_session):
        c = admin_session.post(f"{API}/tasks", json={
            "title": "TEST_Reassignable",
            "description": "x", "price": 60.0,
            "assignee_id": worker1["id"],
        })
        tid = c.json()["id"]
        # reassign to worker2
        r = admin_session.patch(f"{API}/tasks/{tid}", json={"assignee_id": worker2["id"]})
        assert r.status_code == 200
        # new assignee should get task_assigned
        n2 = _list_notifs(worker2_session)
        m_new = next((n for n in n2 if n["type"] == "task_assigned" and n.get("meta", {}).get("task_id") == tid), None)
        assert m_new is not None, "New assignee did not get task_assigned"
        # old assignee should get task_updated with 'moved off'
        n1 = _list_notifs(worker1_session)
        m_old = next((n for n in n1 if n["type"] == "task_updated" and n.get("meta", {}).get("task_id") == tid), None)
        assert m_old is not None, "Old assignee did not get task_updated"
        assert "moved off your list" in m_old["body"].lower()


# --- Goals: admin-assigned ---
class TestGoalAssignment:
    def test_admin_assigns_goal_to_worker_creates_notification(self, admin_session, worker1, worker1_session):
        # POST /api/goals with query params (per server signature)
        r = admin_session.post(
            f"{API}/goals",
            params={
                "title": "TEST_AssignedGoal",
                "target_amount": 100,
                "assignee_id": worker1["id"],
                "period": "weekly",
                "allocation_percent": 50,
            },
        )
        assert r.status_code == 200, f"goal create failed: {r.text}"
        goal = r.json()
        assert goal["owner_id"] == worker1["id"]
        assert goal["assigned_by"] is not None
        # worker should see a goal_assigned notif
        notifs = _list_notifs(worker1_session)
        match = next((n for n in notifs if n["type"] == "goal_assigned" and n.get("meta", {}).get("goal_id") == goal["id"]), None)
        assert match is not None, "No goal_assigned notification"
        assert "🎯 New goal:" in match["title"], f"title: {match['title']}"

    def test_worker_cannot_assign_goal_to_another_worker(self, worker1_session, worker2):
        r = worker1_session.post(
            f"{API}/goals",
            params={"title": "TEST_WorkerCantAssign", "target_amount": 10, "assignee_id": worker2["id"]},
        )
        assert r.status_code == 403

    def test_admin_no_assignee_owns_goal_self(self, admin_session):
        r = admin_session.post(f"{API}/goals", params={"title": "TEST_AdminOwnGoal", "target_amount": 20})
        assert r.status_code == 200
        goal = r.json()
        # owner is admin (not None), assigned_by None
        assert goal.get("assigned_by") in (None, "")
        # cleanup
        # no delete endpoint required by tests; left as-is


# --- Push subscription endpoints ---
class TestPushEndpoints:
    def test_public_key_returns_key_and_available(self):
        r = requests.get(f"{API}/push/public-key")
        assert r.status_code == 200
        data = r.json()
        assert "key" in data
        assert "available" in data
        if data["available"]:
            assert isinstance(data["key"], str) and len(data["key"]) > 0

    def test_subscribe_upsert_and_unsubscribe(self, worker1_session):
        endpoint = f"https://test.example/abc-{int(time.time()*1000)}"
        sub_body = {
            "subscription": {
                "endpoint": endpoint,
                "keys": {"p256dh": "xx_p256dh", "auth": "yy_auth"},
            }
        }
        r1 = worker1_session.post(f"{API}/push/subscribe", json=sub_body)
        assert r1.status_code == 200
        # second call should upsert (no error / no duplicate)
        r2 = worker1_session.post(f"{API}/push/subscribe", json=sub_body)
        assert r2.status_code == 200
        # verify single document in DB
        count = _db.push_subscriptions.count_documents({"endpoint": endpoint})
        assert count == 1, f"expected 1 subscription, got {count}"
        active = _db.push_subscriptions.find_one({"endpoint": endpoint})
        assert active["is_active"] is True

        # unsubscribe
        ru = worker1_session.post(f"{API}/push/unsubscribe", json=sub_body)
        assert ru.status_code == 200
        after = _db.push_subscriptions.find_one({"endpoint": endpoint})
        assert after["is_active"] is False

    def test_subscribe_requires_endpoint(self, worker1_session):
        r = worker1_session.post(f"{API}/push/subscribe", json={"subscription": {}})
        assert r.status_code == 400


# --- Reminder loop ---
class TestReminderLoop:
    def test_reminder_fires_and_dedups(self, admin_session, worker1, worker1_session):
        # Create a task and set it to be due in ~15 min UTC, daily frequency
        c = admin_session.post(f"{API}/tasks", json={
            "title": "TEST_DueSoonReminder",
            "description": "x", "price": 12.0,
            "assignee_id": worker1["id"],
            "frequency": "daily",
        })
        assert c.status_code == 200, c.text
        task = c.json()
        tid = task["id"]

        # Calculate a due_time ~15 minutes in the future (UTC)
        future = dt.datetime.utcnow() + dt.timedelta(minutes=15)
        due_time = f"{future.hour:02d}:{future.minute:02d}"

        # Patch directly via API to set due_time + frequency=daily
        r = admin_session.patch(f"{API}/tasks/{tid}", json={
            "due_time": due_time,
            "frequency": "daily",
        })
        assert r.status_code == 200

        # Force-reset last_reminder_date in DB so the loop is eligible to fire today
        _db.tasks.update_one({"id": tid}, {"$set": {"last_reminder_date": None}})

        # Wait up to 75s for the loop to tick (REMINDER_LOOP_SECONDS=60)
        deadline = time.time() + 75
        match = None
        while time.time() < deadline:
            notifs = _list_notifs(worker1_session)
            match = next(
                (n for n in notifs if n["type"] == "task_due_soon" and n.get("meta", {}).get("task_id") == tid),
                None,
            )
            if match:
                break
            time.sleep(5)

        assert match is not None, "task_due_soon notification was not created within 75s"

        # Verify last_reminder_date is today
        today_iso = dt.datetime.utcnow().date().isoformat()
        fresh = _db.tasks.find_one({"id": tid})
        assert fresh.get("last_reminder_date") == today_iso

        # Dedup: capture count, wait one more tick window, verify count unchanged
        notifs1 = _list_notifs(worker1_session)
        count_before = sum(1 for n in notifs1 if n["type"] == "task_due_soon" and n.get("meta", {}).get("task_id") == tid)
        time.sleep(65)
        notifs2 = _list_notifs(worker1_session)
        count_after = sum(1 for n in notifs2 if n["type"] == "task_due_soon" and n.get("meta", {}).get("task_id") == tid)
        assert count_after == count_before, f"Dedup failed: count went {count_before} -> {count_after}"


# --- Cleanup ---
@pytest.fixture(scope="module", autouse=True)
def cleanup_workers(admin_session, worker1, worker2):
    yield
    for w in (worker1, worker2):
        try:
            admin_session.delete(f"{API}/workers/{w['id']}")
        except Exception:
            pass
