"""Completion-event history + alarms (live preview API + direct DB checks).
Run: REACT_APP_BACKEND_URL=... pytest -q backend/tests/test_completions_alarms.py -s
"""
import asyncio
import os
import time
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import pytest
import requests
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient

load_dotenv("/app/backend/.env")
API = os.environ["REACT_APP_BACKEND_URL"].rstrip("/") + "/api"
TZ = ZoneInfo(os.environ.get("WEEK_TZ") or "UTC")


def _db_run(coro_fn):
    async def go():
        db = AsyncIOMotorClient(os.environ["MONGO_URL"])[os.environ["DB_NAME"]]
        return await coro_fn(db)
    return asyncio.run(go())


def _login(email, pw):
    r = requests.post(f"{API}/auth/login", json={"email": email, "password": pw}, timeout=20)
    r.raise_for_status()
    d = r.json()
    return {"Authorization": f"Bearer {d.get('access_token') or d.get('token')}"}, d["user"]


@pytest.fixture(scope="module")
def admin():
    return _login("admin@loveworks.com", "admin123")


@pytest.fixture(scope="module")
def worker():
    return _login("lovetest@loveworks.com", "Love123!")


def _slots(admin_h, wid):
    rows = requests.get(f"{API}/admin/worker-status", headers=admin_h, timeout=20).json()
    row = next(r for r in rows if (r.get("id") or r.get("worker", {}).get("id") or r.get("user_id")) == wid)
    return row["completions_by_day"]


def test_repeating_task_completed_on_two_days_counts_both(admin, worker):
    ah, _ = admin
    wh, wu = worker
    t = requests.post(f"{API}/tasks", headers=ah, json={"title": "TEST_daily_repeat", "price": 5, "assignee_id": wu["id"], "frequency": "daily"}, timeout=20).json()
    tid = t["id"]
    try:
        today_idx = datetime.now(TZ).weekday()
        if today_idx == 0:
            pytest.skip("Monday: yesterday is last week, strip can't show it")
        before = _slots(ah, wu["id"])
        b_y, b_t = before[today_idx - 1]["count"], before[today_idx]["count"]

        # Day 1: complete, then move that completion to yesterday (simulates time passing)
        r = requests.patch(f"{API}/tasks/{tid}", headers=wh, json={"status": "completed"}, timeout=20)
        assert r.status_code == 200
        yday = (datetime.now(TZ) - timedelta(days=1)).replace(hour=12, minute=0, second=0, microsecond=0).astimezone(timezone.utc).isoformat()

        async def shift(db):
            ev = await db.task_completions.find_one({"task_id": tid}, {"_id": 0})
            assert ev, "completion event not recorded"
            await db.task_completions.update_one({"task_id": tid}, {"$set": {"completed_at": yday}})
            await db.tasks.update_one({"id": tid}, {"$set": {"completed_at": yday}})
        _db_run(shift)

        # Rollover loop (60s tick) must reopen the daily task
        deadline = time.time() + 75
        status = None
        while time.time() < deadline:
            status = _db_run(lambda db: db.tasks.find_one({"id": tid}, {"_id": 0, "status": 1}))["status"]
            if status == "assigned":
                break
            time.sleep(5)
        assert status == "assigned", "daily task was not reopened for the new day"

        # Day 2: complete again
        assert requests.patch(f"{API}/tasks/{tid}", headers=wh, json={"status": "completed"}, timeout=20).status_code == 200
        n = _db_run(lambda db: db.task_completions.count_documents({"task_id": tid}))
        assert n == 2, f"expected 2 completion events, got {n}"

        after = _slots(ah, wu["id"])
        assert after[today_idx - 1]["count"] == b_y + 1, "yesterday counter did not move"
        assert after[today_idx]["count"] == b_t + 1, "today counter did not move"
        mine = requests.get(f"{API}/me/weekly-activity", headers=wh, timeout=20).json()["completions_by_day"]
        assert mine[today_idx - 1]["count"] >= 1 and mine[today_idx]["count"] >= 1

        # Untick today: only today's tick is undone, yesterday survives
        assert requests.patch(f"{API}/tasks/{tid}", headers=wh, json={"status": "assigned"}, timeout=20).status_code == 200
        undone = _slots(ah, wu["id"])
        assert undone[today_idx - 1]["count"] == b_y + 1
        assert undone[today_idx]["count"] == b_t
    finally:
        requests.delete(f"{API}/tasks/{tid}", headers=ah, timeout=20)


def test_alarm_is_stored_and_fires(worker):
    wh, wu = worker
    fire = (datetime.now(timezone.utc) + timedelta(seconds=20)).isoformat()
    r = requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_alarm", "fire_at": fire, "source": "web"}, timeout=20)
    assert r.status_code == 200, r.text
    aid = r.json()["id"]
    rec = _db_run(lambda db: db.alarms.find_one({"id": aid}, {"_id": 0}))
    assert rec and rec["status"] == "scheduled" and rec["user_id"] == wu["id"]
    assert any(a["id"] == aid for a in requests.get(f"{API}/alarms", headers=wh, timeout=20).json())

    deadline = time.time() + 60
    while time.time() < deadline:
        rec = _db_run(lambda db: db.alarms.find_one({"id": aid}, {"_id": 0}))
        if rec["status"] == "fired":
            break
        time.sleep(3)
    assert rec["status"] == "fired", "alarm never fired"
    note = _db_run(lambda db: db.notifications.find_one({"user_id": wu["id"], "type": "alarm", "meta.alarm_id": aid}, {"_id": 0}))
    assert note and note["link"] == f"/worker?alarm={aid}"

    # snooze + cancel
    s = requests.post(f"{API}/alarms/{aid}/snooze", headers=wh, json={"minutes": 10}, timeout=20).json()
    assert s["status"] == "scheduled"
    assert requests.delete(f"{API}/alarms/{aid}", headers=wh, timeout=20).status_code == 200
    assert _db_run(lambda db: db.alarms.find_one({"id": aid}, {"_id": 0}))["status"] == "cancelled"


def test_alarm_validation(worker):
    wh, _ = worker
    past = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
    assert requests.post(f"{API}/alarms", headers=wh, json={"title": "x", "fire_at": past}, timeout=20).status_code == 400
    assert requests.post(f"{API}/alarms", headers=wh, json={"title": "x", "fire_at": "tomorrow"}, timeout=20).status_code == 400
    assert requests.post(f"{API}/alarms", json={"title": "x", "fire_at": past}, timeout=20).status_code == 401
