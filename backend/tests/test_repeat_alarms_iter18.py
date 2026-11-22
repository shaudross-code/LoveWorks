"""Iteration 18: repeating alarms edge cases, Clocked In status, live-activity endpoint auth,
delete-task keeps completion history, concurrent-tick guard.
Run: REACT_APP_BACKEND_URL=... pytest -p no:xdist backend/tests/test_repeat_alarms_iter18.py
"""
import asyncio
import os
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import pytest
import requests
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient

load_dotenv("/app/backend/.env")
API = os.environ["REACT_APP_BACKEND_URL"].rstrip("/") + "/api"
TZ = "America/Chicago"


def _db(fn):
    async def go():
        db = AsyncIOMotorClient(os.environ["MONGO_URL"])[os.environ["DB_NAME"]]
        return await fn(db)
    return asyncio.run(go())


def _login(email, pw):
    d = requests.post(f"{API}/auth/login", json={"email": email, "password": pw}, timeout=20).json()
    return {"Authorization": f"Bearer {d.get('access_token')}"}, d["user"]


@pytest.fixture(scope="module")
def worker():
    return _login("lovetest@loveworks.com", "Love123!")


@pytest.fixture(scope="module")
def admin():
    return _login("admin@loveworks.com", "admin123")


@pytest.fixture(scope="module")
def created():
    ids = {"alarms": [], "tasks": []}
    yield ids
    if ids["alarms"]:
        _db(lambda db: db.alarms.delete_many({"id": {"$in": ids["alarms"]}}))
        _db(lambda db: db.notifications.delete_many({"meta.alarm_id": {"$in": ids["alarms"]}}))
    if ids["tasks"]:
        _db(lambda db: db.tasks.delete_many({"id": {"$in": ids["tasks"]}}))
        _db(lambda db: db.task_completions.delete_many({"task_id": {"$in": ids["tasks"]}}))
        _db(lambda db: db.alarms.delete_many({"task_id": {"$in": ids["tasks"]}}))


def _mk(wh, created, **body):
    r = requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_it18", **body}, timeout=20)
    if r.status_code == 200:
        created["alarms"].append(r.json()["id"])
    return r


# --- Repeating alarms ---
def test_time_passed_today_rolls_to_next_week(worker, created):
    wh, _ = worker
    now_l = datetime.now(ZoneInfo(TZ))
    past = now_l - timedelta(minutes=10)
    if past.date() != now_l.date():
        pytest.skip("near midnight")
    r = _mk(wh, created, repeat_days=[now_l.weekday()], time_of_day=past.strftime("%H:%M"), tz=TZ)
    assert r.status_code == 200, r.text
    fire = datetime.fromisoformat(r.json()["fire_at"]).astimezone(ZoneInfo(TZ))
    assert fire.date() == (now_l + timedelta(days=7)).date()
    assert fire.strftime("%H:%M") == past.strftime("%H:%M")


def test_duplicate_days_deduped_and_repeat_wins_over_fire_at(worker, created):
    wh, _ = worker
    far = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
    r = _mk(wh, created, repeat_days=[3, 1, 1], time_of_day="08:15", tz=TZ, fire_at=far)
    assert r.status_code == 200, r.text
    a = r.json()
    assert a["repeat_days"] == [1, 3]
    fire = datetime.fromisoformat(a["fire_at"]).astimezone(ZoneInfo(TZ))
    assert fire.weekday() in (1, 3) and fire.strftime("%H:%M") == "08:15"
    assert fire < datetime.now(timezone.utc) + timedelta(days=8)


def test_empty_repeat_days_is_one_off(worker, created):
    wh, _ = worker
    when = (datetime.now(timezone.utc) + timedelta(hours=2)).isoformat()
    r = _mk(wh, created, repeat_days=[], fire_at=when)
    assert r.status_code == 200, r.text
    assert r.json()["repeat_days"] is None and r.json()["time_of_day"] is None


def test_other_timezone_respected(worker, created):
    wh, _ = worker
    r = _mk(wh, created, repeat_days=list(range(7)), time_of_day="09:00", tz="Asia/Tokyo")
    assert r.status_code == 200
    fire = datetime.fromisoformat(r.json()["fire_at"]).astimezone(ZoneInfo("Asia/Tokyo"))
    assert fire.strftime("%H:%M") == "09:00"
    assert fire - datetime.now(timezone.utc) <= timedelta(days=1)


def test_other_user_cannot_touch_repeating_alarm(worker, admin, created):
    wh, _ = worker
    ah, _ = admin
    a = _mk(wh, created, repeat_days=[2], time_of_day="10:00", tz=TZ).json()
    for path, m in ((f"/alarms/{a['id']}", "delete"), (f"/alarms/{a['id']}/dismiss", "post"), (f"/alarms/{a['id']}/snooze", "post")):
        r = getattr(requests, m)(f"{API}{path}", headers=ah, json={"minutes": 5} if "snooze" in path else None, timeout=20)
        assert r.status_code == 404, (path, r.status_code)


