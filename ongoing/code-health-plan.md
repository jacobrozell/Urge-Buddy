# Code health and analytics plan

> Repo folder renamed to `UrgeBuddy/` (2026-11-02). Replace `TrackBoth/` in paths below.

**Goal:** Stop silent data loss before 1.0, then pay down structure after launch. Measure the app without collecting any data.
**Repo:** `/Users/jrozell/Desktop/personal/UrgeBuddy` (Xcode project lives in the inner `UrgeBuddy/` folder)
**Branch:** `claude/dazzling-albattani-7mg4uh`
**Status legend:** `[ ]` not started · `[~]` in progress · `[x]` done · `[>]` deferred

**Last updated:** 2026-11-01

---

## Read this first (rules for the agent doing the work)

1. **Paths.** In this doc, `App/…`, `Features/…`, `Tests/…` and `project.yml` are relative to `/Users/jrozell/Desktop/personal/TrackBoth/TrackBoth`. `ongoing/…`, `Specs/…`, `docs/…` are relative to `/Users/jrozell/Desktop/personal/TrackBoth`.
2. **The working tree has other people's uncommitted changes** (`TodayScreen.swift`, `TodayChrome.swift`, `UrgeFlowView.swift`, `BreathingCircle.swift`, specs). Do not revert, reformat, or "clean up" anything you were not told to touch. Edit only the lines named here.
3. **Do not commit or push.** Leave changes in the working tree.
4. **Do one phase at a time.** Finish its "Done when" checks before starting the next. Tick the boxes in this file as you go and update **Last updated**.
5. **Line numbers drift.** Every site below is listed with its call text. Find it with `rg` on the call text, not the line number.
6. **Adding a new `.swift` file** needs the Xcode project regenerated: `cd TrackBoth/TrackBoth && xcodegen generate`. Then run `git diff --stat TrackBoth.xcodeproj` and confirm only file references changed.
7. **Build and test** with the XcodeBuildMCP tools: `session_show_defaults` first, then `build_sim`. For tests, use `test_sim` with `extraArgs: ["-only-testing:TrackBothTests"]`. UI tests are out of scope.
8. **Style.** Match the surrounding code. No new comments unless they state a constraint the code can't show. User-facing strings go in `Domain/Copy/RecoveryCopy.swift`.
9. **Privacy is fixed.** D12 in `Specs/ProductSpec.md` is **Telemetry: None** and App Privacy is **Data Not Collected**. Never add an SDK, a package, or a network call. Never log user-entered text (vice names, reasons, notes, plans) as `.public`.
10. **If something in this plan doesn't match the code, stop and report it.** Don't invent a different design.

---

## Baseline (2026-11-01)

| Check | Result |
|-------|--------|
| Unit tests | 122/122 pass, 16 s |
| Build warnings | 1 (`App/RootView.swift`, `await SnapshotOrientationLock.applyIfNeeded()`, the function isn't async) |
| App code / tests | 9,206 / 2,153 lines, 94 app files |
| `try?` in app code | 56, of which about 33 are writes in views |
| Force unwraps | 6, all safe constants |
| SwiftLint (defaults, no config) | ~330. 214 `line_length`, 56 `identifier_name` |
| TODO / FIXME | 0 |
| Release dSYMs | `DEBUG_INFORMATION_FORMAT = dwarf-with-dsym` for Release. OK. |

## Decision: analytics

D12 stays **Telemetry: None**. App Privacy stays **Data Not Collected**. No SDK, no network calls.

Measure with what Apple already collects from users who opt in to share with developers (App Store Connect App Analytics and Xcode Organizer), plus on-device logs. The only thing that leaves the device is a feedback email the user writes and sends.

---

## Phase 1 — Before 1.0 submit

### 1.1 Surface save failures `[x]`

**Problem.** `RecoveryStore.persist` calls `ModelContext.saveChanges`, which logs the error and throws `RecoveryStoreError.saveFailed`. Views call the store with `try?`, so the error is dropped and the user thinks the change saved.

**Design.** A `PersistAction` value in the SwiftUI environment. Views call `persist("what") { try … }`. On failure it logs and tells the nearest `.persistFailureAlert()` modifier above it to show an alert. Each sheet or full-screen cover attaches its own modifier, so the alert always shows on the screen that's visible (a SwiftUI alert attached under a presented sheet can't appear).

