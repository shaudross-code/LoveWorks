#!/usr/bin/env bash
# Rebuild the web app and refresh the iOS + Android shells so Xcode / Android Studio show exactly what the web app shows.
set -euo pipefail
cd "$(dirname "$0")/../frontend"

yarn build
npx cap sync

# cap sync rewrites CapApp-SPM/Package.swift pointing at node_modules; keep the vendored copy so Xcode needs no Node.
sed -i 's#path: "../../../node_modules/@capacitor/push-notifications"#path: "../Plugins/CapacitorPushNotifications"#' ios/App/CapApp-SPM/Package.swift
grep -q 'Plugins/CapacitorPushNotifications' ios/App/CapApp-SPM/Package.swift && echo "iOS Package.swift OK (vendored plugin)"
echo "Native shells synced."
