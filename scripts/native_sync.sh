#!/usr/bin/env bash
# Rebuild the web app and refresh the iOS + Android shells so Xcode / Android Studio show exactly what the web app shows.
set -euo pipefail
cd "$(dirname "$0")/../frontend"

yarn build
# Generated bundles are committed for the native shells; tell linters to skip them.
for f in build/static/js/*.js; do
  grep -q '^/\* eslint-disable \*/' "$f" || { printf '/* eslint-disable */\n' | cat - "$f" > "$f.tmp" && mv "$f.tmp" "$f"; }
done
npx cap sync

# cap sync rewrites CapApp-SPM/Package.swift pointing at node_modules; keep the vendored copy so Xcode needs no Node.
sed -i 's#path: "../../../node_modules/@capacitor/push-notifications"#path: "../Plugins/CapacitorPushNotifications"#' ios/App/CapApp-SPM/Package.swift
grep -q 'Plugins/CapacitorPushNotifications' ios/App/CapApp-SPM/Package.swift && echo "iOS Package.swift OK (vendored plugin)"
echo "Native shells synced."
