# LoveWorks — Complete App Specification (Recreation Blueprint)
> Purpose: this document contains enough detail to rebuild the entire app from scratch.
> Companion docs: `PRD.md` (product summary/backlog), `test_credentials.md`, `/app/STORE_SUBMISSION_GUIDE.md`.
> Last synced with code: June 2026 (server.py 2,722 lines; frontend 13 pages / 12 components).

---

## 1. Product concept

**LoveWorks** ("formerly ClockWork") is a pink-and-gold, love-themed household/labor management app.
An **Admin** (overseer, typically a partner/parent) creates **Worker** accounts, assigns priced tasks,
and celebrates their achievements. Workers clock in/out of multiple concurrent life activities,
complete tasks for money, save toward **Goals** and **Trips**, track household **Essentials**,
earn **Awards**, keep **streaks**, and collaborate as **teammates**.

Motto: *"Show your Love. Get Loved with Gifts."*

---

## 2. Tech stack & infrastructure

| Layer | Tech |
|---|---|
| Backend | FastAPI (Python), Motor (async MongoDB), bcrypt, PyJWT, pywebpush |
| Frontend | React 19 (CRA/react-scripts 5), React Router 7, Tailwind, shadcn/ui (Radix), lucide-react, sonner, axios, framer-motion |
| DB | MongoDB (env `MONGO_URL`, `DB_NAME`) |
| Storage | Emergent Object Storage (`https://integrations.emergentagent.com/objstore/api/v1/storage`, init with `EMERGENT_LLM_KEY` → storage_key; retry-once on 403) |
| Push | Web Push (VAPID) via Service Worker `public/sw.js` |
| Mobile | PWA (manifest + SW caching) + Capacitor 7 projects in `frontend/ios/` & `frontend/android/` (appId `com.loveworks.app`) |

**Service layout**: backend on 0.0.0.0:8001 (all routes prefixed `/api`), frontend on :3000, supervisor-managed. Frontend calls `process.env.REACT_APP_BACKEND_URL`.

**Backend .env keys**: `MONGO_URL`, `DB_NAME`, `CORS_ORIGINS`, `JWT_SECRET`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `FRONTEND_URL`, `EMERGENT_LLM_KEY`, `APP_NAME` (=clockwork, used as storage path prefix), `WEEK_TZ` (business timezone, e.g. America/Chicago), `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY` (\n-escaped PEM), `VAPID_SUBJECT`.

**CORS**: if `CORS_ORIGINS` is `*` or empty → `allow_origin_regex = https?://(localhost(:\d+)?|.*\.emergentagent\.com|.*\.emergent\.host)` with credentials; else comma-split explicit origins.

---

## 3. Authentication

- JWT HS256. Access token 24h (`type: "access"`, claims sub/email/role), refresh 7d (`type: "refresh"`).
- Tokens delivered BOTH as httpOnly cookies (`access_token`, `refresh_token`; secure, SameSite=None) AND `access_token` in the login JSON body, which the frontend stores in `localStorage` and sends as `Authorization: Bearer` (interceptor in `lib/api.js`).
- Token lookup order in `get_current_user`: cookie → Bearer header → `?auth=<token>` query param (the query fallback exists so `<img>` tags can load protected files).
- Brute force: 5 failed logins per `ip:email` identifier → 429 lockout for 15 min (`login_attempts` collection). Cleared on success.
- Presence: every authenticated request touches `users.last_seen_at` (throttled to once/30s).
- Admin seeding on startup: create `ADMIN_EMAIL`/`ADMIN_PASSWORD` user (name "Administrator") if missing; if it exists but the password doesn't match env, the hash is RESET to env password (idempotent).
- Roles: `admin`, `worker`. `require_admin` dependency guards admin routes.

---

## 4. MongoDB collections & document shapes

All ids are `uuid4` strings in field `id` (Mongo `_id` always excluded from reads via projection `{"_id": 0}`). All timestamps are UTC ISO strings.

### users
`{id, email(lowercase, unique), password_hash(bcrypt), name, role: "admin"|"worker", created_at, last_seen_at?, avatar_path?}`
Serialized to API as: `{id,email,name,role,created_at,last_seen_at,avatar_path,avatar_url: "/api/files/{path}"|null}`.

