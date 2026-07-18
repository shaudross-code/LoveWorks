# ClockWork — PRD

## Problem statement (original)
> I need an app that allows users to clock in and clock out, also assign different tasks for them to do during their workday and an editable price for each task — but I must be the overseer of the users that login and be able to assign them tasks from an admin point of view.

## Architecture
- **Backend**: FastAPI + Motor (MongoDB) at 0.0.0.0:8001, all routes under `/api`
- **Frontend**: React 19 + React Router 7 + Tailwind + shadcn/ui, served on :3000
- **Auth**: JWT (HS256), httpOnly cookies (`access_token`, `refresh_token`) + Bearer header fallback
- **DB collections**: `users` (admin + workers), `tasks`, `time_entries`, `login_attempts`, `password_reset_tokens`
- **Theme**: Black & gold playfully-professional (Outfit + Manrope)

## User personas
- **Admin (Overseer)** — seeded from `.env`. Single account by default. Manages workers, tasks, payroll.
- **Worker** — created by admin. Clocks in/out, completes tasks, sees own history & earnings.

## Core requirements (static)
1. Admin can create/delete workers (email + password + name).
2. Admin can create tasks with editable price + assignee; can edit/delete.
3. Workers can clock in / clock out (single active entry rule).
4. Workers can mark assigned tasks `in_progress` or `completed`.
5. Admin payroll dashboard sums completed-task prices per worker + total hours.
6. Role-based routes (Admin vs Worker).

## What's implemented (Feb 2026)
- JWT login/me/logout/refresh with bcrypt + brute-force lockout (5/15min)
- Admin: dashboard overview, workers CRUD, tasks CRUD with inline price edit, payroll page
- Worker: hero clock-in/out (live timer, gold-pulse CTA), task list with start/complete toggle, history page
- Sonner toasts, Radix dialogs, role-guarded routes, mobile responsive
- Goals, awards, announcements, notifications bell, weekly strip with streak flames
- Live worker monitor with online dots, idle detection groundwork, per-worker daily/weekly hours
- Text-to-speech for task descriptions (Web Speech API, browser native)
- Profile avatars via Emergent Object Storage
- **(Jun 2026) Admin Overview "Potential Earnings" card** — totals + per-worker weekly & monthly projections from `/api/admin/worker-status` (`potential_weekly`, `potential_monthly`)
- **(Jun 2026) Worker notifications closed all gaps** — bell + Web Push (Service Worker + VAPID):
  - Task created/assigned → worker ping (existing)
  - Task edited (price, due_time, due_at, due_day_of_week, title) → worker ping ("task_updated")
  - Task reassigned → both new + previous assignees pinged
  - Goal assigned by admin (NEW: `POST /api/goals?assignee_id=…` admin path) → worker ping ("goal_assigned")
  - Task completed → admin gets a "task_completed" ping with worker name + earnings
  - Background reminder loop (60s tick) fires `task_due_soon` 30 min before due_time (TZ-aware)
  - `PushPrompt` banner on worker dashboard + Profile toggle; `/api/push/{public-key,subscribe,unsubscribe,test}` endpoints
- **(Jun 2026) Timezone audit & fix (CRITICAL)** — all window math (weekly strip, goal periods, streaks, reminders) now runs in `APP_TZ` (env `WEEK_TZ`, default America/Chicago) instead of UTC:
  - `_start_of_{day,week,month,year}` return tz-aware datetimes in APP_TZ
  - `iso_utc()` serializes to UTC for Mongo string-range queries
  - Per-weekday assignment uses `done.astimezone(APP_TZ).weekday()`
  - Streak award + reminder loop use local "today"
  - Tests at `/app/backend/tests/test_timezone.py` (6 unit + integrated seed test passing)
  - 21/21 testing-agent backend cases pass on iteration_3

## Prioritized backlog (next phases)
**P1**
- CSV export of payroll
- Worker invitation email (resend integration)
- Task due dates + reminders

**P2**
- Hourly-rate option in addition to fixed-price tasks
- Multi-admin support / role permissions
- Charts on dashboard (recharts already available)
- Bulk task assignment

**P3**
- Photo proof of completion (object storage)
- Notifications & shift reminders
- Stripe payout integration

## Test credentials
- Admin: `admin@clockwork.com` / `admin123` (seeded automatically)
