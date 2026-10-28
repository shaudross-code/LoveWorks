# Copilot instructions for this repo

This repository contains a LoveWorks app with a React frontend, FastAPI backend, and Capacitor mobile wrappers for Android and iOS. The iOS native project lives under `frontend/ios/` and should be treated as a build target, not as the primary source of application logic.

## App architecture

- Frontend app logic lives in `frontend/src/`.
- Backend service logic lives in `backend/server.py` and `backend/tests/`.
- Capacitor config is in `frontend/capacitor.config.json`.
- Native iOS project is in `frontend/ios/App/`.

## Xcode/iOS workflow

- Keep the native iOS project aligned with the web app and Capacitor config.
- Prefer updating React/Capacitor configuration instead of editing native Swift/Objective-C unless the task is specifically about Xcode build or signing.
- Always check `STORE_SUBMISSION_GUIDE.md` and `PUSH_SETUP_GUIDE.md` before making app-store or push-notification changes.
- Use `cd frontend && npx cap sync ios` after config changes that affect the native project.

## Build and release rules

- Do not bake preview URLs into release bundles.
- Do not change the bundle identifier or app metadata without checking the existing project conventions.
- Protect signing and credentials; never print secrets or upload them to logs.
- Keep the Xcode project state stable and minimal.

## Expected behavior

When handling Xcode issues, explain the root cause, the files touched, and the exact validation steps relevant to iOS/Capacitor builds.