### tasks
`{id, title, description, price: float, assignee_id, status: "assigned"|"in_progress"|"completed", created_by, created_at, completed_at?, due_at?(ISO), due_time?("HH:MM" 24h), due_day_of_week?(0=Mon..6=Sun), estimated_hours?, daily_hours?(stored in hours; UI has hours/minutes toggle), frequency: "once"|"daily"|"weekly"|"monthly", payout_schedule: "per_task"|"daily"|"weekly"|"monthly", last_reminder_date?("YYYY-MM-DD" local), last_reminder_at?}`

### time_entries
`{id, user_id, clock_in(ISO), clock_out(ISO|null), duration_seconds, activity}`
Activities enum: `working, studying, break, cleaning, workout, parenting, self_care`.

### goals (shared by Goals AND Trips via `kind`)
`{id, owner_id, kind: "goal"|"trip" (legacy rows without kind = goal), title, product_link?, image_path?, deadline?(ISO), target_amount?, period: "once"|"daily"|"weekly"|"monthly"|"yearly" (default weekly), allocation_percent: 0..100 (default 100), status: "open"|"completed", appreciation?, completed_at?, completed_by?, acknowledged_at?, assigned_by?(admin id if admin-assigned), reactions: [{emoji, by_id, by_name, at}], collaborator_ids: [uid], created_at}`

### essentials
`{id, owner_id, title, price, quantity(≥1), category: "household"|"everyday"|"groceries"|"personal"|"kids"|"other", note?, image_path?, purchased: bool, recurring: bool, due_date?(ISO), completed_at?(set when purchased=true, cleared when false), collaborator_ids: [uid], created_by, created_at}`

### notifications
`{id, user_id, type, title, body, link?, meta{}, read: bool, created_at}`

### awards
`{id, user_id, code, title, description, icon, earned_at}` — unique index (user_id, code).

### announcements
`{id, title(≤140), body(≤4000), tag: "update"|"feature"|"maintenance"|"announcement", created_by, created_at}`

### peer_access
`{id, requester_id, target_id, status: "pending"|"granted"|"denied", note?, created_at, decided_at?, forced_by?(admin id)}` — unique index (requester_id, target_id).

### push_subscriptions
`{endpoint(unique), user_id, subscription(PushSubscription.toJSON()), is_active, created_at, updated_at}`

### files
`{id, user_id, storage_path, content_type, size, is_deleted, created_at}` — soft-delete registry for object storage; `/api/files/{path}` only serves rows with `is_deleted: false`.

### login_attempts
`{identifier: "ip:email", count, last_attempt}`

### Startup indexes
users.email(u), users.id(u), tasks.assignee_id, time_entries(user_id,clock_out), login_attempts.identifier, files.storage_path, goals.owner_id, notifications(user_id,read,created_at desc), awards(user_id,code)(u), announcements.created_at, push_subscriptions.endpoint(u) + (user_id,is_active), essentials.owner_id, peer_access(requester_id,target_id)(u) + (target_id,status).

---

## 5. Timezone rules (CRITICAL)

- `APP_TZ = ZoneInfo(env WEEK_TZ)`, fallback UTC. ALL day/week/month/year boundaries computed in APP_TZ:
  - `_start_of_day` = local midnight; `_start_of_week` = local Monday 00:00; `_start_of_month/year` similarly.
- Mongo range queries against ISO-string fields use `iso_utc(boundary)` (boundary converted back to UTC ISO).
- Weekly strips split each time entry across local day boundaries so hours land on the right weekday.
- Reminder loop interprets `due_time` HH:MM as LOCAL wall clock.

---

## 6. API endpoints (all under /api)

### Auth & profile
| Method Path | Auth | Notes |
|---|---|---|
| POST /auth/login | — | body {email,password}; 401 invalid; 429 lockout; sets cookies; returns {user, access_token, token_type} |
| POST /auth/logout | user | clears cookies |
| GET /auth/me | user | serialized user |
| POST /auth/refresh | refresh cookie | re-issues access cookie + returns {access_token} |
| PATCH /me/profile | user | body {name 1..80} |
| POST /me/avatar | user | multipart file; JPEG/PNG/WEBP/GIF ≤3MB; stores at `{APP_NAME}/avatars/{uid}/{uuid}.{ext}`; soft-deletes previous |
| DELETE /me/avatar | user | |
| GET /files/{path} | user (or ?auth=) | streams object storage content |

