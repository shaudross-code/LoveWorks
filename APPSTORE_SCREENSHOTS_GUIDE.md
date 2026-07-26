# 📱 App Store Screenshot Submission Guide — iLoveWorks

All screenshots captured live from the sandboxed reviewer/demo accounts. **All data is demo-safe** (no real user PII).

---

## 📐 Specs

| Item | Value |
|---|---|
| **Resolution** | 1290 × 2796 px (portrait) |
| **Device class** | iPhone 6.9" (iPhone 16/15 Pro Max) — Apple's primary required size |
| **Format** | PNG, RGB, no alpha |
| **Total captured** | 18 screens (admin + worker flows) |
| **Location** | `/app/appstore_screenshots/*.png` |
| **6.5" fallback** | `/app/appstore_screenshots/iphone_6.5/*.png` (1284 × 2778 — for older listings) |

---

## 🏆 Recommended Upload Order (7 Best — Maximum Conversion)

Upload these in **this exact order** to App Store Connect → your app → App Store tab → *iOS 6.9" Display*:

| # | File | What It Shows | Caption Suggestion (optional overlay) |
|---|---|---|---|
| 1 | **`10_worker_home.png`** | Clock-in button, shift timer, earnings | *"Clock in with a single tap"* |
| 2 | **`03_tasks.png`** | Tasks with prices, completion states | *"Every task pays. Every second counts."* |
| 3 | **`01_admin_overview.png`** | Admin dashboard, live stats, payroll | *"Oversee your whole crew at a glance"* |
| 4 | **`04_goals.png`** | Goals with progress bars, allocations | *"Save toward what actually matters"* |
| 5 | **`13_worker_trips.png`** | Trips list with allocated $ | *"Plan trips your crew is actually saving for"* |
| 6 | **`12_worker_awards.png`** | Achievement medals & progress | *"Earn medals for every milestone"* |
| 7 | **`07_payroll.png`** | Total payroll due, hours, per-worker | *"Payroll math done for you"* |

> **Why this order?** First screenshot is the highest-converting. `10_worker_home.png` shows the golden Clock-in button — the primary user action — instantly conveying what the app does.

---

## 📁 Complete Screenshot Inventory

### Admin (reviewer@loveworks.com — sandbox)
| File | Screen |
|---|---|
| `00_login.png` | Login screen |
| `01_admin_overview.png` | Admin dashboard (top) |
| `01b_admin_overview_scroll.png` | Admin dashboard (earnings + workers section) |
| `02_workers.png` | Worker roster with live status |
| `03_tasks.png` | Task management |
| `04_goals.png` | Goals with allocations |
| `05_trips.png` | Trips tracker |
| `06_essentials.png` | Household essentials list |
| `07_payroll.png` | Payroll totals |
| `08_announcements.png` | Team announcements |
| `09_admin_profile.png` | Admin profile |

### Worker (demo@loveworks.com — sandbox)
| File | Screen |
|---|---|
| `10_worker_home.png` | Clock-in home |
| `11_worker_history.png` | Time entries log |
| `12_worker_awards.png` | Trophy case / medals |
| `13_worker_trips.png` | Personal trips |
| `14_worker_essentials.png` | Shopping list |
| `15_worker_announcements.png` | Notifications |
| `16_worker_profile.png` | Worker profile |

---

## ⬇️ How to Download the Files

From your development machine:
```bash
# If working on remote/container, download via git or the Emergent file manager
# Then locate: /app/appstore_screenshots/
```

**On the Emergent platform:** open the file browser → navigate to `/app/appstore_screenshots/` → select all → download zip.

**Or use scp/rsync** from your Mac:
```bash
scp -r your-container:/app/appstore_screenshots ~/Desktop/
```

---

## 📤 How to Upload to App Store Connect

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps** → **iLoveWorks** → **App Store** tab
3. Under *iOS App*, choose your version → scroll to **App Previews and Screenshots**
4. Select **iPhone 6.9" Display** (this is now the **required** primary size)
5. Drag & drop the 7 recommended PNGs in order (or up to 10 max)
6. Repeat for **iPhone 6.5" Display** if you want to support older screens (use files from `/iphone_6.5/`)
7. Click **Save**

> **Tip:** Apple auto-generates the 6.7", 6.1", and older sizes from your 6.9" upload — you usually **only need to upload the 6.9" set**.

---

## 🎨 Optional: Add Marketing Text Overlays

For an extra 20-30% download conversion, add bold captions to each screenshot before uploading. Tools:
- **[Screenshots.pro](https://screenshots.pro/)** — free, drag-drop, App Store templates built in
- **Fastlane frameit** — automated, developer-friendly
- **Figma** — full control, use captions from the table above

If you want, I can generate a Python script that overlays the recommended captions directly onto your PNGs — just say the word.

---

## ✅ Data Safety Confirmation

Every screenshot was captured through the **sandbox-isolated** reviewer and demo accounts. Contents:
- No real user emails, names, or PII
- Sample workers named "Demo Worker"
- Placeholder task titles ("Water the plants", "Fold the laundry")
- Fake payroll totals ($13, $60, etc.)

Safe to submit to Apple, Google Play, and use in marketing.
