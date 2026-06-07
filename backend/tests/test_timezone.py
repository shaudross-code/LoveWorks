"""Timezone correctness for the weekly strip + window helpers.
Run with: pytest -xvs /app/backend/tests/test_timezone.py
"""
import os
import sys
import asyncio
from datetime import datetime, timezone, timedelta

sys.path.insert(0, "/app/backend")

# Force a known TZ before importing server
os.environ["WEEK_TZ"] = "America/Chicago"

from zoneinfo import ZoneInfo  # noqa: E402
from server import (  # noqa: E402
    _start_of_day, _start_of_week, _start_of_month, _start_of_year,
    APP_TZ, iso_utc, db, now_utc,
)

CHI = ZoneInfo("America/Chicago")


def test_app_tz_loaded():
    assert APP_TZ.key == "America/Chicago"


def test_start_of_week_is_local_monday():
    # Saturday 02:00 UTC = Friday 20:00 CST -> week_start should be Mon 00:00 CST of that local Mon
    dt = datetime(2026, 1, 17, 2, 0, tzinfo=timezone.utc)  # Sat 02:00 UTC = Fri 20:00 CST
    ws = _start_of_week(dt)
    assert ws.tzinfo is not None
    # Monday of that local week is Jan 12 (CST)
    assert ws.year == 2026 and ws.month == 1 and ws.day == 12
    assert ws.hour == 0 and ws.minute == 0
    assert ws.utcoffset() == timedelta(hours=-6)  # CST


def test_sunday_evening_local_does_not_cross_into_new_week():
    # Sun 23:30 CST -> still inside the Mon..Sun week starting prior Monday
    dt = datetime(2026, 1, 19, 5, 30, tzinfo=timezone.utc)  # Mon 05:30 UTC = Sun 23:30 CST
    ws = _start_of_week(dt)
    # Local Sun 23:30 -> still within week of Mon Jan 12 (because in CST it's still Sunday)
    assert ws.day == 12


def test_iso_utc_serializes_to_z_offset():
    dt = datetime(2026, 1, 12, 0, 0, tzinfo=CHI)  # 06:00 UTC
    s = iso_utc(dt)
    assert s.endswith("+00:00")
    assert "T06:00:00" in s


def test_start_of_month_is_local_first():
    dt = datetime(2026, 2, 1, 4, 0, tzinfo=timezone.utc)  # Feb 1 04:00 UTC = Jan 31 22:00 CST
    som = _start_of_month(dt)
    assert som.day == 1 and som.month == 1  # local month is still January


async def _create_user(role="worker", email_suffix="tz"):
    uid = f"tz-user-{email_suffix}"
    await db.users.update_one(
        {"id": uid},
        {"$set": {
            "id": uid, "email": f"{email_suffix}@tz.test", "role": role,
            "name": "TZ User", "password_hash": "x", "created_at": now_utc().isoformat(),
        }},
        upsert=True,
    )
    return uid


async def _seed_completion(uid, completed_at_iso, price=10.0, title="task"):
    await db.tasks.insert_one({
        "id": f"task-{title}-{completed_at_iso}",
        "assignee_id": uid,
        "title": title,
        "price": price,
        "status": "completed",
        "completed_at": completed_at_iso,
        "created_at": now_utc().isoformat(),
    })


def test_completed_at_at_local_day_boundary_lands_on_correct_weekday():
    """Tue 23:30 CST (Wed 05:30 UTC) should appear on Tue, not Wed."""
    async def run():
        # use a real Tuesday in the CURRENT week so the worker-status endpoint catches it
        now_l = now_utc().astimezone(CHI)
        monday = now_l - timedelta(days=now_l.weekday())
        tuesday_2330_local = monday.replace(hour=23, minute=30, second=0, microsecond=0) + timedelta(days=1)
        completed_utc = tuesday_2330_local.astimezone(timezone.utc).isoformat()
        uid = await _create_user(email_suffix="boundary")
        # cleanup any prior test rows
        await db.tasks.delete_many({"assignee_id": uid})
        await _seed_completion(uid, completed_utc, price=11.0, title="boundary-task")

        # Reproduce the per-day bucket math the endpoint uses
        week_start = _start_of_week(now_utc())
        rows = await db.tasks.find({
            "assignee_id": uid, "status": "completed",
            "completed_at": {"$gte": iso_utc(week_start)},
        }, {"_id": 0}).to_list(20)
        assert len(rows) == 1
        done = datetime.fromisoformat(rows[0]["completed_at"])
        dow = done.astimezone(APP_TZ).weekday()
        assert dow == 1, f"expected Tue (weekday=1), got {dow}"

        # cleanup
        await db.tasks.delete_many({"assignee_id": uid})
        await db.users.delete_one({"id": uid})

    asyncio.get_event_loop().run_until_complete(run())
