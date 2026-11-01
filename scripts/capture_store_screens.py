"""
Regenerate ALL store screenshots (App Store + Google Play) from the sandboxed reviewer/demo accounts.

Profiles (exact store sizes):
  iphone_6.9   430x932  @3   -> 1290x2796  (/app/appstore_screenshots)
  ipad_13      1032x1376 @2  -> 2064x2752  (/app/appstore_screenshots/ipad_13)
  play_phone   360x640  @3   -> 1080x1920  (/app/playstore_assets/phone)
  tablet_7in   720x1280 @1.5 -> 1080x1920  (/app/playstore_assets/tablet_7in)
  tablet_10in  810x1440 @2   -> 1620x2880  (/app/playstore_assets/tablet_10in)

The look is forced PER BROWSER TAB via sessionStorage.forceTheme (read by ThemeContext) — nothing in the
database changes, so the crew's live theme is never affected. Main set = default gold look; a small
"seasonal_halloween" set is captured with the Halloween look.
"""
import asyncio
import os
import shutil
from playwright.async_api import async_playwright

BASE = os.environ.get("APP_URL", "https://labor-admin-hub.preview.emergentagent.com")
API = f"{BASE}/api"
ADMIN = ("reviewer@loveworks.com", "iLoveWorks2026!")
WORKER = ("demo@loveworks.com", "DemoWorker2026!")

PROFILES = [
    ("iphone_6.9", "/app/appstore_screenshots", {"width": 430, "height": 932}, 3, "ios"),
    ("ipad_13", "/app/appstore_screenshots/ipad_13", {"width": 1032, "height": 1376}, 2, "ios"),
    ("play_phone", "/app/playstore_assets/phone", {"width": 360, "height": 640}, 3, "android"),
    ("tablet_7in", "/app/playstore_assets/tablet_7in", {"width": 720, "height": 1280}, 1.5, "android"),
    ("tablet_10in", "/app/playstore_assets/tablet_10in", {"width": 810, "height": 1440}, 2, "android"),
]
UA = {
    "ios": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
    "android": "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36",
}

ADMIN_SCREENS = [
    ("01_admin_overview", "/admin", None),
    ("02_workers", "/admin/workers", None),
    ("02b_worker_sizes_admin", "/admin/workers", "sizes_dialog"),
    ("03_tasks", "/admin/tasks", None),
    ("04_goals", "/admin/goals", None),
    ("05_trips", "/admin/trips", None),
    ("06_essentials", "/admin/essentials", None),
    ("07_payroll", "/admin/payroll", None),
    ("08_announcements", "/admin/announcements", None),
    ("09_admin_profile", "/admin/profile", None),
]
WORKER_SCREENS = [
    ("10_worker_home", "/worker", None),
    ("11_worker_history", "/worker/history", None),
    ("12_worker_awards", "/worker/awards", None),
    ("13_worker_trips", "/worker/trips", None),
    ("14_worker_essentials", "/worker/essentials", None),
    ("15_worker_announcements", "/worker/announcements", None),
    ("16_my_sizes", "/worker/sizes", None),
    ("17_measure_guide", "/worker/sizes", "measure_guide"),
    ("18_worker_profile", "/worker/profile", None),
]
SEASONAL = [("10_worker_home", "/worker", None), ("16_my_sizes", "/worker/sizes", None)]


async def login(page, context, creds):
    await context.clear_cookies()
    await page.goto(f"{BASE}/login", wait_until="domcontentloaded", timeout=60000)
    await page.evaluate("localStorage.clear(); sessionStorage.clear();")
    await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=60000)
    await page.wait_for_selector('input[type="email"]', timeout=20000)
    await page.fill('input[type="email"]', creds[0])
    await page.fill('input[type="password"]', creds[1])
    await page.click('button[type="submit"]')
    await page.wait_for_timeout(4000)


async def do_action(page, action):
    if action == "sizes_dialog":
        await page.locator('[data-testid^="sizes-worker-"]').first.click()
        await page.wait_for_selector('[data-testid="worker-sizes-dialog"]', timeout=15000)
        await page.wait_for_timeout(1500)
    elif action == "measure_guide":
        await page.click('[data-testid="open-measure-guide"]')
        await page.wait_for_selector('[data-testid="measure-guide-image"]', timeout=15000)
        await page.wait_for_timeout(1500)


async def shot(page, out_dir, name, url, action=None):
    await page.goto(f"{BASE}{url}", wait_until="networkidle", timeout=60000)
    await page.wait_for_timeout(2200)
    await page.evaluate("window.scrollTo(0, 0)")
    if action:
        await do_action(page, action)
    await page.wait_for_timeout(500)
    await page.screenshot(path=os.path.join(out_dir, f"{name}.png"), full_page=False, type="png")
    print(f"  ✓ {name}")


async def capture_profile(p, key, out_dir, viewport, scale, kind, seasonal=False, theme="default"):
    os.makedirs(out_dir, exist_ok=True)
    browser = await p.chromium.launch(headless=True)
    context = await browser.new_context(viewport=viewport, device_scale_factor=scale, is_mobile=kind != "tablet",
                                        has_touch=True, user_agent=UA[kind], reduced_motion="reduce")
    await context.add_init_script(f"sessionStorage.setItem('forceTheme', '{theme}')")
    page = await context.new_page()
    print(f"▶ {key} -> {out_dir}")
    if seasonal:
        await login(page, context, WORKER)
        for name, url, action in SEASONAL:
            await shot(page, out_dir, name, url, action)
    else:
        await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=60000)
        await page.wait_for_timeout(1500)
        await page.screenshot(path=os.path.join(out_dir, "00_login.png"), full_page=False, type="png")
        print("  ✓ 00_login")
        await login(page, context, ADMIN)
        for name, url, action in ADMIN_SCREENS:
            await shot(page, out_dir, name, url, action)
        await login(page, context, WORKER)
        for name, url, action in WORKER_SCREENS:
            await shot(page, out_dir, name, url, action)
    await browser.close()


async def main():
    for _, out_dir, *_rest in PROFILES:
        if os.path.isdir(out_dir):
            for f in os.listdir(out_dir):
                fp = os.path.join(out_dir, f)
                if f.endswith(".png"):
                    os.remove(fp)
    async with async_playwright() as p:
        for key, out_dir, viewport, scale, kind in PROFILES:
            await capture_profile(p, key, out_dir, viewport, scale, kind)
        for key, out_dir, viewport, scale, kind in PROFILES[:1] + PROFILES[2:3]:
            await capture_profile(p, key, os.path.join(out_dir, "seasonal_halloween"), viewport, scale, kind, seasonal=True, theme="halloween")
    print("\n✅ All store screenshots regenerated")


if __name__ == "__main__":
    asyncio.run(main())
