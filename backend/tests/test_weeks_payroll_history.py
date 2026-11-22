"""Week math, weekly payroll + paid marks, week history and crew health — all must agree."""
import os
import time
import uuid
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import pytest
import requests
from dotenv import load_dotenv
from pymongo import MongoClient

load_dotenv("/app/backend/.env")
API = os.environ["REACT_APP_BACKEND_URL"].rstrip("/") + "/api"
TZ = ZoneInfo(os.environ.get("WEEK_TZ") or "UTC")
db = MongoClient(os.environ["MONGO_URL"])[os.environ["DB_NAME"]]


def _login(email, password):
    r = requests.post(f"{API}/auth/login", json={"email": email, "password": password}, timeout=20)
    r.raise_for_status()
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _monday(d):
    return d - timedelta(days=d.weekday())


@pytest.fixture(scope="module")
def ctx():
    admin = _login("admin@loveworks.com", "admin123")
    email = f"test_weeks_{uuid.uuid4().hex[:8]}@loveworks.com"
    r = requests.post(f"{API}/workers", json={"email": email, "password": "Weeks123!", "name": "Weeks Test"}, headers=admin, timeout=20)
    r.raise_for_status()
    wid = r.json()["id"]
    worker = _login(email, "Weeks123!")
    today_local = datetime.now(TZ).date()
    this_mon = _monday(today_local)
    last_mon = this_mon - timedelta(days=7)
    # last week: Wednesday 23:30 local is already Thursday in UTC; it must still count on Wednesday
    wed_late = datetime(last_mon.year, last_mon.month, last_mon.day, 23, 30, tzinfo=TZ) + timedelta(days=2)
    sun_night = datetime(last_mon.year, last_mon.month, last_mon.day, 22, 0, tzinfo=TZ) + timedelta(days=6)
    rows = [
        {"completed_at": wed_late.astimezone(timezone.utc).isoformat(), "price": 12.5, "title": "Late Wed"},
        {"completed_at": (wed_late - timedelta(hours=5)).astimezone(timezone.utc).isoformat(), "price": 7.25, "title": "Wed"},
    ]
    for c in rows:
        db.task_completions.insert_one({"id": str(uuid.uuid4()), "task_id": f"t-{uuid.uuid4().hex[:6]}", "worker_id": wid,
                                        "frequency": "daily", **c})
    # shift from Sunday 22:00 to Monday 02:00 local: 2h last week (Sun), 2h this week (Mon)
    db.time_entries.insert_one({"id": str(uuid.uuid4()), "user_id": wid, "activity": "work",
                                "clock_in": sun_night.astimezone(timezone.utc).isoformat(),
                                "clock_out": (sun_night + timedelta(hours=4)).astimezone(timezone.utc).isoformat(),
                                "duration_seconds": 4 * 3600})
    yield {"admin": admin, "worker": worker, "wid": wid, "this_mon": this_mon.isoformat(), "last_mon": last_mon.isoformat(),
           "wed": (last_mon + timedelta(days=2)).isoformat(), "sun": (last_mon + timedelta(days=6)).isoformat()}
    # undo test paid marks so their rows leave the admin's real Google Sheet, then remove the worker
    for _ in range(15):
        if requests.get(f"{API}/payroll/sheet", headers=admin, timeout=20).json().get("pending", 0) == 0:
            break
        time.sleep(1)
    for p in db.payouts.find({"worker_id": wid}, {"_id": 0, "week_start": 1}):
        requests.delete(f"{API}/payroll/week/{p['week_start']}/paid/{wid}", headers=admin, timeout=20)
    time.sleep(4)
    requests.delete(f"{API}/workers/{wid}", headers=admin, timeout=20)


def _row(data, wid):
    return next(r for r in data["rows"] if r["worker"]["id"] == wid)


def test_last_week_buckets_by_local_day(ctx):
    d = requests.get(f"{API}/payroll/week", params={"week": ctx["wed"]}, headers=ctx["admin"], timeout=20).json()
    assert d["week_start"] == ctx["last_mon"] and not d["is_current"]
    r = _row(d, ctx["wid"])
    assert r["earned"] == 19.75 and r["tasks_completed"] == 2
    by_day = {x["date"]: x for x in r["days"]}
    assert by_day[ctx["wed"]]["count"] == 2 and by_day[ctx["wed"]]["earned"] == 19.75
    assert by_day[ctx["sun"]]["hours"] == 2.0
    assert r["hours"] == 2.0


