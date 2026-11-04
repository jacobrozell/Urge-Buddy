# UI/UX polish before 1.0

**Goal:** Fix the visible rough edges a first-time App Store user would notice, without changing product behavior or data.
**Repo:** `/Users/jrozell/Desktop/personal/apps/UrgeBuddy`
**Written:** 2026-11-02, from a code read of every screen plus simulator screenshots (iPhone 17, light and dark) and the 1.0 marketing screenshots.
**Status legend:** `[ ]` not started · `[~]` in progress · `[x]` done · `[>]` deferred

**Last updated:** 2026-11-02

---

## Read this first (rules for whoever implements this)

1. **Work on a branch.** `git switch -c ui-polish`. Make **one commit per phase** below. Do not push or open a PR unless the owner asks.
2. **Do tasks in order.** Phase 1 adds the shared pieces later phases use.
3. **Only change what a task says.** If you notice something else, add it to [Found while working](#found-while-working) at the bottom. Do not fix it.
4. **Never hand-edit `UrgeBuddy/UrgeBuddy.xcodeproj`.** If you add a new `.swift` file, put it in an existing source folder and run `xcodegen generate` from `UrgeBuddy/`.
5. **No raw colors.** Use only the `Color.tb…` tokens in `UrgeBuddy/DesignSystem/Palette.swift`. No `Color.white`, `.gray`, `Color(red:…)`, or hex in views. The one exception that already exists is `.black.opacity(…)` for shadows.
6. **All user-facing text goes in `UrgeBuddy/Domain/Copy/RecoveryCopy.swift`.** Don't put string literals in views. If you change a string that a test checks (search `Tests/` for the property name), update the test in the same commit.
7. **Keep every `.accessibilityIdentifier(…)`.** UI tests find controls by these IDs. If you move a control, move its ID with it.
8. **Every animation must respect Reduce Motion.** Read `@Environment(\.accessibilityReduceMotion)` and skip the motion when it is `true` (see `UrgeBuddy/DesignSystem/Motion.swift` for the existing helpers).
9. **Spec governance.** When a task adds a component or changes how something looks or reads, update the matching spec in the same commit: components and styles → `Specs/DesignSystemSpec.md` §8.4; screen copy and flows → `Specs/ProductSpec.md`. Each task says which.
10. **Tap targets stay ≥ 44×44 pt.** Text must not be truncated at the largest accessibility text size (AX5).

### Build and test commands

Run from `UrgeBuddy/` (the folder with `project.yml`).

```bash
xcodebuild build -project UrgeBuddy.xcodeproj -scheme UrgeBuddy -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath ../.derivedData/uxreview CODE_SIGNING_ALLOWED=NO -quiet
```

```bash
xcodebuild test -project UrgeBuddy.xcodeproj -scheme UrgeBuddy -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:UrgeBuddyTests CODE_SIGNING_ALLOWED=NO
```

```bash
xcodebuild test -project UrgeBuddy.xcodeproj -scheme UrgeBuddy -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:UrgeBuddyUITests CODE_SIGNING_ALLOWED=NO
```

The UI suite is slow. Run it in the background and at the end of Phases 2, 3, 4, and 10 at minimum.

### Taking screenshots to check your work

After a build, install and launch on the booted iPhone 17 with demo data. `-ui_testing` uses an in-memory store, so it never touches real data. `-release_ui` hides the Debug section in Settings.

```bash
D="iPhone 17"; APP=../.derivedData/uxreview/Build/Products/Debug-iphonesimulator/UrgeBuddy.app; xcrun simctl install "$D" "$APP"
```

```bash
xcrun simctl terminate "iPhone 17" com.jacobrozell.TrackBoth; xcrun simctl launch "iPhone 17" com.jacobrozell.TrackBoth -ui_testing -release_ui -skip_onboarding -seed_marketing; sleep 6; xcrun simctl io "iPhone 17" screenshot /tmp/today.png
```

Swap the launch arguments to reach other screens:

| Screen | Extra arguments (after `-ui_testing -release_ui`) |
|--------|----------------------------------------------------|
| Onboarding | none |
| Today, empty | `-skip_onboarding` |
| Today, demo | `-skip_onboarding -seed_marketing` |
| Today, cut back | `-skip_onboarding -seed_cutback` |
| Check-in sheet | `-skip_onboarding -seed_marketing -present_checkin` |
| Urge ride | `-skip_onboarding -seed_marketing -urge_ride` |
| Slip summary | `-skip_onboarding -seed_marketing -slip_summary` |
| Progress tab | `-skip_onboarding -seed_marketing -tab_progress` |
| Progress detail | `-skip_onboarding -seed_marketing -tab_progress -open_first_detail` |
| Settings | `-skip_onboarding -seed_marketing -tab_settings` |

Dark mode: `xcrun simctl ui "iPhone 17" appearance dark` (set it back with `light`).

Large text: `xcrun simctl ui "iPhone 17" content_size accessibility-extra-extra-extra-large` (reset with `large`).

**Every task's "Done when" includes a before and after screenshot.** Take the "before" one before you edit.

---

## Sprint order

| # | Task | Phase | Effort | Status |
|---|------|-------|--------|--------|
| 1.1 | [Pressed and disabled states for every custom button](#11-pressed-and-disabled-states) | Foundations | S | [x] |
| 1.2 | [`ChoiceButton` for paired answers](#12-choicebutton) | Foundations | S | [x] |
| 1.3 | [`tbField` text-field style](#13-tbfield-text-field-style) | Foundations | S | [x] |
| 1.4 | [Fix edge-to-edge lists on iPhone](#14-fix-edge-to-edge-lists) | Foundations | XS | [x] |
| 2.1 | [Move the date out of the toolbar](#21-move-the-date-out-of-the-toolbar) | Today | XS | [x] |
| 2.2 | [Say "check in" on the streak banner](#22-say-check-in-on-the-streak-banner) | Today | XS | [x] |
| 2.3 | [Make the urge-surfing row dismissible](#23-dismissible-urge-surfing-row) | Today | S | [x] |
| 2.4 | [No empty section headers](#24-no-empty-section-headers) | Today | S | [x] |
| 2.5 | [Chevrons on tappable cards](#25-chevrons-on-tappable-cards) | Today | XS | [x] |
| 2.6 | [Animate the habit check](#26-animate-the-habit-check) | Today | XS | [x] |
| 2.7 | [Weekday letters under the week dots](#27-weekday-letters-under-the-week-dots) | Today | S | [x] |
| 2.8 | [Two choices on the empty state](#28-two-choices-on-the-empty-state) | Today | S | [x] |
| 3.1 | [Check-in answers show what you picked](#31-check-in-answers-show-what-you-picked) | Check-in | S | [x] |
| 3.2 | [Yesterday prompt uses the app's buttons](#32-yesterday-prompt-buttons) | Check-in | XS | [x] |
| 4.1 | [Pin the urge outcome buttons to the bottom](#41-pin-the-urge-outcome-buttons) | Urge | M | [x] |
| 4.2 | [Merge the intro card and the "What is urge surfing?" row](#42-merge-intro-and-link) | Urge | XS | [x] |
| 5.1 | [Slip summary: one button style, equal tiles, no double close](#51-slip-summary-cleanup) | Slip | S | [x] |
| 6.1 | [Progress summary card lines up with the list](#61-progress-summary-alignment) | Progress | XS | [x] |
| 6.2 | [Calendar: no markers on future days](#62-calendar-future-days) | Progress | S | [x] |
| 6.3 | [Quiet empty "Urges" line on the detail screen](#63-quiet-empty-urges-line) | Progress | XS | [x] |
| 7.1 | [Disable the reminder time while reminders are off](#71-reminder-time-disabled) | Settings | XS | [x] |
| 8.1 | [Onboarding progress bar starts with a filled step](#81-onboarding-progress-bar) | Onboarding | XS | [x] |
| 8.2 | [Celebration looks like a celebration](#82-celebration-hero) | Celebration | S | [x] |
| 10 | [Final QA and re-capture marketing screenshots](#10-final-qa) | QA | M | [x] |

Phase 9 is intentionally empty. See [Decisions for the owner](#decisions-for-the-owner): those are not for the implementer.

---

## Phase 1 — Foundations

Commit message for the phase: `Give custom buttons pressed states and add shared choice and field styles.`

### 1.1 Pressed and disabled states

**Why:** Every custom button and tappable card uses `.buttonStyle(.plain)`. They give almost no feedback when pressed, so the app feels unresponsive next to system controls.

**Files:**
- New: `UrgeBuddy/DesignSystem/Components/PressableStyle.swift`
- Edit: `UrgeBuddy/DesignSystem/Components/Buttons.swift`, `UrgeBuddy/DesignSystem/Components/ChipGrid.swift`, `UrgeBuddy/Features/Today/TodayChrome.swift`, `UrgeBuddy/Features/Today/ViceCard.swift`, `UrgeBuddy/Features/Today/CutBackCard.swift`, `UrgeBuddy/Features/Today/HabitCheckRow.swift`

**Steps:**

1. Create `PressableStyle.swift`:

   ```swift
   import SwiftUI

   /// Dims and slightly shrinks on press. Dims more when disabled. Reduce Motion keeps the dim and skips the shrink.
   struct PressableStyle: ButtonStyle {
       func makeBody(configuration: Configuration) -> some View {
           PressableBody(configuration: configuration)
       }
   }

   private struct PressableBody: View {
       let configuration: ButtonStyleConfiguration
       @Environment(\.isEnabled) private var isEnabled
       @Environment(\.accessibilityReduceMotion) private var reduceMotion

       var body: some View {
           configuration.label
               .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.45)
               .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
               .animation(reduceMotion ? nil : UrgeBuddyMotion.quick, value: configuration.isPressed)
       }
   }

   extension ButtonStyle where Self == PressableStyle {
       static var pressable: PressableStyle { PressableStyle() }
   }
   ```

2. Run `xcodegen generate` from `UrgeBuddy/`.
3. In **only the files listed above**, replace `.buttonStyle(.plain)` with `.buttonStyle(.pressable)`. Leave every other file alone (the urge flow, slip flow, and Progress list have their own tasks or don't need it).
4. `SecondaryButton` in `Buttons.swift` has no `accessibilityID` parameter but `PrimaryButton` does. Add the same `var accessibilityID: String? = nil` and `.modifier(AccessibilityIDModifier(id: accessibilityID))` to `SecondaryButton` so later tasks can use it.

**Done when:**
- Build passes. Pressing the check-in banner, a vice card, a habit row, a chip, and "Get started" in onboarding visibly dims.
- The disabled Done button in the check-in sheet still looks disabled (before: pale teal; after: about the same).
- Spec: add a `PressableStyle` row to the §8.4 table in `Specs/DesignSystemSpec.md`: "`.buttonStyle(.pressable)` — 0.8 opacity and 0.98 scale on press, 0.45 opacity when disabled, no scale under Reduce Motion. Use on every custom-drawn button."

### 1.2 `ChoiceButton`

**Why:** The check-in sheet and the "yesterday" prompt use system `.borderedProminent` and `.bordered` buttons. They are a different shape (small capsules that hug their text) from every other button in the app. And after you tap **Free today**, nothing on screen changes. Only VoiceOver hears "selected".

**Files:** New `UrgeBuddy/DesignSystem/Components/ChoiceButton.swift`.

**Steps:**

1. Create the component. It matches the selected and unselected colors `ChipGrid` already uses:

   ```swift
   import SwiftUI

   /// One answer in a pair ("Free today" / "I slipped"). Selected = Brand fill with a checkmark.
   struct ChoiceButton: View {
       var title: String
       var isSelected: Bool = false
       var accessibilityID: String? = nil
       var action: () -> Void

       var body: some View {
           Button(action: action) {
               HStack(spacing: Spacing.xs) {
                   if isSelected {
                       Image(systemName: "checkmark").accessibilityHidden(true)
                   }
                   Text(title).multilineTextAlignment(.center)
               }
               .font(.subheadline.weight(.semibold))
               .foregroundStyle(isSelected ? Color.tbOnBrand : Color.tbTextPrimary)
               .frame(maxWidth: .infinity, minHeight: 44)
               .padding(.horizontal, Spacing.m)
               .background(
                   isSelected ? Color.tbBrand : Color.tbSurfaceMuted,
                   in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
               )
           }
           .buttonStyle(.pressable)
           .accessibilityLabel(title)
           .accessibilityAddTraits(isSelected ? .isSelected : [])
           .accessibilityIdentifier(accessibilityID ?? "")
       }
   }
   ```

2. Add `#Preview`s in the same four flavors the other components use (`"Light"`, `"Dark"`, `"AX3"`, `"Landscape"`). Copy the pattern from the bottom of `Buttons.swift`. Show one selected and one unselected button in a `VStack`.
3. Run `xcodegen generate`.

**Done when:** Build passes and the previews render. Spec: add a `ChoiceButton` row to §8.4.

### 1.3 `tbField` text-field style

**Why:** Text fields use `.textFieldStyle(.roundedBorder)`: a thin gray-bordered box with small corners that matches nothing else in the app (see the "Anything on your mind?" field in the check-in sheet).

**Files:** New `UrgeBuddy/DesignSystem/Components/FieldStyle.swift`. Edit the 10 call sites found by `grep -rn "roundedBorder" UrgeBuddy/Features`.

**Steps:**

1. Create:

   ```swift
   import SwiftUI

   /// Filled field on Surface, matching cards and controls.
   struct TBFieldStyle: TextFieldStyle {
       func _body(configuration: TextField<Self._Label>) -> some View {
           configuration
               .padding(.horizontal, Spacing.m)
               .padding(.vertical, Spacing.s)
               .frame(minHeight: 44)
               .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
       }
   }

   extension TextFieldStyle where Self == TBFieldStyle {
       static var tbField: TBFieldStyle { TBFieldStyle() }
   }
   ```

2. Run `xcodegen generate`.
3. Replace every `.textFieldStyle(.roundedBorder)` in `Features/` with `.textFieldStyle(.tbField)`.
4. **Check each call site's background.** The field is `Surface` (white in light mode). If a field sits **inside** a white card, it will disappear. For those, wrap nothing and instead change that one call site to use `Color.tbSurfaceMuted`. The simplest way is to give the style an init parameter: `var fill: Color = .tbSurface`, and use `.textFieldStyle(TBFieldStyle(fill: .tbSurfaceMuted))` where needed. Check each one with a screenshot.

**Done when:** All 10 fields have the rounded filled look and are clearly visible in light and dark. Spec: add a `TBFieldStyle` row to §8.4.

### 1.4 Fix edge-to-edge lists

**Why:** In Settings (and Get help now), the grouped list rows run to the screen edges with no rounded corners. Progress uses the normal inset look. The cause is `readableListMargins()`: on any screen narrower than 640 pt it sets the side margin to `max(0, negative) = 0`.

**File:** `UrgeBuddy/DesignSystem/AdaptiveLayout.swift`, inside `ReadableListMargins`.

**Step:** Change

```swift
.contentMargins(.horizontal, max(0, (width - AdaptiveLayout.textColumnWidth) / 2), for: .scrollContent)
```

to

```swift
.contentMargins(.horizontal, max(Spacing.l, (width - AdaptiveLayout.textColumnWidth) / 2), for: .scrollContent)
```

**Done when:** Settings on iPhone shows inset rounded groups with a 16 pt side margin, like Progress. On iPad the list is still centered in a readable column.

---

## Phase 2 — Today

Commit message: `Tidy the Today screen: date, banner copy, empty sections, and card affordances.`

### 2.1 Move the date out of the toolbar

**Why:** On iOS 26 the date ("Mon, Nov 2") in the top-right toolbar gets a Liquid Glass capsule. It looks like a button but does nothing. The check-in sheet has the same problem.

**Files:** `UrgeBuddy/Features/Today/TodayScreen.swift`, `UrgeBuddy/Features/CheckIn/CheckInSheet.swift`.

**Steps:**
1. `TodayScreen.swift`: delete the whole `.toolbar { … }` block that holds `dateLabel`. Then, at the top of the main `VStack`, change `if dynamicTypeSize.usesAccessibilityLayout { dateLabel }` to just `dateLabel` so it always shows under the large "Today" title.
2. In `dateLabel`, use the long form so it reads as a subtitle: `.dateTime.weekday(.wide).month(.wide).day()` ("Monday, November 2").
3. `CheckInSheet.swift`: delete the `ToolbarItem(placement: .topBarTrailing)` that shows the date. Leave Close and the confirmation item alone.

**Done when:** No capsule in the top-right of Today or the check-in sheet. The date shows as gray text under "Today" at normal and AX5 sizes. `dynamicTypeSize` may now be unused in `TodayScreen` — remove it only if the compiler says it is unused.

### 2.2 Say "check in" on the streak banner

**Why:** With a streak, the big teal banner reads "9 days in a row · 1 to go · about 10 seconds". The words "check in" never appear, so a new user doesn't know it's the daily check-in or what "1 to go" means.

**Files:** `UrgeBuddy/Domain/Copy/RecoveryCopy.swift`, `UrgeBuddy/Tests/Unit/RecoveryCopyTests.swift`.

**Step:** Change `checkInBanner(left:)` to:

```swift
static func checkInBanner(left: Int) -> String {
    left == 1 ? "Check in · 1 thing left · about 10 seconds" : "Check in · \(left) things left · about 10 seconds"
}
```

Update the assertion at `RecoveryCopyTests.swift:34` to `"Check in · 3 things left · about 10 seconds"`, and add one for `left: 1`.

**Done when:** Unit tests pass. The banner subtitle starts with "Check in". Spec: update the Today banner copy in `Specs/ProductSpec.md` (search for "to go").

### 2.3 Dismissible urge-surfing row

**Why:** The "Urge surfing — An urge rises and passes, like a wave" row takes the second-best spot on Today forever. After someone has read it once, it's noise. The explainer is still in Settings → Support and inside the urge flow.

**Files:** `UrgeBuddy/Services/Preferences.swift`, `UrgeBuddy/Features/Today/TodayChrome.swift`, `UrgeBuddy/Features/Today/TodayScreen.swift`, `RecoveryCopy.swift`.

**Steps:**
1. In `Preferences`, add `hasDismissedUrgeSurfingTip: Bool` exactly like `hasAcceptedDisclaimer` (a `Bool` getter and setter plus a new `Key` constant, `"pref.dismissedUrgeSurfingTip"`).
2. In `UrgeSurfingRow`, add `var onDismiss: () -> Void`. Add a trailing `xmark` button, styled exactly like the one in `YesterdayPrompt` (44 pt frame, `TextSecondary`, `.accessibilityLabel(RecoveryCopy.dismiss)`). Put it **outside** the main `Button` so the two taps don't fight: wrap the existing `Button` and the new `xmark` button in an `HStack`, and move the `.padding` and `.background` from the inner label to that `HStack`. Keep the existing chevron.
3. In `TodayScreen`, add `@State private var surfingTipDismissed = Preferences.hasDismissedUrgeSurfingTip`. Show `UrgeSurfingRow` only when `model.showsSOS && !surfingTipDismissed`. The dismiss closure sets both the preference and the state to `true`, inside `withAnimation(reduceMotion ? nil : UrgeBuddyMotion.spring)` (add `@Environment(\.accessibilityReduceMotion) private var reduceMotion`).
4. Also set the preference to `true` when the row itself is tapped and the sheet opens: tapping it means they've seen it.
5. **Do not** change the SOS "I'm having an urge" button.

**Done when:** The row shows on a fresh install, disappears when tapped or dismissed, and stays gone after relaunch (relaunch **without** `-ui_testing`, because `-ui_testing` clears `UserDefaults` on every launch in `BootstrapStoreRecovery.swift`; that also means UI tests always start with the row visible). UI tests pass. Spec: ProductSpec Today section.

### 2.4 No empty section headers

**Why:** With only a cut back, Today shows "QUITTING +" with nothing under it, then "CUTTING BACK" (with no +). With no habits, "BUILDING +" sits alone at the bottom. Empty headers look broken.

**File:** `UrgeBuddy/Features/Today/TodayScreen.swift`. Possibly a small new view in `TodayChrome.swift`.

**Steps:**
1. **Quitting:** render `quittingSection` only when `!model.vices.isEmpty || model.cutBacks.isEmpty`.
2. **Cutting back:** when the quitting section is hidden (vices empty, cut backs present), give the Cutting back `SectionHeader` the add button the Quitting header had: `addLabel: RecoveryCopy.addQuitting, addID: AccessibilityIdentifiers.todayAddQuitting`, opening `.add(.vice)`. This keeps the UI-test ID on screen. Otherwise leave the Cutting back header with no + (today's behavior).
3. **Building, when empty:** keep the header and its +, and under it add an `AddPlaceholderRow` — a full-width row the same height as a habit row, with a `plus.circle` icon in `Brand`, the text `RecoveryCopy.addBuilding`, a `TextSecondary` dashed border (`RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Color.tbTextSecondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))`), and `.buttonStyle(.pressable)`. Tapping it does the same as the header +. Hide it from VoiceOver (`.accessibilityHidden(true)`), since the header + already announces the same action.

**Done when:** Screenshot with `-seed_cutback` shows no empty "QUITTING" header and a + on "CUTTING BACK". With no habits, "BUILDING" has a dashed "add" row under it. UI tests pass.

### 2.5 Chevrons on tappable cards

**Why:** Vice cards and cut-back cards open the detail screen, but nothing says they're tappable. The banner and urge-surfing rows already use a chevron.

**Files:** `ViceCard.swift`, `CutBackCard.swift`.

**Step:** In each card's header `HStack` (icon + name), add after the name:

```swift
Spacer(minLength: Spacing.s)
Image(systemName: "chevron.right")
    .font(.footnote.weight(.semibold))
    .foregroundStyle(Color.tbTextSecondary)
    .accessibilityHidden(true)
```

**Done when:** Both cards show a small gray chevron top-right. VoiceOver labels are unchanged.

### 2.6 Animate the habit check

**Why:** Ticking a habit swaps the circle for a checkmark with no motion. It's the most frequent tap in the app.

**File:** `HabitCheckRow.swift`, `toggleButton`.

**Step:** On the `Image(systemName: model.isDoneToday ? … )`, add:

```swift
.contentTransition(.symbolEffect(.replace))
.symbolEffect(.bounce, value: reduceMotion ? false : model.isDoneToday)
```

and add `@Environment(\.accessibilityReduceMotion) private var reduceMotion` to the struct.

**Done when:** Ticking a habit morphs and bounces the icon. With Reduce Motion on (Settings → Accessibility → Motion in the simulator), it just swaps.

### 2.7 Weekday letters under the week dots

**Why:** The row of seven dots on a vice card has no labels. Users can't tell which dot is today or which day the amber triangle is.

**File:** `UrgeBuddy/DesignSystem/Components/DayDots.swift`.

**Steps:**
1. The caller already passes `labels` (full weekday names like "Monday"). Add `var showsInitials: Bool = true`.
2. Wrap each `DayMark` in a `VStack(spacing: 2)` with, under it when `showsInitials` and a label exists, `Text(String(labels[index].prefix(1)))` in `.caption2`, `TextSecondary`. Hide the letter from VoiceOver.
3. Check the vice card and cut-back card at AX5. If the letters overlap or make the row wrap badly, hide them when `dynamicTypeSize.usesAccessibilityLayout` (read `@Environment(\.dynamicTypeSize)`).
4. Check that `labels` are weekday names in the current locale. If they are not (for example "Today"), derive the letter from `Calendar.current.veryShortWeekdaySymbols` instead. Do not hard-code English letters.

**Done when:** Vice and cut-back cards show "M T W T F S S"-style letters under the dots, in the right order for the device's first weekday. Previews still render. Spec: §8.4 `DayDots` row.

### 2.8 Two choices on the empty state

**Why:** A brand-new Today says "Add a vice or a habit" but the only button, "Add something", always opens the vice form.

**Files:** `UrgeBuddy/DesignSystem/Components/EmptyState.swift`, `TodayScreen.swift`, `RecoveryCopy.swift`.

**Steps:**
1. Add `var secondaryTitle: String? = nil` and `var secondaryAction: (() -> Void)? = nil` to `EmptyState`. When both are set, render a `SecondaryButton` under the primary one.
2. Add copy: `static let addSomethingToQuit = "Quit or cut back"` and `static let addAHabit = "Build a habit"`.
3. In `TodayScreen`, the primary button becomes `addSomethingToQuit` → `.add(.vice)`. The secondary is `addAHabit` → `.add(.positive)`.
4. Search the UI tests for the old "Add something" title or ID before renaming anything. If a test taps it by title, update the test.

**Done when:** Fresh Today shows both buttons, and each opens the right form. Spec: §8.4 `EmptyState` row and ProductSpec Today section.

---

## Phase 3 — Check-in

Commit message: `Show the chosen check-in answer and match the app's buttons.`

### 3.1 Check-in answers show what you picked

**File:** `UrgeBuddy/Features/CheckIn/CheckInSheet.swift`, `freeButton` and `slippedButton`.

**Steps:**
1. Replace `freeButton` with:

   ```swift
   ChoiceButton(
       title: RecoveryCopy.freeToday,
       isSelected: row.answer == .free,
       accessibilityID: AccessibilityIdentifiers.checkInFree(row.id)
   ) { markFree(row.id) }
   ```

2. Replace `slippedButton` with a `ChoiceButton` (never selected — choosing it opens the slip sheet, and the row then shows the "thanks" text) with `accessibilityID: AccessibilityIdentifiers.checkInSlipped(row.id)` and the existing action.
3. Remove the now-unused `.tint`, `.buttonStyle`, and `.frame` modifiers that were on the old buttons.
4. Leave `answerRow`'s `ViewThatFits` HStack/VStack as is.

**Done when:** Tapping "Free today" turns it teal with a checkmark. Both buttons are equal width and the same height as each other. UI tests for check-in pass.

### 3.2 Yesterday prompt buttons

**File:** `UrgeBuddy/Features/Today/TodayChrome.swift`, `YesterdayPrompt.actions`.

**Step:** Replace the two system buttons with `ChoiceButton(title: RecoveryCopy.yesterdayYes, action: onYes)` and `ChoiceButton(title: RecoveryCopy.iSlipped, action: onSlipped)`. Remove the old `.buttonStyle`, `.tint`, and `.frame` modifiers. If any accessibility IDs are on the old buttons, pass them through.

**Done when:** The prompt's buttons match the check-in sheet. To see it, you need a vice whose yesterday has no answer; if no launch argument produces that, check it in an Xcode preview or note in the PR that it was checked in code only.

---

## Phase 4 — Urge ride

Commit message: `Keep the urge outcome buttons in reach during a ride.`

### 4.1 Pin the urge outcome buttons

**Why:** This is the most important screen in the app, used in a hard moment. "The urge passed" and "I slipped" are at the very bottom, under the intro, the explainer link, the journal, your plan, your whys, and habit suggestions. On an iPhone that is several screens of scrolling.

**File:** `UrgeBuddy/Features/Urge/UrgeFlowView.swift`. Read the whole file first. It is long and has careful presentation logic. **Do not change any of that logic.**

**Steps:**
1. Find `rideSupport(_:)`. At the bottom it renders `PrimaryButton(title: RecoveryCopy.theUrgePassed, …)` and the slip `Button { beginFinish(.slipped) }`. Move those two buttons, unchanged (same actions, same accessibility IDs), into a new `private func rideActions(_ model: UrgeViewModel) -> some View` that returns them in a `VStack(spacing: Spacing.s)`.
2. In portrait (when `AdaptiveLayout.isShortHeight(vertical: verticalSizeClass)` is `false`), show `rideActions` pinned to the bottom. In `body`, the `ScrollView` sits inside `if let model { … }`, so `model` is already unwrapped there. Add this right after the `ScrollView`'s existing `.scrollDismissesKeyboard(.interactively)`:

   ```swift
   .safeAreaInset(edge: .bottom) {
       if model.step == .ride, pendingFinish == nil,
          !AdaptiveLayout.isShortHeight(vertical: verticalSizeClass) {
           ReadableColumn { rideActions(model) }
               .padding(.vertical, Spacing.s)
               .background(Color.tbCalm.opacity(0.95).ignoresSafeArea(edges: .bottom))
       }
   }
   ```

3. In landscape (short height), keep the buttons where they are now, at the end of `rideSupport`. So `rideSupport` should still call `rideActions(model)` when `isShortHeight` is `true`.
4. Don't change the journal editor, the whys, or the habit chips.

**Done when:**
- Portrait: "The urge passed" and "I slipped" are visible at the bottom without scrolling, and the content scrolls behind them. When the keyboard is up for the journal, the buttons sit above the keyboard or are covered by it — either is fine, but nothing may overlap the text field.
- Landscape iPhone and iPhone Duo inner screen: same as before.
- After tapping "I slipped" (the journal confirm step), the pinned bar is gone.
- UI tests `urge.passed`, `urge.slipped`, and the journal save/delete tests pass.

### 4.2 Merge intro and link

**Why:** The intro card ("This is urge surfing. The urge rises…") and the "What is urge surfing?" row right under it say the same thing twice.

**File:** `UrgeFlowView.swift`, `rideSupport`.

**Step:** Put `surfingLink` **inside** the intro card's container, under the text, instead of as its own row. The simplest way: wrap the intro `Text` and `surfingLink` in one `VStack(alignment: .leading, spacing: Spacing.m)` and move the intro's `.padding(Spacing.l)` and `.background(…)` to that `VStack`. Then remove `surfingLink`'s own background and use `.padding(.vertical, Spacing.xs)` in its place.

**Done when:** One card with the text and a "What is urge surfing? ›" line at its bottom. The link still opens the explainer sheet.

---

## Phase 5 — Slip

Commit message: `Match the slip summary's buttons and tiles to the rest of the app.`

### 5.1 Slip summary cleanup

**File:** `UrgeBuddy/Features/Slip/SlipFlowView.swift`.

**Steps:**
1. **Button style.** In `summaryActions()`, replace the custom white bordered "Need more support?" button with `SecondaryButton(title: RecoveryCopy.needSupport) { showHelp = true }`.
2. **Equal-height tiles.** In `summaryStat(…)`, add `.frame(maxHeight: .infinity, alignment: .topLeading)` immediately **before** the existing `.frame(maxWidth: .infinity, alignment: .leading)`. In `summaryStats(_:)`, add `.fixedSize(horizontal: false, vertical: true)` to the `HStack` (not the `VStack`).
3. **Tile copy.** The first tile reads "22 / Recent days free / of 23". Change it to value `"\(summary.freeDays) of \(summary.countedDays)"`, label `RecoveryCopy.slipRecentDaysFree`, and no caption. If `slipOfCounted` becomes unused, delete it and any test that only checks it.
4. **Double close.** The summary has both a top "Close" and a bottom "Back to Today" that do the same thing. Find the Close toolbar item and hide it only while the summary step is showing. Keep Close on the earlier steps.

**Done when:** Screenshot with `-slip_summary` shows two equal-height tiles ("22 of 23" and "$176.00"), a gray secondary "Need more support?" button above the teal "Back to Today", and no Close at the top. In landscape the actions still appear in the toolbar as before.

---

## Phase 6 — Progress

Commit message: `Align the Progress summary and quiet the calendar.`

### 6.1 Progress summary alignment

**Why:** The summary card ($176.00 total saved) is narrower than the metric list under it, and there's a large gap between them.

**File:** `UrgeBuddy/Features/Progress/ProgressScreen.swift`.

**Steps:**
1. On the `ProgressSummaryCard` row, add `.listRowInsets(EdgeInsets())`.
2. On the `List`, add `.listSectionSpacing(.compact)`.

**Done when:** The summary card's left and right edges line up with the metric list group, and the gap between them is about the same as between other groups. Check on iPad too (split view sidebar).

### 6.2 Calendar future days

**Why:** In the detail calendar, every future day has a gray dot under it, which looks like data.

**File:** `UrgeBuddy/DesignSystem/Components/MonthCalendar.swift`, `dayCell(_:)`.

**Steps:**
1. Compute `let isFuture = day > calendar.startOfDay(for: Date())`.
2. If `isFuture`, draw `Color.clear.frame(width: 12, height: 12)` in place of the `DayMark` (keeps the row height the same), make the number `TextSecondary`, and add `.disabled(true)` on the button.
3. For VoiceOver, future days should read just the date. The label is `.accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)), \(state.accessibilityName)")` at the end of `dayCell`. When `isFuture`, drop the `, \(state.accessibilityName)` part. Keep the `.accessibilityIdentifier` line as is.

**Done when:** Future days show only a gray number. Past and today are unchanged. Tapping a future day does nothing. Run the UI tests (the day editor tests tap past days).

### 6.3 Quiet empty "Urges" line

**File:** `UrgeBuddy/Features/Progress/MetricDetailScreen.swift`. Find where `RecoveryCopy.noUrgesYet` is shown.

**Step:** Style that text `.font(.footnote)` and `.foregroundStyle(Color.tbTextSecondary)` so it reads as a hint, not as data.

**Done when:** In the detail screenshot, "Urges you ride out show up here." is smaller and gray.

---

## Phase 7 — Settings

Commit message: `Disable the reminder time while reminders are off.`

### 7.1 Reminder time disabled

**File:** `UrgeBuddy/Features/Settings/SettingsScreen.swift`, the `reminders` section.

**Step:** Add `.disabled(!remindersEnabled)` to the `DatePicker(RecoveryCopy.time, …)`.

**Done when:** With "Daily check-in" off, the Time row is grayed out. Turning it on enables it.

---

## Phase 8 — Onboarding and celebration

Commit message: `Fill the first onboarding step and give milestones a hero.`

### 8.1 Onboarding progress bar

**Why:** On the first page the progress bar is empty, so it's invisible and looks like a stray line.

**File:** `UrgeBuddy/Features/Onboarding/OnboardingFlow.swift`, `progressFraction`.

**Step:** Change the body to:

```swift
guard !model.pages.isEmpty else { return 1 }
return CGFloat(model.pageIndex + 1) / CGFloat(model.pages.count)
```

**Done when:** The first page shows a short teal fill. The last page is full. Run `OnboardingViewModelTests` (they shouldn't touch this, but confirm).

### 8.2 Celebration hero

**Why:** A milestone sheet shows a plain "7" in the same size as numbers elsewhere, then a sentence. It doesn't feel like an achievement.

**File:** `UrgeBuddy/Features/Celebration/CelebrationView.swift`.

**Steps:**
1. Add `@ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 120`.
2. Replace both `Text("\(request.threshold)").bigNumberStyle()…` with a `heroBadge` view:

   ```swift
   private var heroBadge: some View {
       ZStack {
           Circle().fill(request.isVice ? Color.tbBrandSoft : Color.tbHabitSoft)
           VStack(spacing: 0) {
               Text("\(request.threshold)")
                   .font(.system(size: heroSize * 0.42, weight: .bold, design: .rounded))
                   .monospacedDigit()
               Text(RecoveryCopy.daysUnit(request.threshold))
                   .font(.subheadline.weight(.semibold))
           }
           .foregroundStyle(request.isVice ? Color.tbBrand : Color.tbHabit)
       }
       .frame(width: heroSize, height: heroSize)
       .accessibilityHidden(true)
   }
   ```

3. Add `RecoveryCopy.daysUnit(_:)` returning `"day"` for 1 and `"days"` otherwise, unless an equivalent already exists (search for `"days"` in `RecoveryCopy.swift` first and reuse it).
4. The milestone sentence under it already says the number, so VoiceOver loses nothing by hiding the badge.
5. Check the contrast: `Brand` on `BrandSoft` and `Habit` on `HabitSoft` must be ≥ 4.5:1 in both modes. Add those two pairs to `Tests/Unit/WCAGContrastTests.swift` using the existing pattern. If a pair fails, use `TextPrimary` for the text instead of the tint and tell the owner.

**Done when:** The milestone sheet shows a large soft circle with the number and "days" inside, scaling with text size. It still fades in under Reduce Motion (the existing `urgeBuddyCelebration` modifier handles that). Check landscape (`isShortHeight` branch) too. Spec: DesignSystemSpec §8.5 Celebration bullet.

---

## 10. Final QA

Commit message (only if this phase changes files): `Update specs and screenshots after the UI polish.`

1. **Tests.** Run unit tests and the full UI suite. Both must be green. Paste the summary counts in the PR or hand-off note.
2. **Large text.** Set AX5 (`content_size accessibility-extra-extra-extra-large`) and screenshot Today, check-in, urge ride, slip summary, Progress, detail, Settings, and onboarding. Nothing may be cut off mid-word, and every button must still be reachable.
3. **Dark mode.** Repeat the main screenshots in dark. Look especially at new `ChoiceButton`s, `tbField` fields, and the celebration badge.
4. **Reduce Motion.** Turn it on and check the habit check, button press, urge ride, and celebration.
5. **VoiceOver spot check** (Accessibility Inspector or the simulator): the vice card still reads as one element; the check-in "Free today" says "selected" after tapping; the dismiss button on the urge-surfing row is labeled.
6. **iPad and Duo.** Screenshot Today and the urge ride on the iPad Pro 13-inch and iPhone Duo simulators (both are already set up). Check the urge ride's pinned buttons on the iPad (they should be inside the readable column, not full width).
7. **Specs.** Make sure every task's spec update is done. Set `Last verified` and `Commit` in the Verification tables of any spec you touched.
8. **Marketing screenshots.** Today, cut back, slip summary, progress detail, and urge ride all changed, so the five App Store screenshots per device are now out of date. Re-run `Scripts/capture-marketing-screenshots.sh` for iPhone and iPad and `Scripts/capture-duo-marketing-screenshots.sh` for Duo. **Do not upload them to App Store Connect.** Tell the owner they're ready.
9. Update this file's status table and `ongoing/README.md`.

---

## Decisions for the owner

These came up in the review but change the brand or product. **Implementers: skip these.**

| # | Question | Notes |
|---|----------|-------|
| A | **Dark-mode brand is very bright.** The check-in banner and SOS button are large flat fills of `#2DD4BF` on near-black. Tone it down (for example `#14B8A6`), or use `BrandSoft` fills with `Brand` text in dark? | Palette change. Must re-run `WCAGContrastTests` and update §8.1. |
| B | ~~**Brand mark reads as "sync".**~~ Done 2026-11-03: the app icon and `BrandMark` are both the teal two overlapping circles. Re-render the icon with `Scripts/render-app-icon.sh`. | |
| C | **Run clock repeats the days.** The card says "9 days free" and then "9d 4h 12m · $176 saved". Drop the days from the clock line ("4h 12m into day 10"), or keep it? | Copy and tests in `RecoveryCopyTests`. |
| D | **Collapse the urge journal** behind a "Write it down" button to shorten the ride screen further. | Would change the urge journal UI tests. |
| E | **Re-upload screenshots.** Phase 10 regenerates them; uploading to App Store Connect is yours. | |

---

## Found while working

Implementers: add anything you noticed but didn't fix here, with file and line.

- The strength step keeps the "What is urge surfing?" pill. The ride screen embeds that link in the intro card via `surfingLink(inCard:)`.
- The yesterday prompt has no launch argument, so its `ChoiceButton`s were checked in code only.
- Reasons and plan fields on metric detail sit on a `Surface` card, so they use `TBFieldStyle(fill: .tbSurfaceMuted)`. The other fields stay `Surface` on `Background`.
- The settings spec line (Time disabled while reminders are off) is in the onboarding/celebration commit. The settings code commit had already landed.
- Pinning the urge buttons with `safeAreaInset` left the journal field under the bar, so the journal UI test could not focus it. The buttons sit in a `VStack` under the scroll view instead. Content does not scroll behind them.
- Settings' last rows (Import, Delete all data) sit under the tab bar on iPhone 17.
- No launch argument opens the celebration sheet or an unanswered yesterday, so those were checked in code. Reduce Motion and VoiceOver were not run live.
