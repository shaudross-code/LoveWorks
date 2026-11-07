import json

path = "iLoveWorks/Assets.xcassets/AppIcon.appiconset/Contents.json"
with open(path, "r") as f:
    data = json.load(f)

new_images = []
for img in data.get("images", []):
    if "appearances" in img and "filename" not in img:
        continue # Skip the empty placeholders that cause App Store Connect issues
    new_images.append(img)

# Just in case, ensure there's an explicit app store icon fallback for Older App Store Connect API
# The iOS universal size works for iOS 11+, but App Store connect specifically extracts the 1024x1024 image.
# Usually single size covers it, but let's make sure the array is clean.
data["images"] = new_images

with open(path, "w") as f:
    json.dump(data, f, indent=2)

