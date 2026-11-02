import SwiftData
import XCTest
@testable import UrgeBuddy

@MainActor
final class ProgressViewModelTests: XCTestCase {
    func testCardsMatchDomainForTheFixture() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: 8, firstReason: nil)
        try store.logSlip(alcohol, occurredAt: date(2026, 10, 5, 20), triggers: [], note: nil)
        let entries = try store.context.fetch(FetchDescriptor<MetricEntry>())
        let model = ProgressViewModel(calendar: .testNY, locale: Locale(identifier: "en_US"))
        model.update(metrics: [alcohol], entries: entries, urges: [], now: date(2026, 10, 13, 10))
        XCTAssertEqual(model.active.first?.line, RecoveryCopy.viceProgress(days: 7, longest: 7, free: 11, counted: 12))
        XCTAssertEqual(model.summary.savedText, "$88.00 saved")
        XCTAssertEqual(model.summary.savedValue, "$88.00")
        XCTAssertEqual(model.summary.urgesBeaten, 0)
        XCTAssertEqual(model.summary.daysCheckedIn, ProgressMath.daysCheckedIn(loggedDays: entries.map(\.day), now: date(2026, 10, 13, 10), calendar: .testNY))
        XCTAssertEqual(model.summary.checkInStreak, 0)
    }

    func testACostWithNothingSavedYetStillShowsZero() throws {
        let harness = try TestHarness()
        let started = date(2026, 10, 13, 8)
        let alcohol = try harness.store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: started, costPerDay: 8, firstReason: nil)
        let model = ProgressViewModel(calendar: .testNY, locale: Locale(identifier: "en_US"))
        model.update(metrics: [alcohol], entries: [], urges: [], now: date(2026, 10, 13, 10))
        XCTAssertEqual(model.summary.savedText, "$0.00 saved")
        XCTAssertEqual(model.summary.savedValue, "$0.00")
    }

    func testArchiveMovesTheCardAndRestoreBringsItBack() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        let model = ProgressViewModel(calendar: .testNY, locale: Locale(identifier: "en_US"))
        let now = date(2026, 10, 13, 10)
        model.update(metrics: [alcohol], entries: [], urges: [], now: now)
        XCTAssertEqual(model.active.map(\.name), ["Alcohol"])

        try store.setArchived(alcohol, true)
        model.update(metrics: [alcohol], entries: [], urges: [], now: now)
        XCTAssertTrue(model.active.isEmpty)
        XCTAssertEqual(model.archived.map(\.id), [alcohol.id])

        try store.setArchived(alcohol, false)
        model.update(metrics: [alcohol], entries: [], urges: [], now: now)
        XCTAssertEqual(model.active.map(\.id), [alcohol.id])
        XCTAssertTrue(model.archived.isEmpty)
    }

    func testDemoProgressAndDetailMatchDomain() throws {
        let calendar = Calendar.testNY
        let locale = Locale(identifier: "en_US")
        let harness = try TestHarness(calendar: calendar)
        let now = date(2026, 11, 1, 18)
        try DemoData.seed(context: harness.container.mainContext, now: now, calendar: calendar)
        let metrics = try harness.store.context.fetch(FetchDescriptor<Metric>(sortBy: [SortDescriptor(\.sortOrder)]))
        let entries = try harness.store.context.fetch(FetchDescriptor<MetricEntry>())
        let urges = try harness.store.context.fetch(FetchDescriptor<UrgeEvent>())

        let progress = ProgressViewModel(calendar: calendar, locale: locale)
        progress.update(metrics: metrics, entries: entries, urges: urges, now: now)

        XCTAssertEqual(progress.summary.urgesBeaten, 4)
        XCTAssertEqual(progress.summary.savedText, "$212.00 saved")
        XCTAssertEqual(
            progress.summary.daysCheckedIn,
            ProgressMath.daysCheckedIn(loggedDays: entries.map(\.day), now: now, calendar: calendar)
        )

        for metric in metrics where !metric.isArchived {
            let card = try XCTUnwrap(progress.active.first { $0.id == metric.id })
            XCTAssertEqual(card.line, expectedLine(metric, entries: entries, now: now, calendar: calendar))

            let detail = MetricDetailViewModel(calendar: calendar, locale: locale, now: now)
            detail.update(metric: metric, entries: entries, urges: urges, now: now)
            if metric.name == "Alcohol" {
                XCTAssertEqual(detail.stats.primary, "8 days free")
                XCTAssertEqual(Array(detail.stats.tiles.map(\.value).prefix(2)), ["8", "14"])
                let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
                let saved = try XCTUnwrap(RecoveryMath.moneySaved(
                    totalFreeDays: RecoveryMath.totalFreeDays(history, now: now, calendar: calendar),
                    costPerDay: metric.costPerDay
                ))
                XCTAssertEqual(detail.stats.tiles[3].value, RecoveryCopy.money(saved, locale: locale))
            }
            if metric.name == "Smoking" {
                XCTAssertEqual(detail.stats.primary, RecoveryCopy.todayAmount(3, limit: 8, unit: "cigarettes"))
                let history = Snapshots.cutBackHistory(for: metric, entries: entries, calendar: calendar)
                let average = try XCTUnwrap(CutBackMath.average(inLast: 7, history, now: now, calendar: calendar))
                XCTAssertEqual(detail.stats.tiles[1].value, RecoveryCopy.average(average))
            }
        }
    }

    func testDaysCheckedInDropsDaysOutsideTheWindow() {
        let now = date(2026, 10, 13, 10)
        let count = ProgressMath.daysCheckedIn(
            loggedDays: [date(2026, 10, 13, 9), date(2026, 10, 12, 9), date(2026, 9, 1, 9)],
            now: now,
            calendar: .testNY
        )
        XCTAssertEqual(count, 2)
        XCTAssertEqual(ProgressMath.daysCheckedIn(loggedDays: [], now: now, calendar: .testNY), 0)
    }

    private func expectedLine(_ metric: Metric, entries: [MetricEntry], now: Date, calendar: Calendar) -> String {
        if metric.isCuttingBack {
            let history = Snapshots.cutBackHistory(for: metric, entries: entries, calendar: calendar)
            let window = CutBackMath.withinDays(inLast: 30, history, now: now, calendar: calendar)
            return RecoveryCopy.cutBackProgress(
                today: RecoveryCopy.todayAmount(CutBackMath.amount(on: now, history, calendar: calendar), limit: history.limit, unit: metric.unitLabel),
                average: CutBackMath.average(inLast: 7, history, now: now, calendar: calendar).map { RecoveryCopy.averageShort($0) },
                within: window.within,
                logged: window.logged
            )
        }
        if metric.habitType == .vice {
            let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
            let window = RecoveryMath.freeDays(inLast: 30, history, now: now, calendar: calendar)
            return RecoveryCopy.viceProgress(
                days: RecoveryMath.currentRunDays(history, now: now, calendar: calendar),
                longest: RecoveryMath.longestRunDays(history, now: now, calendar: calendar),
                free: window.free,
                counted: window.counted
            )
        }
        let history = Snapshots.habitHistory(for: metric, entries: entries, calendar: calendar)
        return RecoveryCopy.habitProgress(
            run: HabitMath.currentRun(history, now: now, calendar: calendar),
            best: HabitMath.bestRun(history, now: now, calendar: calendar),
            done: HabitMath.doneCount(inLast: 30, history, now: now, calendar: calendar),
            counted: 30
        )
    }
}

