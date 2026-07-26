"""
Capture high-quality App Store screenshots at Apple 6.9" iPhone spec.
- Native size: 430 x 932 pt with device_scale_factor=3 → PNG output 1290 x 2796 (Apple's required resolution).
- Uses sandboxed reviewer/demo accounts so all data is safe for review.
"""
import asyncio
import os
from playwright.async_api import async_playwright

BASE = os.environ.get("APP_URL", "https://labor-admin-hub.preview.emergentagent.com")
OUT = "/app/appstore_screenshots"
os.makedirs(OUT, exist_ok=True)

ADMIN_EMAIL = "reviewer@loveworks.com"
ADMIN_PASS = "iLoveWorks2026!"
WORKER_EMAIL = "demo@loveworks.com"
WORKER_PASS = "DemoWorker2026!"


async def login(page, email, password):
    # Force to login page and clear any stale session
    await page.goto(f"{BASE}/login", wait_until="domcontentloaded", timeout=45000)
    await page.evaluate("localStorage.clear(); sessionStorage.clear();")
    await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=45000)
    await page.wait_for_selector('input[type="email"]', timeout=15000)
    await page.wait_for_timeout(800)
    await page.fill('input[type="email"]', email)
    await page.fill('input[type="password"]', password)
    await page.click('button[type="submit"]')
    await page.wait_for_timeout(4500)


async def shot(page, url, filename, scroll_y=0, wait_extra=0):
    await page.goto(f"{BASE}{url}", wait_until="networkidle", timeout=45000)
    await page.wait_for_timeout(2500 + wait_extra)
    await page.evaluate(f"window.scrollTo(0, {scroll_y})")
    await page.wait_for_timeout(600)
    path = os.path.join(OUT, filename)
    await page.screenshot(path=path, full_page=False, type="png")
    print(f"✓ {filename}")


async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        # Apple 6.9" iPhone Pro Max: 1290 x 2796 px = 430 x 932 pt @ 3x
        context = await browser.new_context(
            viewport={"width": 430, "height": 932},
            device_scale_factor=3,
            is_mobile=True,
            has_touch=True,
            user_agent="Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
        )
        page = await context.new_page()

        # ---- LOGIN SCREEN (unauthenticated) ----
        await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=45000)
        await page.wait_for_timeout(2000)
        await page.screenshot(path=os.path.join(OUT, "00_login.png"), full_page=False, type="png")
        print("✓ 00_login.png")

        # ---- ADMIN FLOWS (reviewer sandbox) ----
        await login(page, ADMIN_EMAIL, ADMIN_PASS)

        await shot(page, "/admin", "01_admin_overview.png")
        await shot(page, "/admin", "01b_admin_overview_scroll.png", scroll_y=500)
        await shot(page, "/admin/workers", "02_workers.png")
        await shot(page, "/admin/tasks", "03_tasks.png")
        await shot(page, "/admin/goals", "04_goals.png")
        await shot(page, "/admin/trips", "05_trips.png")
        await shot(page, "/admin/essentials", "06_essentials.png")
        await shot(page, "/admin/payroll", "07_payroll.png")
        await shot(page, "/admin/announcements", "08_announcements.png")
        await shot(page, "/admin/profile", "09_admin_profile.png")

        # ---- WORKER FLOWS (demo sandbox) ----
        await page.evaluate("localStorage.clear(); sessionStorage.clear();")
        await login(page, WORKER_EMAIL, WORKER_PASS)

        await shot(page, "/worker", "10_worker_home.png", wait_extra=1000)
        await shot(page, "/worker/history", "11_worker_history.png")
        await shot(page, "/worker/awards", "12_worker_awards.png")
        await shot(page, "/worker/trips", "13_worker_trips.png")
        await shot(page, "/worker/essentials", "14_worker_essentials.png")
        await shot(page, "/worker/announcements", "15_worker_announcements.png")
        await shot(page, "/worker/profile", "16_worker_profile.png")

        await browser.close()
        print("\n✅ All screenshots saved to", OUT)


if __name__ == "__main__":
    asyncio.run(main())
