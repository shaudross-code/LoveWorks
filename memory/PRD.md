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
- **(Jun 2026) Timezone audit & fix (CRITICAL)** — all window math (weekly strip, goal periods, streaks, reminders) now runs in `APP_TZ` (env `WEEK_TZ`, default America/Chicago) instead of UTC. Tests at `/app/backend/tests/test_timezone.py`.
- **(Jun 2026) Full rebrand → LoveWorks**
  - Pink-rose heart emblem replaces "C/L" letters in login + admin + worker layouts
  - Login motto: "Show your Love. Get Loved with Gifts." (pink glow)
  - "Welcome back" / "Sign in to start showing Love." in pink
  - Romantic gift icons floating across login (heart, gift, plane, flower, wine, gem, money, key, bag, shirt) with `loveFloat` keyframe
  - Sidebar active-state and mobile nav pills switched from gold to pink
- **(Jun 2026) Concurrent activity clocks** — workers can run multiple activities at once (Working + Parenting + Studying, etc.). Backend blocks only duplicate same-activity clocks. New "**Self Care**" activity added. `/time/clock-out` accepts `?activity=` / `?entry_id=` or defaults to close-all.
- **(Jun 2026) Goals — full edit + delete + photo + celebrate**
  - Full edit (title, photo, deadline, product link, target, period, allocation %, teammates)
  - Delete with confirmation
  - Goal image upload/replace/remove endpoints
  - Progress bar auto-locks to 100% + period_amount = target when `status=completed`
- **(Jun 2026) Trips tab** — clone of Goals filtered by `kind="trip"`; admin-assign + worker-add; same edit surface
- **(Jun 2026) Essentials tab** — new collection with name, price, quantity, category (household/everyday/groceries/personal/kids/other), photo, note, purchased ✓, recurring / one-time toggle, due_date, completed_at. Totals: grand / pending / stocked. Admin & worker both have `/admin/essentials` and `/worker/essentials`.
- **(Jun 2026) Admin totals strips** on Goals & Trips & Essentials + **View-by-worker** filter
- **(Jun 2026) Collaborators** on goals/trips/essentials — `collaborator_ids` field, add/remove via `/{collection}/{id}/collaborators`; new `/api/peers` endpoint for workers; pink 🤝 chip on shared cards; `TeammatesField` component in every edit dialog
- **(Jun 2026) Admin sees streaks + inconsistencies** — chips on each worker card: 🔥 N-day streak, ⚠️ streak broken, 💤 N missed days, 📉 N light days, ✨ clean week
- **(Jun 2026) Peer-overview permission flow** — worker A requests to see worker B's overview → B gets a bell notification with **Accept / Decline** inline; admin can force-grant via `/api/admin/peer-access/force`
- **(Jun 2026) One-time option** on tasks (already), goals/trips (new `period="once"`), essentials (`recurring: bool` + `due_date` + auto `completed_at`)
- **(Jun 2026) Mobile responsive polish** — h3xl→lg:5xl H1 scaling, 144px clock-in circle on mobile, hero p-5 on mobile / p-10 desktop, container padding tightened, two-row mobile top nav (LoveWorks header + sticky scrollable pill row) on both admin and worker layouts
- **(Jun 2026) Notification panel positioning** — new `align="left|right"` prop (default right), sidebar bell uses `left`. Panel width `min(360px, calc(100vw-2rem))`. Sidebar `z-50`, panel `z-[60]` to sit above main content headings.
- **(Jun 2026) App Store / Play Store readiness**
  - **PWA complete**: `public/manifest.json` (standalone, portrait, maskable icons), offline-capable service worker (`sw.js` — precache + network-first navigation + SWR statics, skips `/api` and non-GET), SW registered at startup in `index.js`, apple-touch-icon + iOS meta tags in `index.html`. Installable from Safari/Chrome today.
  - **Custom branding icon**: generated pink heart with gold outline + raining gold hearts/money/gifts (`frontend/assets/icon-only.png` 1024 source; public icons 192/512/maskable/180/badge/favicon derived).
  - **Capacitor 7** (Node 20-compatible; v8 needs Node 22): `capacitor.config.json` (appId `com.loveworks.app`), native projects at `frontend/ios/` + `frontend/android/`, all native icons/splashes generated via `@capacitor/assets`, `cap sync` done.
  - **`/app/STORE_SUBMISSION_GUIDE.md`** — full step-by-step for Apple App Store (Xcode/archive/App Store Connect) and Google Play (signed .aab/Play Console), plus privacy-policy and demo-credentials requirements.
  - ⚠️ Before store builds: point `frontend/.env` REACT_APP_BACKEND_URL to production, `yarn build && npx cap sync`.
  - Regression-tested: iteration_4.json — 18/18 backend, frontend smoke 100%, SW does not interfere with API calls.

## Prioritized backlog (next phases)
**P0**
- (store prereq) "Delete my account" button in Profile — Apple requires account deletion for App Store approval
- (store prereq) Public `/privacy` privacy-policy page — required by both stores

**P1**
- Refactor `server.py` into `/app/backend/routes` + `/app/backend/models` (2,700+ lines, technical debt)
- Admin uploads avatar for worker during account creation
- Idle alert: admin toast when a worker is clocked in but inactive >10 min
- "Crew" page for workers to browse peers and send/manage `peer_access` requests

**P2**
- Change-password section on Profile page
- Worker avatars next to their tasks in admin Tasks page
- Auto-generate today's instance of recurring tasks at midnight
- WeeklyStrip day tile click → scroll Tasks page to that day's completed tasks
- Hourly-rate option, multi-admin support, dashboard charts, bulk task assignment

**P3**
- Weekly leaderboard on Admin Overview (gold-medal #1 by earnings + streak)
- CSV export of payroll
- Trips & Essentials top-line numbers on Admin Overview
- Photo proof of completion, Stripe payout integration, worker invitation email (Resend)

## Test credentials
- Admin: `admin@clockwork.com` / `admin123` (seeded automatically)
- Worker: `lovetest@loveworks.com` / `Love123!`

## Critical notes for future agents
- User deploys to production from preview — never link preview/production URLs; remind user to redeploy to see changes live.
- Trips share the `goals` collection with `kind="trip"`. Essentials are their own collection.
- Workers can run multiple concurrent time entries (Working + Parenting + Self Care…); only duplicate same-activity clocks are blocked.
- Test reports: `/app/test_reports/iteration_1..3.json` (last full testing_agent run was BEFORE Trips/Essentials/Collaboration/Rebrand).
