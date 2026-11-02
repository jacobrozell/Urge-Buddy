# TrackBoth Rules and Data Spec

> Spec governance: behavior changes update the matching spec in the same commit.


Domain rules below are product decisions. Implement the worked examples exactly. Future schema changes after launch need a new `TrackBothSchemaV3` with nested model copies and a `MigrationStage`. `TrackBothSchemaV2` is the frozen baseline. Do not add that ladder now.

## 6. Data model and rules

### 6.1 Conventions

- **Day anchor:** store calendar days as **local noon** (`DayMath.anchor(_:)`). Compare days with `calendar.startOfDay(for:)`. *Why noon:* storing midnight means a westward time-zone change shifts the value into the previous day (00:00 EDT = 21:00 PDT the day before). Noon survives time-zone shifts of up to ±11 hours.
- **Timestamps** (`occurredAt`, `startedAt`, urge times) are real `Date`s, not anchors.
- **Enums are stored as raw `String`s** (`statusRaw`, `outcomeRaw`) with computed accessors. SwiftData `#Predicate` can't filter on enum properties reliably. Raw strings also keep a future CloudKit move possible.
- Every stored property **has a default value** and every relationship-like reference is a `UUID` (same pattern as the current code). That keeps future iCloud sync possible (CloudKit requires defaults/optionals).
- Lists of tags are stored as a single `|`-joined string (`triggersRaw`) with a typed accessor. Don't use `[String]` attributes.
- **One entry per (metric, day).** `RecoveryStore` upserts it. Never insert a second entry for the same day.

### 6.2 Models (`Data/Models/`)

```swift
// Data/Models/Metric.swift
import Foundation
import SwiftData

@Model
final class Metric {
    var id: UUID = UUID()
    var name: String = ""
    var habitType: HabitType = HabitType.vice   // .vice = quitting, .positive = building
    var iconName: String = "circle.dashed"      // SF Symbol from presets
    var createdAt: Date = Date()
    /// Vice: when the current quit attempt began (the "quit date"). Habit: when tracking began.
    var startedAt: Date = Date()
    /// Vice only. Money the vice cost per day, decimal string, e.g. "12.50".
    var costPerDayRaw: String?
    /// Vice only. "When I feel the urge, I will …"
    var ifThenPlan: String?
    var sortOrder: Int = 0
    var isArchived: Bool = false

    init(name: String, habitType: HabitType, iconName: String, startedAt: Date = Date(), sortOrder: Int = 0) {
        self.name = name
        self.habitType = habitType
        self.iconName = iconName
        self.startedAt = startedAt
        self.sortOrder = sortOrder
    }

    var costPerDay: Decimal? {
        get {
            guard let costPerDayRaw, let value = Decimal(string: costPerDayRaw), value > 0 else { return nil }
            return value
        }
        set {
            if let newValue, newValue > 0 {
                costPerDayRaw = NSDecimalNumber(decimal: newValue).stringValue
            } else {
                costPerDayRaw = nil
            }
        }
    }
}
```

```swift
// Data/Models/HabitType.swift — keep the existing raw values so legacy imports map 1:1.
enum HabitType: String, CaseIterable, Codable {
    case positive = "positive"   // UI: "Building"
    case vice = "vice"           // UI: "Quitting"
}
```

```swift
// Data/Models/MetricEntry.swift
@Model
final class MetricEntry {
    var id: UUID = UUID()
    var metricID: UUID = UUID()
    /// Local-noon anchor of the calendar day (DayMath.anchor).
    var day: Date = Date()
    var statusRaw: String = EntryStatus.free.rawValue
    /// When it happened. For slips this restarts the free clock.
    var occurredAt: Date = Date()
    var note: String?
    var triggersRaw: String = ""

    init(metricID: UUID, day: Date, status: EntryStatus, occurredAt: Date) {
        self.metricID = metricID
        self.day = day
        self.statusRaw = status.rawValue
        self.occurredAt = occurredAt
    }

    var status: EntryStatus {
        get { EntryStatus(rawValue: statusRaw) ?? .free }
        set { statusRaw = newValue.rawValue }
    }

    var triggers: [TriggerTag] {
        get { TriggerTag.decode(triggersRaw) }
        set { triggersRaw = TriggerTag.encode(newValue) }
    }
}

enum EntryStatus: String, Codable, CaseIterable {
    case free      // vice: confirmed free day
    case slipped   // vice: used / did it
    case done      // habit: completed
    case partial   // amount habit: logged, below target
    case within    // cut back: at or under the limit
    case over      // cut back: over the limit
}
```

