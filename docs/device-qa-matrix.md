# Device QA matrix — adaptive layout

Manual checklist for landscape, iPad multitasking, and iPhone Duo. Mark rows with date, device, and pass/fail after automated UI tests and spot checks.

Related: [Specs/DesignSystemSpec.md](../Specs/DesignSystemSpec.md) §8.7, [ongoing/adaptive-layout-plan.md](../ongoing/adaptive-layout-plan.md).

**Automated (2026-10-31):** `TrackBothTests` (incl. `AdaptiveLayoutTests`), `TrackBothUITests` + `AdaptiveLayoutUITests` on iPhone 17; iPad-width `testProgressSplitOnRegularWidth` when window ≥ 744pt.

**App Store screenshots (2026-11-02), light portrait:**

- iPhone 17 Pro Max, 1320×2868: Today, urge ride, slip summary, progress detail, cut back.
- iPad Pro 13-inch (M5), 2064×2752: the same five scenes.
- iPhone Duo: not captured. Device Hub had no windows, and the Duo simulator stopped on a data-migration failure.

Files are in `marketing-screenshots/` and are not committed. Dark mode, AX3, Stage Manager, and folding mid-urge are still open below.

---

## iPhone 17 portrait

- Today — pass (2026-10-31, UI tests)
- Check-in — pass (2026-10-31, UI tests)
- Urge — pass (2026-10-31, UI tests)
- Slip — pass (2026-10-31, UI tests)
- Progress (stack push) — pass (2026-10-31, UI tests)
- Metric Detail — not manually re-run
- Day editor — not manually re-run
- Metric form — not manually re-run
- Celebration — not manually re-run
- Lock — not manually re-run
- Onboarding — not manually re-run
- Settings — not manually re-run
- Crisis resources — not manually re-run

## iPhone 17 landscape

- Today (SOS + check-in reachable) — pass (2026-10-31, UI tests)
- Check-in (toolbar Done) — pass (2026-10-31, UI tests)
- Urge (side-by-side ride) — pass (2026-10-31, UI tests)
- Slip (toolbar Save) — pass (2026-10-31, UI tests)
- Onboarding (Next reachable) — pass (2026-10-31, UI tests)
- Progress — stack push (expected); not UI-tested separately
- Metric Detail two columns — manual spot-check pending
- Remaining screens — manual spot-check pending

## iPhone Pro Max landscape

- Today two columns — manual pending
- Progress stack — manual pending

## iPad Air 11 portrait / landscape

- Progress split + detail — pass partial (2026-10-31, UI test opens detail on wide window)
- Today two columns — manual pending
- Form/page sheets — manual pending

## iPad mini Split View ⅓

- Collapses to phone stack — manual pending

## Stage Manager resize

- Smooth layout transitions — manual pending

## iPhone Duo folded / open / fold mid-flow

- Outer portrait layout — manual pending (Device Hub `Scripts/devicehub-pose.swift`)
- Inner split + two columns — manual pending
- Fold with check-in / urge / onboarding draft open — manual pending

## Dynamic Type AX3 portrait and landscape

- Single column (no forced two-column) — manual pending

## Dark mode

- Core tabs + urge calm screen — manual pending

---

## Sign-off

| Role | Name | Date | Build |
|------|------|------|-------|
| Developer | Agent | 2026-10-31 | 7 |
