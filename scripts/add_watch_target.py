"""Adds the iLoveWorksWatch watchOS app target to iLoveWorks.xcodeproj (idempotent)."""
import re
import sys

PATH = "/app/iLoveWorks.xcodeproj/project.pbxproj"
P = "300B846700BB12BB"
ID = {k: f"CE9F9B{v}{P}" for k, v in {
    "product": "A0", "target": "A1", "sources": "A2", "frameworks": "A3", "resources": "A4",
    "group": "A5", "exceptions": "A6", "configlist": "A7", "debug": "A8", "release": "A9",
    "proxy": "AA", "dependency": "AB", "embedphase": "AC", "buildfile": "AD",
}.items()}

APP_TARGET = "CE9F9B48300B846500BB12BB"
PROJECT = "CE9F9B41300B846400BB12BB"

src = open(PATH).read()
if ID["target"] in src:
    print("Watch target already present")
    sys.exit(0)


def insert_before(marker: str, text: str) -> None:
    global src
    assert src.count(marker) == 1, f"marker not unique: {marker}"
    src = src.replace(marker, text + marker)


def insert_after(marker: str, text: str) -> None:
    global src
    assert src.count(marker) == 1, f"marker not unique: {marker}"
    src = src.replace(marker, marker + text)


T = "\t"


def settings(debug: bool) -> str:
    lines = [
        "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;",
        "CODE_SIGN_ENTITLEMENTS = iLoveWorksWatch/iLoveWorksWatch.entitlements;",
        "CODE_SIGN_STYLE = Automatic;",
        "CURRENT_PROJECT_VERSION = 1;",
        "DEVELOPMENT_TEAM = 3TKQ757JMH;",
        "ENABLE_PREVIEWS = YES;",
        "GENERATE_INFOPLIST_FILE = YES;",
        "INFOPLIST_FILE = iLoveWorksWatch/Info.plist;",
        "INFOPLIST_KEY_CFBundleDisplayName = iLoveWorks;",
        'INFOPLIST_KEY_NSHealthShareUsageDescription = "iLoveWorks reads your Active and Resting calories to show today\'s totals on your Watch and iPhone.";',
        'INFOPLIST_KEY_NSHealthUpdateUsageDescription = "iLoveWorks saves the live workouts you record on your Watch to Apple Health.";',
        'INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";',
        "INFOPLIST_KEY_WKCompanionAppBundleIdentifier = TUE.iLoveWorks;",
        "INFOPLIST_KEY_WKRunsIndependentlyOfCompanionApp = NO;",
        "LD_RUNPATH_SEARCH_PATHS = (",
        f'{T}"$(inherited)",',
        f'{T}"@executable_path/Frameworks",',
        ");",
        "MARKETING_VERSION = 1.0;",
        "PRODUCT_BUNDLE_IDENTIFIER = TUE.iLoveWorks.watchkitapp;",
        'PRODUCT_NAME = "$(TARGET_NAME)";',
        "SDKROOT = watchos;",
        "SKIP_INSTALL = YES;",
        "SWIFT_APPROACHABLE_CONCURRENCY = YES;",
        "SWIFT_EMIT_LOC_STRINGS = YES;",
        "SWIFT_VERSION = 5.0;",
        "TARGETED_DEVICE_FAMILY = 4;",
        "WATCHOS_DEPLOYMENT_TARGET = 10.0;",
    ]
    if not debug:
        lines.append("VALIDATE_PRODUCT = YES;")
    return "".join(f"{T*4}{l}\n" for l in lines)


# Build files
insert_before("/* End PBXBuildFile section */", (
    f"{T*2}{ID['buildfile']} /* iLoveWorksWatch.app in Embed Watch Content */ = {{isa = PBXBuildFile; "
    f"fileRef = {ID['product']} /* iLoveWorksWatch.app */; platformFilter = ios; "
    f"settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};\n"
))

# Container proxy
insert_before("/* End PBXContainerItemProxy section */", (
    f"{T*2}{ID['proxy']} /* PBXContainerItemProxy */ = {{\n"
    f"{T*3}isa = PBXContainerItemProxy;\n"
    f"{T*3}containerPortal = {PROJECT} /* Project object */;\n"
    f"{T*3}proxyType = 1;\n"
    f"{T*3}remoteGlobalIDString = {ID['target']};\n"
    f"{T*3}remoteInfo = iLoveWorksWatch;\n"
    f"{T*2}}};\n"
))