#### Step 1. Add copy

In `Domain/Copy/RecoveryCopy.swift`, next to `static let close = "Close"`, add:

```swift
static let ok = "OK"
static let saveFailedTitle = "Couldn't save that"
static let saveFailedMessage = "Try again. If it keeps happening, close and reopen Urge Buddy."
```

If `ok` already exists, reuse it and skip that line.

#### Step 2. Create `App/PersistAction.swift`

```swift
import SwiftUI

/// Runs a write from a view. On failure it logs and asks the nearest
/// `.persistFailureAlert()` to tell the user.
struct PersistAction {
    var onFailure: @MainActor (Error) -> Void = { _ in }

    @MainActor
    @discardableResult
    func callAsFunction<T>(_ operation: String, _ work: () throws -> T) -> T? {
        do {
            return try work()
        } catch {
            logger.logError(error, context: "Couldn't save: \(operation)")
            onFailure(error)
            return nil
        }
    }
}

extension EnvironmentValues {
    @Entry var persist = PersistAction()
}

private struct PersistFailureAlert: ViewModifier {
    @State private var failed = false

    func body(content: Content) -> some View {
        content
            .environment(\.persist, PersistAction { _ in failed = true })
            .alert(RecoveryCopy.saveFailedTitle, isPresented: $failed) {
                Button(RecoveryCopy.ok, role: .cancel) {}
            } message: {
                Text(RecoveryCopy.saveFailedMessage)
            }
    }
}

extension View {
    /// Attach at the root of every screen and every sheet or cover that writes data.
    func persistFailureAlert() -> some View {
        modifier(PersistFailureAlert())
    }
}
```

`operation` is a short fixed English label such as `"mark free"`. Never pass user text into it, because it's logged.

Run `xcodegen generate` (rule 6), then `build_sim`. Fix compile errors before going on.

#### Step 3. Attach the modifier

Add `.persistFailureAlert()` in exactly these places:

