"""Capture only worker screenshots (admin already done)."""
import asyncio, os
from playwright.async_api import async_playwright

BASE = "https://labor-admin-hub.preview.emergentagent.com"
OUT = "/app/appstore_screenshots"

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            viewport={"width": 430, "height": 932},
            device_scale_factor=3,
            is_mobile=True,
            has_touch=True,
            user_agent="Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
        )
        page = await context.new_page()

        # Fresh login as worker
        await page.goto(f"{BASE}/login", wait_until="domcontentloaded", timeout=45000)
        await page.evaluate("localStorage.clear(); sessionStorage.clear();")
        await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=45000)
        await page.wait_for_selector('input[type="email"]', timeout=15000)
        await page.wait_for_timeout(1000)
        await page.fill('input[type="email"]', "demo@loveworks.com")
        await page.fill('input[type="password"]', "DemoWorker2026!")
        await page.click('button[type="submit"]')
        await page.wait_for_timeout(5000)
        print(f"Worker landed on: {page.url}")

        async def shot(url, filename, scroll_y=0, wait_extra=0):
            await page.goto(f"{BASE}{url}", wait_until="networkidle", timeout=45000)
            await page.wait_for_timeout(2500 + wait_extra)
            await page.evaluate(f"window.scrollTo(0, {scroll_y})")
            await page.wait_for_timeout(600)
            await page.screenshot(path=os.path.join(OUT, filename), full_page=False, type="png")
            print(f"✓ {filename}")

        await shot("/worker", "10_worker_home.png", wait_extra=1000)
        await shot("/worker/history", "11_worker_history.png")
        await shot("/worker/awards", "12_worker_awards.png")
        await shot("/worker/trips", "13_worker_trips.png")
        await shot("/worker/essentials", "14_worker_essentials.png")
        await shot("/worker/announcements", "15_worker_announcements.png")
        await shot("/worker/profile", "16_worker_profile.png")

        await browser.close()
        print("\n✅ Worker screenshots done")

asyncio.run(main())
