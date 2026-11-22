"""Repeating alarms, lock-screen timer (Live Activity) push plumbing, and the Clocked In status.
Run: REACT_APP_BACKEND_URL=... pytest -q backend/tests/test_repeat_alarms_live_activity.py
"""
import asyncio
import os
import sys
import time
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import pytest
import requests
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient

load_dotenv("/app/backend/.env")
API = os.environ["REACT_APP_BACKEND_URL"].rstrip("/") + "/api"
TZ = "America/Chicago"
FAKE_FCM = "TEST_fake_fcm_token_live_activity"


def _db(fn):
    async def go():
        db = AsyncIOMotorClient(os.environ["MONGO_URL"])[os.environ["DB_NAME"]]
        return await fn(db)
    return asyncio.run(go())


def _login(email, pw):
    d = requests.post(f"{API}/auth/login", json={"email": email, "password": pw}, timeout=20).json()
    return {"Authorization": f"Bearer {d.get('access_token') or d.get('token')}"}, d["user"]


@pytest.fixture(scope="module")
def worker():
    h, u = _login("lovetest@loveworks.com", "Love123!")
    requests.post(f"{API}/time/clock-out", headers=h, timeout=20)  # start clean
    return h, u


def test_repeating_alarm_next_occurrence_and_fields(worker):
    wh, _ = worker
    now_l = datetime.now(ZoneInfo(TZ))
    target = now_l + timedelta(minutes=5)
    body = {"title": "TEST_repeat", "repeat_days": [target.weekday()], "time_of_day": target.strftime("%H:%M"), "tz": TZ}
    r = requests.post(f"{API}/alarms", headers=wh, json=body, timeout=20)
    assert r.status_code == 200, r.text
    a = r.json()
    assert a["repeat_days"] == [target.weekday()] and a["time_of_day"] == target.strftime("%H:%M") and a["tz"] == TZ
    fire = datetime.fromisoformat(a["fire_at"]).astimezone(ZoneInfo(TZ))
    assert fire.strftime("%H:%M") == target.strftime("%H:%M") and fire.date() == target.date()
    assert any(x["id"] == a["id"] for x in requests.get(f"{API}/alarms", headers=wh, timeout=20).json())
    requests.delete(f"{API}/alarms/{a['id']}", headers=wh, timeout=20)


def test_weekdays_alarm_skips_weekend(worker):
    wh, _ = worker
    r = requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_wk", "repeat_days": [0, 1, 2, 3, 4], "time_of_day": "07:30", "tz": TZ}, timeout=20)
    assert r.status_code == 200, r.text
    fire = datetime.fromisoformat(r.json()["fire_at"]).astimezone(ZoneInfo(TZ))
    assert fire.weekday() < 5 and fire.strftime("%H:%M") == "07:30"
    assert fire > datetime.now(timezone.utc)
    requests.delete(f"{API}/alarms/{r.json()['id']}", headers=wh, timeout=20)


@pytest.mark.parametrize("bad", [
    {"repeat_days": [7], "time_of_day": "07:00", "tz": TZ},
    {"repeat_days": [1], "time_of_day": "25:00", "tz": TZ},
    {"repeat_days": [1], "time_of_day": "07:00", "tz": "Mars/Base"},
    {"repeat_days": [1], "time_of_day": "7am", "tz": TZ},
    {},
])
def test_repeating_alarm_validation(worker, bad):
    wh, _ = worker
    assert requests.post(f"{API}/alarms", headers=wh, json={"title": "x", **bad}, timeout=20).status_code == 400


def test_repeating_alarm_fires_and_reschedules_itself(worker):
    wh, wu = worker
    today = datetime.now(ZoneInfo(TZ)).weekday()
    a = requests.post(f"{API}/alarms", headers=wh, json={"title": "TEST_repeat_fire", "repeat_days": [today], "time_of_day": "06:00", "tz": TZ}, timeout=20).json()
    due = (datetime.now(timezone.utc) - timedelta(seconds=1)).isoformat()
    _db(lambda db: db.alarms.update_one({"id": a["id"]}, {"$set": {"fire_at": due}}))
    deadline = time.time() + 40
    rec = None
    while time.time() < deadline:
        rec = _db(lambda db: db.alarms.find_one({"id": a["id"]}, {"_id": 0}))
        if rec["fire_at"] != due:
            break
        time.sleep(3)
    assert rec["fire_at"] != due, "repeating alarm never fired"
    assert rec["status"] == "scheduled", "series must stay scheduled after ringing"
    nxt = datetime.fromisoformat(rec["fire_at"]).astimezone(ZoneInfo(TZ))
    assert nxt.weekday() == today and nxt.strftime("%H:%M") == "06:00" and nxt > datetime.now(timezone.utc)
    note = _db(lambda db: db.notifications.find_one({"user_id": wu["id"], "type": "alarm", "meta.alarm_id": a["id"]}, {"_id": 0}))
    assert note
    # Stop keeps the series; cancel ends it
    assert requests.post(f"{API}/alarms/{a['id']}/dismiss", headers=wh, timeout=20).status_code == 200
    assert _db(lambda db: db.alarms.find_one({"id": a["id"]}, {"_id": 0}))["status"] == "scheduled"
    requests.delete(f"{API}/alarms/{a['id']}", headers=wh, timeout=20)
    assert _db(lambda db: db.alarms.find_one({"id": a["id"]}, {"_id": 0}))["status"] == "cancelled"