**Amounts and day notes** (added in place to `TrackBothSchemaV2`; new properties are optional or defaulted, so lightweight migration keeps existing stores):

| Model | Field | Rule |
|-------|-------|------|
| `Metric` | `viceModeRaw: String = "quit"` | `ViceMode.quit` or `.cutBack`. Habits ignore it. |
| `Metric` | `unit: String?` | Display unit. Falls back to "times". |
| `Metric` | `dailyTarget: Int?` | Habit: target (≥ 1; `nil` = yes/no habit). Cut back: daily limit (≥ 0). |
| `Metric` | `baselinePerDay: Int?` | Cut back only. Usual amount before cutting back (> 0). |
| `MetricEntry` | `amount: Int?` | Cut back and amount habits only. |
| `DayNote` (new) | `day`, `moodRaw` (0 = none, 1…5), `text?`, `updatedAt` | One per calendar day (noon anchor), across all metrics. |

`within`/`over` is decided when the amount is saved against the limit at that time, so changing the limit later doesn't rewrite past days. `Metric.tracksAmount` = cut back, or a habit with a target.

```swift
// Data/Models/UrgeEvent.swift
@Model
final class UrgeEvent {
    var id: UUID = UUID()
    var metricID: UUID = UUID()
    var startedAt: Date = Date()
    var endedAt: Date?
    var outcomeRaw: String = UrgeOutcome.inProgress.rawValue
    var intensity: Int = 3            // 1…5
    var triggersRaw: String = ""
    var note: String?

    init(metricID: UUID, intensity: Int, startedAt: Date = Date()) {
        self.metricID = metricID
        self.intensity = intensity
        self.startedAt = startedAt
    }

    var outcome: UrgeOutcome {
        get { UrgeOutcome(rawValue: outcomeRaw) ?? .unknown }
        set { outcomeRaw = newValue.rawValue }
    }
}

enum UrgeOutcome: String, Codable, CaseIterable { case inProgress, resisted, slipped, unknown }
```

```swift
// Data/Models/Reason.swift
@Model
final class Reason {
    var id: UUID = UUID()
    var metricID: UUID = UUID()
    var text: String = ""
    var createdAt: Date = Date()
    var sortOrder: Int = 0           // 0 = primary

    init(metricID: UUID, text: String, sortOrder: Int) {
        self.metricID = metricID
        self.text = text
        self.sortOrder = sortOrder
    }
}
```

```swift
// Data/Models/TrackBothSchema.swift
enum TrackBothSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Metric.self, MetricEntry.self, UrgeEvent.self, Reason.self]
    }
}

enum TrackBothMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [TrackBothSchemaV2.self] }
    static var stages: [MigrationStage] { [] }
}
```

> **Future schema changes (after launch):** `TrackBothSchemaV2` becomes the frozen baseline. Any later change needs a `TrackBothSchemaV3` with **nested copies** of the models and a `MigrationStage`. Write this down in `RulesAndDataSpec.md`. Don't do it now.

### 6.3 Container (`Data/BootstrapStoreRecovery.swift`)

- `ModelConfiguration("TrackBothV2", schema: schema)` gives a **new store file**, so the old `TrackBoth.store` on dev devices is never opened. That avoids a crash into the in-memory fallback.
- Pass `migrationPlan: TrackBothMigrationPlan.self` to `ModelContainer`.
- If the launch arguments contain `-ui_testing`, use `isStoredInMemoryOnly: true` and clear the `UserDefaults` domain.
- Keep the existing in-memory fallback and `mode` flag. Show `StoreRecoveryBanner` ("Your data couldn't be loaded. Changes won't be saved. Export or contact support.") when `mode == .inMemoryFallback`.
- **Owner note:** before installing the new build on a personal device, export JSON from the old build (Settings → Export) and import it in the new one (§6.10 legacy import).

### 6.4 `RecoveryStore` (`Data/RecoveryStore.swift`) — the only place that writes