### Workers & peers
| POST /workers | admin | {email,password≥6,name} → 400 if email in use |
| GET /workers | admin | list serialized workers |
| DELETE /workers/{id} | admin | cascades: deletes their tasks + time_entries |
| GET /peers | user | all workers minus self: {id,name,email,avatar_url} |

### Tasks
| POST /tasks | admin | TaskCreate (see model). Notifies assignee "New task: {title}" with price + when-string (due date "%b %d" / DOW / "by HH:MM" / "no deadline") |
| GET /tasks | user | worker→own; admin→all (+optional ?assignee_id=) with assignee_name/email attached |
| PATCH /tasks/{id} | user | Worker: only own task, only status (assigned/in_progress/completed; completed sets completed_at). Admin: any field; `due_day_of_week: -1` clears. Notifications: reassignment pings new assignee ("Task assigned to you") + old assignee ("Task reassigned"); other changes send ONE composite "Task updated: …" (price → $X · due time → … · deadline → … · day → … · title updated). Deadline/assignee/frequency changes reset `last_reminder_date`. On completion: early_bird award if before due_time (local), task-count awards evaluated, ALL admins notified "✅ {worker} finished: {title} / Earned $X" |
| DELETE /tasks/{id} | admin | |

### Time clock (CONCURRENT clocks)
| POST /time/clock-in | user | body {activity} (default working). 400 only if the SAME activity already has an open entry. Evaluates streak awards |
| POST /time/clock-out | user | query ?activity= or ?entry_id= closes matching; NO params = close ALL open entries. Returns single entry if 1 closed, else {closed:[…], count} |
| GET /time/active | user | LIST of open entries (sorted by clock_in asc; [] if none) |
| GET /time/entries | user | worker→own; admin all or ?user_id= ; sorted clock_in desc |

### Goals / Trips (`kind` param distinguishes)
| POST /goals | user | **QUERY params** (multipart body for optional image file): title*, product_link, deadline(YYYY-MM-DD or ISO), target_amount, period, allocation_percent, assignee_id(admin-only assign; owner becomes worker; notifies "🎯/✈️ New goal/trip: …"), kind=goal|trip |
| GET /goals | user | ?kind=&owner_id= ; worker sees own OR collaborator docs; kind=goal also matches legacy no-kind rows; response attaches image_url, progress{} and (admin) owner object |
| PATCH /goals/{id} | owner/collab/admin | JSON GoalUpdate {title, product_link, deadline, target_amount, period, allocation_percent} |
| POST /goals/{id}/image | owner/collab/admin | multipart; soft-deletes old |
| DELETE /goals/{id}/image | owner/collab/admin | |
| POST /goals/{id}/complete | admin | {appreciation?} → status completed, acknowledged_at=null; notifies owner "🎉 Goal achieved" |
| POST /goals/{id}/react | user | {emoji} from set {👍 ❤️ 🔥 🎉 ⭐ 💪 🙌 💎}; toggles per (user,emoji); notifies owner unless self |
| POST /goals/{id}/acknowledge | owner | sets acknowledged_at (dismisses CongratsModal) |
| POST /goals/{id}/reopen | admin | back to open, clears completed_* + appreciation |
| DELETE /goals/{id} | owner/admin only | soft-deletes image |
| POST /goals/{id}/collaborators | editor | {user_id} (worker only, not owner); notifies "🤝 You're now on goal: …" |
| DELETE /goals/{id}/collaborators/{uid} | owner/admin, or self-remove | |

**Progress math** (`_attach_goal_progress`): earnings buckets per owner = sums of completed-task prices in today/week/month/year windows (APP_TZ). `contrib_X = bucket_X * allocation_percent/100`. `period_amount` chosen by goal period (once→year bucket). `pct_of_target = min(100, period/target*100)` rounded to 1dp. **If status=completed: pct forced 100 and period_amount forced = target.**

