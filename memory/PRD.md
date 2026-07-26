# LoveWorks (formerly ClockWork) — PRD

> **For precise app recreation, see `/app/memory/APP_SPEC.md`** — the complete blueprint: every endpoint with params, all data models, business-logic formulas (progress/streaks/potential earnings/reminders), page-by-page UI spec with exact copy, theme tokens, PWA/Capacitor setup, and known quirks.

## Problem statement (original)
> I need an app that allows users to clock in and clock out, also assign different tasks for them to do during their workday and an editable price for each task — but I must be the overseer of the users that login and be able to assign them tasks from an admin point of view.

Evolved into **LoveWorks**: a pink & gold love-themed household/labor management app — concurrent activity clocks, priced tasks, Goals/Trips/Essentials with photos, peer collaboration, gamification (awards/streaks), and web push notifications. Motto: *"Show your Love. Get Loved with Gifts."*

## Architecture (summary — details in APP_SPEC.md)
- **Backend**: FastAPI + Motor (MongoDB) at 0.0.0.0:8001, all routes under `/api` (`server.py` ~2,722 lines — refactor pending)
- **Frontend**: React 19 + React Router 7 + Tailwind + shadcn/ui on :3000; Service Worker `public/sw.js` (push + offline caching)
- **Auth**: JWT HS256, httpOnly cookies + Bearer fallback + `?auth=` for `<img>`; brute-force lockout 5/15min; admin seeded & password re-synced from env on startup
- **DB collections**: users, tasks, time_entries, goals (goals+trips via `kind`), essentials, notifications, awards, announcements, peer_access, push_subscriptions, files, login_attempts
- **Integrations**: Emergent Object Storage (all images), Web Push VAPID (pywebpush), Web Speech API (TTS, browser-native)
- **Timezone**: all day/week/month windows in `APP_TZ` (env `WEEK_TZ`, e.g. America/Chicago), never raw UTC
- **Theme**: dark `#09090B` + gold CTAs + pink brand accents; Outfit (display) + Manrope (body)

## User personas
- **Admin (Overseer)** — seeded from `.env`. Manages workers, tasks, payroll; assigns goals/trips/essentials; celebrates completions with appreciation notes; live-monitors the crew.
- **Worker** — created by admin. Runs concurrent activity clocks, completes priced tasks, saves toward goals/trips, tracks essentials, earns awards/streaks, collaborates with peers.

