# LoveWorks — App Store & Google Play Submission Guide

Your app is now packaged in three ways:
1. **PWA (live now)** — anyone on iPhone/Android can install it from the browser today.
2. **iOS app (Capacitor)** — ready-to-open Xcode project in `frontend/ios/`.
3. **Android app (Capacitor)** — ready-to-open Android Studio project in `frontend/android/`.

---

## 0. Before you build for the stores (IMPORTANT)

The mobile apps bundle the web frontend, and API calls go to `REACT_APP_BACKEND_URL`.
Before building a store release, make sure `frontend/.env` points to your **deployed production URL**
(not the preview URL), then rebuild:

```bash
cd frontend
yarn install
yarn build
npx cap sync
```

Run `npx cap sync` every time you rebuild the web app.

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

### Common rejection points (already handled or to note)
- ✅ App works full-screen with its own icon and splash (not a bare website shell).
- ⚠️ Make sure the production backend is up during review.
- ⚠️ Provide **demo credentials** in the App Review notes (e.g. the worker test account) so Apple can log in.
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
droid
```
