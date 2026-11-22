"""Iteration 17: completion events, payroll/awards, alarms API (independent verification).
Run: export REACT_APP_BACKEND_URL=...; pytest -q backend/tests/test_completions_alarms_iter17.py
"""
import asyncio
import os
import time
from datetime import datetime, timedelta, timezone

import pytest
import requests
import creds as C  # noqa: E402
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient

load_dotenv("/app/backend/.env")
API = C.BASE_URL + "/api"


def _db(fn):
    async def go():
        db = AsyncIOMotorClient(os.environ["MONGO_URL"])[os.environ["DB_NAME"]]
        return await fn(db)
    return asyncio.run(go())


def _login(email, pw):
    r = requests.post(f"{API}/auth/login", json={"email": email, "password": pw}, timeout=20)
    if r.status_code != 200:
        pytest.skip(f"login failed {email}")
    d = r.json()
    return {"Authorization": f"Bearer {d.get('access_token') or d.get('token')}"}, d["user"]


@pytest.fixture(scope="module")
def admin():
    return _login(C.ADMIN["email"], C.ADMIN["password"])


@pytest.fixture(scope="module")
def worker():
    return _login(C.WORKER["email"], C.WORKER["password"])


@pytest.fixture(scope="module")
def sb_admin():
    return _login(C.REVIEWER["email"], C.REVIEWER["password"])


@pytest.fixture(scope="module")
def sb_worker():
    return _login(C.DEMO_WORKER["email"], C.DEMO_WORKER["password"])


@pytest.fixture(scope="module")
def created():
    d = {"tasks": [], "sb_tasks": [], "alarms": []}
    yield d


@pytest.fixture(scope="module", autouse=True)
def cleanup(created):
    yield
    try:
        ah, _ = _login(C.ADMIN["email"], C.ADMIN["password"])
        for t in created["tasks"]:
            requests.delete(f"{API}/tasks/{t}", headers=ah, timeout=20)
        sh, _ = _login(C.REVIEWER["email"], C.REVIEWER["password"])
        for t in created["sb_tasks"]:
            requests.delete(f"{API}/tasks/{t}", headers=sh, timeout=20)
    except Exception:
        pass
    ids = list(created["alarms"])
    if ids:
        _db(lambda db: db.alarms.delete_many({"id": {"$in": ids}}))
        _db(lambda db: db.notifications.delete_many({"type": "alarm", "meta.alarm_id": {"$in": ids}}))


def _mk_task(ah, wid, created, freq="once", price=7.5, key="tasks"):
    r = requests.post(f"{API}/tasks", headers=ah, json={"title": f"TEST_iter17_{freq}", "price": price, "assignee_id": wid, "frequency": freq}, timeout=20)
    assert r.status_code in (200, 201), r.text
    tid = r.json()["id"]
    created[key].append(tid)
    return tid


def _events(tid):
    return _db(lambda db: db.task_completions.find({"task_id": tid}, {"_id": 0}).to_list(100))


def _payroll_row(ah, wid):
    rows = requests.get(f"{API}/payroll", headers=ah, timeout=20).json()
    return next(r for r in rows if r["worker"]["id"] == wid)