@MainActor
final class MetricFormViewModelTests: XCTestCase {
    func testNameIsRequiredAndCapped() {
        let model = MetricFormViewModel(metric: nil)
        XCTAssertFalse(model.canSave)
        model.name = String(repeating: "a", count: 41)
        XCTAssertEqual(model.nameError, RecoveryCopy.nameTooLong)
        model.name = "Alcohol"
        XCTAssertTrue(model.canSave)
        XCTAssertTrue(model.showsTypePicker)
    }

    func testCutBackNeedsALimitAndStartsToday() throws {
        let harness = try TestHarness()
        let model = MetricFormViewModel(metric: nil)
        model.name = "Smoking"
        model.viceMode = .cutBack
        XCTAssertFalse(model.showsQuitDate)
        XCTAssertEqual(model.targetError, RecoveryCopy.limitRequired)
        model.targetText = "0"
        XCTAssertTrue(model.canSave)
        model.unit = "cigarettes"
        model.baselineText = "20"
        let now = date(2026, 10, 13, 10)
        let saved = try model.save(metric: nil, store: harness.store, now: now)
        XCTAssertTrue(saved.isCuttingBack)
        XCTAssertEqual(saved.startedAt, now)
        XCTAssertEqual(saved.dailyTarget, 0)
        XCTAssertEqual(saved.baselinePerDay, 20)
    }

    func testSwitchingCutBackToQuitUsesTheQuitDate() throws {
        let harness = try TestHarness()
        let metric = try harness.store.addMetric(
            name: "Smoking", habitType: .vice, iconName: "smoke", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil,
            tracking: MetricTracking(viceMode: .cutBack, unit: "cigarettes", dailyTarget: 2)
        )
        let model = MetricFormViewModel(metric: metric)
        model.viceMode = .quit
        model.startedAt = date(2026, 10, 13, 8)
        _ = try model.save(metric: metric, store: harness.store, now: date(2026, 10, 13, 10))
        XCTAssertTrue(metric.isQuitting)
        XCTAssertEqual(metric.startedAt, date(2026, 10, 13, 8))
        XCTAssertNil(metric.dailyTarget)
    }

