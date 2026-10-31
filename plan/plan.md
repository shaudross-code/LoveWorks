# My Sizes — Body Measurements & Clothing Sizes Tab

A new "My Sizes" tab in iLoveWorks where each person records their body measurements, shoe size, clothing sizes and gender-relevant underclothes sizes once, saved to their account so it follows them to any phone or computer they sign in on. Admins can view and correct any worker's sizes when ordering uniforms, boots and gear, and the worker is told when an admin changes something.

## Who it's for

- **Workers** — enter and keep their own sizes up to date; everything is optional and can be filled in gradually.
- **Admins** — view and edit any worker's full sizing profile (including underclothes) from the Workers page so workwear orders fit the first time. Admins also get their own My Sizes tab for themselves.

## Core features and experience

**1. Sizing profile basics**
- Fit / gender choice: *Men's*, *Women's*, or *Prefer not to say*. This decides which clothing and underclothes fields appear.
- Units toggle: *Imperial* (in, lb, US shoe) or *Metric* (cm, kg, EU shoe). Values are converted automatically when the toggle changes; the choice is remembered per user.
- "Last updated" line at the top showing the date and who made the change (the worker themself or an admin by name); a gentle reminder badge appears when sizes are older than 12 months.

**2. Body measurements** (all optional)
Height, weight, neck, shoulder width, chest/bust, waist, hips, sleeve length, inseam, head circumference (hats / hard hats), hand circumference (gloves).

**3. Footwear**
Shoe size (entered in US, EU or UK — the other two shown automatically), width (Narrow / Regular / Wide / Extra wide), and a note field for boot preferences (steel toe, high-top, etc.).

**4. Workwear & clothing sizes**
Top / T-shirt (XS–4XL), jacket / outerwear, pants (waist × inseam or letter size), gloves (XS–XXL), hat size, hi-vis vest size. Letter sizes use a tap-to-pick chip row rather than typing.

**5. Underclothes — gender-relevant**
- *Men's*: underwear style (Briefs / Boxers / Boxer briefs / Trunks) and size, undershirt size, sock size.
- *Women's*: bra band and cup, sports bra size, underwear style (Briefs / Bikini / Boyshort / Thong) and size, leggings / base-layer size, sock / hosiery size.
- *Prefer not to say*: underwear size, base-layer size, sock size (no gendered fields).
- Fully visible to the admin alongside every other section — no hidden or opt-in parts.

**6. Fit notes**
Free-text for anything that doesn't fit a box (long torso, prefers loose fit, fabric sensitivities).

**7. Visibility**
- The whole sizing profile — body, footwear, workwear, underclothes and notes — is visible to the admin. The worker's page says so plainly ("Your admin can see and update these to order your gear").
- Workers cannot see each other's sizes.
- Workers can clear all their own sizes with one action.

**8. Admin view & edit**
- On the Workers page each worker gets a **Sizes** button opening the same sizing form the worker sees, editable, with a units toggle and the last-updated line.
- The admin saves changes; only fields that actually changed are recorded.
- A **"Notify worker"** switch sits next to Save, on by default. With it on, the worker receives an in-app notification (bell) — and a push notification where push is already enabled — saying which sizes were updated and by whom (e.g. "Alex updated your sizes: Boot size 10 → 10.5, Gloves L → XL"). The admin can switch it off for trivial corrections (typo fixes) so the worker is not pinged unnecessarily.
- Nothing is sent when the admin saves without changing anything.
- A worker with nothing entered shows "No sizes recorded yet" and the admin can start filling it in on their behalf.

**9. What's new announcement**
When the feature ships, a "What's new" announcement is posted telling the crew the My Sizes tab exists and why (better-fitting gear), per the standing rule that every feature update gets an announcement.

## User flow

**Worker**
1. Taps **My Sizes** in the navigation (placed just before Profile, on both the desktop bar and the mobile scrolling pills).
2. Picks fit/gender and units on first visit; the right sections appear.
3. Opens any section (collapsible cards: Body · Footwear · Workwear · Underclothes · Fit notes), taps chips or types numbers, and taps **Save**. A toast confirms; "Last updated" refreshes.
4. Returns from any device — values are already there and editable.
5. If an admin changed something, a notification appears in the bell (and as a push where enabled); tapping it opens My Sizes with the changed fields briefly highlighted.

**Admin**
1. Opens **Workers**, taps **Sizes** on a worker card.
2. Reviews or edits any section, switches units if needed, decides whether "Notify worker" stays on, and taps **Save**.
3. The worker is notified of the exact changes (unless the switch was turned off).
4. Also has a **My Sizes** tab of their own with the same experience.

## UI/UX feel

- Matches the existing iLoveWorks look: near-black background, gold brand accent, pink highlight for the active tab, same card and pill styling as Essentials and Profile.
- Sections are collapsible cards with a small completion indicator (e.g. "4 of 11 filled") so the page never feels like a long form.
- Letter sizes and styles are chip selectors; numeric fields have unit suffixes and large tap targets for phones.
- Imperial/metric and shoe-size conversions happen live, with the equivalents shown in muted text under the field.
- The admin editing panel is visually tagged "Editing as admin" so it is never confused with the admin's own sizes.
- Works on the small phone layout first (safe-area aware, no header overlap) and scales to desktop as two columns.

## Implementation phases

**Phase 1 — MVP (built now)**
- My Sizes tab for workers and admins with gender/fit selector, units toggle, all five sections, live unit and shoe-size conversion, save/edit/clear, last-updated line with who changed it.
- Admin **Sizes** panel on the Workers page: full view and edit of every section, "Notify worker" switch (default on), change-aware notification to the worker (in-app bell + push where enabled).
- "What's new" announcement posted on release.

**Phase 2**
- Crew Sizes table on the admin side: all workers' sizes in one sortable view with a CSV export for bulk uniform orders.
- Admin can request a worker to confirm or update stale sizes (sends an in-app notification).
- Size-change history per worker ("was L in Jan, now XL — changed by Alex").

**Phase 3**
- Gear order helper: pick items (boots, hi-vis, gloves) and auto-fill quantities per size across the crew.
- Optional measurement photos / fit guide illustrations showing where to measure.
- Brand-specific size charts (e.g. map a chest measurement to a specific boot or workwear brand's size).

## Assumptions

- The tab is named **My Sizes** and sits before Profile in the worker and admin navigation; it is a standalone tab rather than a section inside Profile.
- Imperial is the default unit system (the app already uses US dollars and US-style payroll); metric is one tap away.
- Gender is captured only as a *fit* choice (Men's / Women's / Prefer not to say) to drive which size fields show; it is not added to the worker's general profile or shown elsewhere.
- The entire sizing profile, including underclothes, is visible to and editable by the admin. Workers cannot see each other's sizes.
- The worker notification is sent automatically on any admin save that changes at least one value, unless the admin turns off "Notify worker" for that save. It lists the changed fields with old → new values. A worker editing their own sizes does not trigger a notification to anyone.
- Every field is optional; partial saves are fine; nothing is required to use the rest of the app.
- Shoe sizes are converted between US / EU / UK with standard men's and women's conversion tables (Prefer not to say uses the men's table).
- Reviewer / demo sandbox accounts get sample sizes so App Store / Play reviewers can see the tab populated.
- The web app and preview get the feature immediately; the iOS and Android apps pick it up on the next native build and store update.
- The 12-month "update your sizes" reminder is a badge on the tab only — no push or email in this phase.
