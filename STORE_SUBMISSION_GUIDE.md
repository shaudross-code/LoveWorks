# iLoveWorks — App Store & Google Play Submission Guide

Your app is now packaged in three ways:
1. **PWA (live now)** — anyone on iPhone/Android can install it from the browser today.
2. **iOS app (Capacitor)** — ready-to-open Xcode project in `frontend/ios/`.
3. **Android app (Capacitor)** — ready-to-open Android Studio project in `frontend/android/`.

---

## 0. Before you build for the stores (READ THIS)

The mobile apps **bundle** the web frontend at build time, so the API URL is **frozen into
the binary**. If you build with the preview URL, your App Store app will forever hit the
preview environment — not what you want.

We've set this up correctly:
- `frontend/.env` → preview URL (used while developing in Emergent)
- `frontend/.env.production` → **your production URL** `https://labor-admin-hub.emergent.host`
  (used automatically by `yarn build` — Create React App picks it up over `.env` in production mode)

Every time you build for the stores, run these commands on your Mac:

```bash
cd frontend
yarn install
yarn build            # produces build/ with the PRODUCTION URL baked in
npx cap sync          # copies build/ into ios/ and android/ + updates plugins
```

Then open Xcode / Android Studio and archive/build as usual.

**If you ever change the backend URL**, edit `frontend/.env.production` and repeat
`yarn build && npx cap sync`.

**Sanity check before submitting**: after `yarn build`, run
`grep -c "preview.emergentagent" frontend/build/static/js/main.*.js` — it MUST print `0`.
Then `grep -c "emergent.host" frontend/build/static/js/main.*.js` — it must print `1` or more.

---

## 1. PWA — works today, no store needed

- **iPhone**: open the app in Safari → Share → "Add to Home Screen". Full-screen, with the LoveWorks heart icon and push notifications.
- **Android**: Chrome shows an "Install app" prompt automatically (or menu → "Install app").

Nothing else to do — this is already live.

---

## 2. Apple App Store (requires a Mac with Xcode)

### Prerequisites
- Mac with **Xcode 15+** (`xcode-select --install` for command line tools)
- **Apple Developer account** ($99/yr) — you have this ✓
- CocoaPods: `sudo gem install cocoapods`

### Steps
1. Download the code (use "Save to GitHub" in Emergent, then clone on your Mac).
2. ```bash
   cd frontend
   yarn install
   yarn build
   npx cap sync ios
   npx cap open ios        # opens Xcode
   ```
3. In Xcode:
   - Select the **App** target → *Signing & Capabilities* → choose your Team (your Apple Developer account).
   - Bundle Identifier is `com.loveworks.app` (change it if you want, must be unique).
   - Add capability **Push Notifications** if you want native push later (web push works inside the webview on iOS 16.4+).
4. Set version/build number under *General*.
5. Menu **Product → Archive** → *Distribute App* → *App Store Connect* → Upload.
6. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com):
   - Create a new app: name **LoveWorks**, bundle ID `com.loveworks.app`, category *Lifestyle* or *Productivity*.
   - Fill in: description, keywords, support URL, privacy policy URL (**required** — see §4).
   - Screenshots: 6.7" iPhone (1290×2796) and 5.5" (1242×2208). Take them from the app running in the iOS Simulator (`Cmd+S` saves a screenshot).
   - App Privacy: declare that you collect email, name, and photos (user content) linked to identity, for app functionality.
7. Submit for review. First review typically takes 1–3 days.

### Demo credentials for App Review Notes (COPY-PASTE)
Apple's reviewer needs credentials to sign in. In App Store Connect →
**App Review Information → Sign-in required (ON) → paste this into "Sign-in Information"**:

```
Email: reviewer@loveworks.com
Password: iLoveWorks2026!

Notes:
- This is a dedicated, fully SANDBOXED reviewer admin account — it only sees its own
  demo data and cannot see or affect any real household's data (and vice versa).
- After sign-in you'll land on the admin dashboard, pre-populated with a demo worker,
  tasks, a goal, a trip, an essential and payroll history. You can:
    • View workers, tasks, payroll, goals, trips, essentials.
    • Create a new worker (Workers → +) to see the invite flow.
    • Assign a task and mark it complete to see the earnings & awards flow.
- To test the worker-side experience, log out and sign in with:
    Email: demo@loveworks.com
    Password: DemoWorker2026!
- Account deletion is at Profile → Danger zone.
```

The `reviewer@loveworks.com` account is idempotently seeded from `backend/.env`
(`REVIEWER_EMAIL` / `REVIEWER_PASSWORD`), along with a sandbox demo worker
(`REVIEWER_WORKER_EMAIL` / `REVIEWER_WORKER_PASSWORD`) and its sample data, so they
always exist after a deploy and passwords never drift. **Both accounts carry a
`sandbox` flag: every admin endpoint (workers, tasks, payroll, goals, trips,
essentials, announcements, notifications, live monitor) is scoped so sandbox
accounts and real accounts can never see each other's data.**

### Common rejection points (already handled or to note)
- ✅ App works full-screen with its own icon and splash (not a bare website shell).
- ⚠️ Make sure the production backend is up during review.
- ✅ Provided **demo credentials** in the App Review notes block above (`reviewer@loveworks.com` — dedicated reviewer admin).
- ✅ Account deletion: available in-app at Profile → Danger zone → "Delete my account" (Apple requirement — done).

