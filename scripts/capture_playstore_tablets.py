"""
Google Play tablet screenshots, exact 9:16.
- 7-inch:  viewport 720x1280 @1.5 -> 1080x1920
- 10-inch: viewport 810x1440 @2   -> 1620x2880
"""
import asyncio
import os
from playwright.async_api import async_playwright

BASE = os.environ.get("APP_URL", "https://labor-admin-hub.preview.emergentagent.com")

ADMIN = ("reviewer@loveworks.com", "iLoveWorks2026!")
WORKER = ("demo@loveworks.com", "DemoWorker2026!")

DEVICES = [
    ("tablet_7in", {"width": 720, "height": 1280}, 1.5),
    ("tablet_10in", {"width": 810, "height": 1440}, 2),
]


async def login(page, context, email, password):
    await page.goto(f"{BASE}/login", wait_until="domcontentloaded", timeout=45000)
    await page.evaluate("localStorage.clear(); sessionStorage.clear();")
    await context.clear_cookies()
    await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=45000)
    await page.wait_for_selector('input[type="email"]', timeout=15000)
    await page.wait_for_timeout(800)
    await page.fill('input[type="email"]', email)
    await page.fill('input[type="password"]', password)
    await page.click('button[type="submit"]')
    await page.wait_for_timeout(4500)


async def shot(page, out, url, filename, wait_extra=0):
    await page.goto(f"{BASE}{url}", wait_until="networkidle", timeout=45000)
    await page.wait_for_timeout(2500 + wait_extra)
    await page.screenshot(path=os.path.join(out, filename), full_page=False, type="png")
    print(f"✓ {out}/{filename}")


async def capture(p, name, viewport, dsf):
    out = f"/app/playstore_assets/{name}"
    os.makedirs(out, exist_ok=True)
    browser = await p.chromium.launch(headless=True)
    context = await browser.new_context(
        viewport=viewport, device_scale_factor=dsf, is_mobile=True, has_touch=True,
        user_agent="Mozilla/5.0 (Linux; Android 14; SM-X510) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    )
    page = await context.new_page()

    await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=45000)
    await page.wait_for_timeout(2000)
    await page.screenshot(path=os.path.join(out, "00_login.png"), full_page=False, type="png")
    print(f"✓ {out}/00_login.png")

    await login(page, context, *ADMIN)
    await shot(page, out, "/admin", "01_admin_overview.png")
    await shot(page, out, "/admin/tasks", "02_tasks.png")
    await shot(page, out, "/admin/goals", "03_goals.png")
    await shot(page, out, "/admin/payroll", "04_payroll.png")

    await login(page, context, *WORKER)
    await shot(page, out, "/worker", "05_worker_home.png", wait_extra=1000)
    await shot(page, out, "/worker/trips", "06_worker_trips.png")
    await shot(page, out, "/worker/essentials", "07_worker_essentials.png")

    await browser.close()


async def main():
    async with async_playwright() as p:
        for name, viewport, dsf in DEVICES:
            await capture(p, name, viewport, dsf)
    print("\n✅ Done")


if __name__ == "__main__":
    asyncio.run(main())