# --- Completion events ---
class TestCompletionEvents:
    def test_complete_records_one_event_and_idempotent(self, admin, worker, created):
        ah, _ = admin
        wh, wu = worker
        tid = _mk_task(ah, wu["id"], created)
        p0 = _payroll_row(ah, wu["id"])
        r = requests.patch(f"{API}/tasks/{tid}", headers=wh, json={"status": "completed"}, timeout=20)
        assert r.status_code == 200 and r.json()["status"] == "completed"
        ev = _events(tid)
        assert len(ev) == 1
        e = ev[0]
        assert e["worker_id"] == wu["id"] and e["title"] == "TEST_iter17_once" and e["price"] == 7.5
        assert e["completed_at"] == r.json()["completed_at"]
        # resend completed -> no second row
        r2 = requests.patch(f"{API}/tasks/{tid}", headers=wh, json={"status": "completed"}, timeout=20)
        assert r2.status_code == 200
        assert len(_events(tid)) == 1
        p1 = _payroll_row(ah, wu["id"])
        assert p1["tasks_completed"] == p0["tasks_completed"] + 1
        assert round(p1["tasks_earnings"] - p0["tasks_earnings"], 2) == 7.5
        # untick -> removed
        assert requests.patch(f"{API}/tasks/{tid}", headers=wh, json={"status": "assigned"}, timeout=20).status_code == 200
        assert len(_events(tid)) == 0
        p2 = _payroll_row(ah, wu["id"])
        assert p2["tasks_completed"] == p0["tasks_completed"]

    def test_untick_removes_only_current_event(self, admin, worker, created):
        ah, _ = admin
        wh, wu = worker
        tid = _mk_task(ah, wu["id"], created, freq="daily", price=3)
        p0 = _payroll_row(ah, wu["id"])
        # A historic event from 2 days ago for this task
        old = (datetime.now(timezone.utc) - timedelta(days=2)).isoformat()
        _db(lambda db: db.task_completions.insert_one({"id": "TEST_hist_" + tid, "task_id": tid, "worker_id": wu["id"], "completed_at": old, "title": "TEST_iter17_daily", "price": 3.0, "frequency": "daily"}))
        assert requests.patch(f"{API}/tasks/{tid}", headers=wh, json={"status": "completed"}, timeout=20).status_code == 200
        assert len(_events(tid)) == 2
        p1 = _payroll_row(ah, wu["id"])
        assert p1["tasks_completed"] == p0["tasks_completed"] + 2
        assert round(p1["tasks_earnings"] - p0["tasks_earnings"], 2) == 6.0
        assert requests.patch(f"{API}/tasks/{tid}", headers=wh, json={"status": "assigned"}, timeout=20).status_code == 200
        ev = _events(tid)
        assert len(ev) == 1 and ev[0]["completed_at"] == old

    def test_awards_still_work(self, worker):
        wh, _ = worker
        r = requests.get(f"{API}/awards", headers=wh, timeout=20)
        assert r.status_code == 200
        assert requests.get(f"{API}/awards/catalog", headers=wh, timeout=20).status_code == 200

    def test_weekly_activity_shape(self, worker):
        wh, _ = worker
        r = requests.get(f"{API}/me/weekly-activity", headers=wh, timeout=20)
        assert r.status_code == 200
        assert len(r.json()["completions_by_day"]) == 7


# --- Alarms ---
def _fire(sec):
    return (datetime.now(timezone.utc) + timedelta(seconds=sec)).astimezone(timezone(timedelta(hours=-6))).isoformat()