    func testAmountHabitNeedsATargetOfOne() {
        let model = MetricFormViewModel(metric: nil)
        model.name = "Water"
        model.habitType = .positive
        model.tracksHabitAmount = true
        model.targetText = "0"
        XCTAssertEqual(model.targetError, RecoveryCopy.targetRequired)
        model.targetText = "8"
        XCTAssertTrue(model.canSave)
        XCTAssertEqual(model.tracking.dailyTarget, 8)
    }

    func testNewHabitStartsNow() throws {
        let harness = try TestHarness()
        let model = MetricFormViewModel(metric: nil)
        model.habitType = .positive
        model.name = "Walk"
        model.startedAt = date(2020, 1, 1)
        let now = date(2026, 10, 13, 10)
        let saved = try model.save(metric: nil, store: harness.store, now: now)
        XCTAssertEqual(saved.startedAt, now)
        XCTAssertNil(saved.costPerDay)
    }
}

@MainActor
final class CheckInStreakTests: XCTestCase {
    func testStreakCountsAnsweredDaysAndStopsAtAGap() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(
            name: "Alcohol",
            habitType: .vice,
            iconName: "wineglass",
            startedAt: date(2026, 10, 1, 9),
            costPerDay: nil,
            firstReason: nil
        )
        let now = date(2026, 10, 13, 10)
        for day in [10, 12, 13] {
            try store.markFree(alcohol, on: date(2026, 10, day), now: date(2026, 10, day, 9))
        }
        try store.logSlip(alcohol, occurredAt: date(2026, 10, 9, 20), triggers: [], note: nil)
        let entries = try store.context.fetch(FetchDescriptor<MetricEntry>())

        XCTAssertEqual(ProgressMath.checkInStreak(metrics: [alcohol], entries: entries, now: now, calendar: .testNY), 2)
        XCTAssertTrue(ProgressMath.isCheckedIn(on: now, metrics: [alcohol], entries: entries, now: now, calendar: .testNY))

        let openToday = entries.filter { !Calendar.testNY.isDate($0.day, inSameDayAs: now) }
        XCTAssertEqual(ProgressMath.checkInStreak(metrics: [alcohol], entries: openToday, now: now, calendar: .testNY), 1)
        XCTAssertFalse(ProgressMath.isCheckedIn(on: now, metrics: [alcohol], entries: openToday, now: now, calendar: .testNY))
    }

    func testPresumedFreeDaysDoNotCount() throws {
        let harness = try TestHarness()
        let alcohol = try harness.store.addMetric(
            name: "Alcohol",
            habitType: .vice,
            iconName: "wineglass",
            startedAt: date(2026, 10, 1, 9),
            costPerDay: nil,
            firstReason: nil
        )
        let now = date(2026, 10, 13, 10)
        XCTAssertEqual(ProgressMath.checkInStreak(metrics: [alcohol], entries: [], now: now, calendar: .testNY), 0)
    }

    func testHabitOnlyStreakUsesDoneDays() throws {
        let harness = try TestHarness()
        let store = harness.store
        let walk = try store.addMetric(
            name: "Walk",
            habitType: .positive,
            iconName: "figure.walk",
            startedAt: date(2026, 10, 1, 9),
            costPerDay: nil,
            firstReason: nil
        )
        try store.setHabitDone(walk, on: date(2026, 10, 12), done: true, now: date(2026, 10, 12, 8))
        try store.setHabitDone(walk, on: date(2026, 10, 11), done: true, now: date(2026, 10, 11, 8))
        let entries = try store.context.fetch(FetchDescriptor<MetricEntry>())
        let now = date(2026, 10, 13, 10)
        XCTAssertEqual(ProgressMath.checkInStreak(metrics: [walk], entries: entries, now: now, calendar: .testNY), 2)
        XCTAssertFalse(ProgressMath.isCheckedIn(on: now, metrics: [walk], entries: entries, now: now, calendar: .testNY))
    }

    func testEveryViceHasToBeAnswered() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        let smoking = try store.addMetric(name: "Smoking", habitType: .vice, iconName: "smoke", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        try store.markFree(alcohol, on: date(2026, 10, 13), now: date(2026, 10, 13, 9))
        try store.markFree(alcohol, on: date(2026, 10, 12), now: date(2026, 10, 12, 9))
        let entries = try store.context.fetch(FetchDescriptor<MetricEntry>())
        let now = date(2026, 10, 13, 10)
        XCTAssertEqual(ProgressMath.checkInStreak(metrics: [alcohol, smoking], entries: entries, now: now, calendar: .testNY), 0)
    }
}