```swift
@MainActor
final class RecoveryStore {
    let context: ModelContext
    init(context: ModelContext) { self.context = context }

    // Metrics
    func addMetric(name: String, habitType: HabitType, iconName: String,
                   startedAt: Date, costPerDay: Decimal?, firstReason: String?) throws -> Metric
    func update(_ metric: Metric, name: String, iconName: String, startedAt: Date, costPerDay: Decimal?) throws
    func setPlan(_ metric: Metric, plan: String?) throws
    func setArchived(_ metric: Metric, _ archived: Bool) throws
    func reorder(_ metrics: [Metric]) throws                     // rewrites sortOrder 0…n
    func delete(_ metric: Metric) throws                         // + its entries, urges, reasons, milestone ledger record

    // Days
    func markFree(_ metric: Metric, on day: Date, now: Date = Date()) throws   // vice; upsert status .free
    func logSlip(_ metric: Metric, occurredAt: Date, triggers: [TriggerTag], note: String?) throws // upsert .slipped for day of occurredAt
    func setHabitDone(_ metric: Metric, on day: Date, done: Bool, now: Date = Date()) throws        // upsert .done or delete entry
    func clearDay(_ metric: Metric, on day: Date) throws         // delete entry for that day

    // Urges
    func startUrge(for metric: Metric, intensity: Int, now: Date = Date()) throws -> UrgeEvent
    func finishUrge(_ urge: UrgeEvent, outcome: UrgeOutcome, triggers: [TriggerTag], note: String?, now: Date = Date()) throws

    // Reasons
    func addReason(_ text: String, to metric: Metric) throws
    func updateReason(_ reason: Reason, text: String) throws
    func deleteReason(_ reason: Reason) throws
    func reorderReasons(_ reasons: [Reason]) throws

    // Everything
    func deleteAllData() throws                                  // all 4 models + Preferences.resetAll() + MilestoneLedger.clearAll()
}
```

Rules:
- Every public method ends with `context.saveChanges(operation:entity:)`. If that returns `false`, throw `RecoveryStoreError.saveFailed`.
- After every successful save, post `Notification.Name.recoveryDataChanged`. `RootView` listens and refreshes scheduled notifications (§7.5).
- `entry(for:on:)` is internal: it fetches with `FetchDescriptor<MetricEntry>` using `#Predicate { $0.metricID == id && $0.day >= start && $0.day < end }`, where `start`/`end` bracket the calendar day.
- `logSlip` refuses (throws `.slipBeforeStart`) when `occurredAt < startOfDay(metric.startedAt)`.
- `markFree` on a day that's already `.slipped` → **do nothing**. Only the Day editor's explicit "Free" (which calls `clearDay` and then `markFree`) can override a slip.
- `setAmount(_:on:amount:)` does nothing unless `tracksAmount`. Cut back: saves `within`/`over`; 0 is kept as a logged day. Amount habit: `done` at or above target, `partial` below, 0 deletes the entry. `addAmount` adds a delta, floored at 0.
- `setHabitDone(done: true)` on an amount habit raises the amount to the target.
- `setDayNote(on:mood:text:)` upserts, trims text, and deletes the note when both mood and text are empty.
- `addMetric`/`update` take `MetricTracking` and normalize it: quit vices clear unit, target, and baseline; habits keep a unit only with a target.

### 6.5 `DayMath` (`Domain/Calendar/DayMath.swift`)

```swift
import Foundation

enum DayMath {
    /// Local-noon anchor used for stored `MetricEntry.day` values.
    static func anchor(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? calendar.startOfDay(for: date)
    }

    static func key(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    /// 23:59:59 on the given day (used when a slip is logged for a past day).
    static func endOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }

    /// Every day key from `start` through `end`, inclusive.
    static func days(from start: Date, through end: Date, calendar: Calendar = .current) -> [Date] {
        var result: [Date] = []
        var cursor = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        while cursor <= last {
            result.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }
}
```

### 6.6 Recovery math (`Domain/Recovery/RecoveryMath.swift`, `Domain/Habits/HabitMath.swift`)

Domain works on value types, never on `@Model` objects. `Data/Snapshots.swift` maps models to these.

