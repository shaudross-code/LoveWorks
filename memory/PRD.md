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
- **Store assets (Jun 2026)**: 18 App Store screenshots (1290x2796, sandbox demo data, `/app/appstore_screenshots/`, guide at `/app/APPSTORE_SCREENSHOTS_GUIDE.md`); Google Play feature graphic 1024x500 at `/app/playstore_assets/feature_graphic_1024x500.png` (also served at `/feature_graphic_1024x500.png`); Play screenshots (all exact 9:16): 13 phone 1080x1920 (`playstore_assets/phone/`), 8 tablet-7in 1080x1920 (`tablet_7in/`), 8 tablet-10in 1620x2880 (`tablet_10in/`) via `scripts/capture_playstore*.py`; zip served at `/playstore_assets.zip`.
- **Native push (Jul 2026, code complete — awaiting user's Firebase files)**: `@capacitor/push-notifications@8` + `src/lib/nativePush.js` (permission/register/token POST, deep-link on tap, silent token re-sync on login via AuthContext); PushPrompt banner + Profile toggle handle native; backend `firebase-admin`, `POST /api/push/register-device|unregister-device` (tested: upsert/deactivate/401), `send_native_push()` wired into `notify()` (FCM skipped gracefully until service-account file exists → `fcm_ready:false`), invalid-token pruning, `device_tokens` indexes + account-deletion cascade; iOS AppDelegate APNs→FCM mapping (guarded, app runs without plist), Podfile `FirebaseMessaging`, Info.plist remote-notification background mode + `ITSAppUsesNonExemptEncryption=false`; Android gradle auto-applies google-services.json. `cap sync` done, prod build verified (0 preview refs). **User must add**: `frontend/android/app/google-services.json`, `backend/firebase-service-account.json`, GoogleService-Info.plist via Xcode + APNs .p8 upload + Push capability — full steps in `/app/PUSH_SETUP_GUIDE.md`. FCM delivery itself untestable here (needs real device + Firebase project).
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
**Recent (Jul 2026)**:
- Legacy email migration — startup migration renames `*@clockwork.com` emails → `*@loveworks.com` (idempotent, same user id so all data carries). Verified in preview; production applies on next redeploy.
- **Edit worker** (`PATCH /api/workers/{id}`: name/email/password, dup-email 400, sandbox-scoped) + pencil-icon dialog on Admin Workers page. Tested via curl + UI.
- **Edit announcements** (`PATCH /api/announcements/{id}`, sets `edited_at`; no re-notification) + pencil-icon reusing compose dialog, "· edited" label. Tested via curl + UI.
- **STANDING RULE**: after every feature update/change, post an in-app announcement (POST /api/announcements as admin) describing what's new — user requested this workflow. Preview and production DBs are separate: post to production only AFTER user redeploys (prod admin creds same as preview).
- **Header overlap fix (Jul 2026, tested iteration_8: frontend 100%)**: AdminLayout mobile spacer was a flex-row sibling of <main> (zero width) so the fixed top bar + pills covered page H1s on mobile; spacer moved inside <main> with height calc(104px + var(--safe-top)). iOS notch safe-area added: `--safe-top: env(safe-area-inset-top)` in index.css, `viewport-fit=cover` in index.html, safe-area offsets on AdminLayout fixed bars + WorkerLayout sticky header. Web rebuilt + `cap sync` done.
- **My Sizes tab (Jul 2026, tested iteration_9: 17/17 backend, frontend ~100% after fixes)**:
  - Collection `sizes` (one doc per user, unique `user_id`): `fit` (mens|womens|unspecified|null), `units` (imperial|metric, per-user preference), `values` in CANONICAL units (lengths cm, weight kg, `shoe_us` = US size on the fit's scale; letter/chip sizes as strings), `updated_at`, `updated_by {id,name,role}`.
  - Backend (`server.py` "# --- Sizes" block after `update_worker`): `SIZE_FIELDS` spec, `_clean_size_values` (drops unknown keys, numeric range 0–1000, bool/str guards), `_diff_sizes` (0.005 tolerance, values formatted in the WORKER's units), `_save_sizes`. Routes: `GET/PUT/DELETE /api/sizes/me`; admin `GET/PUT /api/workers/{id}/sizes` (sandbox-scoped; `notify: bool = True`; admin edits never change worker units). Change-aware notification type `sizes_updated` ("<Admin> updated your sizes" / "Waist 34 in → 35 in, …" max 4 + "+N more", link `/worker/sizes?changed=k1,k2`). Nothing sent when nothing changed or notify=false. Cascade delete in `delete_worker` + `delete_my_account`; demo worker seeded with sample sizes.
  - Frontend: `lib/sizes.js` (SECTIONS spec w/ fit-specific underclothes fields, form keeps display strings + exact `canon` numbers so unit toggles never drift, US/EU/UK shoe tables: men's UK=US−1 EU=US+33, women's UK=US−2 EU=US+31), `pages/MySizes.jsx` (/worker/sizes + /admin/sizes; highlight via `?changed=` for 6s; fixed bottom Save/Clear bar on mobile), `components/sizes/{SizesForm,SizeFields,LastUpdated,WorkerSizesDialog}.jsx`, Sizes button on Admin Workers cards, nav item "My Sizes" before Profile (both layouts; active mobile pill auto-scrolls into view), bell icon for `sizes_updated`.
  - "What's new" announcement posted in PREVIEW (id a88b4f4d…) and edited to mention the additions below. Must be re-posted in production after the user redeploys.
  - **Measurement guide (same day)**: 10 generated illustrations in `/app/frontend/public/measure/*.webp` (~10 KB each: height, neck, shoulder, chest, waist, hips, sleeve, inseam, head, hand). `lib/measureGuide.js` (titles + tips), `components/sizes/MeasureGuideDialog.jsx` (image, tip, prev/next, dots), "How" button beside each body-measurement label (`guide-{key}`) + "How to measure" button in the Body section (`open-measure-guide`). Works inside the admin Worker Sizes dialog (nested dialog). Announcement "New: Measurement guide in My Sizes" posted in PREVIEW (id 951ec5dc…) — re-post in production after redeploy.
  - **Follow-up (same day)**: Height entered as feet & inches in imperial (two inputs, cm equivalent shown; metric stays a single cm field; backend formats diffs as 5'11"). New sections **Casual fits** (casual top, hoodie, jeans waist/inseam, shorts, dress size [women's], preferred fit) and **Workout fits** (top, shorts, joggers, leggings/tights, compression, preferred fit) placed between Footwear and Workwear. Field type "height" added to `SIZE_FIELDS` + `lib/sizes.js` (`ftIn`, `setHeightImperial`, `HeightField`). Self-tested via curl + Playwright (ft/in ↔ cm round-trips, diff text, section order).
  - Phase 2/3 backlog: Crew Sizes table + CSV for bulk orders; admin "please confirm your sizes" request; size-change history; gear order helper; measurement guide images; brand size charts.

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
- Test reports: `/app/test_reports/iteration_1..9.json` (iteration_4 = full regression incl. Trips/Essentials/Collaboration/PWA — all pass; iteration_6 = Capacitor CORS + Bearer-only auth — 23/23 backend + 6/6 frontend; iteration_9 = My Sizes — 17/17 backend via `backend/tests/test_sizes_iter9.py`, needs `REACT_APP_BACKEND_URL` env var exported to run).
- **Native apps need a rebuild** to pick up My Sizes: `cd frontend && yarn build && npx cap sync` (production URL baked via `.env.production`).
- **Git push request (Nov 1 2026)**: no active task; all work committed (HEAD 7d5c35b). Agent cannot push — user must tap **Save to GitHub** in the chat bar.
- **Store screenshots regenerated + popover fixes (Nov 1 2026; popover fixes tested iteration_15/16: pass)**:
  - `scripts/capture_store_screens.py` captures ALL store sets in one run (iPhone 6.9" 1290×2796, iPad 13" 2064×2752, Play phone 1080×1920, 7" 1080×1920, 10" 1620×2880; 20 screens each incl. `16_my_sizes`, `17_measure_guide`, `02b_worker_sizes_admin`; plus 2-shot `seasonal_halloween/` sets). Forces the look PER TAB via `sessionStorage.forceTheme` (read by ThemeContext) — never changes a live setting (the first version briefly set the reviewer SANDBOX theme to default, which the user noticed; fixed). iPhone 6.5" fallbacks resized. Zips: `frontend/public/appstore_screenshots.zip` (19 MB), `frontend/public/playstore_assets.zip` (11 MB). Guide: `/app/APPSTORE_SCREENSHOTS_GUIDE.md`. Long-running: start with `setsid nohup … &` (≈20 min) or the tool timeout kills it.
  - Reactions emoji picker → Radix Popover (portal, collision-aware, closes on outside tap/Esc) with horizontally scrollable row; WeeklyStrip day popover clamped inside the strip, opens on touch tap (pointer-type aware — mouseenter+click used to cancel each other), keyboard Enter/Space works, closes on outside tap; removed `overflow-hidden` from Workers cards (was clipping the popover); Goals/Trips: TabsList wraps, cards `min-w-0`, long titles break, stat row 2-col under 400px → no sideways scroll at 320px.
- **Code review (Nov 1 2026, code_review_agent → fixes tested iteration_14: 6/6 new + 53/56 regression; the 3 fails are stale assertions)**: verdict READY WITH FIXES. Fixed: `GET /files/{path}` now sandbox-scoped (owner or same-sandbox user; projection must include `id` — testing agent caught an empty-dict falsy bug); `PATCH/DELETE /tasks/{id}` scoped to admin's `_scoped_worker_ids`, reassign validates worker in `_sb`, status allow-list; `TaskCreate/TaskUpdate` price `ge=0`, title length; login lockout counter resets after the 15-min window and keys on first `X-Forwarded-For` IP; theme auto window uses `now_local()`; worker/account deletion soft-deletes `files` rows; AdminTasks form validates price. Left as-is (intentional): startup resets admin password to `ADMIN_PASSWORD` env — it is the owner's only way to set the production admin password until an in-app change-password exists. Fit change pruning opposite-fit sizes is intentional.
- **Due-day bug + Holiday themes (Nov 1 2026, tested iteration_13: all pass; 2 minor follow-ups fixed after)**:
  - Bug: `POST /tasks` rejected `due_day_of_week: -1` (what the form sends when no day is picked) → every new task failed with "due_day_of_week must be 0..6". Fix: `_validate_dow` treats -1/""/None as None. Form now shows "Due day of the week" for ALL frequencies (option "No specific day"), and the Daily-required/Frequency grid stacks on mobile (no label overlap). WorkerDashboard: day-of-week-only tasks count as due on the next occurrence of that weekday (today counts) → appear in Due today / Due this week + weekly potential; tasks due beyond this week now show in "Open · later" (previously fell out of every bucket).
  - Holiday themes: backend `HOLIDAY_THEMES` (newyear, valentines, stpatricks, easter [computed], july4, halloween, thanksgiving [4th Thu], christmas), auto window = ±7 days around the holiday (nearest wins), `GET /api/theme` (public, sandbox-aware via optional auth), `PUT /api/theme {mode}` admin (`auto` | `default` | key) stored in `settings` {key:'theme', sandbox}. Frontend: `context/ThemeContext.jsx` sets `<html data-theme>`; `index.css` defines RGB-triplet vars per theme and `tailwind.config.js` maps yellow/pink/rose 300–500 to `rgb(var(--c-*)/<alpha-value>)` so the whole app recolours with zero markup changes; `components/HolidayDecor.jsx` (HolidayBadge in both headers, 9 drifting emoji floaters, reduced-motion aware); `components/ThemeSettings.jsx` on admin Profile (Auto / Default / 8 holidays + schedule). Announcement "Happy Halloween 🎃 — holiday themes are here" posted in PREVIEW (id 74fa7598…); re-post in production after redeploy. Native bundles resynced.
  - Known cosmetic: `due_day_of_week:"x"` returns 422 (pydantic) instead of 400 — UI never sends strings.
- **"CHECK AGAIN" round 3 (tested iteration_12: 58/58 static + all browser checks)**: no new user commits since round 2. Re-verified the SPM project graph and added native look parity: iOS Info.plist `UIStatusBarStyle=LightContent`, `UIUserInterfaceStyle=Dark`, `UIViewControllerBasedStatusBarAppearance=false` (otherwise the clock is black on our black header); Android `res/values/colors.xml` (app-level override of Capacitor's indigo colorPrimary/Dark → #09090B, accent #FACC15) + `styles.xml` statusBarColor/navigationBarColor/windowLightStatusBar=false; Privacy page safe-top padding; bundles resynced (main.3983a432.js). Guide button now opens at step 1 (Height).
- **Xcode mismatch, round 2 (Oct 31 2026, tested iteration_11: 87/88 static — the 1 fail is a false positive on a code comment — + browser regression pass)**: REAL root cause — the repo root contains a separate hand-written SwiftUI project (`/app/iLoveWorks.xcodeproj` + `/app/iLoveWorks/*.swift`, bundle id TUE.iLoveWorks, pushed from the user's Mac via origin/main) that the user has been building; it has its own UI. The Capacitor project needed CocoaPods + Firebase (`pod install`, Pods ignored) so it likely failed to build for them. Fix: converted `frontend/ios` to **Swift Package Manager** (`npx cap add ios --packagemanager SPM`), vendored the push plugin at `frontend/ios/App/Plugins/CapacitorPushNotifications` (Package.swift re-pointed; no node_modules needed on the Mac), AppDelegate rewritten without Firebase (APNs hooks kept), restored Assets/LaunchScreen/Info.plist keys (UIBackgroundModes, ITSAppUsesNonExemptEncryption=false, display name), bundle id com.loveworks.app, version 1.0.1 build 3, pinned `@capacitor/push-notifications` to ^7. New `scripts/native_sync.sh` = yarn build + cap sync + Package.swift re-point — USE THIS after any frontend change. Docs: `/app/NATIVE_BUILD_GUIDE.md`, `/app/README.md` (both explain the two Xcode projects). The root SwiftUI project is the user's own work — leave untouched. Firebase re-add path documented (SPM firebase-ios-sdk) for when FCM is configured.
- **Xcode mismatch, round 1 (Oct 31 2026, tested iteration_10: 21/21 static + browser)**: root cause — `ios/App/App/public` + `capacitor.config.json` (and the Android equivalents) were gitignored, so Xcode on the user's Mac built with a stale/absent web bundle. Fix: un-ignored them in `frontend/ios/.gitignore` + `frontend/android/.gitignore` (bundles are now committed on Save to GitHub), set `ios.contentInset` to `"never"` (CSS already handles safe areas; "always" doubled the top gap), rebuilt + `cap sync` for both platforms. Also fixed: Workers card horizontal overflow at 390px (`grid-cols-1`, `min-w-0`, wrapping action row) and added `ScrollToTop` on route change in `App.js`. Guide: `/app/NATIVE_BUILD_GUIDE.md`. ALWAYS run `yarn build && npx cap sync` after frontend changes so the committed bundle stays current (do NOT use `CI=true` — pre-existing eslint warnings fail the build).
- **Capacitor iOS/Android build MUST rely on Bearer token, not cookies.** Do not re-enable `withCredentials: true` in `/app/frontend/src/lib/api.js` without also fixing the platform ingress `*` rewrite. Same-origin browser cookies still work unchanged.
- **Production URL is baked into mobile builds via `frontend/.env.production`** — never delete this file. If prod URL changes, edit it and re-run `yarn build && npx cap sync`.
- **craco.config.js env-order bug (fixed 2026-07-26)**: `require("dotenv").config()` at the top of craco.config.js loaded `.env` (preview URL) before CRA's `.env.production` handling, so production builds silently baked the PREVIEW url. Fix: craco.config.js now loads `.env.production` first when `NODE_ENV=production`. Sanity check after any build: `grep -c "preview.emergentagent" build/static/js/main.*.js` must be 0 (note: grepping for "labor-admin-hub" is a false positive — the preview domain contains it too).
- **Store builds require a fresh production deploy first**: reviewer account seed + capacitor:// CORS origins only exist after redeploying the backend. Verified 2026-07-26 that production still lacked both (reviewer login 401, capacitor origin preflight 400) until user redeploys.