class TestAlarms:
    def test_create_list_isolation(self, worker, sb_worker, created):
        wh, wu = worker
        sh, su = sb_worker
        r = requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_alarm_a", "fire_at": _fire(3600), "note": "n1", "source": "web"}, timeout=20)
        assert r.status_code == 200, r.text
        a = r.json()
        created["alarms"].append(a["id"])
        assert a["status"] == "scheduled" and a["title"] == "TEST_alarm_a" and a["note"] == "n1" and a["source"] == "web"
        assert any(x["id"] == a["id"] for x in requests.get(f"{API}/alarms", headers=wh, timeout=20).json())
        assert not any(x["id"] == a["id"] for x in requests.get(f"{API}/alarms", headers=sh, timeout=20).json())
        # B cannot cancel/snooze/dismiss A's alarm
        assert requests.delete(f"{API}/alarms/{a['id']}", headers=sh, timeout=20).status_code == 404
        assert requests.post(f"{API}/alarms/{a['id']}/snooze", headers=sh, json={"minutes": 5}, timeout=20).status_code == 404
        assert requests.post(f"{API}/alarms/{a['id']}/dismiss", headers=sh, timeout=20).status_code == 404

    def test_validation(self, worker):
        wh, _ = worker
        assert requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_x", "fire_at": _fire(-3600)}, timeout=20).status_code == 400
        assert requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_x", "fire_at": "not-a-date"}, timeout=20).status_code == 400
        assert requests.post(f"{API}/alarms", json={"title": "TEST_x", "fire_at": _fire(3600)}, timeout=20).status_code == 401
        assert requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_x", "fire_at": _fire(3600), "source": "android"}, timeout=20).status_code == 400
        assert requests.post(f"{API}/alarms", headers=wh, json={"title": "", "fire_at": _fire(3600)}, timeout=20).status_code == 422

    def test_task_id_of_other_worker_404(self, worker, sb_admin, sb_worker, admin, created):
        wh, wu = worker
        sah, _ = sb_admin
        _, su = sb_worker
        other = _mk_task(sah, su["id"], created, key="sb_tasks")
        assert requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_x", "fire_at": _fire(3600), "task_id": other}, timeout=20).status_code == 404
        mine = _mk_task(admin[0], wu["id"], created)
        r = requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_task_alarm", "fire_at": _fire(3600), "task_id": mine}, timeout=20)
        assert r.status_code == 200 and r.json()["task_id"] == mine
        created["alarms"].append(r.json()["id"])

    def test_snooze_dismiss_cancel(self, worker, created):
        wh, _ = worker
        a = requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_sd", "fire_at": _fire(3600)}, timeout=20).json()
        created["alarms"].append(a["id"])
        before = datetime.now(timezone.utc)
        s = requests.post(f"{API}/alarms/{a['id']}/snooze", headers=wh, json={"minutes": 10}, timeout=20)
        assert s.status_code == 200 and s.json()["status"] == "scheduled"
        delta = (datetime.fromisoformat(s.json()["fire_at"]) - before).total_seconds()
        assert 590 <= delta <= 620
        assert requests.post(f"{API}/alarms/{a['id']}/snooze", headers=wh, json={"minutes": 0}, timeout=20).status_code == 422
        assert requests.post(f"{API}/alarms/{a['id']}/dismiss", headers=wh, timeout=20).status_code == 200
        assert _db(lambda db: db.alarms.find_one({"id": a["id"]}))["status"] == "done"
        assert not any(x["id"] == a["id"] for x in requests.get(f"{API}/alarms", headers=wh, timeout=20).json())
        b = requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_cx", "fire_at": _fire(3600)}, timeout=20).json()
        created["alarms"].append(b["id"])
        assert requests.delete(f"{API}/alarms/{b['id']}", headers=wh, timeout=20).status_code == 200
        doc = _db(lambda db: db.alarms.find_one({"id": b["id"]}, {"_id": 0}))
        assert doc is not None and doc["status"] == "cancelled"
        assert not any(x["id"] == b["id"] for x in requests.get(f"{API}/alarms", headers=wh, timeout=20).json())

    def test_list_hides_fired_older_than_24h(self, worker, created):
        wh, wu = worker
        a = requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_old", "fire_at": _fire(3600)}, timeout=20).json()
        created["alarms"].append(a["id"])
        old = (datetime.now(timezone.utc) - timedelta(hours=30)).isoformat()
        _db(lambda db: db.alarms.update_one({"id": a["id"]}, {"$set": {"status": "fired", "fire_at": old}}))
        assert not any(x["id"] == a["id"] for x in requests.get(f"{API}/alarms", headers=wh, timeout=20).json())

    def test_fire_once_worker_and_admin_links(self, worker, admin, created):
        wh, wu = worker
        ah, au = admin
        w = requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_fire_w", "fire_at": _fire(5)}, timeout=20).json()
        a = requests.post(f"{API}/alarms", headers=ah, json={"title": "TEST_fire_a", "fire_at": _fire(5), "note": "adm"}, timeout=20).json()
        created["alarms"] += [w["id"], a["id"]]
        deadline = time.time() + 50
        while time.time() < deadline:
            docs = _db(lambda db: db.alarms.find({"id": {"$in": [w["id"], a["id"]]}}, {"_id": 0}).to_list(5))
            if all(d["status"] == "fired" for d in docs):
                break
            time.sleep(3)
        assert all(d["status"] == "fired" and d["fired_at"] for d in docs)
        time.sleep(20)  # another loop tick must not re-notify
        nw = _db(lambda db: db.notifications.find({"type": "alarm", "meta.alarm_id": w["id"]}, {"_id": 0}).to_list(5))
        na = _db(lambda db: db.notifications.find({"type": "alarm", "meta.alarm_id": a["id"]}, {"_id": 0}).to_list(5))
        assert len(nw) == 1 and len(na) == 1
        assert nw[0]["link"] == f"/worker?alarm={w['id']}" and nw[0]["meta"]["kind"] == "alarm" and nw[0]["user_id"] == wu["id"]
        assert na[0]["link"] == f"/admin?alarm={a['id']}" and na[0]["body"] == "adm"
        # fired within 24h still listed
        assert any(x["id"] == w["id"] and x["status"] == "fired" for x in requests.get(f"{API}/alarms", headers=wh, timeout=20).json())


# --- Rollover for weekly/monthly ---
def test_weekly_monthly_rollover(admin, worker, created):
    ah, _ = admin
    wh, wu = worker
    tw = _mk_task(ah, wu["id"], created, freq="weekly")
    tm = _mk_task(ah, wu["id"], created, freq="monthly")
    for t in (tw, tm):
        assert requests.patch(f"{API}/tasks/{t}", headers=wh, json={"status": "completed"}, timeout=20).status_code == 200
    old = (datetime.now(timezone.utc) - timedelta(days=40)).isoformat()
    _db(lambda db: db.tasks.update_many({"id": {"$in": [tw, tm]}}, {"$set": {"completed_at": old}}))
    deadline = time.time() + 75
    docs = []
    while time.time() < deadline:
        docs = _db(lambda db: db.tasks.find({"id": {"$in": [tw, tm]}}, {"_id": 0}).to_list(5))
        if all(d["status"] == "assigned" for d in docs):
            break
        time.sleep(5)
    assert all(d["status"] == "assigned" and d["completed_at"] is None and d["last_completed_at"] == old for d in docs)