def test_shift_across_monday_counts_this_week(ctx):
    d = requests.get(f"{API}/payroll/week", headers=ctx["admin"], timeout=20).json()
    r = _row(d, ctx["wid"])
    assert d["week_start"] == ctx["this_mon"] and d["is_current"]
    assert r["days"][0]["hours"] >= 2.0


def test_completing_a_task_pays_at_completion_price(ctx):
    t = requests.post(f"{API}/tasks", json={"title": "Weekly test task", "price": 10, "assignee_id": ctx["wid"], "frequency": "daily"},
                      headers=ctx["admin"], timeout=20).json()
    requests.patch(f"{API}/tasks/{t['id']}", json={"status": "completed"}, headers=ctx["worker"], timeout=20).raise_for_status()
    requests.patch(f"{API}/tasks/{t['id']}", json={"price": 99}, headers=ctx["admin"], timeout=20).raise_for_status()
    wk = requests.get(f"{API}/me/weekly-activity", headers=ctx["worker"], timeout=20).json()
    assert wk["week_earned"] == 10 and wk["week_tasks"] == 1
    r = _row(requests.get(f"{API}/payroll/week", headers=ctx["admin"], timeout=20).json(), ctx["wid"])
    assert r["earned"] == 10
    hist = requests.get(f"{API}/me/history/weeks", params={"weeks": 2}, headers=ctx["worker"], timeout=20).json()
    assert [w["week_start"] for w in hist["weeks"]] == [ctx["this_mon"], ctx["last_mon"]]
    assert hist["weeks"][0]["earned"] == 10 and hist["weeks"][1]["earned"] == 19.75
    assert hist["weeks"][0]["days"][datetime.now(TZ).weekday()]["tasks"][0]["price"] == 10


def test_mark_paid_locks_amount_until_undone(ctx):
    admin, wid, week = ctx["admin"], ctx["wid"], ctx["last_mon"]
    assert requests.post(f"{API}/payroll/week/{week}/paid", json={"worker_ids": [wid]}, headers=admin, timeout=20).json()["marked"] == 1
    assert requests.post(f"{API}/payroll/week/{week}/paid", json={"worker_ids": [wid]}, headers=admin, timeout=20).json()["marked"] == 0
    r = _row(requests.get(f"{API}/payroll/week", params={"week": week}, headers=admin, timeout=20).json(), wid)
    assert r["payout"]["amount"] == 19.75 and r["changed_since_paid"] is False
    # a late completion lands in the paid week: the paid amount stays, the row is flagged
    late = datetime.fromisoformat(f"{ctx['wed']}T10:00:00").replace(tzinfo=TZ).astimezone(timezone.utc).isoformat()
    db.task_completions.insert_one({"id": str(uuid.uuid4()), "task_id": "t-late", "worker_id": wid, "completed_at": late, "price": 5, "title": "Late"})
    r = _row(requests.get(f"{API}/payroll/week", params={"week": week}, headers=admin, timeout=20).json(), wid)
    assert r["payout"]["amount"] == 19.75 and r["earned"] == 24.75 and r["changed_since_paid"] is True
    hist = requests.get(f"{API}/me/history/weeks", params={"weeks": 2}, headers=ctx["worker"], timeout=20).json()
    assert hist["weeks"][1]["payout"]["amount"] == 19.75
    alltime = next(x for x in requests.get(f"{API}/payroll", headers=admin, timeout=20).json() if x["worker"]["id"] == wid)
    assert alltime["paid_total"] == 19.75 and alltime["owed"] == round(alltime["tasks_earnings"] - 19.75, 2)
    assert requests.delete(f"{API}/payroll/week/{week}/paid/{wid}", headers=admin, timeout=20).json()["removed"] == 1
    requests.post(f"{API}/payroll/week/{week}/paid", json={"worker_ids": [wid]}, headers=admin, timeout=20)
    r = _row(requests.get(f"{API}/payroll/week", params={"week": week}, headers=admin, timeout=20).json(), wid)
    assert r["payout"]["amount"] == 24.75 and r["changed_since_paid"] is False


def test_future_week_cannot_be_paid(ctx):
    nxt = (datetime.fromisoformat(ctx["this_mon"]) + timedelta(days=7)).date().isoformat()
    r = requests.post(f"{API}/payroll/week/{nxt}/paid", json={}, headers=ctx["admin"], timeout=20)
    assert r.status_code == 400


