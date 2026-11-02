# TrackBoth — Feature inventory

Living register for the recovery overhaul. Every new feature starts as **Planned** until the phase that builds it lands.

**Last reviewed:** 2026-11-01
**Stage:** Overhaul in progress

## Status legend

| Status | Meaning |
|--------|---------|
| **Planned** | In the approved plan, not built yet |
| **Ships 1.0** | Implemented for this overhaul |
| **Cut** | Removed on purpose. Do not bring it back in 1.0 |
| **Later** | After 1.0 |

## Core loop

| Feature | Status | Notes |
|---------|--------|-------|
| Today — check-in banner, vice cards, habit rows | **Ships 1.0** | Phase 5. Urge, slip, and detail from Today are stubs until Phases 6 and 7 |
| Daily check-in sheet | **Ships 1.0** | Phase 5. "I slipped" opens a stub until Phase 6 |
| Urge flow (ride it out) | **Ships 1.0** | Phase 6 |
| Slip flow | **Ships 1.0** | Phase 6. Amber, no guilt copy |
| Milestone celebration, re-earnable after a slip | **Ships 1.0** | Phase 6. Ledger records when Keep going is tapped |
| Progress + metric detail + day editor | **Planned** | Phase 7. Progress already shows the urges-beaten count |
| Add / edit metric | **Ships 1.0** | Progress and Today both open the form |
| Onboarding (quit date, reason, reminders, lock, disclaimer) | **Ships 1.0** | Built. Unit-tested draft mapping. UI test not run |
| Daily reminder + milestone notifications | **Ships 1.0** | Scheduler and settings toggle. Not fired on a device yet |
| App lock and app-switcher privacy cover | **Ships 1.0** | Built. Not checked on a device |
| Settings, backup/restore, delete all, crisis resources | **Ships 1.0** | v6 round-trip and v5 import unit-tested. Legacy import code exists, not retested this pass |
| Home-screen quick action and `trackboth://urge` | **Ships 1.0** | Phase 6 |
| Cut back mode (daily limit, count, trend, savings) | **Ships 1.0** | Added 2026-11-01. Per vice: quit or cut back. Unit, UI, and backup tests |
| Amount habits (daily target, partial days) | **Ships 1.0** | Added 2026-11-01. Water preset defaults to 8 glasses |
| Day mood and note | **Ships 1.0** | Added 2026-11-01. End of check-in, Day editor, Progress "Recent days" |

## Cut from the pre-overhaul app

| Feature | Status | Why |
|---------|--------|-----|
| Goals tab, weekly/monthly goals | **Cut** | Daily targets and limits replace them. Weekly goals are **Later** |
| Per-entry mood chips, starred entries | **Cut** | One mood per day replaces them |
| Quantity and units | **Back** | Returned as cut back mode and amount habits |
| Charts tab and chart export | **Cut** | Replaced by a calendar and three recovery stats |
| Color themes and font picker | **Cut** | One palette, follows the system |
| Per-device layout files | **Cut** | iPhone portrait only. Adaptive rules stay |
| Widget, Watch, Live Activities, Shortcuts | **Later** | A single days-free widget is optional after launch |
| Launch splash animation | **Cut** | The system launch screen is enough |
| Placeholder "My habit / My vice" rows | **Cut** | Onboarding requires a real choice |
| Demo data in Release | **Cut** | Debug and screenshots only |

## Later

| Feature | Status | Notes |
|---------|--------|-------|
| App Intents, urge widgets, notification actions, neutral icon, catch-up, weekly goals, insights | **Later** | Ordered list in `FutureIdeas/backlog.md` |
| iPad and landscape | **Shipped (in branch)** | Adaptive layout plan; see `ongoing/adaptive-layout-plan.md` |
