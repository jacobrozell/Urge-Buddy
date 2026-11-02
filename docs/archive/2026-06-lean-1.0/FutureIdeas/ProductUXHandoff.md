# Product & UX Handoff — TrackBoth

Handoff from a product/UX review session (2026-06-21). Captures improvement ideas and **decisions Jacob needs to make** before implementation. Follow-up agent or future session should read this first, then confirm decisions with Jacob before changing `ProductSurface` or ship scope.

> Last updated: 2026-06-21 · Stage: Pre-ship RC (1.0.0 build 3) · branch `main`  
> **Status:** Decisions locked · P0 implementation done 2026-06-21

**Related:** [backlog.md](backlog.md) · [competitive-strategy.md](../docs/product/competitive-strategy.md) · [feature-inventory.md](../docs/feature-inventory.md) · [lean-1.0-master-plan.md](../docs/release/lean-1.0-master-plan.md) · [ProductSurfaceSpec.md](../Specs/ProductSurfaceSpec.md)

---

## Executive summary

TrackBoth’s wedge is **dual habit + vice tracking in one honest daily log** — not a quit-only app. Engineering is strong (`TrackingSemantics`, adaptive layouts, onboarding presets, export, 166+ unit tests).

**Blocker resolved (2026-06-21):** Jacob locked ship surface — lean hybrid with polished features ungated. See **Decisions** below and `ProductSurface.swift`.

---

## Decisions — locked 2026-06-21

| # | Decision | Jacob's answer |
|---|----------|----------------|
| 1 | Ship surface | **Hybrid lean 1.0** — ungate polished features for a complete app; nothing unpolished |
| 2 | Goals | **Show progress on Track rows** (not Goals tab in Release) |
| 3 | Vice rows | **Slip timer + full metadata** (savings, goals progress, quantity) |
| 4 | Milestones | **Ship in 1.0** |
| 5 | Charts | **Charts tab** — line, bar, heatmap only; quantity chart dev-only |
| 6 | App Store copy | **Yes, copy tweaks** for redesigned UI; screenshots deferred |
| 7 | Motivations | **Full Motivation tab** (I Am Sober-style relapse prevention) |
| 8 | Onboarding skip | **Allow skip** — create placeholder rows (`My habit` / `My vice`) |
| 9 | Monetization | **Free always** — no Pro tier |

### Release tab bar (implemented)

**Track · History · Motivation · Charts · Settings** (5 tabs)  
Goals tab = dev only · Quantity charts = dev only

### Implemented 2026-06-21

- `ProductSurface.swift` — ship flags per table above
- `TrackMetricRow.swift` — extended metadata on compact rows
- `ChartModels.swift` / `ChartControlsView.swift` — quantity chart gated
- `OnboardingView.swift` — placeholder metrics on skip; copy tweaks
- `MetricPreset.swift` — `onboardingPlaceholders`
- `docs/release/app-store-copy.md` — listing copy (screenshots TBD)
- `Specs/ProductSurfaceSpec.md` — aligned matrix
- Tests updated (`ProductSurfaceTests`, `TrackBothUITests`, `MetricPresetTests`)

### Still open (P1 backlog)

- App Store screenshots
- Device QA + 7-day dogfood
- Hosted privacy URL + Connect questionnaires
- Quantity charts QA (dev-only until pass)

### Done 2026-06-21 (release prep)

- Hero streak display on Track rows
- Week calendar completion dots
- Motivational progress subtitle + stats grid vice icon
- Slip-moment motivation in LoggingSheet
- Tab order: Track · History · Motivation · Charts · Settings
- Widget embed removed from main app target
- Docs aligned: feature-inventory, core-scope, ship checklist, README

---

## Decisions for Jacob (archived — answered above)

### Decision 1 — Ship surface for 1.0 App Store ⭐ **P0**

| Option | Tabs in Release | Positioning |
|--------|-----------------|-------------|
| **A. Confidence 1.0** (current code) | Track · History · Settings | Simplicity, daily log + history, dual-tracking clarity |
| **B. Lean 1.0** (docs/specs) | Track · Goals · History · Charts · Motivation · Settings | Breadth vs Clean Slate; “patterns + goals + why” |
| **C. Hybrid** | Track · History · Settings + selective re-enable | e.g. Charts OR inline goal progress, not full 6-tab |

