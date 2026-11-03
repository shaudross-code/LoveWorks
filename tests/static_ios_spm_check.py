# Static verification of Capacitor iOS SPM conversion + committed web bundles (iteration 11)
import os, re, json, glob, plistlib, subprocess, sys

R = []
def check(name, cond, info=""):
    R.append((name, bool(cond)))
    print(("PASS " if cond else "FAIL ") + name + (f"  [{info}]" if info and not cond else ""))

F = "/app/frontend"
IOS = f"{F}/ios/App"

# --- pbxproj
pbx = open(f"{IOS}/App.xcodeproj/project.pbxproj").read()
check("pbx XCLocalSwiftPackageReference CapApp-SPM", 'XCLocalSwiftPackageReference "CapApp-SPM"' in pbx)
check("pbx CapApp-SPM in Frameworks", "CapApp-SPM in Frameworks" in pbx)
for k, v in [("PRODUCT_BUNDLE_IDENTIFIER", "com.loveworks.app"), ("MARKETING_VERSION", "1.0.1"),
             ("CURRENT_PROJECT_VERSION", "3"), ("IPHONEOS_DEPLOYMENT_TARGET", "14.0")]:
    vals = set(re.findall(rf"{k} = ([^;]+);", pbx))
    check(f"pbx {k} == {v}", vals == {v}, str(vals))
check("no Podfile", not os.path.exists(f"{IOS}/Podfile"))
check("no App.xcworkspace", not os.path.exists(f"{IOS}/App.xcworkspace"))
check("no Pods refs in pbx", "Pods" not in pbx, str(re.findall(r".{20}Pods.{20}", pbx)[:3]))
check("pbx braces balanced", pbx.count("{") == pbx.count("}"))
check("pbx parens balanced", pbx.count("(") == pbx.count(")"))
# relativePath of local package
m = re.search(r'XCLocalSwiftPackageReference "CapApp-SPM" \*/ = \{[^}]*relativePath = ([^;]+);', pbx)
check("pbx local pkg relativePath CapApp-SPM", m and m.group(1).strip('"') == "CapApp-SPM", m.group(1) if m else None)

# --- Package.swift
pk = open(f"{IOS}/CapApp-SPM/Package.swift").read()
check("root Package capacitor-swift-pm.git", "capacitor-swift-pm.git" in pk)
check("root Package exact 7.6.8", 'exact: "7.6.8"' in pk)
check("root Package local plugin path", 'path: "../Plugins/CapacitorPushNotifications"' in pk)
check("root Package no node_modules", "node_modules" not in pk)
plug = os.path.normpath(f"{IOS}/CapApp-SPM/../Plugins/CapacitorPushNotifications")
check("plugin dir resolves", os.path.isdir(plug), plug)
for p in ["Package.swift", "ios/Sources/PushNotificationsPlugin/PushNotificationsPlugin.swift",
          "ios/Sources/PushNotificationsPlugin/PushNotificationsHandler.swift",
          "ios/Tests/PushNotificationsPluginTests/PushNotificationsPluginTests.swift"]:
    check(f"plugin file {p}", os.path.isfile(f"{plug}/{p}"))
pp = open(f"{plug}/Package.swift").read()
check("plugin Package from 7.0.0", 'from: "7.0.0"' in pp)
check("plugin target path", 'path: "ios/Sources/PushNotificationsPlugin"' in pp)
check("plugin test path", 'path: "ios/Tests/PushNotificationsPluginTests"' in pp)
check("plugin product name CapacitorPushNotifications", 'name: "CapacitorPushNotifications"' in pp)
src = open(f"{plug}/ios/Sources/PushNotificationsPlugin/PushNotificationsPlugin.swift").read()
check("plugin swift has class PushNotificationsPlugin", "class PushNotificationsPlugin" in src)
check("plugin swift CAPBridgedPlugin", "CAPBridgedPlugin" in src)
check("plugin swift no Firebase", "Firebase" not in src)

# --- AppDelegate
ad = open(f"{IOS}/App/AppDelegate.swift").read()
check("AD no import Firebase", "import Firebase" not in ad)
check("AD no FirebaseMessaging", "FirebaseMessaging" not in ad)
for s in ["import Capacitor", "@UIApplicationMain", "capacitorDidRegisterForRemoteNotifications",
          "capacitorDidFailToRegisterForRemoteNotifications", "ApplicationDelegateProxy.shared.application(app, open: url",
          "continue: userActivity"]:
    check(f"AD contains {s}", s in ad)
check("AD braces balanced", ad.count("{") == ad.count("}"))
# Any other swift file importing Firebase in App target
others = [f for f in glob.glob(f"{IOS}/App/**/*.swift", recursive=True) if "Firebase" in open(f).read()]
check("no Firebase in any App/*.swift", not others, str(others))

# --- Info.plist
ip = plistlib.load(open(f"{IOS}/App/Info.plist", "rb"))
check("plist CFBundleDisplayName", ip.get("CFBundleDisplayName") == "iLoveWorks", ip.get("CFBundleDisplayName"))
check("plist UIBackgroundModes", ip.get("UIBackgroundModes") == ["remote-notification"], ip.get("UIBackgroundModes"))
check("plist ITSAppUsesNonExemptEncryption False", ip.get("ITSAppUsesNonExemptEncryption") is False)
check("plist UILaunchStoryboardName", ip.get("UILaunchStoryboardName") == "LaunchScreen")
print("   plist CFBundleShortVersionString:", ip.get("CFBundleShortVersionString"), "CFBundleVersion:", ip.get("CFBundleVersion"), "CFBundleIdentifier:", ip.get("CFBundleIdentifier"))
for sb in ["LaunchScreen", "Main"]:
    check(f"{sb}.storyboard", os.path.isfile(f"{IOS}/App/Base.lproj/{sb}.storyboard"))