```swift
import Foundation

struct ViceHistory: Equatable {
    var startedAt: Date
    var slips: [Date]                 // occurredAt of every .slipped entry
    var confirmedFreeDays: Set<Date>  // startOfDay keys of .free entries
}

enum DayState: Equatable {
    case beforeStart, future, slipped, confirmedFree, presumedFree, todayPending
}

enum RecoveryMath {
    static func relevantSlips(_ h: ViceHistory) -> [Date] {
        h.slips.filter { $0 >= h.startedAt }.sorted()
    }

    /// When the current free run began: the latest slip, or the quit date.
    static func currentRunStart(_ h: ViceHistory) -> Date {
        relevantSlips(h).last ?? h.startedAt
    }

    /// Whole 24-hour periods in the current run. Drives "N days free" and milestones.
    static func currentRunDays(_ h: ViceHistory, now: Date, calendar: Calendar = .current) -> Int {
        let start = currentRunStart(h)
        guard now > start else { return 0 }
        return calendar.dateComponents([.day], from: start, to: now).day ?? 0
    }

    /// Day/hour/minute components for the live clock.
    static func currentRunClock(_ h: ViceHistory, now: Date, calendar: Calendar = .current) -> DateComponents {
        let start = currentRunStart(h)
        return calendar.dateComponents([.day, .hour, .minute], from: start, to: max(now, start))
    }

    static func longestRunDays(_ h: ViceHistory, now: Date, calendar: Calendar = .current) -> Int {
        let points = [h.startedAt] + relevantSlips(h) + [max(now, h.startedAt)]
        return zip(points, points.dropFirst())
            .map { calendar.dateComponents([.day], from: $0, to: $1).day ?? 0 }
            .max() ?? 0
    }

    static func state(of day: Date, in h: ViceHistory, now: Date, calendar: Calendar = .current) -> DayState {
        state(of: calendar.startOfDay(for: day), in: h, slipDays: slipDays(h, calendar), now: now, calendar: calendar)
    }

    /// (free, counted) over the last `window` days ending today.
    static func freeDays(inLast window: Int, _ h: ViceHistory, now: Date, calendar: Calendar = .current) -> (free: Int, counted: Int) {
        let today = calendar.startOfDay(for: now)
        guard window > 0, let first = calendar.date(byAdding: .day, value: -(window - 1), to: today) else { return (0, 0) }
        return tally(DayMath.days(from: first, through: today, calendar: calendar), h, now: now, calendar: calendar)
    }

    /// Free days since the quit date. Never reset by a slip.
    static func totalFreeDays(_ h: ViceHistory, now: Date, calendar: Calendar = .current) -> Int {
        tally(DayMath.days(from: h.startedAt, through: now, calendar: calendar), h, now: now, calendar: calendar).free
    }

    /// Money saved = total free days × cost per day. Not reset by a slip.
    static func moneySaved(totalFreeDays: Int, costPerDay: Decimal?) -> Decimal? {
        guard let costPerDay, costPerDay > 0, totalFreeDays > 0 else { return nil }
        return costPerDay * Decimal(totalFreeDays)
    }

    // MARK: - Private

    private static func slipDays(_ h: ViceHistory, _ calendar: Calendar) -> Set<Date> {
        Set(relevantSlips(h).map { calendar.startOfDay(for: $0) })
    }

    private static func state(of key: Date, in h: ViceHistory, slipDays: Set<Date>, now: Date, calendar: Calendar) -> DayState {
        let today = calendar.startOfDay(for: now)
        if key < calendar.startOfDay(for: h.startedAt) { return .beforeStart }
        if key > today { return .future }
        if slipDays.contains(key) { return .slipped }
        if h.confirmedFreeDays.contains(key) { return .confirmedFree }
        return key == today ? .todayPending : .presumedFree
    }

    private static func tally(_ days: [Date], _ h: ViceHistory, now: Date, calendar: Calendar) -> (free: Int, counted: Int) {
        let slips = slipDays(h, calendar)
        return days.reduce(into: (free: 0, counted: 0)) { acc, day in
            switch state(of: day, in: h, slipDays: slips, now: now, calendar: calendar) {
            case .confirmedFree, .presumedFree:
                acc.free += 1
                acc.counted += 1
            case .slipped:
                acc.counted += 1
            case .beforeStart, .future, .todayPending:
                break
            }
        }
    }
}
```