**Implications**

- **A:** Fastest to ship; must make Track + History carry “progress” and vice differentiation without hidden tabs.
- **B:** Aligns docs, screenshots, QA; 6 tabs on iPhone may need UX pass; more TestFlight surface area.
- **C:** Requires explicit list of which `ProductSurface` flags flip to `true` in Release.

**Files to change after decision:** `TrackBoth/Support/Release/ProductSurface.swift`, `docs/feature-inventory.md`, `Specs/ProductSurfaceSpec.md`, `docs/release/1.0.0-core-scope.md`, App Store screenshots/copy.

**Jacob’s answer:** **Hybrid lean 1.0** — polished features ungated; Goals tab stays dev-only.

---

### Decision 2 — Invisible goals ⭐ **P0**

Onboarding creates monthly boolean goals (`MetricPresetFactory`) but Goals tab is hidden in Release.

| Option | Action |
|--------|--------|
| **A. Stop creating goals** in Release until Goals UI ships | No phantom data |
| **B. Show goal progress inline** on Track rows (e.g. `18/30 this month`) | Re-enable `showsExtendedRowMetadata` for goals only, or subset |
| **C. Re-enable Goals tab** (ties to Decision 1B) | Full goals surface |

**Jacob’s answer:** **B** — Show goal progress inline on Track rows; Goals tab dev-only.

---

### Decision 3 — Vice differentiation in Release ⭐ **P1**

Money saved, slip recovery timer, and extended row metadata exist but are gated (`showsExtendedRowMetadata == false` in Release).

| Option | What ships on vice rows |
|--------|-------------------------|
| **A. Streak/clean only** (current Release) | Status + caption streak |
| **B. Streak + money saved** when `costPerUnit` set | Competitive vs Clean Slate |
| **C. B + optional slip timer** | Per-vice toggle in Edit; show on row when enabled |
| **D. Full extended metadata** | Goals progress + savings + slip + quantity on rows |

**Jacob’s answer:** **D** — Full extended metadata including slip timer.

---

### Decision 4 — Milestone celebrations in Release **P1**

`MilestoneEvaluator` + `MilestoneBannerView` built; `showsMilestoneBanners` is DEBUG-only.

| Option | Action |
|--------|--------|
| **A. Ship milestones in 1.0** | Enable in Release; 7–365 day thresholds |
| **B. Defer to 1.1** | Keep DEBUG-only for now |

**Jacob’s answer:** **A** — Ship milestones in 1.0.

---

### Decision 5 — Charts in Release **P1** (if not already decided in Decision 1)

Charts tab answers “patterns over months” — key differentiator vs quit-only apps.

| Option | Action |
|--------|--------|
| **A. Charts tab in 1.0** | Re-enable `showsCharts` in Release |
| **B. History-only progress** | Invest in calendar density, filters, entry context — no Charts tab |
| **C. Charts in 1.1** | Ship 3-tab now; charts as first post-1.0 feature |

**Jacob’s answer:** **A (subset)** — Charts tab with line, bar, heatmap; quantity chart dev-only.

---

### Decision 6 — Motivations in Release **P2**

Motivation library tied to vices is more actionable than a generic journal (per competitive strategy).

| Option | Action |
|--------|--------|
| **A. Motivation tab in 1.0** | Re-enable `showsMotivation` |
| **B. Slip-moment only** | Surface primary motivation in `LoggingSheet` on vice slip; no tab |
| **C. Defer to 1.1** | No motivation UI in 1.0 Release |

**Jacob’s answer:** **A** — Full Motivation tab (I Am Sober-style).

---

### Decision 7 — Onboarding empty path **P2**

If user selects zero presets, they land on empty Track + Add sheet.

| Option | Action |
|--------|--------|
| **A. Keep as-is** | Power users skip presets |
| **B. Soft minimum** | “Pick at least one” on Ready page |
| **C. Default suggestion** | Highlight “1 habit + 1 vice” on Ready page |