def test_snoozed_repeating_alarm_fires_then_resumes_series(worker, created):
    wh, wu = worker
    today = datetime.now(ZoneInfo(TZ)).weekday()
    a = _mk(wh, created, repeat_days=[today], time_of_day="05:00", tz=TZ).json()
    s = requests.post(f"{API}/alarms/{a['id']}/snooze", headers=wh, json={"minutes": 10}, timeout=20)
    assert s.status_code == 200 and s.json()["repeat_days"] == [today]
    # force the snoozed ring to be due now
    due = (datetime.now(timezone.utc) - timedelta(seconds=1)).isoformat()
    _db(lambda db: db.alarms.update_one({"id": a["id"]}, {"$set": {"fire_at": due}}))
    rec = None
    end = time.time() + 40
    while time.time() < end:
        rec = _db(lambda db: db.alarms.find_one({"id": a["id"]}, {"_id": 0}))
        if rec["fire_at"] != due:
            break
        time.sleep(3)
    assert rec["fire_at"] != due, "snoozed repeat never fired"
    assert rec["status"] == "scheduled"
    nxt = datetime.fromisoformat(rec["fire_at"]).astimezone(ZoneInfo(TZ))
    assert nxt.strftime("%H:%M") == "05:00" and nxt.weekday() == today
    n = _db(lambda db: db.notifications.count_documents({"meta.alarm_id": a["id"], "type": "alarm"}))
    assert n == 1
    # Still listed after ringing
    assert any(x["id"] == a["id"] for x in requests.get(f"{API}/alarms", headers=wh, timeout=20).json())


# --- Clocked In status + live activity endpoint ---
def test_clocked_in_from_web_and_invalid_activity(worker):
    wh, _ = worker
    requests.post(f"{API}/time/clock-out", headers=wh, timeout=20)
    try:
        t0 = time.time()
        r = requests.post(f"{API}/time/clock-in", headers=wh, json={"activity": "clocked_in"}, timeout=20)
        assert r.status_code == 200 and r.json()["activity"] == "clocked_in"
        print("web clock-in latency", round(time.time() - t0, 2))
        assert requests.post(f"{API}/time/clock-in", headers=wh, json={"activity": "clocked_in"}, timeout=20).status_code == 400
        assert requests.post(f"{API}/time/clock-in", headers=wh, json={"activity": "napping"}, timeout=20).status_code == 400
    finally:
        assert requests.post(f"{API}/time/clock-out", headers=wh, timeout=20).status_code == 200
    assert requests.get(f"{API}/time/active", headers=wh, timeout=20).json() == []


def test_live_activity_endpoint_auth_and_validation(worker):
    wh, _ = worker
    assert requests.post(f"{API}/push/live-activity", json={"fcm_token": "x"}, timeout=20).status_code == 401
    assert requests.post(f"{API}/push/live-activity", headers=wh, json={}, timeout=20).status_code == 422
    # unknown device token -> no-op, ok
    r = requests.post(f"{API}/push/live-activity", headers=wh, json={"fcm_token": "TEST_unknown_tok", "start_token": "zz"}, timeout=20)
    assert r.status_code == 200 and r.json()["ok"] is True
    assert _db(lambda db: db.device_tokens.find_one({"token": "TEST_unknown_tok"})) is None


# --- Delete keeps history; concurrent ticks ---
def test_delete_task_keeps_completions_and_cancels_alarms(admin, worker, created):
    ah, _ = admin
    wh, wu = worker
    t = requests.post(f"{API}/tasks", headers=ah, json={"title": "TEST_it18_del", "price": 3, "assignee_id": wu["id"]}, timeout=20).json()
    created["tasks"].append(t["id"])
    assert requests.patch(f"{API}/tasks/{t['id']}", headers=wh, json={"status": "completed"}, timeout=20).status_code == 200
    al = _mk(wh, created, fire_at=(datetime.now(timezone.utc) + timedelta(hours=3)).isoformat(), task_id=t["id"]).json()
    assert requests.delete(f"{API}/tasks/{t['id']}", headers=ah, timeout=20).status_code == 200
    assert _db(lambda db: db.task_completions.count_documents({"task_id": t["id"]})) == 1
    assert _db(lambda db: db.alarms.find_one({"id": al["id"]}))["status"] == "cancelled"
    pr = requests.get(f"{API}/payroll", headers=ah, timeout=20)
    assert pr.status_code == 200


def test_concurrent_ticks_record_one_completion(admin, worker, created):
    ah, _ = admin
    wh, wu = worker
    t = requests.post(f"{API}/tasks", headers=ah, json={"title": "TEST_it18_race", "price": 1, "assignee_id": wu["id"]}, timeout=20).json()
    created["tasks"].append(t["id"])
    with ThreadPoolExecutor(6) as ex:
        codes = list(ex.map(lambda _: requests.patch(f"{API}/tasks/{t['id']}", headers=wh, json={"status": "completed"}, timeout=20).status_code, range(6)))
    assert all(c == 200 for c in codes), codes
    assert _db(lambda db: db.task_completions.count_documents({"task_id": t["id"]})) == 1