| File | Where |
|------|-------|
| `App/RootView.swift` | On the `Group { if onboarded { MainTabView() } else { OnboardingFlow … } }`, directly after its closing `}` and before `.background(Color.tbBackground)`. |
| `App/RootView.swift` | Inside `.fullScreenCover(item: urgeBinding)`: on `UrgeFlowView(…) { router.finishUrge() }`. |
| `App/RootView.swift` | Inside `.sheet(item: $cover)`: on `CheckInSheet(metrics:entries:)`. |
| `Features/Urge/UrgeFlowView.swift` | Inside `.sheet(isPresented: $showSlip)`: on `SlipFlowView(…)`. |
| `Features/CheckIn/CheckInSheet.swift` | Inside `.sheet(isPresented: slippingPresented)`: on the presented view. |
| `Features/Today/TodayScreen.swift` | Inside `.sheet(item: $sheet)`: on the `switch` result (wrap the `switch` in a `Group { … }` if needed). |
| `Features/Progress/ProgressScreen.swift` | Inside `.sheet(isPresented: $showAdd)`: on the presented view. |
| `Features/Progress/MetricDetailScreen.swift` | Inside `.sheet(item: $sheet, onDismiss:)`: on the presented view (wrap in `Group` if it's a `switch`). |

Leave `SlipFlowView`'s help sheet and `SettingsScreen`'s share sheet alone; they don't write.

#### Step 4. Replace the writes

In each file that has a row below, add `@Environment(\.persist) private var persist` next to the file's other `@Environment` properties. `DayEditorSheet` is a separate struct inside `MetricDetailScreen.swift`, so it needs its own property.

Patterns:

```swift
// Before
try? store.markFree(metric, on: yesterday, now: Date())
// After
persist("mark free") { try store.markFree(metric, on: yesterday, now: Date()) }

// Before: dismiss or close after the write
try? model.delete(metric, store: RecoveryStore(context: modelContext))
dismiss()
// After: only dismiss on success, so the alert has a screen to show on
guard persist("delete metric", { try model.delete(metric, store: RecoveryStore(context: modelContext)) }) != nil else { return }
dismiss()
```

Log only (no alert) is for places where no screen will be left to show the alert:

```swift
do {
    try model?.saveDayNote(now: Date())
} catch {
    logger.logError(error, context: "Couldn't save: day note on dismiss")
}
```

**Every site, with the action to take:**

| File | Call text | Action |
|------|-----------|--------|
| `App/RootView.swift` | `try? DemoData.seedIfEmpty(context: modelContext)` | Leave. Debug launch argument only. |
| `App/RootView.swift` | `try? RecoveryStore(context: modelContext).resolveAbandonedUrges()` | Log only. Background cleanup; the user didn't do anything. |
| `Features/Onboarding/OnboardingFlow.swift` | `_ = try? store.addMetric(` inside `finish()` | Wrap the whole `for draft in drafts { … }` loop in one `persist("finish onboarding") { … }` (use `try` inside, drop `try?`). If it returns `nil`, `return` before any `Preferences.` line so onboarding stays open. |
| `Features/CheckIn/CheckInSheet.swift` | `.onDisappear { try? model?.saveDayNote(now: Date()) }` | Log only. The sheet is closing. |
| `Features/CheckIn/CheckInSheet.swift` | `try? model.setAmount(row.id, value, metrics: metrics, now: Date())` | `persist("set amount")`. |
| `Features/CheckIn/CheckInSheet.swift` | `try? model.saveDayNote(now: Date())` (not the `onDisappear` one) | `persist("save day note")`. |
| `Features/CheckIn/CheckInSheet.swift` | `try? model.markFree(id, metrics: metrics, now: Date())` | `persist("mark free")`. |
| `Features/CheckIn/CheckInSheet.swift` | `try? model.toggleHabit(id, metrics: metrics, now: Date())` | `persist("toggle habit")`. |
| `Features/CheckIn/CheckInSheet.swift` | `try? model.finish(metrics: metrics, now: Date(), celebrated: celebrated)` | `persist("finish check-in")`. |
| `Features/Urge/UrgeFlowView.swift` | `Button(RecoveryCopy.theUrgePassed) { try? model?.passed(now: Date()) }` (in `confirmationDialog`) | `persist("urge passed")`. |
| `Features/Urge/UrgeFlowView.swift` | `try? model?.markNotSure(now: Date()); onClose()` | `persist("urge not sure")`. Call `onClose()` only if it didn't return `nil`. |
| `Features/Urge/UrgeFlowView.swift` | `try? model?.markSlipped(now: Date())` inside the `SlipFlowView` completion | `persist("urge slipped")`. Always set `showSlip = false`. Call `onClose()` only on success. |
| `Features/Urge/UrgeFlowView.swift` | `try? model.begin(metrics: metrics, now: Date())` (two sites: intensity button and Skip) | `persist("start urge")`. |
| `Features/Urge/UrgeFlowView.swift` | `try? model.passed(now: Date())` (in `PrimaryButton`) | `persist("urge passed")`. |
| `Features/Urge/UrgeFlowView.swift` | `try? await Task.sleep(for: .seconds(8))` | Leave. Not a write. |
| `Features/Urge/UrgeFlowView.swift` | `try? RecoveryStore(context: modelContext).setHabitDone(habit, on: Date(), done: true, now: Date())` | `persist("habit done")`. |
| `Features/Urge/UrgeFlowView.swift` | `try? RecoveryStore(…).addAmount(metric, 1, …)` then `try? model?.markSlipped(now: Date())` in `slipped()` | One `persist("cut-back slip") { try …addAmount…; try model?.markSlipped(now: Date()) }`. Call `onClose()` only on success. |
| `Features/Urge/UrgeFlowView.swift` | `(try? store.reasons(for: id)…` | Leave. Read with a fallback. |
| `Features/Urge/UrgeFlowView.swift` | `try? model.commitReflection(keepJournal: model.journalChoice == .save)` in `leavePassed()` | `guard persist("urge reflection", { … }) != nil else { return }`, then `onClose()`. Added 2026-11-01 (new journal write). |
| `Features/Urge/UrgeFlowView.swift` | `try? model?.commitReflection(keepJournal: keep)` in `commitPassed(keep:)` | Same as above. Added 2026-11-01. |
| `Features/Slip/SlipFlowView.swift` | `try? model?.save(metric: metric, now: Date())` (two sites) | `persist("save slip")`. |
| `Features/CheckIn/CheckInViewModel.swift` | `let note = try? store.dayNote(on: now)` | Leave. Read in a view model. |
| `Features/Settings/SettingsScreen.swift` | `try? DemoData.seedIfEmpty(context: modelContext)` | Leave. Debug only. |
| `Features/Settings/SettingsScreen.swift` | `try? RecoveryStore(context: modelContext).deleteAllData()` in `deleteAll()` | `guard persist("delete all data", { … }) != nil else { return }` so reminders and lock are only reset on success. |
| `Features/Today/TodayScreen.swift` | `try? store.setHabitDone(metric, on: Date(), done: done, now: Date())` | `persist("habit done")`. |
| `Features/Today/TodayScreen.swift` | `try? RecoveryStore(context: modelContext).setAmount(metric, on: Date(), amount: amount, now: Date())` | `persist("set amount")`. |
| `Features/Today/TodayScreen.swift` | `try? store.markFree(metric, on: yesterday, now: Date())` | `persist("mark yesterday free")`. |
| `Features/Progress/MetricFormView.swift` | `_ = try? model.save(metric: metric, store: …, now: Date())` then `if model.canSave { dismiss() }` | `guard persist("save metric", { try model.save(…) }) != nil else { return }`, then keep `if model.canSave { dismiss() }`. |
| `Features/Progress/MetricFormView.swift` | `try? model.delete(metric, store: …)` then `dismiss()` | Guard pattern above. |
| `Features/Progress/ProgressScreen.swift` | `try? model.moveActive(from:to:metrics:store:)` | `persist("reorder")`. |
| `Features/Progress/ProgressScreen.swift` | `try? RecoveryStore(context: modelContext).setArchived(metric, false)` | `persist("restore")`. |
| `Features/Progress/MetricDetailScreen.swift` | `try? RecoveryStore(context: modelContext).setArchived(metric, false)` | `persist("restore")`. |
| `Features/Progress/MetricDetailScreen.swift` | `try? RecoveryStore(context: modelContext).deleteReason(reason)` (two sites) | `persist("delete reason")`. |
| `Features/Progress/MetricDetailScreen.swift` | `try? RecoveryStore(context: modelContext).addReason(newReason, to: metric)` | `persist("add reason")`. If the next lines clear the draft, only clear on success. |
| `Features/Progress/MetricDetailScreen.swift` | `try? RecoveryStore(context: modelContext).updateReason(editingReason, text: reasonDraft)` | `persist("edit reason")`. Same rule for clearing the editor. |
| `Features/Progress/MetricDetailScreen.swift` | `try? RecoveryStore(context: modelContext).reorderReasons(ordered)` | `persist("reorder reasons")`. |
| `Features/Progress/MetricDetailScreen.swift` | `try? RecoveryStore(context: modelContext).setPlan(metric, plan: …)` | `persist("save plan")`. |
| `MetricDetailScreen.swift` → `DayEditorSheet.load()` | `(try? store.entry(for: metric.id, on: day))?.amount ?? 0` and `let note = try? store.dayNote(on: day)` | Leave. Reads with fallbacks. |
| `DayEditorSheet.saveAmount()` | `try? RecoveryStore(context: modelContext).setAmount(metric, on: day, amount: amount, now: Date())` | `persist("set amount")`. |
| `DayEditorSheet.saveNote()` | `try? RecoveryStore(context: modelContext).setDayNote(…)` | `persist("save day note")`. |
| `DayEditorSheet.markFree()` | `if let existing = try? store.entry(…), existing.status == .slipped { try? store.clearDay(…) }` then `try? store.markFree(…)` | One `persist("mark day free") { if let existing = try store.entry(…), existing.status == .slipped { try store.clearDay(…) }; try store.markFree(…) }`. If the function dismisses afterwards, only dismiss on success. |
| `DayEditorSheet.clear()` | `try? RecoveryStore(context: modelContext).clearDay(metric, on: day)` | `persist("clear day")`. Same dismiss rule. |
| `DayEditorSheet.setDone(_:)` | `try? RecoveryStore(context: modelContext).setHabitDone(metric, on: day, done: done, now: Date())` | `persist("habit done")`. Same dismiss rule. |

If you find a write `try?` in `Features/` or `App/` that isn't in this table, convert it with `persist` and add a row here.

#### Step 5. Unit test

Create `Tests/Unit/PersistActionTests.swift`:

```swift
import XCTest
@testable import TrackBoth

@MainActor
final class PersistActionTests: XCTestCase {
    func testFailureReturnsNilAndReports() {
        var reported = false
        let persist = PersistAction { _ in reported = true }
        let result: Int? = persist("test") { throw RecoveryStoreError.saveFailed }
        XCTAssertNil(result)
        XCTAssertTrue(reported)
    }

    func testSuccessReturnsValueAndStaysQuiet() {
        var reported = false
        let persist = PersistAction { _ in reported = true }
        XCTAssertEqual(persist("test") { 5 }, 5)
        XCTAssertFalse(reported)
    }
}
```

If `RecoveryStoreError.saveFailed` isn't accessible, define a private `struct Boom: Error {}` in the test file and throw that. Run `xcodegen generate` again.

#### Done when

- [x] `rg -n 'try\?' TrackBoth/Features TrackBoth/App` (from the repo root) shows only the **Leave** rows above: two `DemoData.seedIfEmpty`, `Task.sleep`, `store.reasons(for:)`, `store.dayNote(on: now)` in `CheckInViewModel`, and the two reads in `DayEditorSheet.load()`, plus the `store.entry` check folded into `markFree` if you kept it as a read.
- [x] `build_sim` succeeds with no new warnings.
- [x] `test_sim` with `-only-testing:TrackBothTests` passes (124 or more tests).
- [x] Manual smoke test on the simulator: launch with `-ui_testing -skip_onboarding -seed_demo`. Mark a habit done on Today, open and close a check-in, and start and pass an urge. No alerts should appear and the changes should stick.

### 1.2 Release checks `[~]`

- [x] Release builds produce dSYMs (`dwarf-with-dsym`), so Organizer crash logs are symbolicated.
- [x] `App/RootView.swift`: change `await SnapshotOrientationLock.applyIfNeeded()` to `SnapshotOrientationLock.applyIfNeeded()`. Rebuild and confirm 0 warnings.
- [ ] **Jacob, manual:** in App Store Connect → App Privacy, confirm **Data Not Collected**, matching `Resources/PrivacyInfo.xcprivacy`.

---

## Phase 2 — Analytics without collection (launch week)

### 2.1 What we watch `[ ]`

| Question | Source |
|----------|--------|
| Are people installing? | App Store Connect → App Analytics: impressions, product page views, downloads, conversion rate |
| Do they come back? | App Analytics: day 1 / 7 / 28 retention, sessions per active device |
| Is it stable? | App Analytics crashes. Xcode Organizer: crashes, hangs, launch time, battery, disk writes |
| What do they say? | Ratings, reviews, feedback email |

1.0 targets:
- Crash-free sessions ≥ 99.5%.
- Day-7 retention recorded weekly from launch. No target until there are 4 weeks of data.
- Zero hang reports over 2 s in the urge flow.

- [ ] Add a "Launch metrics" section to `docs/project-status.md` with this table and the targets.

### 2.2 Portfolio reports `[ ]`

Goal: the portfolio PO skill can show TrackBoth numbers the way it does for the GA4 apps.

1. [ ] Read `DaRules/scripts/trigger-xcode-cloud.sh` and reuse its `generate_jwt` approach (ES256 JWT from `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_ID`, and the `.p8` in `~/.config/personal/`). Source `~/.config/personal/app-store-connect.env`. **Never print the env file, the key, or the JWT.** Never touch any other Apple account (see the workspace rule about iosbuild and myocv.com).
2. [ ] Create `DaRules/scripts/asc-analytics.sh <bundle-id>`:
   - `GET /v1/apps?filter[bundleId]=com.jacobrozell.TrackBoth` → app ID.
   - `GET /v1/apps/{id}/analyticsReportRequests`. If there is no `ONGOING` request, `POST /v1/analyticsReportRequests` with `accessType: ONGOING` and the app relationship. Print "Requested. Reports appear within 48 hours." and exit 0.
   - If the POST returns 403, the key lacks the role Apple requires for analytics reports. Print that and stop. Jacob makes a new key; don't retry.
   - Otherwise `GET /v1/analyticsReportRequests/{id}/reports?filter[category]=APP_USAGE` and `…=APP_STORE_ENGAGEMENT`. Pick the reports named like "App Sessions", "App Crashes", and "App Store Downloads" / "App Store Discovery and Engagement".
   - For each: `GET /v1/analyticsReports/{id}/instances?filter[granularity]=DAILY`, take the last 28 days, `GET /v1/analyticsReportInstances/{id}/segments`, download each segment `url` (gzip CSV), and sum by date.
   - Print a short table: date range, downloads, sessions, active devices, crashes.
3. [ ] Add a TrackBoth row to `DaRules/skills/portfolio-po/analytics.md` under the app table: source **App Store Connect (no GA4)**, command `DaRules/scripts/asc-analytics.sh com.jacobrozell.TrackBoth`, start vs finish = sessions vs crashes. Add one line saying TrackBoth must never get GA4 or Firebase (D12).
4. [ ] Run the script once after 1.0 is live. Paste the result into this doc.

### 2.3 On-device diagnostics `[ ]`

1. [ ] **Logger.** Rewrite the internals of `Services/Logger.swift` to use `os.Logger` (one per `LogCategory`, subsystem `com.jacobrozell.TrackBoth`). Keep the public method names (`debug`, `info`, `warn`, `error`, `fatal`, `logError`, `logDataOperation`, `logPerformance`, `logUserAction`) and the global `logger` so no call site changes. Use `privacy: .public` for the message (call sites pass only fixed labels and error descriptions). Drop the `#if DEBUG print(…)` block; Xcode's console shows `os.Logger` output. Remove the `details!` force unwrap in `logUserAction` with `if let`.
2. [ ] **MetricKit.** New file `Services/DiagnosticsSubscriber.swift`: an `NSObject, MXMetricManagerSubscriber` singleton. In `didReceive(_ payloads: [MXDiagnosticPayload])`, log for each payload the crash, hang, and CPU or disk exception counts with `logger.error(…, category: .performance)`. Don't log the call-stack JSON. Register it in `AppDelegate`'s `didFinishLaunching` with `MXMetricManager.shared.add(DiagnosticsSubscriber.shared)`. Nothing is sent anywhere.
3. [ ] **Feedback email.** In `Support/Navigation/AppSupport.swift`, change the mail body footer to `TrackBoth \(installedVersion) (\(build)) · iOS \(UIDevice.current.systemVersion) · \(modelIdentifier)`. `build` comes from `CFBundleVersion`. `modelIdentifier` comes from `utsname().machine`. Nothing else goes in: no metric names, no counts.
4. [ ] Run `xcodegen generate`, `build_sim`, and unit tests.

**Done when:** builds clean, tests pass, and `rg -n 'os_log\(' TrackBoth/TrackBoth` returns nothing.

---

## Phase 3 — Structure (1.1)

Don't start until 1.0 is submitted. Do the steps in order; each ends with a green build and tests.

### 3.1 Move writes out of views `[ ]`

1. [ ] `MetricDetailScreen` creates `RecoveryStore(context:)` 13 times. Add these methods to `MetricDetailViewModel` (it already exists; look at how it's created in `MetricDetailScreen` and follow that): `restore`, `addReason`, `updateReason`, `deleteReason`, `moveReason(_:by:)`, `savePlan`. Each takes a `RecoveryStore` and throws. The view calls them through `persist`.
2. [ ] Move `DayEditorSheet`'s writes (`saveAmount`, `saveNote`, `markFree`, `clear`, `setDone`) into a new `DayEditorViewModel` in `Features/Progress/DayEditorViewModel.swift`.
3. [ ] Add tests to `MetricDetailViewModelTests.swift` and a new `DayEditorViewModelTests.swift` using `TestHarness` from `Tests/Unit/Support/TestStore.swift`. One test per method: call it, then fetch and assert.
4. [ ] Repeat for `TodayScreen` (3 sites → `TodayViewModel`, which exists), `UrgeFlowView` habit chip and cut-back slip (→ `UrgeViewModel`), `SettingsScreen.deleteAll`, `ProgressScreen`, `MetricFormView`.

**Done when:** `rg -n 'RecoveryStore\(context' TrackBoth/TrackBoth/Features` only matches lines that create a view model or pass a store into one.

### 3.2 Split large files `[ ]`

1. [ ] `MetricDetailScreen.swift` (661 lines). Move into new files in `Features/Progress/`, cutting and pasting with no logic changes:
   - `DayEditorSheet` → `DayEditorSheet.swift`
   - `reasonsSection`, `reasonRow`, and the reason editor state → `MetricReasonsSection.swift` as its own `View` taking `metric` and the view model
   - `planSection` and `savePlan` → `MetricPlanSection.swift`
   - `recordPanel`, `recentRow`, `triggerBar` → `MetricRecordPanel.swift`
2. [ ] `OnboardingFlow.swift` (501 lines). Move each page (`welcome`, `chooseVices` + `viceWhen`, `why` + `chipRow`, `habits`, `reminders`, `privacy`, `disclaimer`) into `Features/Onboarding/Pages/<Name>Page.swift`, each a `View` taking `@Bindable var model: OnboardingViewModel`.
3. [ ] After each file move: `xcodegen generate`, build, tests, and a simulator screenshot of the screen to confirm it looks the same.

**Done when:** no file in `Features/` is over 400 lines (`find TrackBoth/TrackBoth/Features -name '*.swift' | xargs wc -l | sort -rn | head`).

### 3.3 Make lint meaningful `[ ]`

1. [ ] Add `TrackBoth/TrackBoth/.swiftlint.yml`:
   ```yaml
   included: [App, DesignSystem, Features, Domain, Data, Services, Support, Tests]
   line_length:
     warning: 160
     error: 220
   identifier_name:
     excluded: [id, x, y, i, on, to, at, lhs, rhs]
   function_body_length:
     warning: 60
   type_body_length:
     warning: 400
   ```
2. [ ] Run `swiftlint lint --quiet` from that folder. Fix the rest by hand (no `--fix` on files with other people's uncommitted changes). `swiftlint --fix` is fine for `trailing_whitespace` and `trailing_newline` only.
3. [ ] Add a post-compile script to the `TrackBoth` target in `project.yml`: `if which swiftlint >/dev/null; then swiftlint lint --quiet; fi` (warnings only, never fails the build, skipped on Xcode Cloud if SwiftLint is missing). `xcodegen generate`.

**Done when:** `swiftlint lint --quiet | wc -l` is 0.

---

## Log

| Date | Phase | Result |
|------|-------|--------|
| 2026-11-01 | Plan | Written. Analytics decision: Apple-only, Data Not Collected. |
| 2026-11-01 | 1.1, 1.2 | `PersistAction` + `.persistFailureAlert()` added; every write `try?` in `Features/` and `App/` converted, only the Leave reads remain. `RootView` `await` warning fixed. Build 0 warnings, 132/132 unit tests pass, simulator smoke test (habit done, check-in open/close, urge start/pass) showed no alerts and changes stuck. Deviations: the plan's `rg` path had an extra `TrackBoth/` (fixed above); `UrgeFlowView` gained a journal feature mid-run, so `markSlipped`/`markNotSure` now take `keepJournal:` (same handling) and two new `commitReflection` writes were converted (rows added); the two multi-statement `persist` closures (`cut-back slip`, `mark day free`) need an explicit `() throws -> Void in` to type-check; onboarding uses `let saved: Void? = persist(…)` then `guard saved != nil`. `xcodegen` also picked up another agent's new `Features/Journal/` files and `JournalEntryTests.swift`. App Store Connect privacy check still open for Jacob. |
