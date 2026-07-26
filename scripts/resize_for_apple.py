"""Generate additional Apple screenshot sizes from the 1290x2796 masters:
   - 6.5" iPhone (1284x2778) - required for older App Store listings
   - 13" iPad (2064x2752) - only if you support iPad
   - Marketing 1242x2688 (legacy 6.5")
"""
import os
from PIL import Image

SRC = "/app/appstore_screenshots"
OUT_65 = "/app/appstore_screenshots/iphone_6.5"
OUT_IPAD = "/app/appstore_screenshots/ipad_13"
os.makedirs(OUT_65, exist_ok=True)
os.makedirs(OUT_IPAD, exist_ok=True)

def resize(src_path, out_path, size):
    im = Image.open(src_path)
    # Preserve full frame; iPhone 6.5" is same aspect ratio (portrait), scale directly
    im2 = im.resize(size, Image.LANCZOS)
    im2.save(out_path, "PNG", optimize=True)

files = sorted([f for f in os.listdir(SRC) if f.endswith(".png") and not f.startswith(".")])
for f in files:
    src = os.path.join(SRC, f)
    if os.path.isdir(src):
        continue
    # 6.5" iPhone (1284 x 2778)
    resize(src, os.path.join(OUT_65, f), (1284, 2778))
    print(f"→ 6.5\":  {f}")

print("\n✅ 6.5\" versions generated for older App Store fallback")