```swift
struct HabitHistory: Equatable {
    var startedAt: Date
    var doneDays: Set<Date>   // startOfDay keys of .done entries
}

enum HabitMath {
    /// "Never miss twice": one missed day pauses the run; two missed days in a row end it.
    /// Today never counts as a miss because the day isn't over.
    static func currentRun(_ h: HabitHistory, now: Date, calendar: Calendar = .current) -> Int {
        let firstDay = calendar.startOfDay(for: h.startedAt)
        var cursor = calendar.startOfDay(for: now)
        let today = cursor
        var run = 0
        var consecutiveMisses = 0
        while cursor >= firstDay {
            if h.doneDays.contains(cursor) {
                run += 1
                consecutiveMisses = 0
            } else if cursor != today {
                consecutiveMisses += 1
                if consecutiveMisses >= 2 { break }
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return run
    }

    /// Yesterday was missed and today isn't done yet. Show the gentle "Don't miss twice" hint.
    static func isAtRisk(_ h: HabitHistory, now: Date, calendar: Calendar = .current) -> Bool {
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              yesterday >= calendar.startOfDay(for: h.startedAt) else { return false }
        return !h.doneDays.contains(today)
            && !h.doneDays.contains(yesterday)
            && currentRun(h, now: now, calendar: calendar) > 0
    }

    /// Longest run ever, using the same never-miss-twice rule walking forward.
    static func bestRun(_ h: HabitHistory, now: Date, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        var best = 0
        var run = 0
        var consecutiveMisses = 0
        for day in DayMath.days(from: h.startedAt, through: now, calendar: calendar) {
            if h.doneDays.contains(day) {
                run += 1
                consecutiveMisses = 0
            } else if day != today {
                consecutiveMisses += 1
                if consecutiveMisses >= 2 { run = 0 }
            }
            best = max(best, run)
        }
        return best
    }

    static func doneCount(inLast window: Int, _ h: HabitHistory, now: Date, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        guard window > 0, let first = calendar.date(byAdding: .day, value: -(window - 1), to: today) else { return 0 }
        return h.doneDays.filter { $0 >= first && $0 <= today }.count
    }
}
```

**Worked examples** (copy these into tests verbatim). Calendar = Gregorian, time zone = `America/New_York`, year **2026**. Habit examples use startedAt = Oct 1.