for a in ["AppIcon.appiconset", "Splash.imageset"]:
    d = f"{IOS}/App/Assets.xcassets/{a}"
    pngs = glob.glob(f"{d}/*.png")
    check(f"{a} PNG+Contents.json", os.path.isfile(f"{d}/Contents.json") and pngs, f"{len(pngs)} pngs")
    if os.path.isfile(f"{d}/Contents.json"):
        cj = json.load(open(f"{d}/Contents.json"))
        missing = [i["filename"] for i in cj.get("images", []) if i.get("filename") and not os.path.isfile(f"{d}/{i['filename']}")]
        check(f"{a} Contents.json files exist", not missing, str(missing))

# --- capacitor.config.json
cc = json.load(open(f"{IOS}/App/capacitor.config.json"))
check("cap appId", cc.get("appId") == "com.loveworks.app")
check("cap appName", cc.get("appName") == "iLoveWorks")
check("cap ios.contentInset never", cc.get("ios", {}).get("contentInset") == "never")
check("cap packageClassList Push", "PushNotificationsPlugin" in cc.get("packageClassList", []))
check("config.xml", os.path.isfile(f"{IOS}/App/config.xml"))
root_cc = json.load(open(f"{F}/capacitor.config.json"))
check("root capacitor.config appId match", root_cc.get("appId") == cc.get("appId"))

# --- git ignore
paths = ["frontend/ios/App/App/public/index.html", "frontend/ios/App/App/capacitor.config.json",
         "frontend/ios/App/Plugins/CapacitorPushNotifications/Package.swift", "frontend/ios/App/CapApp-SPM/Package.swift",
         "frontend/android/app/src/main/assets/public/index.html",
         "frontend/ios/App/Plugins/CapacitorPushNotifications/ios/Sources/PushNotificationsPlugin/PushNotificationsPlugin.swift",
         "frontend/ios/App/App/config.xml"]
r = subprocess.run(["git", "check-ignore", "-v"] + paths, cwd="/app", capture_output=True, text=True)
check("git check-ignore none ignored", r.returncode == 1 and not r.stdout.strip(), r.stdout)

# --- bundle freshness
bi = open(f"{F}/build/index.html").read()
bh = re.search(r"main\.[0-9a-f]+\.js", bi).group(0)
for name, pub in [("ios", f"{IOS}/App/public"), ("android", f"{F}/android/app/src/main/assets/public")]:
    ix = open(f"{pub}/index.html").read()
    m = re.search(r"main\.[0-9a-f]+\.js", ix)
    check(f"{name} main hash == build ({bh})", m and m.group(0) == bh, m.group(0) if m else None)
    js = open(f"{pub}/static/js/{bh}").read() if os.path.isfile(f"{pub}/static/js/{bh}") else ""
    for s in ["My Sizes", "How to measure", "Casual fits", "Workout fits", "https://labor-admin-hub.emergent.host"]:
        check(f"{name} js contains {s}", s in js)
    check(f"{name} js no preview URL", "labor-admin-hub.preview.emergentagent.com" not in js)
    webps = glob.glob(f"{pub}/measure/*.webp")
    check(f"{name} measure 10 webp", len(webps) == 10, str(len(webps)))
    check(f"{name} viewport-fit=cover", "viewport-fit=cover" in ix)

# --- package.json
pj = json.load(open(f"{F}/package.json"))
deps = {**pj.get("dependencies", {}), **pj.get("devDependencies", {})}
check("pkg push-notifications ^7", deps.get("@capacitor/push-notifications") == "^7", deps.get("@capacitor/push-notifications"))
caps = {k: v for k, v in deps.items() if k.startswith("@capacitor/")}
print("   capacitor deps:", caps)
check("all @capacitor major 7", all(re.sub(r"[^\d.]", "", v).split(".")[0] == "7" for v in caps.values()), str(caps))
nv = json.load(open(f"{F}/node_modules/@capacitor/push-notifications/package.json"))["version"]
check("node_modules push version 7.x", nv.startswith("7."), nv)
for p in ["core", "ios", "android", "cli"]:
    fp = f"{F}/node_modules/@capacitor/{p}/package.json"
    if os.path.isfile(fp):
        v = json.load(open(fp))["version"]
        check(f"node_modules @capacitor/{p} 7.x", v.startswith("7."), v)
# vendored plugin version matches node_modules
vp = f"{plug}/package.json"
if os.path.isfile(vp):
    check("vendored plugin version == node_modules", json.load(open(vp))["version"] == nv)

# --- scripts/docs
ns = "/app/scripts/native_sync.sh"
nst = open(ns).read()
check("native_sync executable", os.access(ns, os.X_OK))
for s in ["yarn build", "npx cap sync", "../Plugins/CapacitorPushNotifications"]:
    check(f"native_sync contains {s}", s in nst)
g = open("/app/NATIVE_BUILD_GUIDE.md").read()
for s in ["frontend/ios/App/App.xcodeproj", "iLoveWorks.xcodeproj"]:
    check(f"guide mentions {s}", s in g)
check("guide mentions Swift Package Manager", "Swift Package Manager" in g)
check("README points to frontend/ios/App/App.xcodeproj", "frontend/ios/App/App.xcodeproj" in open("/app/README.md").read())

print(f"\nTOTAL {sum(1 for _, ok in R if ok)}/{len(R)} passed")
fails = [n for n, ok in R if not ok]
if fails:
    print("FAILED:", fails)
sys.exit(1 if fails else 0)
