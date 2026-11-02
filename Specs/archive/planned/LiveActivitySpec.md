**Estimated release:** `1.1`

# Urge Timer Live Activity Specification

## 1. Purpose

When someone leaves the app mid-urge, the countdown keeps going on the Lock Screen and in the Dynamic Island. Leaving the app is the riskiest moment in an urge, so the timer should stay in view and one tap should bring them back.

**Status:** Planned. Cut from 1.0.0.

---

## 2. Scope

- One Live Activity for the active urge timer. No other Live Activities. Streaks and days free belong in widgets.
- Starts when the ride step begins (`UrgeViewModel.begin`). Updates on **+5 min**. Ends on passed, slipped, not sure, or close.
- If the app opens after the timer ran out with no outcome, end the activity and show the urge flow's close dialog ("How did it go?").
- Tapping it opens `trackboth://urge` on the ride step for the same urge.
- Off when the user has turned off Live Activities in Settings. No in-app toggle in v1.

### Layouts

| Surface | Content |
|---------|---------|
| Compact leading | Wave or breathing glyph |
| Compact trailing | Countdown (`Text(timerInterval:)`) |
| Minimal | Progress ring (`ProgressView(timerInterval:)`, circular) |
| Expanded | Ring, countdown, "Ride it out", **I'm okay** button (App Intent, marks passed) |
| Lock Screen | Ring, countdown, "Ride it out", the user's if-then plan when discreet mode is off |

### Privacy

The Lock Screen and Dynamic Island can be seen by anyone nearby.

- Never show the vice name, substance, or the word "urge". Use "Ride it out".
- Show the if-then plan and reasons only when discreet mode is off, and only on the Lock Screen.

---

## 3. Technical notes

- New widget extension target in `project.yml`. It also hosts the 1.1 widgets and the Control Center control, so build it once.
- `NSSupportsLiveActivities = YES` on the app target.
- `UrgeActivityAttributes`: static `urgeID`. Content state is `endDate` and `duration` (matches `UrgeViewModel`).
- The countdown and ring are rendered by the system from `endDate`. No per-second updates, no push server, no background tasks. This avoids the battery worry in [`WidgetSpec.md`](WidgetSpec.md).
- Set `staleDate` to `endDate`. When stale, show "Still with it?" in place of the countdown.
- The **I'm okay** intent writes through `RecoveryStore` (needs the shared App Group store).

---

## 4. Tests

- Unit: start, +5 min, and every outcome update or end the activity once.
- Unit: no content state field contains metric name or reasons when discreet mode is on.
- Manual: background the app mid-timer on a Dynamic Island device and on a non-Island device (Lock Screen only). Check Reduce Motion and AX5.

---

## 5. Verification

| Field | Value |
|-------|--------|
| **Estimated release** | `1.1` |
| **Last verified** | 2026-11-01 |
| **Commit** | (not started) |
| **Code** | — |