## Core requirements (static)
1. Admin creates/deletes workers (email + password + name).
2. Admin creates tasks with editable price, assignee, deadlines (date / time-of-day / day-of-week), estimated & daily hours, frequency (once/daily/weekly/monthly), payout schedule.
3. Workers clock in/out — **multiple concurrent activities** (Working, Studying, Break, Cleaning, Workout, Parenting, Self Care); only duplicate same-activity clocks blocked.
4. Workers mark tasks in_progress/completed; completion = earnings.
5. Payroll dashboard: per-worker completed-task earnings + hours; potential weekly/monthly projections.
6. Goals & Trips (shared collection, `kind`): target amount, period, allocation % of task earnings, photo, deadline, product link, collaborators, admin celebrate/reopen, reactions, congrats popup.
7. Essentials: household list with price×quantity, category, photo, recurring/one-time, due date, purchased toggle, totals.
8. Peer-overview permission flow (request → Accept/Decline in bell → view peer's weekly strip; admin force-grant).
9. Notifications: in-app bell + Web Push for task assigned/updated/due-soon/completed, goal assigned/completed/reactions, collabs, announcements, awards, peer requests. 30-min due reminders via background loop.
10. Role-based routing, mobile-responsive two-row nav, installable PWA.

## What's implemented
**Feb 2026 (ClockWork base)**: JWT auth + lockout; admin overview/workers/tasks/payroll; worker clock hero + task list + history; goals, awards, announcements, notification bell, weekly strips + streaks; live worker monitor (online dots, per-day hours); TTS SpeakButton; avatars via object storage.

**Jun 2026**:
- Admin Overview "Potential Earnings" (weekly/monthly per-worker projections)
- Notification gap closure: task edited/reassigned/completed pings, admin goal-assign path, `task_due_soon` reminder loop (60s tick, 30-min lead, TZ-aware, race-safe dedup), Web Push (SW + VAPID, PushPrompt banner + Profile toggle, `/push/*` endpoints)
- Timezone audit: all window math in APP_TZ (`backend/tests/test_timezone.py`)
- **Full rebrand → LoveWorks**: pink heart emblem, romantic login backdrop (10 floating gift icons), pink motto/headlines, pink active-nav pills
- **Concurrent activity clocks** + new Self Care activity; clock-out by entry/activity/all
- Goals full edit/delete/photo/celebrate; completed goals lock progress display at 100%/target
- **Trips tab** (admin + worker, goals kind=trip, view-by-worker filter)
- **Essentials tab** (own collection: category/qty/photo/note/purchased/recurring/due_date; totals strips; shared admin+worker component)
- **Collaborators** (`collaborator_ids` + TeammatesField + `/peers`; 🤝 chips)
- Admin sees worker streak/inconsistency chips (🔥/⚠️/💤/📉/✨)
- **Peer-overview permission flow** (request/respond/granted/revoke/admin-force + `/peer-overview/{id}`)
- One-time option across tasks/goals/trips (`period="once"`) & essentials (`recurring` bool)
- Mobile polish (two-row fixed nav, 144px mobile clock CTA, H1 scaling) + notification panel align/z-index fixes
- **App Store / Play Store readiness**: full PWA (manifest, offline SW caching, iOS meta, generated pink-heart icon set), Capacitor 7 native projects (`frontend/ios`, `frontend/android`, appId `com.loveworks.app`), `/app/STORE_SUBMISSION_GUIDE.md`. ⚠️ Before store builds: set production `REACT_APP_BACKEND_URL`, `yarn build && npx cap sync`. Regression-tested (iteration_4: 18/18 backend, frontend smoke 100%).
- **APP_SPEC.md** written (full recreation blueprint).
- **Store prerequisites + alerts + iLoveWorks rebrand (Jun 2026, tested iteration_5: 11/11 backend, frontend 100%)**:
  - Public `/privacy` page (no auth, 9 sections, linked from login + Profile) — store privacy-URL requirement done
  - `DELETE /api/me` account deletion (password-confirmed, 403 for admin, full cascade incl. collaborator pulls + file soft-delete) + Profile "Danger zone" dialog — Apple requirement done
  - Idle alert: reminder_loop notifies admins (`worker_idle`) + nudges the worker (`clock_out_reminder`) when clocked in but inactive ≥10 min (dedup per last_seen marker); `/admin/worker-status` returns `is_idle`/`idle_minutes`; 💤 idle chip on admin worker cards
  - Clock-out alert: admins get `worker_clock_out` notification with per-activity durations on every worker clock-out
  - Rebrand → **iLoveWorks** with gold gradient wordmark (`.brand-gold` CSS class) across login/layouts/privacy; index.html/manifest/sw.js/capacitor.config/native strings.xml + Info.plist updated; new app icon generated (gold "iLoveWorks" lettering + pink heart + raining gold hearts/money/gifts); all PWA + native icons/splashes regenerated, web rebuilt, `cap sync` done; SW cache bumped to `iloveworks-v2`

- **Capacitor mobile ↔ backend fix (Jul 2026, tested iteration_6: 23/23 backend, 6/6 frontend flows — 100%)**:
  - User bug: "Xcode can't get api keys" → iOS build opens but can't reach server. Three root causes fixed:
    1. **Backend CORS** (`server.py` ~line 2751): `allow_origin_regex` extended to include `capacitor://localhost` (iOS webview) and `ionic://localhost`, anchored `^...$`.
    2. **Axios `withCredentials: true` → `false`** in `/app/frontend/src/lib/api.js`. Emergent ingress rewrites `Access-Control-Allow-Origin` to `*` on all responses; combined with `Access-Control-Allow-Credentials: true` this is a CORS spec violation that browsers reject. Removing credentials mode makes wildcard origin acceptable. Bearer token from `localStorage.access_token` (already in interceptor) is the sole auth mechanism for cross-origin (mobile) calls; same-origin browser calls still send cookies by default.
    3. **`.env.production`** created at `/app/frontend/.env.production` with `REACT_APP_BACKEND_URL=https://labor-admin-hub.emergent.host` so `yarn build` bakes the production URL into the iOS/Android bundle. `.env` still holds preview URL for dev.
  - Updated `/app/STORE_SUBMISSION_GUIDE.md` §0 with exact build sequence (`yarn build && npx cap sync`) and post-build sanity check (`grep -r "labor-admin-hub" frontend/build/static/js`).
  - Known ingress quirk: platform Cloudflare/ingress overwrites specific `Access-Control-Allow-Origin` header from FastAPI with `*`. Safe only while frontend keeps `withCredentials=false`.

- **Reviewer sandbox isolation (Jul 2026, tested iteration_7: 28/28 backend — 100%)**:
  - User request: reviewer account must not contain/see the real household's data (it's for Apple review only).
  - `sandbox: true` flag on reviewer admin + new seeded demo worker (`demo@loveworks.com` / `DemoWorker2026!`, env `REVIEWER_WORKER_EMAIL/PASSWORD`) with sample data (3 tasks, 1 goal, 1 trip, 1 essential, 1 time entry).
  - `_sb(user)` + `_scoped_worker_ids(user)` helpers scope EVERY admin-facing endpoint (workers, peers, tasks, time entries, payroll, worker-status, goals, essentials + totals, announcements create/list/delete + fan-out, awards, peer-access, idle/clock-out/task-completed admin notifications). Sandbox admins created workers inherit the flag. Bidirectional: reviewer never sees real data; owner never sees reviewer's test data.
  - Regression test: `/app/backend/tests/test_sandbox_isolation.py`.

