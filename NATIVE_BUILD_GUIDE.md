# Native build guide (iOS / Android)

## ⚠️ There are TWO Xcode projects in this repo — open the right one

| Project | What it is | Looks like the web app? |
|---|---|---|
| **`frontend/ios/App/App.xcodeproj`** ✅ | The **Capacitor shell**. It displays the exact web bundle (same React code, same CSS) with native push hooks. **This is the App Store app.** | **Yes — pixel for pixel** |
| `iLoveWorks.xcodeproj` (repo root) | A separate hand-written SwiftUI app that talks to the same API. It was added from a Mac/Xcode session and has its own UI. | No — it is a different UI and will never match 1:1 |

If Xcode shows a UI that "doesn't look like the web version", you opened the root `iLoveWorks.xcodeproj`.
Close it and open **`frontend/ios/App/App.xcodeproj`** instead.

## Build the iOS app (no CocoaPods, no Node needed)
The Capacitor project uses **Swift Package Manager**:
- `capacitor-swift-pm` (Capacitor runtime) is fetched from GitHub by Xcode on first build.
- The push-notifications plugin is vendored in `frontend/ios/App/Plugins/CapacitorPushNotifications` (no `node_modules` needed).
- The web bundle (`frontend/ios/App/App/public`) and `capacitor.config.json` are committed, so no `cap sync` is needed on your Mac.

1. In Emergent: **Save to GitHub**.
2. On your Mac: `git pull`, then double-click **`frontend/ios/App/App.xcodeproj`** (not the `.xcworkspace`, there is none now).
3. Wait for "Resolving package graph" to finish (first time only, needs internet).
4. Target **App** → *Signing & Capabilities*: pick your Team. Add **Push Notifications** capability (+ Capability) if you want APNs.
5. **Product ▸ Clean Build Folder** (⇧⌘K) → **Run** on a simulator/device → **Archive** for TestFlight.

Bundle ID: `com.loveworks.app` · Version 1.0.1 (build 3) · Deployment target iOS 14.

## Build the Android app
Open `frontend/android` in Android Studio → **Build ▸ Clean Project** → Run / Generate Signed Bundle.
The bundle in `frontend/android/app/src/main/assets/public` is committed too.

## When the web app changes (agent side)
Run `bash scripts/native_sync.sh` — it rebuilds the web app (`frontend/.env.production` → `https://labor-admin-hub.emergent.host`),
runs `npx cap sync`, and re-points `CapApp-SPM/Package.swift` at the vendored plugin. Then Save to GitHub.
Do **not** run `yarn build` with `CI=true` (pre-existing eslint warnings fail the build).

## Safe areas
`capacitor.config.json` → `ios.contentInset: "never"`; the notch/status bar is handled in CSS
(`--safe-top: env(safe-area-inset-top)` + `viewport-fit=cover`). Don't switch it back to `"always"` — that doubles the top gap.

## Firebase / FCM (later)
The Capacitor `AppDelegate.swift` forwards APNs tokens to the plugin and no longer imports Firebase, so the project builds with
zero extra setup. When Firebase is configured (see `PUSH_SETUP_GUIDE.md`): add `GoogleService-Info.plist` to the App target,
File ▸ Add Package Dependencies ▸ `https://github.com/firebase/firebase-ios-sdk` (product **FirebaseMessaging**), and add
`FirebaseApp.configure()` + `Messaging.messaging().apnsToken = deviceToken` back into `AppDelegate.swift`.