**Jacob’s answer:** **A + placeholders** — Allow skip; create `My habit` / `My vice` starter rows.

---

### Decision 8 — App Store positioning copy **P1**

| Field | Recommendation (from competitive strategy) |
|-------|------------------------------------------|
| Name | **TrackBoth** (one word) |
| Subtitle | **Habits & Vices** |
| Tagline | Build streaks. Track clean days. One daily log. |
| Screenshots | Must show **both** Habits and Vices sections on Track |

**Jacob’s answer:** Copy tweaks for redesigned UI — see [`docs/release/app-store-copy.md`](../docs/release/app-store-copy.md). Screenshots later.

---

### Decision 9 — Monetization (can defer past 1.0) **P3**

Suggested model from competitive strategy:

| Tier | Includes |
|------|----------|
| **Free** | Unlimited habits/vices, daily log, streaks, goals, basic motivations |
| **Pro** (~$9.99/yr or $1.99/mo) | iCloud sync, premium themes, advanced insights, export? |

Do not paywall the daily logging loop.

**Jacob’s answer:** **Free always** — no Pro tier.

---

## What to preserve (don’t regress)

These are the core wedge — amplify, don’t bury:

1. **Honest dual semantics** — `Domain/Tracking/TrackingSemantics.swift`; habit done = `true`, vice avoided = `false`; `hasBeenLogged` for streak eligibility.
2. **One-tap daily loop** — Track tab toggle → done; stats grid “Logged today X/Y”.
3. **Vice-specific UX** — shield / X icons, “Avoided it” copy in `LoggingSheet`.
4. **Onboarding creates real data** — preset chips → metrics (not empty home).
5. **Local-first + JSON export** — trust for sensitive vices.
6. **Tested streak math** — no phantom streaks; domain tests are a moat.

---

## Improvement backlog (by priority)

Implementation order assumes Jacob’s decisions above. Do not start P1+ until Decision 1–2 are answered.

### P0 — Align ship story

| # | Idea | Notes |
|---|------|-------|
| 1 | Resolve docs vs Release mismatch | `feature-inventory.md`, `1.0.0-core-scope.md`, `README.md` still describe 6-tab lean 1.0 |
| 2 | Fix invisible goals | Per Decision 2 |
| 3 | Rename drift cleanup | `HomeViewModel` → Track naming; specs still say “Home” tab |

### P1 — Lean into the wedge

| # | Idea | Notes |
|---|------|-------|
| 4 | **Bigger streak/clean display** on rows | Competitive strategy: hero number, not subheadline caption; `TrackMetricRow.swift` |
| 5 | **Milestone banners** in Release | `MilestoneEvaluator`, `MilestoneBannerView`; gated in `TrackScreen` |
| 6 | **Vice row metadata** in Release | Savings, slip timer; `extendedMetadataRow` in `TrackMetricRow.swift` |
| 7 | **Week calendar completion dots** | `TrackWeekCalendar.swift` — dots under days: all logged / partial / none |
| 8 | **Stats grid upgrades** | “3 of 5 done — 2 vices left”; tap-to-scroll to incomplete |
| 9 | **App Store assets** | Dual habit+vice screenshots; subtitle “Habits & Vices” |

### P2 — UX polish

| # | Idea | Notes |
|---|------|-------|
| 10 | **Slip-moment motivation** in `LoggingSheet` | When vice = slip, surface primary motivation (optional) |
| 11 | **History as progress surface** | Calendar density, discoverable filters, streak context on entry cards |
| 12 | **Onboarding copy sharpen** | “What do you want to **build**?” / “**break**?” — structure exists |
| 13 | **Onboarding empty path** | Per Decision 7 |
| 14 | **Vice icon tone** | Stats grid uses `xmark.circle.fill` red — consider shield / less punitive |
| 15 | **Edit mode discoverability** | Context menu exists; consider clearer “manage” affordance |
| 16 | **Re-view onboarding** | Settings already has it; add “Add more presets” shortcut? |
| 17 | **Deep link expansion** | `trackboth://` → Track only; future `trackboth://log/<metricId>` |

### P3 — Post-1.0 (don’t distract 1.0)