### Essentials
| GET /essentials | user | worker: own+collab; admin: all or ?owner_id=; admin gets owner attached |
| POST /essentials | user | QUERY params + optional file: title*, price*(≥0), category(defaults other), quantity(≥1), note, assignee_id(admin), recurring(bool), due_date |
| PATCH /essentials/{id} | editor | JSON EssentialUpdate; purchased=true sets completed_at, false clears |
| POST /essentials/{id}/image | editor | multipart |
| DELETE /essentials/{id} | owner/admin | |
| GET /essentials/totals | user | {count,total,purchased_total,pending_total,by_category} — line value = price×quantity |
| POST/DELETE /essentials/{id}/collaborators[/{uid}] | as goals |

**Permission helpers**: `_can_edit_doc` = admin OR owner OR collaborator; `_can_delete_doc` = admin OR owner only.

### Payroll & admin monitor
| GET /payroll | admin | per worker: {worker, tasks_completed, tasks_earnings, total_seconds, total_hours, currently_clocked_in} (all-time sums) |
| GET /admin/worker-status | admin | rich per-worker live status — see §7 |
| GET /me/weekly-activity | user | own {streak_days, completions_by_day: 7×{day,count,earned,hours,titles(≤5)}} Mon..Sun in APP_TZ |

### Notifications & awards & announcements
| GET /notifications?limit= | user | {items(desc, ≤200), unread} |
| POST /notifications/{id}/read, /notifications/read-all | user | |
| GET /awards | user (admin ?user_id=) | {earned_count,total,items:[{code,title,description,icon,earned,earned_at}]} |
| GET /awards/catalog | user | |
| POST /announcements | admin | fans out notification to EVERY worker with tag icon (✨🛠️📣) |
| GET /announcements | user | all, desc |
| DELETE /announcements/{id} | admin | |

### Peer access (consent-based overview sharing)
| POST /peer-access/request | worker | {target_id, note?}; upserts to pending; notifies target "👀 X wants to see your overview" with meta.request_id |
| POST /peer-access/{id}/respond | target | {accept: bool} → granted/denied; notifies requester "🤝 X approved/declined…" |
| GET /peer-access/incoming | user | pending where I'm the target (+requester object) |
| GET /peer-access/granted | user | {i_can_see:[…+target], can_see_me:[…+requester]} |
| DELETE /peer-access/{id} | either party or admin | revoke |
| POST /admin/peer-access/force?requester_id&target_id | admin | silently grants; notifies both |
| GET /peer-overview/{target_id} | granted viewer or admin | target's {worker, streak_days, completions_by_day} |

### Push
| GET /push/public-key | — | {key, available} |
| POST /push/subscribe | user | {subscription} upsert by endpoint |
| POST /push/unsubscribe | user | is_active=false |
| POST /push/test | user | sends self "🔔 Push test" |

### Health
GET /api/ → `{"message": "LoveWorks API", "ok": true}`

---

## 7. Business logic details

### /admin/worker-status response per worker
`{worker, online(last_seen<120s), last_seen_at, currently_clocked_in, active_activity(primary=earliest), active_clock_in_at, active_activities:[{id,activity,clock_in}], today_worked_seconds/hours, week_worked_seconds/hours, daily_required_hours, weekly_required_hours, today_left_hours, week_left_hours, open_tasks_count, potential_weekly, potential_monthly, streak_days, inconsistencies{missed_days[],low_days[],streak_broken,total_issues}, completions_by_day[7]}`
- Sorted: online first, then clocked-in, then name.
- **Potential earnings** from open tasks: daily→price×5/wk & ×20/mo; weekly→price & ×4; monthly→price/4 & price; once→price both.
- **Required hours**: daily_hours contributes dh/day and dh×5/week (monthly: dh/4 per day); tasks with only estimated_hours and freq weekly/once add est to weekly_required.
- **Streak** = consecutive days ending today with ≥1 completion (this week only, from Monday).
- **Inconsistencies** (days before today, this week): missed = 0 completions AND <0.05h clocked; low = >0h but <50% of daily_required; streak_broken = yesterday empty but earlier week had completions.

