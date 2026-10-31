# Native build guide (iOS / Android)

The iOS and Android apps are thin Capacitor shells that display the **web bundle** copied into
`frontend/ios/App/App/public` and `frontend/android/app/src/main/assets/public`.
If that bundle is stale, Xcode / Android Studio will show an old look even though the web app is current.

Those bundle folders are now **committed to the repo** (un-ignored in `ios/.gitignore` and `android/.gitignore`),
so every "Save to GitHub" carries the exact bundle that matches the web app.

## To ship the current look to the stores
1. In Emergent: **Save to GitHub** (bundle + config are included automatically).
2. On your Mac: `git pull`, then open `frontend/ios/App/App.xcworkspace` in Xcode.
3. Xcode → **Product → Clean Build Folder** (⇧⌘K), then **Run** / **Archive**.
   - Optional (only if you have Node installed): `cd frontend && yarn install && npx cap sync ios` – not required.
   - If CocoaPods complains: `cd frontend/ios/App && pod install`.
4. Android Studio: open `frontend/android`, **Build → Clean Project**, then Run / Generate Signed Bundle.

## When I (the agent) change the web app
I run `cd frontend && yarn build && npx cap sync` so the bundle is refreshed before you save to GitHub.
The build uses `frontend/.env.production` (`REACT_APP_BACKEND_URL=https://labor-admin-hub.emergent.host`) so native apps talk to production.

## Safe areas
`capacitor.config.json` → `ios.contentInset: "never"`; the notch/status bar is handled in CSS
(`--safe-top: env(safe-area-inset-top)` + `viewport-fit=cover`). Do not switch it back to `"always"` — that doubles the top gap.