def test_bad_week_param(ctx):
    assert requests.get(f"{API}/payroll/week", params={"week": "nope"}, headers=ctx["admin"], timeout=20).status_code == 400


def test_worker_cannot_use_admin_endpoints(ctx):
    w = ctx["worker"]
    assert requests.get(f"{API}/payroll/week", headers=w, timeout=20).status_code == 403
    assert requests.get(f"{API}/admin/health/crew", headers=w, timeout=20).status_code == 403
    assert requests.get(f"{API}/admin/workers/{ctx['wid']}/history/weeks", headers=w, timeout=20).status_code == 403


def test_admin_sees_worker_history(ctx):
    d = requests.get(f"{API}/admin/workers/{ctx['wid']}/history/weeks", params={"weeks": 1, "before": ctx["this_mon"]},
                     headers=ctx["admin"], timeout=20).json()
    assert d["weeks"][0]["week_start"] == ctx["last_mon"]
    assert requests.get(f"{API}/admin/workers/nope/history/weeks", headers=ctx["admin"], timeout=20).status_code == 404


def test_crew_health_week_and_not_shared(ctx):
    w, admin, wid = ctx["worker"], ctx["admin"], ctx["wid"]
    mon = datetime.fromisoformat(ctx["this_mon"]).date()
    prev_sun = (mon - timedelta(days=1)).isoformat()
    # the upload API only takes recent days, so seed the week directly
    for day, active, total, kg in ((prev_sun, 100, 1800, 80), (mon.isoformat(), 400, 2200, 79)):
        db.health_daily.update_one({"user_id": wid, "date": day}, {"$set": {"active_kcal": active, "total_kcal": total, "weight_kg": kg,
                                   "weight_source": "scale_bluetooth", "updated_at": datetime.now(timezone.utc).isoformat()}}, upsert=True)
    d = requests.get(f"{API}/admin/health/crew", headers=admin, timeout=20).json()
    r = _row(d, wid)
    assert r["shared"] is True and r["active_total"] >= 400 and r["latest_weight_kg"] is not None
    assert r["days"][0]["weight_kg"] == 79
    if r["latest_weight_date"] == mon.isoformat():
        assert r["weight_change_kg"] == -1.0 and r["weight_source"] == "scale_bluetooth"
    last = _row(requests.get(f"{API}/admin/health/crew", params={"week": prev_sun}, headers=admin, timeout=20).json(), wid)
    assert last["days"][6] == {"date": prev_sun, "active_kcal": 100, "total_kcal": 1800, "weight_kg": 80}
    assert last["active_avg"] == 100 and last["days_with_data"] == 1
    requests.patch(f"{API}/health/sharing", json={"share": False}, headers=w, timeout=20)
    r = _row(requests.get(f"{API}/admin/health/crew", headers=admin, timeout=20).json(), wid)
    assert r == {"worker": r["worker"], "shared": False}


def test_payday_alerts_on_paid_and_undo(ctx):
    admin, worker, wid, week = ctx["admin"], ctx["worker"], ctx["wid"], ctx["last_mon"]
    requests.delete(f"{API}/payroll/week/{week}/paid/{wid}", headers=admin, timeout=20)
    requests.post(f"{API}/payroll/week/{week}/paid", json={"worker_ids": [wid]}, headers=admin, timeout=20).raise_for_status()
    items = requests.get(f"{API}/notifications", headers=worker, timeout=20).json()
    items = items.get("items", items)
    paid = next(n for n in items if n["type"] == "payday")
    assert paid["title"].startswith("You've been paid $") and "Week of" in paid["body"]
    requests.delete(f"{API}/payroll/week/{week}/paid/{wid}", headers=admin, timeout=20).raise_for_status()
    items = requests.get(f"{API}/notifications", headers=worker, timeout=20).json()
    items = items.get("items", items)
    assert items[0]["type"] == "payday" and items[0]["title"] == "Payment update" and "took back" in items[0]["body"]


def test_sheet_status_shape(ctx):
    s = requests.get(f"{API}/payroll/sheet", headers=ctx["admin"], timeout=20).json()
    assert set(s) >= {"configured", "url", "synced", "pending", "error"}
    assert requests.get(f"{API}/payroll/sheet", headers=ctx["worker"], timeout=20).status_code == 403