# Embed Watch Content copy phase
insert_before("/* End PBXCopyFilesBuildPhase section */", (
    f"{T*2}{ID['embedphase']} /* Embed Watch Content */ = {{\n"
    f"{T*3}isa = PBXCopyFilesBuildPhase;\n"
    f"{T*3}buildActionMask = 2147483647;\n"
    f'{T*3}dstPath = "$(CONTENTS_FOLDER_PATH)/Watch";\n'
    f"{T*3}dstSubfolderSpec = 16;\n"
    f"{T*3}files = (\n"
    f"{T*4}{ID['buildfile']} /* iLoveWorksWatch.app in Embed Watch Content */,\n"
    f"{T*3});\n"
    f'{T*3}name = "Embed Watch Content";\n'
    f"{T*3}runOnlyForDeploymentPostprocessing = 0;\n"
    f"{T*2}}};\n"
))

# Product file reference
insert_before("/* End PBXFileReference section */", (
    f"{T*2}{ID['product']} /* iLoveWorksWatch.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; "
    f"includeInIndex = 0; path = iLoveWorksWatch.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n"
))

# Info.plist must not be copied as a resource
insert_before("/* End PBXFileSystemSynchronizedBuildFileExceptionSet section */", (
    f'{T*2}{ID["exceptions"]} /* Exceptions for "iLoveWorksWatch" folder in "iLoveWorksWatch" target */ = {{\n'
    f"{T*3}isa = PBXFileSystemSynchronizedBuildFileExceptionSet;\n"
    f"{T*3}membershipExceptions = (\n"
    f"{T*4}Info.plist,\n"
    f"{T*3});\n"
    f"{T*3}target = {ID['target']} /* iLoveWorksWatch */;\n"
    f"{T*2}}};\n"
))

# Synchronized folder
insert_before("/* End PBXFileSystemSynchronizedRootGroup section */", (
    f"{T*2}{ID['group']} /* iLoveWorksWatch */ = {{\n"
    f"{T*3}isa = PBXFileSystemSynchronizedRootGroup;\n"
    f"{T*3}exceptions = (\n"
    f'{T*4}{ID["exceptions"]} /* Exceptions for "iLoveWorksWatch" folder in "iLoveWorksWatch" target */,\n'
    f"{T*3});\n"
    f"{T*3}path = iLoveWorksWatch;\n"
    f'{T*3}sourceTree = "<group>";\n'
    f"{T*2}}};\n"
))

# Frameworks phase
insert_before("/* End PBXFrameworksBuildPhase section */", (
    f"{T*2}{ID['frameworks']} /* Frameworks */ = {{\n"
    f"{T*3}isa = PBXFrameworksBuildPhase;\n"
    f"{T*3}buildActionMask = 2147483647;\n"
    f"{T*3}files = (\n"
    f"{T*3});\n"
    f"{T*3}runOnlyForDeploymentPostprocessing = 0;\n"
    f"{T*2}}};\n"
))

# Main group + Products group
insert_before(f"{T*4}CE9F9B4A300B846500BB12BB /* Products */,\n",
              f"{T*4}{ID['group']} /* iLoveWorksWatch */,\n")
insert_after(f"{T*4}CE9F9B90300B846700BB12BB /* iLoveWorksWidgets.appex */,\n",
             f"{T*4}{ID['product']} /* iLoveWorksWatch.app */,\n")

# iOS app: embed phase + dependency
insert_after(f"{T*4}CE9F9B9D300B846700BB12BB /* Embed Foundation Extensions */,\n",
             f"{T*4}{ID['embedphase']} /* Embed Watch Content */,\n")
insert_after(f"{T*4}CE9F9B9C300B846700BB12BB /* PBXTargetDependency */,\n",
             f"{T*4}{ID['dependency']} /* PBXTargetDependency */,\n")