| # | Idea | Target | Notes |
|---|------|--------|-------|
| 18 | Home Screen Widget | 1.2 | Partial code; `FutureIdeas/backlog.md` |
| 19 | Onboarding preset expansion | 1.1 | Smoking, alcohol + quantity defaults |
| 20 | Smart notifications | 1.2 | Random motivation, opt-in |
| 21 | iCloud sync | TBD | `docs/plans/swiftdata-icloud-migration.md` |
| 22 | Optional “time since last slip” | 1.2 | Off by default; not second-precision timers |

### Explicitly skip (unless strategy pivots vice-first)

- Full achievement / badge cabinet
- Box breathing / 5-4-3-2-1 grounding tools
- Live second-precision streak timers as primary UI
- Motivation game, Watch (archived), gamification pile

---

## Current Release vs DEBUG (reference)

From `TrackBoth/Support/Release/ProductSurface.swift`:

| Flag | Release | DEBUG (no `-lean_ui`) |
|------|---------|------------------------|
| Tabs: Goals, Motivation, Charts | ❌ | ✅ |
| Milestone banners | ❌ | ✅ |
| Extended row metadata (goals, savings, slip) | ❌ | ✅ |
| Extended themes (4 vs 2) | ❌ | ✅ |
| Advanced metric setup | ❌ | ✅ |
| Extended logging upfront | ❌ | ✅ (or “More options”) |
| Widget | ❌ | ✅ |
| Demo data | ❌ | ✅ |

UI tests use `-lean_ui` to force Confidence 1.0 in DEBUG.

---

## Environment setup (follow-up agent)

```bash
cd ~/Desktop/personal/apps/UrgeBuddy/UrgeBuddy
xcodegen generate            # .xcodeproj is generated
```

Via XcodeBuildMCP (`session_set_defaults`):
- projectPath: `TrackBoth/TrackBoth/TrackBoth.xcodeproj`
- scheme: `TrackBoth` (Release surface) or `TrackBothCI` (tests)
- bundleId: (from `project.yml`)
- simulator: iPhone 17 or any iOS 18+ sim

Useful launch args:
- `-lean_ui` — force 3-tab Confidence surface in DEBUG
- `-skip_onboarding` — UI test bypass
- `-screenshot_demo` — deterministic demo data

Fresh-install: uninstall app, relaunch to see onboarding.

---

## Key implementation hooks

| Idea | Primary files |
|------|----------------|
| Ship surface gating | `Support/Release/ProductSurface.swift` |
| Track rows / streaks | `Features/Track/Components/TrackMetricRow.swift`, `Domain/Streaks/` |
| Week calendar | `Features/Track/Components/TrackWeekCalendar.swift` |
| Stats dashboard | `Features/Track/Components/TrackStatsGrid.swift` |
| Milestones | `Domain/Milestones/MilestoneEvaluator.swift`, `Components/Common/MilestoneBannerView.swift` |
| Logging / slip UX | `Components/Inputs/LoggingSheet.swift` |
| Onboarding | `Views/OnboardingView.swift`, preset factory |
| Tab shell | `Views/ContentView.swift` |
| Vice savings / slip | `Domain/Vice/`, `EditMetricView` |
| Competitive positioning | `docs/product/competitive-strategy.md` |

---

## Acceptance criteria (after decisions + implementation)

- Release build matches **documented** ship surface (no docs/code drift).
- No invisible user data (goals, savings config) without UI to see it.
- Track tab clearly shows **habits AND vices** as first-class sections.
- Streak/clean numbers feel like the reward (not buried metadata).
- Fresh install → onboarding → populated Track (or intentional empty path per Decision 7).
- `ProductSurfaceTests` + UI smoke updated for chosen surface.
- App Store screenshots prove dual-tracking wedge.

---

## Follow-up prompt for Jacob

When you return, reply with answers to **Decisions 1–8** (9 can defer). Example:

```
Decision 1: C — Hybrid: 3 tabs + inline goal progress + milestones
Decision 2: B
Decision 3: B
...
```

Agent should then: update `ProductSurface`, align docs, and sequence P1 work from the backlog.
