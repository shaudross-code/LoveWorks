uuid=$(xcrun simctl list devices Booted | head -n 2 | grep iPhone | awk -F'[{}]' '{print $2}')
echo "Booted ID: $uuid"
if [ ! -z "$uuid" ]; then
    xcrun simctl uninstall "$uuid" com.loveworks.app || true
    xcrun simctl install "$uuid" /Users/user/Library/Developer/Xcode/DerivedData/App-fauuqtrowvjcqhbmfojbwpcbijik/Build/Products/Debug-iphonesimulator/App.app
    xcrun simctl launch "$uuid" com.loveworks.app
fi