### Awards catalog (codes → title/desc/icon)
first_task "First on the Board"/sparkle · five_tasks "High Five"/high-five · ten_tasks "Bronze Worker"/medal-bronze · twentyfive_tasks "Silver Worker"/medal-silver · fifty_tasks "Gold Worker"/medal-gold · hundred_tasks "Platinum Worker"/trophy · early_bird "Early Bird"/sunrise (completed before its due time) · streak_3 "3-Day Streak"/flame · streak_7 "Week Warrior"/flame-gold (clock-in streaks over ALL history, APP_TZ dates).
Granting an award notifies "🏆 New award: …" → /worker/awards.

### Notification types (frontend icon/color map in NotificationBell)
task_assigned(sky/ClipboardList), task_updated(amber), task_due_soon(red/AlarmClock), task_completed(emerald/CheckCircle2, admin-bound), award(yellow/Trophy), announcement(emerald/Megaphone), goal_assigned(fuchsia/Target), goal_completed(yellow/Sparkles), goal_reaction(pink/Heart), collab_added(pink/Users), peer_access_request(pink/Users, renders inline Accept/Decline buttons which call respond + mark read), peer_access_response(emerald/Users), test.
Every `notify()` also fires a Web Push to all active subscriptions (payload {title,body,link,meta}; ttl 12h; 404/410 endpoints deactivated).

### Reminder loop (background asyncio task, started on startup)
Tick every 60s (8s warmup). For each non-completed task with due_time: skip if `last_reminder_date == today(local)`; check `_task_is_due_today` (daily→always; weekly→dow matches or unset; monthly→1st of month; once→due_at date is today, else dow match); if 0 < minutes-until-due ≤ 30 → atomically set last_reminder_date (race-checked) then notify assignee "⏰ Due in N min: {title}".

---

## 8. Frontend

### Routing (App.js, BrowserRouter)
`/` → RootRedirect (by role) · `/login`
Admin (ProtectedRoute role=admin + AdminLayout): `/admin`(Dashboard) `/admin/workers` `/admin/tasks` `/admin/goals` `/admin/trips` `/admin/essentials` `/admin/payroll` `/admin/announcements` `/admin/profile`
Worker (WorkerLayout): `/worker`(Dashboard) `/worker/history` `/worker/trips`(reuses AdminTrips) `/worker/essentials`(reuses AdminEssentials) `/worker/awards` `/worker/announcements` `/worker/profile`
`*` → `/`. Toaster: sonner, richColors, top-right, dark.

AuthContext: user = null(loading)/false(anon)/object. login() stores access_token in localStorage. ProtectedRoute shows gold spinner while null, redirects to /login (with `state.from`) when false, cross-role redirects to own home.

### Theme
- Dark base `#09090B`, panels `#121214`, inputs `#18181b`(zinc-900). Global border color rgba(250,204,21,0.18) (gold).
- Fonts (Google): **Outfit** (`.font-display`, headings, -0.02em) + **Manrope** (body, weight 500).
- Primary CTA = gold `bg-yellow-400 text-black`; brand accents pink (`pink-400`/`rose-500` gradient heart logo); active nav = pink pills.
- CSS vars (shadcn): --primary 48 96% 53% (gold), --radius 0.875rem.
- Animations (index.css): `gold-pulse` (pulsing gold ring on clock-in CTA, 2.4s), `fade-up` (0.5s entrance), `love-float` (6.5s float for login icons), `.no-scrollbar`. Selection = gold bg/black text. Scrollbar thumb hover gold. Sonner dark-gold variables.
- H1 pattern everywhere: eyebrow (`text-xs uppercase tracking-widest text-yellow-400`) + `font-display text-3xl sm:text-4xl lg:text-5xl font-bold`.

