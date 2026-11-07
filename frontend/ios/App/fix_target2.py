import re
with open("App.xcodeproj/project.pbxproj", "r") as f:
    text = f.read()

# Fix the targets not having supported platforms natively set which breaks Xcode 16 sim builds
text = re.sub(
    r'([ \t]+)SDKROOT = iphoneos;', 
    r'\1SDKROOT = iphoneos;\n\1SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";\n\1TARGETED_DEVICE_FAMILY = "1,2";', 
    text
)

with open("App.xcodeproj/project.pbxproj", "w") as f:
    f.write(text)
