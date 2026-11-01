# Static verification of native "look" fixes (iteration 12): Info.plist, Android colors/styles, SPM, bundles, git hygiene
import os, re, json, glob, plistlib, subprocess, sys
import xml.etree.ElementTree as ET

R = []
def check(name, cond, info=""):
    R.append((name, bool(cond)))
    print(("PASS " if cond else "FAIL ") + name + (f"  [{info}]" if info and not cond else ""))

F = "/app/frontend"
IOS = f"{F}/ios/App"
AND = f"{F}/android"

# --- iOS Info.plist
pl = plistlib.load(open(f"{IOS}/App/Info.plist", "rb"))
check("plist UIStatusBarStyle light", pl.get("UIStatusBarStyle") == "UIStatusBarStyleLightContent")
check("plist UIUserInterfaceStyle Dark", pl.get("UIUserInterfaceStyle") == "Dark")
check("plist UIViewControllerBasedStatusBarAppearance False", pl.get("UIViewControllerBasedStatusBarAppearance") is False)
check("plist ITSAppUsesNonExemptEncryption False", pl.get("ITSAppUsesNonExemptEncryption") is False)
check("plist CFBundleDisplayName", pl.get("CFBundleDisplayName") == "iLoveWorks")
check("plist remote-notification", "remote-notification" in pl.get("UIBackgroundModes", []))

# --- SPM
pk = open(f"{IOS}/CapApp-SPM/Package.swift").read()
check("Package exact 7.6.8", 'exact: "7.6.8"' in pk)
check("Package local plugin", 'path: "../Plugins/CapacitorPushNotifications"' in pk)
check("Package no node_modules", "node_modules" not in pk)
plug = f"{IOS}/Plugins/CapacitorPushNotifications"
check("plugin Package.swift", os.path.isfile(f"{plug}/Package.swift"))
swifts = glob.glob(f"{plug}/ios/Sources/PushNotificationsPlugin/*.swift")
check("plugin swift sources", len(swifts) >= 2, str(swifts))
check("plugin from 7.0.0", 'from: "7.0.0"' in open(f"{plug}/Package.swift").read())
pbx = open(f"{IOS}/App.xcodeproj/project.pbxproj").read()
check("pbx local pkg ref", 'XCLocalSwiftPackageReference "CapApp-SPM"' in pbx)
for k, v in [("PRODUCT_BUNDLE_IDENTIFIER", "com.loveworks.app"), ("MARKETING_VERSION", "1.0.1"), ("CURRENT_PROJECT_VERSION", "3")]:
    vals = set(re.findall(rf"{k} = ([^;]+);", pbx))
    check(f"pbx {k}={v}", vals == {v}, str(vals))
for p in ["Podfile", "Pods", "App.xcworkspace"]:
    hits = glob.glob(f"{F}/ios/**/{p}", recursive=True)
    check(f"no {p}", not hits, str(hits))
ad = open(f"{IOS}/App/AppDelegate.swift").read()
check("AppDelegate no import Firebase", not re.search(r"^\s*import\s+Firebase", ad, re.M))
check("AppDelegate capacitorDidRegisterForRemoteNotifications", "capacitorDidRegisterForRemoteNotifications" in ad)

# --- Android
res = f"{AND}/app/src/main/res/values"
try:
    c = {e.get("name"): e.text for e in ET.parse(f"{res}/colors.xml").getroot()}
    check("colors.xml parses", True)
except Exception as e:
    c = {}; check("colors.xml parses", False, str(e))
for n, v in [("colorPrimary", "#09090B"), ("colorPrimaryDark", "#09090B"), ("colorAccent", "#FACC15"), ("appBackground", "#09090B")]:
    check(f"color {n}={v}", (c.get(n) or "").upper() == v, c.get(n))
try:
    root = ET.parse(f"{res}/styles.xml").getroot(); check("styles.xml parses", True)
    st = [s for s in root if s.get("name") == "AppTheme.NoActionBar"][0]
    items = {i.get("name"): i.text for i in st}
except Exception as e:
    items = {}; check("styles.xml parses", False, str(e))
check("statusBarColor", items.get("android:statusBarColor") == "@color/appBackground")
check("navigationBarColor", items.get("android:navigationBarColor") == "@color/appBackground")
check("windowLightStatusBar false", items.get("android:windowLightStatusBar") == "false")
# duplicate color definitions elsewhere (would fail aapt merge)
dups = []
for f in glob.glob(f"{AND}/app/src/main/res/values*/*.xml"):
    if f.endswith("colors.xml"): continue
    t = open(f).read()
    if re.search(r'<color name="(colorPrimary|colorPrimaryDark|colorAccent|appBackground)"', t): dups.append(f)
check("no duplicate color resources", not dups, str(dups))

# --- bundles
def mainjs(p):
    m = re.findall(r"static/js/(main\.[0-9a-f]+\.js)", open(p).read()); return m[0] if m else None
shells = {"build": f"{F}/build", "ios": f"{IOS}/App/public", "android": f"{AND}/app/src/main/assets/public"}
hashes = {k: mainjs(f"{v}/index.html") for k, v in shells.items()}
check("same main hash", len(set(hashes.values())) == 1, str(hashes))
check("hash == main.3983a432.js", hashes["build"] == "main.3983a432.js", hashes["build"])
for k in ("ios", "android"):
    js = open(f"{shells[k]}/static/js/{hashes[k]}").read()
    check(f"{k} js prod url", "https://labor-admin-hub.emergent.host" in js)
    check(f"{k} js no preview url", "preview.emergentagent.com" not in js)
    check(f"{k} js My Sizes", "My Sizes" in js)
    check(f"{k} js How to measure", "How to measure" in js)
    n = len(glob.glob(f"{shells[k]}/measure/*.webp"))
    check(f"{k} 10 measure webp", n == 10, n)
cfgs = {"ios": f"{IOS}/App/capacitor.config.json", "android": f"{AND}/app/src/main/assets/capacitor.config.json", "root": f"{F}/capacitor.config.json"}
for k, p in cfgs.items():
    cj = json.load(open(p))
    if k != "root" or True:
        check(f"{k} cfg contentInset never", cj.get("ios", {}).get("contentInset") == "never", cj.get("ios"))
        check(f"{k} cfg ios.backgroundColor", cj.get("ios", {}).get("backgroundColor") == "#09090B", cj.get("ios"))
        check(f"{k} cfg android.backgroundColor", cj.get("android", {}).get("backgroundColor") == "#09090B", cj.get("android"))

# --- git hygiene
for p in ["frontend/ios/App/App/public/index.html", "frontend/android/app/src/main/assets/public/index.html", "frontend/ios/App/CapApp-SPM/Package.swift"]:
    rc = subprocess.run(["git", "check-ignore", "-q", p], cwd="/app").returncode
    check(f"not ignored {p}", rc == 1, rc)
ox = open("/app/.oxlintignore").read()
check("oxlintignore ios public", "frontend/ios/App/App/public" in ox)
check("oxlintignore android public", "frontend/android/app/src/main/assets/public" in ox)
check("iLoveWorks.xcodeproj exists", os.path.isdir("/app/iLoveWorks.xcodeproj"))

fails = [n for n, ok in R if not ok]
print(f"\n{len(R)-len(fails)}/{len(R)} passed")
sys.exit(1 if fails else 0)