### Layouts
- **AdminLayout**: desktop fixed left sidebar w-64 (#0c0c0e) — pink heart logo + "LoveWorks / ADMIN CONSOLE", NotificationBell(align="left"), nav items (Overview/Workers/Tasks/Goals/Trips/Essentials/Payroll/Announcements/Profile with lucide icons, testids nav-*), footer avatar card + Logout. Mobile (<md): fixed top bar h-14 (logo + logout + bell, z-40) + fixed scrollable pill nav row below (top-14, z-30) + 104px spacer. Active pill: `bg-pink-400 text-white`.
- **WorkerLayout**: sticky top header — logo, inline nav ≥sm (Workday/History/Trips/Essentials/Awards/What's new/Profile), bell, avatar link, logout; <sm second row with scrollable pills.

### Pages (key behaviors + exact copy)
- **Login**: split layout; left brand panel (lg+) with h1 "Show your Love." (pink glow drop-shadow) / "Get Loved with Gifts." (gold), floating icon backdrop (10 lucide icons: Heart, Gift, Plane, Flower2, Wine, Gem, Banknote, KeyRound, ShoppingBag, Shirt with per-icon top/left/delay/size/tint/rotation, `love-float`, hidden <md), "Secured with JWT · Admin invitations only". Right card: "Welcome back" (pink) / "Sign in to start showing Love." Email+password (show/hide toggle), gold Sign-in button, error box, "Need an account? Ask your admin to invite you."
- **WorkerDashboard**: PushPrompt banner → Hero card: activity pills for each running clock, h1 "Punch in to begin." / "You're on the clock." / "You're juggling N clocks."; 6 stat tiles (Shift timer HH:MM:SS live, Today h, Open tasks, Earned $, This-week potential $, All open value $); right side: 144px(sm:176px) round CTA — idle = gold pulsing "Clock in", active = colored ring of primary activity with live timer + "Start another" + red "Clock out all"; "Running clocks" strip (each with Stop button, entry-level clock-out); activity picker grid (7 activities, running ones disabled with "running" tag). → **Deadlines** section: 4 buckets (Overdue/red, Due today/yellow, Due this week/sky, Open·anytime/zinc) each showing ≤4 tasks with price + potential sum, click = complete. → **Your tasks** list (TaskRow: toggle circle → completed strikethrough +"+$X earned" toast, SpeakButton TTS, frequency/payout chips, due date/DOW/time/daily-hours/est-hours meta, Start/Working… button). → **WeeklyStrip** ("Your week") → **GoalsCard**.
- **GoalsCard** (worker goals, embedded): header "Goals & wishlist" + "New goal"; goal cards: 96px image, status chip (In progress/Overdue/Achieved/Ahead of deadline), period + alloc% chips, deadline + product-link hostname, big `$period_amount` of `$target · pct%` + gold progress bar + 4 mini buckets (Today/Week/Month/Year), appreciation quote box, Reactions row, edit/delete icons. Create/edit dialog: title("What do you want?"), target, period select (One-time/Daily/Weekly/Monthly/Yearly), allocation %, product link, deadline date, photo picker (create only; edit uploads via dedicated endpoints in admin page pattern). CongratsModal (gold gradient header "Goal achieved!", PartyPopper, appreciation "From your admin:", auto-POST acknowledge) pops for newest completed+unacknowledged goal.
- **AdminDashboard** ("Today at a glance."): 6 Stat cards (Workers, On the Clock, Hours Logged, Tasks Assigned, Completed, Total Payroll); **Potential earnings** panel (weekly gold + monthly emerald totals, per-worker rows with open-task count); Recent tasks list (6) with status pills.
- **AdminWorkers** ("Your workers." · "Crew · Live"): online/on-clock counts, 20s poll + 1s tick; Invite dialog (name/email/temp password); worker cards: avatar + presence dot, online/last-seen chip, current activity pill + live shift timer or "Off the clock", Today & This-week hour cards with required-hours progress bars + "Xh left"/"Hit daily target", open tasks count, WeeklyStrip, chips row: 🔥 N-day streak / ⚠️ streak broken / 💤 missed days / 📉 light days / ✨ clean week. Delete with confirm (warns cascade).
- **AdminTasks** ("Assign & price tasks."): status Tabs (all/assigned/in_progress/completed); rows with SpeakButton, status/frequency/payout chips, description, assignee + all due metadata, price box, Edit dialog (full form: title, description, price, assignee select, deadline date, due time, day-of-week select shown only when frequency=weekly, total est. hours, daily required with Hours/Minutes unit toggle (minutes stored /60), frequency, payout schedule with explainer), Mark complete, Delete.
- **AdminGoals** ("Workers' wishlist."): "Assign goal to worker" (dialog notifies worker); 3 totals cards (All goals combined / Delivered / Still to deliver by target sums); status Tabs with counts; 2-col goal cards (like GoalsCard + owner avatar + 🤝+N collab chip); actions: Delete (typed confirm dialog: "payroll still counts them"), Edit (photo upload/replace/remove + TeammatesField + all fields), Celebrate (dialog with 6 QUICK_QUOTES chips: "🛒 Ordering it soon!", "✅ It's already ordered.", "📦 It will be shipped soon.", "👏 Good job — you earned it!", "🌟 So proud of you!", "🎉 Way to go — crushed it!" + textarea) / Reopen. Reactions (admin can react, workers read-only).
- **AdminTrips**: same file pattern as AdminGoals but kind=trip, SHARED by worker route (`isAdmin` toggles copy: "Travel plans."/"Your travel plans.", "Assign trip to worker"/"Add a trip", worker create has no assignee). Adds View-by-worker owner filter (admin). Totals: "All trips combined / Booked / Still to book".
- **AdminEssentials** (shared admin+worker route): header "The everyday list."; View-by-worker filter (admin); totals cards Grand total / Still to buy / Stocked up; category Tabs (All + 6 categories with icons Home/Sparkles/Sandwich/User/Baby/Package and per-cat colors); 3-col item cards: photo or category icon, category + owner chips, title (strikethrough+dim when purchased), note, 🔁 recurring / ✨ one-time chip, 📅 due chip, ✓ completed-date chip, `$line` = price×qty, actions: purchased toggle (emerald check), edit, delete. Create/edit dialog: For(optional assignee, admin), title, price, quantity, category select, note, recurring toggle button, due date; edit adds photo upload + TeammatesField.
- **AdminPayroll** ("Who earned what."): gold gradient Total-payroll card + hours card; per-worker rows: avatar, "on the clock" pulse chip, Tasks/Hours/Status metrics, Earned $.
- **Awards** ("Trophy case."): gold progress banner (X/Y earned + %), 3-col cards from AWARD_VISUAL map (gradient icon tiles; unearned = grayscale + Lock "Locked"; earned = green ✓ + date).
- **Announcements** ("What's new."): admin New-post dialog (tag select: New feature/Update/Maintenance/Heads-up → Sparkles/Bell/Wrench/Megaphone with colors), cards with tag chip + timestamp + pre-wrap body, admin delete. Shared route both roles.
- **WorkerHistory** ("Time entries."): total logged, list of entries with activity pill, clock_in → clock_out, duration "Xh Ym" or green "In progress".
- **Profile** (both roles): avatar 120px + camera upload button + remove; email + role chip; display-name form; Notifications section with PushSettings toggle (enable/disable push + copy about 30-min reminders).

### Shared components
- **NotificationBell(align)**: 45s poll; badge 9+; panel `w-[min(360px,calc(100vw-2rem))] z-[60]`, align left|right; mark-all-read; per-item click = mark read + navigate link; peer_access_request items render Accept(emerald)/Decline buttons inline.
- **WeeklyStrip(days, streak, title, dense)**: Mon..Sun tiles (gold gradient when count>0, today ring, flame on streak days, ≥2 streak shows orange "N-day streak" pill); hover/click popover: count · $earned · hours + up to 5 titles. todayIdx = `(getDay()+6)%7`.
- **TeammatesField(docId, collection, ownerId, collaboratorIds, workers, onChanged, label)**: pink chips with avatar + X remove; Select of eligible workers + pink Add button; calls `/{collection}/{id}/collaborators`.
- **Reactions(goal)**: grouped emoji counts; only admin can react/toggle (picker with 8 emojis); workers see counts.
- **SpeakButton(text)**: window.speechSynthesis, prefers en voice, toggles, pulsing gold while speaking, hidden if unsupported.
- **PushPrompt**: banner "Never miss a task deadline." with Enable/Not-now (dismiss stored in localStorage `cw_push_dismissed_at`, 7-day snooze); hidden if unsupported/granted/denied. Also exports **PushSettings** toggle for Profile.
- **Avatar(url,name,size)**: img with `?auth=<token>` else gold initial circle.
- **lib/activities.js**: activity registry with lucide icon + tailwind color classes per activity (working=yellow/Briefcase, studying=sky/BookOpen, break=zinc/Coffee, cleaning=emerald/Sparkles, workout=orange/Dumbbell, parenting=pink/Baby, self_care=rose/HeartPulse).
- **lib/push.js**: urlBase64ToUint8Array, isPushSupported, enablePush (permission → SW register → get /push/public-key → subscribe → POST /push/subscribe), disablePush, sendTestPush.

### data-testid conventions
kebab-case on every interactive/critical element, e.g. login-email/login-password/login-submit, clock-in-btn, clock-out-btn, activity-{key}, stop-clock-{activity}, toggle-task-{id}, nav-*, m-nav-* (mobile), notification-bell, notification-panel, peer-accept-{reqId}, weekly-day-{Mon..}, assign-goal-btn, essential-*, trips-owner-filter, payroll-row-{id}, award-{code}.

---

## 9. PWA & mobile packaging (June 2026)

- `public/manifest.json`: name "LoveWorks — Love · Tasks · Gifts", short_name LoveWorks, standalone, portrait, theme/background #09090B, icons 192/512 + maskable 192/512.
- `public/sw.js`: push + notificationclick handlers (icon /icon-192.png, badge /badge-96.png, tag task-{id}, vibrate, focus-or-open link) **plus** cache `loveworks-v1`: precache [/, manifest, icons]; fetch handler skips non-GET, cross-origin, `/api/*`; navigations network-first→cached '/'; statics stale-while-revalidate.
- SW registered on load in `src/index.js` (guard: protocol startsWith http).
- index.html: manifest link, favicon-32, apple-touch-icon(180), mobile-web-app-capable, apple-mobile-web-app-capable/status-bar black-translucent/title, theme-color, Outfit+Manrope fonts, emergent script.
- Icons generated from `frontend/assets/icon-only.png` (pink heart + gold outline, raining gold hearts/money/gifts on #781b3a); derivatives via PIL (maskable = 80% inset; adaptive foreground = 66%; splash 2732 = icon 1100px centered).
- Capacitor 7 (Node 20; v8 requires Node 22): `capacitor.config.json` appId com.loveworks.app, webDir build, androidScheme https, SplashScreen bg #781b3a. Native projects `frontend/ios/`, `frontend/android/`; assets via `npx @capacitor/assets generate --ios --android`; rebuild flow = `yarn build && npx cap sync`. Store steps in `/app/STORE_SUBMISSION_GUIDE.md`.
- Store prerequisites still open: public /privacy page + in-app account deletion (Apple requirement).

---

## 10. Known quirks & gotchas (do not "fix" blindly)

1. POST /goals and POST /essentials take **query params + multipart file**, not JSON (frontend builds URLSearchParams + FormData).
2. Trips live in the `goals` collection (`kind="trip"`); legacy goal rows may lack `kind`.
3. `/time/active` returns a LIST; older clients expected a single object (frontend tolerates both).
4. Protected images load via `?auth=<jwt>` query param on `/api/files/...`.
5. Admin password re-syncs to env on every startup.
6. Goal progress derives from completed-task earnings buckets — there is no explicit "contribution ledger".
7. Completed goals force 100%/target display regardless of actual earnings.
8. `due_day_of_week: -1` in PATCH /tasks clears the field.
9. `daily_hours` always stored in hours; UI minutes toggle converts (45min → 0.75).
10. AdminTrips/AdminEssentials are shared components rendered under both /admin/* and /worker/* routes with `isAdmin` branching.
11. server.py is a single 2,722-line file (all models + routes) — refactor is a standing P1.
12. Web Speech API (SpeakButton) is browser-native, no backend.
13. User deploys separately to production; preview changes require redeploy to go live.

## 11. Test accounts
- Admin: `admin@clockwork.com` / `admin123` (env-seeded)
- Worker: `lovetest@loveworks.com` / `Love123!`
