# iLoveWorks — Native Push Notifications Setup (iOS & Android)

All code is already implemented. Push goes live the moment you add the 3 Firebase files below.
Web push (browser) keeps working unchanged; native devices use Firebase Cloud Messaging (FCM).

---

## Step 1 — Create the Firebase project (5 min, free)
1. Go to https://console.firebase.google.com → **Add project** → name it `iLoveWorks` → create
   (Google Analytics can be OFF).

## Step 2 — Android: google-services.json
1. Firebase console → Project Overview → click the **Android** icon.
2. Package name: **com.loveworks.app** (must match exactly). Register app.
3. Download **google-services.json**.
4. Put it at: `frontend/android/app/google-services.json`
   (the Gradle build auto-detects it — nothing else to change).

## Step 3 — Backend sending key (service account)
1. Firebase console → ⚙ Project Settings → **Service accounts** tab.
2. Click **Generate new private key** → downloads a JSON file. KEEP IT SECRET.
3. Put it at: `backend/firebase-service-account.json`
   (path already configured via `FIREBASE_CREDENTIALS_PATH` in `backend/.env`).
4. Restart the backend. Log line check: no warnings, and `POST /api/push/register-device`
   responds with `"fcm_ready": true`.

## Step 4 — iOS: APNs key + GoogleService-Info.plist
1. Apple Developer portal → Certificates, Identifiers & Profiles → **Keys** → “+”.
   Enable **Apple Push Notifications service (APNs)** → register → download the `.p8` file.
   Note the **Key ID** and your **Team ID** (top-right of the portal).
2. Firebase console → ⚙ Project Settings → **Cloud Messaging** tab → Apple app configuration →
   **Upload** the `.p8` with the Key ID + Team ID.
3. Firebase console → Project Overview → click the **iOS** icon.
   Bundle ID: **com.loveworks.app**. Register app. Download **GoogleService-Info.plist**.
4. On your Mac, open the project (`npx cap open ios`) and drag **GoogleService-Info.plist**
   into the `App/App` folder in Xcode (check “Copy items if needed”, target: App).
5. In Xcode → App target → **Signing & Capabilities** → “+ Capability” → add **Push Notifications**.
   (Background Modes → Remote notifications is already set in Info.plist.)
6. From `frontend/ios/App` run `pod install` (the Podfile already includes `FirebaseMessaging`).

## Step 5 — Rebuild the mobile apps
```bash
cd frontend
yarn build          # bakes production URL from .env.production
npx cap sync
npx cap open ios    # or: npx cap open android
```

## Step 6 — Test on a real device
1. Install and launch the app on a physical device (push does NOT work on iOS simulators).
2. Log in → tap **Enable notifications** (banner on Worker home, or Profile → push toggle).
3. Accept the system permission dialog.
4. Put the app in the background, then from Profile hit the push test — or trigger any real
   event (assign a task from the admin account). The device gets an OS notification.
   Tapping it deep-links to the page in the notification.

---

## What was implemented (reference)
- **Frontend**: `@capacitor/push-notifications` plugin; `src/lib/nativePush.js`
  (permission + registration + token POST to `/api/push/register-device`, deep-link on tap);
  PushPrompt banner & Profile toggle now work natively; token auto-refresh on every login.
- **Backend**: `firebase-admin`; `POST /api/push/register-device` & `/api/push/unregister-device`;
  `send_native_push()` fires on every in-app notification (task assigned/due/completed, goals,
  announcements, awards, peer requests…); invalid tokens auto-pruned; tokens deleted with account.
- **Android**: Gradle already applies `com.google.gms.google-services` when the JSON exists.
- **iOS**: `AppDelegate.swift` maps APNs→FCM token (guarded — app still runs without the plist);
  Podfile has `FirebaseMessaging`; Info.plist has remote-notification background mode and
  `ITSAppUsesNonExemptEncryption=false` (skips the export-compliance question).
- Production deploy note: the backend needs `firebase-service-account.json` present in the
  deployed environment too — redeploy after adding it.