# Native target
insert_before("/* End PBXNativeTarget section */", (
    f"{T*2}{ID['target']} /* iLoveWorksWatch */ = {{\n"
    f"{T*3}isa = PBXNativeTarget;\n"
    f'{T*3}buildConfigurationList = {ID["configlist"]} /* Build configuration list for PBXNativeTarget "iLoveWorksWatch" */;\n'
    f"{T*3}buildPhases = (\n"
    f"{T*4}{ID['sources']} /* Sources */,\n"
    f"{T*4}{ID['frameworks']} /* Frameworks */,\n"
    f"{T*4}{ID['resources']} /* Resources */,\n"
    f"{T*3});\n"
    f"{T*3}buildRules = (\n"
    f"{T*3});\n"
    f"{T*3}dependencies = (\n"
    f"{T*3});\n"
    f"{T*3}fileSystemSynchronizedGroups = (\n"
    f"{T*4}{ID['group']} /* iLoveWorksWatch */,\n"
    f"{T*3});\n"
    f"{T*3}name = iLoveWorksWatch;\n"
    f"{T*3}packageProductDependencies = (\n"
    f"{T*3});\n"
    f"{T*3}productName = iLoveWorksWatch;\n"
    f"{T*3}productReference = {ID['product']} /* iLoveWorksWatch.app */;\n"
    f'{T*3}productType = "com.apple.product-type.application";\n'
    f"{T*2}}};\n"
))

# Project attributes + target list
insert_after(f"{T*5}CE9F9B91300B846700BB12BB = {{\n{T*6}CreatedOnToolsVersion = 26.6;\n{T*5}}};\n",
             f"{T*5}{ID['target']} = {{\n{T*6}CreatedOnToolsVersion = 26.6;\n{T*5}}};\n")
src = src.replace(
    f"{T*4}CE9F9B91300B846700BB12BB /* iLoveWorksWidgets */,\n{T*3});\n{T*2}}};\n/* End PBXProject section */",
    f"{T*4}CE9F9B91300B846700BB12BB /* iLoveWorksWidgets */,\n{T*4}{ID['target']} /* iLoveWorksWatch */,\n{T*3});\n{T*2}}};\n/* End PBXProject section */",
)

# Resources + Sources phases
for key, isa, end in (("resources", "PBXResourcesBuildPhase", "/* End PBXResourcesBuildPhase section */"),
                      ("sources", "PBXSourcesBuildPhase", "/* End PBXSourcesBuildPhase section */")):
    name = "Resources" if key == "resources" else "Sources"
    insert_before(end, (
        f"{T*2}{ID[key]} /* {name} */ = {{\n"
        f"{T*3}isa = {isa};\n"
        f"{T*3}buildActionMask = 2147483647;\n"
        f"{T*3}files = (\n"
        f"{T*3});\n"
        f"{T*3}runOnlyForDeploymentPostprocessing = 0;\n"
        f"{T*2}}};\n"
    ))

# Target dependency (iOS app -> Watch app)
insert_before("/* End PBXTargetDependency section */", (
    f"{T*2}{ID['dependency']} /* PBXTargetDependency */ = {{\n"
    f"{T*3}isa = PBXTargetDependency;\n"
    f"{T*3}platformFilter = ios;\n"
    f"{T*3}target = {ID['target']} /* iLoveWorksWatch */;\n"
    f"{T*3}targetProxy = {ID['proxy']} /* PBXContainerItemProxy */;\n"
    f"{T*2}}};\n"
))

# Build configurations
insert_before("/* End XCBuildConfiguration section */", (
    f"{T*2}{ID['debug']} /* Debug */ = {{\n"
    f"{T*3}isa = XCBuildConfiguration;\n"
    f"{T*3}buildSettings = {{\n{settings(True)}{T*3}}};\n"
    f"{T*3}name = Debug;\n"
    f"{T*2}}};\n"
    f"{T*2}{ID['release']} /* Release */ = {{\n"
    f"{T*3}isa = XCBuildConfiguration;\n"
    f"{T*3}buildSettings = {{\n{settings(False)}{T*3}}};\n"
    f"{T*3}name = Release;\n"
    f"{T*2}}};\n"
))

insert_before("/* End XCConfigurationList section */", (
    f'{T*2}{ID["configlist"]} /* Build configuration list for PBXNativeTarget "iLoveWorksWatch" */ = {{\n'
    f"{T*3}isa = XCConfigurationList;\n"
    f"{T*3}buildConfigurations = (\n"
    f"{T*4}{ID['debug']} /* Debug */,\n"
    f"{T*4}{ID['release']} /* Release */,\n"
    f"{T*3});\n"
    f"{T*3}defaultConfigurationIsVisible = 0;\n"
    f"{T*3}defaultConfigurationName = Release;\n"
    f"{T*2}}};\n"
))

open(PATH, "w").write(src)
print("Watch target added:", ID["target"])