---

## 3. Google Play Store

### Prerequisites
- **Google Play Console account** ($25 one-time): [play.google.com/console](https://play.google.com/console)
- **Android Studio** (works on Windows/Mac/Linux)

### Steps
1. ```bash
   cd frontend
   yarn install
   yarn build
   npx cap sync android
   npx cap open android    # opens Android Studio
   ```
2. Create a signing key (once, keep it safe forever):
   ```bash
   keytool -genkey -v -keystore loveworks-release.keystore -alias loveworks -keyalg RSA -keysize 2048 -validity 10000
   ```
3. In Android Studio: **Build → Generate Signed Bundle / APK → Android App Bundle (.aab)** → select your keystore → *release*.
4. In Play Console:
   - Create app: **iLoveWorks**, category *Lifestyle*, free.
   - Upload the `.aab` under *Production → Create new release*.
   - Store listing: short description (80 chars), full description, icon 512×512 (`frontend/public/icon-512.png`), feature graphic 1024×500, at least 2 phone screenshots.
   - Complete *Data safety* form (email, name, photos collected; encrypted in transit; users can request deletion).
   - Privacy policy URL is **required** (see §4).
5. Submit. First review can take up to 7 days; updates are usually hours.

---

## 4. Privacy policy (required by BOTH stores)

You need a public URL with a privacy policy.
✅ **Done** — the app serves a public privacy policy at `https://<your-deployed-domain>/privacy` (also linked from the login page and Profile). Use that URL in both store listings.

It must mention: account data (email, name), photos uploaded by users, push notifications, and how to request deletion.

---

## 5. Asset inventory (already generated)

| Asset | Location |
|---|---|
| App icon 1024 (source) | `frontend/assets/icon-only.png` |
| Adaptive icon fg/bg (Android) | `frontend/assets/icon-foreground.png`, `icon-background.png` |
| Splash 2732×2732 | `frontend/assets/splash.png` |
| PWA icons | `frontend/public/icon-192.png`, `icon-512.png`, maskable variants |
| Play Store 512 icon | `frontend/public/icon-512.png` |
| All native iOS/Android icons & splashes | generated into `frontend/ios/` & `frontend/android/` via `npx @capacitor/assets generate` |

To regenerate native icons after changing the source image:
```bash
cd frontend && npx @capacitor/assets generate --ios --android
```

---

## 6. Store listing copy (COPY-PASTE)

### Apple App Store

**App Name** (max 30 chars):
```
iLoveWorks – Chores & Rewards
```

**Subtitle** (max 30 chars):
```
Turn housework into rewards
```

**Promotional Text** (max 170 chars — editable anytime without review):
```
Every chore has a price. Clock in, finish tasks, and watch the money pile up toward goals, trips, and treats — the love-powered way to run your household.
```

**Keywords** (max 100 chars, comma-separated):
```
chores,allowance,family,tasks,rewards,household,time tracker,clock in,goals,payroll,housework
```

**Description** (max 4,000 chars):
```
Show your Love. Get Loved with Gifts. 💛

iLoveWorks turns everyday housework into something worth celebrating. One person runs the show as the Overseer — creating tasks, setting a price on each one, and cheering on the crew. Everyone else clocks in, gets things done, and watches their earnings grow toward the things they actually want.

PRICED TASKS, REAL MOTIVATION
• Assign chores and projects with a dollar value on every task
• Set deadlines by date, day of the week, or time of day
• One-time, daily, weekly, or monthly repeating tasks
• Completing a task instantly adds to that person's earnings

CLOCK IN TO ANYTHING
• Run multiple activity clocks at the same time — Working, Studying, Cleaning, Workout, Parenting, Break, Self Care
• A beautiful live timer keeps everyone honest
• Gentle reminders if you look idle or forget to clock out

GOALS, TRIPS & ESSENTIALS
• Create savings goals with photos, target amounts, and deadlines
• Plan trips together and watch task earnings fill the progress bar
• Keep a shared Essentials list — groceries, household items, kid stuff — with prices, photos, and purchased check-offs
• Collaborate: invite teammates onto shared goals and lists

FOR THE OVERSEER
• Live dashboard: who's clocked in, on what, and for how long
• Payroll view with per-person earnings, hours, and weekly projections
• Celebrate completed goals with appreciation notes and reactions
• Post announcements the whole crew sees instantly

MADE TO KEEP YOU GOING
• Streaks, awards, and a weekly activity strip for every worker
• Push notifications for new tasks, due-soon reminders, completions, and celebrations
• Peer view: request permission to peek at a teammate's week
• Gorgeous pink & gold design that makes chores feel a little less like chores

Whether it's parents motivating kids, partners splitting the load, or a small crew tracking real work — iLoveWorks makes effort visible, valued, and rewarded.

Your data stays yours: accounts are private, photos are stored securely, and you can delete your account (and everything with it) anytime from the app.
```

**What's New (version notes for 1.0)**:
```
Welcome to iLoveWorks 1.0! Priced tasks, multi-activity clock-ins, goals, trips, essentials, awards, and push notifications — everything you need to turn housework into rewards.
```

### Google Play

**Short description** (max 80 chars):
```
Priced chores, clock-ins, goals & rewards — run your household with love.
```

**Full description** (max 4,000 chars): reuse the Apple description above — Play allows the same text.

**Category**: Lifestyle (or Productivity) · **Content rating**: Everyone

