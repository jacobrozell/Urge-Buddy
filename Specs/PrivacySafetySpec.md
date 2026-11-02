# TrackBoth Privacy and Safety Spec

> Spec governance: behavior changes update the matching spec in the same commit.


## Crisis resources

**CrisisResourcesView** (static content, all links tappable):
- "If you're in immediate danger, call **911** or your local emergency number." (`tel:911`)
- **988 Suicide & Crisis Lifeline** (US): call or text **988** (`tel:988`, `sms:988`)
- **SAMHSA National Helpline** (US): **1-800-662-4357**. Free, confidential, 24/7, English and Spanish. (`tel:18006624357`)
- Outside the US: **findahelpline.com** (`https://findahelpline.com`)
- "Stopping alcohol, benzodiazepines, or opioids suddenly can be dangerous. Talk to a doctor or pharmacist."


## Notifications

### 7.5 Notifications (`Services/ReminderScheduler.swift`)

- `requestAuthorization() async -> Bool` uses `.alert, .sound, .badge`. Only call it from onboarding step 6 or the Settings toggle.
- `refresh(context: ModelContext, now: Date = Date()) async`:
  1. Remove pending requests whose identifier starts with `checkin.` or `milestone.`.
  2. If daily reminders are on: for each of the next **7 days** (`d = 0…6`), build `DateComponents(year, month, day, hour, minute)`. **Skip today** if the check-in is already complete or the time has passed. Add `UNNotificationRequest(identifier: "checkin.<yyyy-MM-dd>", trigger: UNCalendarNotificationTrigger(dateMatching:repeats: false))`.
  3. If milestone notifications are on: for each active vice, take the next 2 thresholds after `currentRunDays`. `fireDate = calendar.date(byAdding: .day, value: threshold, to: currentRunStart)`. If it's in the future and within 30 days, add a `UNTimeIntervalNotificationTrigger` (or a calendar trigger) with ID `milestone.<metricID>.<threshold>`.
  4. Stay well under iOS's 64-pending limit: at most 7 + 2 × (active vices, max 10).
- Copy (in `RecoveryCopy`):
  - Check-in: title "Daily check-in", body "How did today go? It takes 10 seconds."
  - Milestone: title "7 days free", body "You reached 7 days free from Alcohol. Open Urge Buddy to celebrate."
  - **Discreet:** check-in title "Urge Buddy", body "Time for your check-in." Milestone body "You reached a new milestone."
- Tapping a notification: set `UNUserNotificationCenter.current().delegate` (in `AppDelegate`). The check-in ID opens the check-in flow; a milestone opens Today.


## App lock

### 7.6 App lock (`Services/AppLock.swift`)

```swift
import LocalAuthentication
import Observation

@Observable @MainActor
final class AppLock {
    static let shared = AppLock()
    var isLocked: Bool
    var isEnabled: Bool {
        didSet { Preferences.appLockEnabled = isEnabled }
    }

    private init() {
        isEnabled = Preferences.appLockEnabled
        isLocked = Preferences.appLockEnabled
    }

    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    func lockIfEnabled() { if isEnabled { isLocked = true } }

    func unlock() async {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            isLocked = false          // no passcode on device → can't lock; fail open, show a note in Settings
            return
        }
        do {
            if try await context.evaluatePolicy(.deviceOwnerAuthentication,
                                                localizedReason: "Unlock Urge Buddy") {
                isLocked = false
            }
        } catch {
            // stay locked; LockScreen shows "Unlock" button again
        }
    }
}
```

- Add `INFOPLIST_KEY_NSFaceIDUsageDescription: "Use Face ID to keep your progress private."` to `project.yml`.
- **Only lock on `.background`, never on `.inactive`.** The Face ID prompt itself makes the scene inactive, so locking there would loop forever.
- `LockScreen`: `BrandMark`, "Urge Buddy is locked", [Unlock] button. Call `unlock()` automatically on appear.


## Preferences

### 7.7 Preferences (`Services/Preferences.swift`)

One enum with static computed properties over `UserDefaults.standard`. Keys are prefixed `pref.`. Contents: `hasCompletedOnboarding`, `hasAcceptedDisclaimer`, `remindersEnabled`, `reminderHour` (default 20), `reminderMinute` (0), `milestoneNotificationsEnabled` (true), `discreetNotifications` (false), `appLockEnabled` (false), `appearance` (`system` / `light` / `dark`), `hasRequestedReview` (false), `dismissedYesterdayPromptDay` (Date?). Plus `resetAll()`.

### 7.8 Review prompt

After a `CelebrationView` for a **7-day vice milestone** is dismissed, and only if `!Preferences.hasRequestedReview`: call `@Environment(\.requestReview)` once, then set the flag. Never after a slip. Never during an urge.


## Release gate — safety, privacy, quality

### 12.2 Safety
- [ ] Disclaimer in onboarding and Settings → About.
- [ ] Crisis resources one tap from Settings and from the slip summary.
- [ ] No medical claims in the app or the listing.

### 12.3 Privacy
- [ ] No network calls (`git grep -n "URLSession\|URLRequest"` returns nothing in the app target).
- [ ] App lock works. The privacy cover hides content in the app switcher.
- [ ] Discreet notifications never show metric names.
- [ ] `PrivacyInfo.xcprivacy` present and correct. App Privacy = Data Not Collected.

### 12.4 Quality
- [ ] CI green: build, unit tests, coverage ≥80% on core files.
- [ ] All UI tests in §11.2 pass.
- [ ] Accessibility gates (§8.6) pass. Inspector audit clean.
- [ ] Device QA matrix and 7-day dogfood done, with zero open P0/P1.
- [ ] Docs updated: README, Specs (with Verification blocks), feature inventory, project status, ongoing.


## Verification

| Field | Value |
|-------|--------|
| Last verified | — |
| Commit | — |