def test_clocked_in_status_is_accepted(worker):
    wh, _ = worker
    r = requests.post(f"{API}/time/clock-in", headers=wh, json={"activity": "clocked_in", "source": "ios"}, timeout=20)
    assert r.status_code == 200, r.text
    assert r.json()["activity"] == "clocked_in"
    assert any(e["activity"] == "clocked_in" for e in requests.get(f"{API}/time/active", headers=wh, timeout=20).json())
    assert requests.post(f"{API}/time/clock-out?source=ios", headers=wh, timeout=20).status_code == 200


def test_live_activity_tokens_and_server_pushes(worker):
    wh, wu = worker
    assert requests.post(f"{API}/push/register-device", headers=wh, json={"token": FAKE_FCM, "platform": "ios"}, timeout=20).json()["fcm_ready"]
    try:
        assert requests.post(f"{API}/push/live-activity", headers=wh, json={"fcm_token": FAKE_FCM, "start_token": "aa11"}, timeout=20).status_code == 200
        dev = _db(lambda db: db.device_tokens.find_one({"token": FAKE_FCM}, {"_id": 0}))
        assert dev["la_start_token"] == "aa11"

        log = "/var/log/supervisor/backend.err.log"
        mark = os.path.getsize(log)
        # Website clock-in: server should try to start the lock-screen timer
        e = requests.post(f"{API}/time/clock-in", headers=wh, json={"activity": "working"}, timeout=20).json()
        assert requests.post(f"{API}/push/live-activity", headers=wh,
                             json={"fcm_token": FAKE_FCM, "activity_token": "bb22", "entry_id": e["id"]}, timeout=20).status_code == 200
        la = _db(lambda db: db.live_activities.find_one({"entry_id": e["id"]}, {"_id": 0}))
        assert la and la["activity_token"] == "bb22" and la["ended"] is False
        # Website break: update; website clock-out: end
        requests.post(f"{API}/time/clock-in", headers=wh, json={"activity": "break"}, timeout=20)
        requests.post(f"{API}/time/clock-out", headers=wh, timeout=20)
        la = _db(lambda db: db.live_activities.find_one({"entry_id": e["id"]}, {"_id": 0}))
        assert la["ended"] is True
        time.sleep(1)
        with open(log) as f:
            f.seek(mark)
            tail = f.read()
        sends = tail.count("live activity send failed")
        assert sends >= 3, f"expected start/update/end attempts, saw {sends}"
        # Fake tokens are rejected by Firebase itself (proves the message was built and sent), not by our code
        assert "registration token" in tail.lower() or "invalid" in tail.lower()
    finally:
        _db(lambda db: db.device_tokens.delete_many({"token": FAKE_FCM}))
        _db(lambda db: db.live_activities.delete_many({"fcm_token": FAKE_FCM}))


def test_live_activity_payload_shape():
    sys.path.insert(0, "/app/backend")
    import server  # noqa: E402
    from firebase_admin import messaging
    state = server._live_activity_state([{"activity": "clocked_in"}, {"activity": "break"}])
    assert state == {"onBreak": True, "activityLabel": "Break"}
    attrs = {"entryId": "e1", "workerName": "Love", "startedAt": 1700000000.0}
    enc = messaging._MessagingService.encode_message(server._live_activity_message("fcm", "la", "start", state, attrs))
    aps = enc["apns"]["payload"]["aps"]
    assert enc["apns"]["live_activity_token"] == "la"
    assert aps["event"] == "start" and aps["attributes-type"] == "ClockInAttributes"
    assert aps["attributes"] == attrs and aps["content-state"] == state and "alert" in aps
    end = messaging._MessagingService.encode_message(server._live_activity_message("fcm", "la", "end", state))
    assert end["apns"]["payload"]["aps"]["event"] == "end" and "dismissal-date" in end["apns"]["payload"]["aps"]
