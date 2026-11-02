# Reviewer-Readiness Handoff — TrackBoth

Handoff for continuing **1.0.0 App Store release** prep. Pairs with [`FutureIdeas/ProductUXHandoff.md`](ProductUXHandoff.md) and [`docs/release/1.0.0-ship-checklist.md`](../docs/release/1.0.0-ship-checklist.md).

> Last updated: 2026-06-21 · Stage: Pre-ship RC (1.0.0 build 4) · branch `main`

---

## Ship surface (locked)

**Tabs:** Track · History · Motivation · Charts · Settings  
**Free** — no IAP · widget not embedded · Goals tab dev-only

---

## Completed (2026-06-21)

- Ship surface locked per product decisions — `ProductSurface.swift`
- Track polish: hero streaks, calendar dots, row metadata, milestone banners
- Motivation tab + primary motivation on Add Metric + slip reminder in LoggingSheet
- Onboarding placeholders on skip (`My habit` / `My vice`)
- Widget embed removed from main app target
- Docs aligned: inventory, core-scope, ship checklist, app-store-copy
- 168 unit tests green · Release build verified · MCP sim smoke (5 tabs)

---

## Remaining (human / Connect-side)

1. **Physical device QA** — fill [`docs/release/QA-Signoff-RC1.md`](../docs/release/QA-Signoff-RC1.md)
2. **7-day dogfood** — daily logging on real device
3. **JSON export → import** on device
4. **Host legal pages** — publish `docs/privacy.html`, `docs/support.html`, `docs/accessibility.html` to GitHub Pages (URLs in `AppLinks.swift`)
5. **App Store Connect** — privacy nutrition label, age rating, listing copy from [`docs/release/app-store-copy.md`](../docs/release/app-store-copy.md)
6. **Screenshots** — deferred; capture after final visual pass
7. **TestFlight RC** — archive Release scheme, upload, internal smoke

---

## Environment setup

```bash
cd ~/Desktop/personal/apps/UrgeBuddy/UrgeBuddy
xcodegen generate
```

XcodeBuildMCP defaults:
- projectPath: `TrackBoth/TrackBoth/TrackBoth.xcodeproj`
- scheme: `TrackBoth`
- bundleId: `com.jacobrozell.TrackBoth`
- simulator: iPhone 17 — UDID `22114A58-1110-4FC7-8431-F7B84B6C7465`

Useful launch args:
- `-lean_ui` — simulate Release ship surface in DEBUG
- `-skip_onboarding` — bypass onboarding
- `-screenshot_demo` — demo data for screenshots

Fresh install: `xcrun simctl uninstall <UDID> com.jacobrozell.TrackBoth`

---

## Acceptance criteria

- Fresh install → onboarding (or skip → placeholder rows) → log on Track → History shows entries
- Vice slip opens LoggingSheet with “Remember why” when motivation exists
- All 5 Release tabs reachable on iPhone
- Export JSON → import round-trip on device
- Support + Privacy links load from hosted pages
- No P0/P1 open bugs

## Key references

- [`ProductUXHandoff.md`](ProductUXHandoff.md) · [`app-store-copy.md`](../docs/release/app-store-copy.md) · [`QA-Signoff-RC1.md`](../docs/release/QA-Signoff-RC1.md) · [`1.0.0-checklist.md`](../docs/release/1.0.0-checklist.md)