| # | Setup | Expect |
|---|-------|--------|
| V1 | startedAt = Oct 1 09:00, no slips, now = Oct 13 10:00 | currentRunDays 12; totalFreeDays 12 (Oct 1–12; Oct 13 is `todayPending`); freeDays(inLast:30) = (12, 12) |
| V2 | V1 + slip at Oct 10 20:00, now = Oct 13 10:00 | currentRunStart = Oct 10 20:00; currentRunDays 2; longestRunDays 9; totalFreeDays 11; freeDays(30) = (11, 12) |
| V3 | V2 + confirmed free Oct 13 | freeDays(30) = (12, 13); state(Oct 13) = confirmedFree |
| V4 | Slip occurredAt Sep 20 (before startedAt Oct 1) | ignored: same results as V1 |
| V5 | costPerDay 8, V2 | moneySaved = 88 |
| V6 | Today: startedAt now − 3h | currentRunDays 0; clock 0d 3h 0m |
| V7 | DST fall-back: startedAt Oct 31 12:00, now Nov 2 12:00 (Sun Nov 1, 2026 is the 25-hour day) | currentRunDays 2; totalFreeDays 2 |
| V8 | DST spring-forward: startedAt Mar 7 12:00, now Mar 9 12:00 (Sun Mar 8, 2026 is the 23-hour day) | currentRunDays 2; totalFreeDays 2 |
| H1 | done Oct 10, 11, 12; now Oct 13 (not done) | currentRun 3; isAtRisk false |
| H2 | done Oct 9, 10, 12; now Oct 13 (not done) | currentRun 3 (single miss on Oct 11 pauses, doesn't end) |
| H3 | done Oct 8, 9, 10; now Oct 13 | currentRun 0 (Oct 12 + Oct 11 missed) |
| H4 | done Oct 10, 11; now Oct 13 (not done, Oct 12 missed) | currentRun 2; isAtRisk true |
| H5 | startedAt Oct 13, now Oct 13, not done | currentRun 0; isAtRisk false |

### 6.6a Cut back math (`Domain/Quantity/AmountMath.swift`)

- `AmountMath.step(for: target)`: 5 when the target is ≥ 20, else 1. Habit done when amount ≥ target. Over when amount > limit.
- `CutBackMath` works on a `CutBackHistory` (start, limit, baseline, logged days keyed by anchor).
- Day state: before start, future, today pending (nothing logged yet), not logged (past, unknown), within, over.
- `withinDays(inLast: n)` and `average(inLast: n)` cover the n days before today, from the start date on, and count logged days only.
- `reductionPercent = round((1 − average / baseline) × 100)`, `nil` without a baseline or when the average isn't below it. Today falls back to "Avg N a day".
- Money saved = Σ max(0, baseline − amount) over logged days before today × costPerDay ÷ baseline. It needs a baseline and is added to Progress "Total saved".

### 6.7 Triggers (`Domain/Triggers/TriggerTag.swift`)

```swift
enum TriggerTag: String, CaseIterable, Codable, Identifiable {
    case hungry, angry, lonely, tired          // HALT
    case stressed, anxious, sad, bored
    case celebrating, social, cue, routine, other
    var id: String { rawValue }

    var title: String {
        switch self {
        case .hungry: "Hungry"
        case .angry: "Angry"
        case .lonely: "Lonely"
        case .tired: "Tired"
        case .stressed: "Stressed"
        case .anxious: "Anxious"
        case .sad: "Down"
        case .bored: "Bored"
        case .celebrating: "Celebrating"
        case .social: "Around others"
        case .cue: "Saw it nearby"
        case .routine: "Usual time"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .hungry: "fork.knife"
        case .angry: "flame"
        case .lonely: "person"
        case .tired: "bed.double"
        case .stressed: "bolt.heart"
        case .anxious: "waveform.path.ecg"
        case .sad: "cloud.rain"
        case .bored: "hourglass"
        case .celebrating: "party.popper"
        case .social: "person.3"
        case .cue: "eye"
        case .routine: "clock"
        case .other: "ellipsis.circle"
        }
    }

    static func encode(_ tags: [TriggerTag]) -> String { tags.map(\.rawValue).joined(separator: "|") }
    static func decode(_ raw: String) -> [TriggerTag] { raw.split(separator: "|").compactMap { TriggerTag(rawValue: String($0)) } }
}
```

### 6.8 Insights (`Domain/Triggers/PatternInsights.swift`)

- `topTriggers(from: [[TriggerTag]], limit: 3) -> [(TriggerTag, Int)]`: count across slips and urges for one metric, sort by count descending then by `TriggerTag.allCases` order, drop `.other` unless it's the only one.
- `TimeOfDay`: `.morning` 05:00–11:59, `.afternoon` 12:00–16:59, `.evening` 17:00–21:59, `.night` 22:00–04:59.
- `hardestTime(from timestamps: [Date]) -> TimeOfDay?`: the bucket with the most slips + non-resisted urges. `nil` if fewer than 3 data points or a tie for first place.
- `urgeSummary(_ outcomes: [UrgeOutcome]) -> (beaten: Int, total: Int)`: total excludes `.inProgress`.
- `urgeBreakdown(_ samples: [UrgeSample]) -> UrgeBreakdown`: beaten, slipped, unsure, total, and mean intensity. In-progress samples are left out of every field, including the average.
- `hardestWeekday(from timestamps: [Date]) -> Int?`: the `Calendar` weekday with the most slips + non-resisted urges. `nil` if fewer than 3 timestamps or a tie for first. Same timestamps as `hardestTime`.

### 6.9 Milestones (`Domain/Milestones/MilestonePolicy.swift` + `Services/MilestoneLedger.swift`)

```swift
enum MilestonePolicy {
    static let viceDays = [1, 3, 7, 14, 30, 60, 90, 180, 270, 365]
    static let habitRuns = [3, 7, 14, 30, 60, 100, 200, 365]

    /// Every threshold reached by `value`, including yearly ones after 365 (730, 1095, …).
    static func reached(_ value: Int, isVice: Bool) -> [Int] {
        let base = (isVice ? viceDays : habitRuns).filter { $0 <= value }
        let yearly = value >= 730 ? Array(stride(from: 730, through: value, by: 365)) : []
        return base + yearly
    }

    static func next(after value: Int, isVice: Bool) -> Int {
        let list = isVice ? viceDays : habitRuns
        return list.first { $0 > value } ?? ((value / 365) + 1) * 365
    }

    /// Celebrate only the HIGHEST newly reached threshold (no stacked celebrations after backfills).
    static func pending(value: Int, isVice: Bool, highestCelebrated: Int) -> Int? {
        let effectiveHighest = value < highestCelebrated ? 0 : highestCelebrated   // run restarted → re-earnable
        guard let top = reached(value, isVice: isVice).last, top > effectiveHighest else { return nil }
        return top
    }
}
```

> Domain never sees `HabitType` (that enum lives in `Data/Models/` beside the SwiftData models). Callers pass `metric.habitType == .vice`.

`MilestoneLedger` (UserDefaults, key `milestoneLedger.v2`, `[metricUUIDString: Int]`):
- `highestCelebrated(for:) -> Int`
- `record(_ threshold: Int, for:)`
- `reset(for:)` when the value has dropped below the stored highest (call before evaluating pending).
- `clearAll()`

When to check: on Today `onAppear`, after the check-in Done, after an urge resolves, and when the app becomes active. If something's pending → present `CelebrationView`. If several metrics have pending milestones, show them one after another, vices first.

### 6.10 Export / import (`Data/Export/`)

**v5 format** (`TrackBothBackup`):

```json
{
  "schemaVersion": 5,
  "exportDate": "2026-10-28T20:00:00Z",
  "metrics": [{ "id": "…", "name": "Alcohol", "habitType": "vice", "iconName": "wineglass",
                "createdAt": "…", "startedAt": "…", "costPerDay": "8", "ifThenPlan": "…",
                "sortOrder": 0, "isArchived": false }],
  "entries": [{ "id": "…", "metricID": "…", "day": "…", "status": "slipped",
                "occurredAt": "…", "note": null, "triggers": ["tired", "routine"] }],
  "urges":   [{ "id": "…", "metricID": "…", "startedAt": "…", "endedAt": "…",
                "outcome": "resisted", "intensity": 4, "triggers": [], "note": null }],
  "reasons": [{ "id": "…", "metricID": "…", "text": "…", "createdAt": "…", "sortOrder": 0 }]
}
```

- Dates: ISO 8601 (`JSONEncoder.DateEncodingStrategy.iso8601`). File name: `TrackBoth-Backup-YYYY-MM-DD.json`. Share with `ShareLink` on a temp file URL.
- Import = **replace all** (confirm first: "This replaces everything on this device with the backup."). Validate everything before deleting anything. Do it in one transaction: decode → validate → `deleteAllData()` → insert → save.
- Unknown `schemaVersion` > 6 → error "This backup is from a newer version of TrackBoth."
- **v6** (current export) adds optional fields, so v5 and v6 decode with the same struct: metric `viceMode`, `unit`, `dailyTarget`, `baselinePerDay`; entry `amount`; top-level `dayNotes: [{ id, day, mood, text, updatedAt }]`. An unknown `viceMode` or two notes on the same day fail validation.

**Legacy import (schema 1–4, from the old app).** Decode with the old structs (rename them `LegacyExportV4` and keep them in `Data/Export/LegacyExportV4.swift`):

| Old | New |
|-----|-----|
| metric `habitType`, `name`, `createdAt`, `id` | same |
| metric `startedAt` | Vice: the earliest of `createdAt` and that metric's earliest logged entry date. Habit: `createdAt`. |
| metric `costPerUnit` | `costPerDayRaw` |
| metric `primaryMotivation` (non-empty) | `Reason(sortOrder: 0)` |
| metric `iconName` | Look up `Presets` by case-insensitive name. Fallback `"circle.dashed"`. |
| entry with `hasBeenLogged == true`, habit, `value == true` | `.done`, `day = anchor(date)`, `occurredAt = date` |
| entry with `hasBeenLogged == true`, vice, `value == false` | `.free` |
| entry with `hasBeenLogged == true`, vice, `value == true` | `.slipped`, `occurredAt = DayMath.endOfDay(date)` |
| entry with `hasBeenLogged != true` and non-empty `motivation` | `Reason` (sortOrder after the existing ones) |
| entry `details` | `note` |
| habit `value == false`, quantity, unit, mood, starred, goals | **dropped** |

Tests: round-trip v5; import a fixture of each legacy version (put JSON fixtures in `Tests/Unit/Fixtures/`; build them from the old `ExportImportTests` before deleting it in Phase 3).



## Verification

| Field | Value |
|-------|--------|
| Last verified | 2026-10-28 |
| Commit | Phase 2 domain tests (V1–V8, H1–H5) |