## Prioritized backlog
**P1**
- Refactor `server.py` into `/app/backend/routes` + `/app/backend/models` (~2,830 lines)
- Admin uploads avatar for worker during account creation
- "Crew" page for workers to browse peers and send/manage peer_access requests

**P2**
- Change-password section on Profile
- Worker avatars next to tasks in admin Tasks page
- Auto-generate today's instance of recurring tasks at midnight
- WeeklyStrip day-tile click → scroll Tasks to that day's completions
- Hourly-rate option, multi-admin, dashboard charts, bulk task assignment

**P3**
- Weekly leaderboard on Admin Overview; CSV payroll export; Trips/Essentials top-line numbers on Overview; photo proof of completion; Stripe payouts; worker invitation email (Resend)

## Test credentials
- Admin (owner): `admin@loveworks.com` / `admin123` (seeded from `ADMIN_EMAIL` in `backend/.env`; renamed from `admin@clockwork.com` on 2026-07-26)
- Reviewer admin (App Store / Play Store demo — SANDBOXED, sees only its own demo data): `reviewer@loveworks.com` / `iLoveWorks2026!` (seeded from `REVIEWER_EMAIL` in `backend/.env`, added 2026-07-26; sandbox isolation added later that day)
- Sandbox demo worker (reviewer's worker login): `demo@loveworks.com` / `DemoWorker2026!` (seeded from `REVIEWER_WORKER_EMAIL`)
- Worker: `lovetest@loveworks.com` / `Love123!`

## Critical notes for future agents
- User deploys to production separately — never link preview/production URLs; remind them to redeploy to see changes live.
- Trips share the `goals` collection (`kind="trip"`); legacy rows may lack `kind`. Essentials are their own collection.
- POST /goals and POST /essentials use **query params + multipart file**, not JSON bodies.
- Workers can hold multiple concurrent time entries; `/time/active` returns a list.
- Capacitor projects in `frontend/ios|android`: regenerate assets via `npx @capacitor/assets generate`, re-sync via `npx cap sync`; never hand-edit.
- Test reports: `/app/test_reports/iteration_1..6.json` (iteration_4 = full regression incl. Trips/Essentials/Collaboration/PWA — all pass; iteration_6 = Capacitor CORS + Bearer-only auth — 23/23 backend + 6/6 frontend).
- **Capacitor iOS/Android build MUST rely on Bearer token, not cookies.** Do not re-enable `withCredentials: true` in `/app/frontend/src/lib/api.js` without also fixing the platform ingress `*` rewrite. Same-origin browser cookies still work unchanged.
- **Production URL is baked into mobile builds via `frontend/.env.production`** — never delete this file. If prod URL changes, edit it and re-run `yarn build && npx cap sync`.
- **craco.config.js env-order bug (fixed 2026-07-26)**: `require("dotenv").config()` at the top of craco.config.js loaded `.env` (preview URL) before CRA's `.env.production` handling, so production builds silently baked the PREVIEW url. Fix: craco.config.js now loads `.env.production` first when `NODE_ENV=production`. Sanity check after any build: `grep -c "preview.emergentagent" build/static/js/main.*.js` must be 0 (note: grepping for "labor-admin-hub" is a false positive — the preview domain contains it too).
- **Store builds require a fresh production deploy first**: reviewer account seed + capacitor:// CORS origins only exist after redeploying the backend. Verified 2026-07-26 that production still lacked both (reviewer login 401, capacitor origin preflight 400) until user redeploys.
