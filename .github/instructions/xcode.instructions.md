---
applyTo: '**/*.{js,jsx,ts,tsx,swift,m,mm,plist,json,md}'
---

# Xcode project guidance

Use this repository’s Xcode/Capacitor setup for any iOS-related work.

- The app name and bundle id should remain consistent with the existing project configuration.
- App logic should live in the React frontend; Xcode should mainly handle build, signing, app metadata, and native capabilities.
- Keep iOS build configuration consistent with `frontend/capacitor.config.json` and the project under `frontend/ios/App/`.
- For push notifications and App Store setup, rely on `PUSH_SETUP_GUIDE.md` and `STORE_SUBMISSION_GUIDE.md` rather than improvising native settings.
- After native-affecting frontend or config changes, run `cd frontend && npx cap sync ios` before validating Xcode changes.
