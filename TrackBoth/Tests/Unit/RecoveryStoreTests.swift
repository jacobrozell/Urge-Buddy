import SwiftData
import XCTest
@testable import TrackBoth

@MainActor
final class RecoveryStoreTests: XCTestCase {
    private var harness: TestHarness!
    private var store: RecoveryStore! { harness.store }
    private let calendar = Calendar.testNY

    override func setUp() async throws {
        harness = try TestHarness(calendar: calendar)
    }

    func testUpsertKeepsOneEntryPerDay() throws {
        let metric = try vice()
        let day = date(2026, 10, 10, 9)
        try store.markFree(metric, on: day, now: day)
        try store.markFree(metric, on: date(2026, 10, 10, 18), now: date(2026, 10, 10, 18))
        let entries = try store.entries(for: metric.id)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.status, .free)
    }

    func testMarkFreeDoesNotOverrideASlip() throws {
        let metric = try vice()
        let when = date(2026, 10, 10, 20)
        try store.logSlip(metric, occurredAt: when, triggers: [.tired], note: "After dinner")
        try store.markFree(metric, on: when, now: date(2026, 10, 10, 21))
        let entry = try store.entry(for: metric.id, on: when)
        XCTAssertEqual(entry?.status, .slipped)
        XCTAssertEqual(entry?.note, "After dinner")
    }

    func testClearingASlipLetsTheDayEditorMarkItFree() throws {
        let metric = try vice()
        let when = date(2026, 10, 10, 20)
        try store.logSlip(metric, occurredAt: when, triggers: [.tired], note: "After dinner")
        try store.clearDay(metric, on: when)
        try store.markFree(metric, on: when, now: date(2026, 10, 10, 21))
        let entry = try store.entry(for: metric.id, on: when)
        XCTAssertEqual(entry?.status, .free)
        XCTAssertNil(entry?.note)
    }

    func testLogSlipRejectsATimeBeforeTheQuitDay() throws {
        let metric = try vice(started: date(2026, 10, 10, 9))
        XCTAssertThrowsError(try store.logSlip(metric, occurredAt: date(2026, 10, 9, 23), triggers: [], note: nil)) { error in
            XCTAssertEqual(error as? RecoveryStoreError, .slipBeforeStart)
        }
        XCTAssertTrue(try store.entries(for: metric.id).isEmpty)
    }

    func testSetHabitDoneFalseDeletesTheEntry() throws {
        let habit = try habit()
        let day = date(2026, 10, 12)
        try store.setHabitDone(habit, on: day, done: true, now: day)
        try store.setHabitDone(habit, on: day, done: false, now: day)
        XCTAssertNil(try store.entry(for: habit.id, on: day))
    }

    func testCutBackAmountsSnapshotTheLimitAndKeepZero() throws {
        let metric = try store.addMetric(
            name: "Smoking", habitType: .vice, iconName: "smoke", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil,
            tracking: MetricTracking(viceMode: .cutBack, unit: "cigarettes", dailyTarget: 5)
        )
        let day = date(2026, 10, 10)
        try store.setAmount(metric, on: day, amount: 0)
        XCTAssertEqual(try store.entry(for: metric.id, on: day)?.status, .within)
        try store.addAmount(metric, 6, on: day)
        let entry = try store.entry(for: metric.id, on: day)
        XCTAssertEqual(entry?.amount, 6)
        XCTAssertEqual(entry?.status, .over)
        try store.update(metric, name: metric.name, iconName: metric.iconName, startedAt: metric.startedAt, costPerDay: nil,
                         tracking: MetricTracking(viceMode: .cutBack, unit: "cigarettes", dailyTarget: 10))
        XCTAssertEqual(try store.entry(for: metric.id, on: day)?.status, .over)
    }

    func testAmountHabitIsPartialThenDoneAndZeroRemovesIt() throws {
        let water = try store.addMetric(
            name: "Water", habitType: .positive, iconName: "drop", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil,
            tracking: MetricTracking(unit: "glasses", dailyTarget: 8)
        )
        let day = date(2026, 10, 10)
        try store.setAmount(water, on: day, amount: 3)
        XCTAssertEqual(try store.entry(for: water.id, on: day)?.status, .partial)
        try store.setHabitDone(water, on: day, done: true)
        XCTAssertEqual(try store.entry(for: water.id, on: day)?.amount, 8)
        XCTAssertEqual(try store.entry(for: water.id, on: day)?.status, .done)
        try store.setAmount(water, on: day, amount: 0)
        XCTAssertNil(try store.entry(for: water.id, on: day))
    }

    func testQuitViceIgnoresAmountsAndDropsAmountFields() throws {
        let metric = try store.addMetric(
            name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil,
            tracking: MetricTracking(viceMode: .quit, unit: "drinks", dailyTarget: 3)
        )
        XCTAssertNil(metric.unit)
        XCTAssertNil(metric.dailyTarget)
        try store.setAmount(metric, on: date(2026, 10, 10), amount: 2)
        XCTAssertTrue(try store.entries(for: metric.id).isEmpty)
    }

    func testDayNoteUpsertsAndClears() throws {
        let day = date(2026, 10, 10, 9)
        try store.setDayNote(on: day, mood: .good, text: "  Walked  ")
        try store.setDayNote(on: date(2026, 10, 10, 21), mood: .great, text: "Walked")
        XCTAssertEqual(try store.context.fetchCount(FetchDescriptor<DayNote>()), 1)
        XCTAssertEqual(try store.dayNote(on: day)?.mood, .great)
        try store.setDayNote(on: day, mood: nil, text: " ")
        XCTAssertNil(try store.dayNote(on: day))
    }

    func testDeleteCascadesEntriesUrgesAndReasons() throws {
        let metric = try vice()
        try store.addReason("For my health", to: metric)
        try store.logSlip(metric, occurredAt: date(2026, 10, 12, 20), triggers: [.bored], note: nil)
        _ = try store.startUrge(for: metric, intensity: 4, now: date(2026, 10, 11, 18))
        MilestoneLedger.record(7, for: metric.id)
        try store.delete(metric)
        XCTAssertEqual(try store.context.fetchCount(FetchDescriptor<Metric>()), 0)
        XCTAssertEqual(try store.context.fetchCount(FetchDescriptor<MetricEntry>()), 0)
        XCTAssertEqual(try store.context.fetchCount(FetchDescriptor<UrgeEvent>()), 0)
        XCTAssertEqual(try store.context.fetchCount(FetchDescriptor<Reason>()), 0)
        XCTAssertEqual(MilestoneLedger.highestCelebrated(for: metric.id), 0)
    }

    func testDeleteAllClearsModelsPreferencesAndTheLedger() throws {
        let metric = try vice()
        Preferences.hasCompletedOnboarding = true
        MilestoneLedger.record(3, for: metric.id)
        try store.deleteAllData()
        XCTAssertEqual(try store.context.fetchCount(FetchDescriptor<Metric>()), 0)
        XCTAssertFalse(Preferences.hasCompletedOnboarding)
        XCTAssertEqual(MilestoneLedger.highestCelebrated(for: metric.id), 0)
    }

    func testReorderRewritesSortOrder() throws {
        let first = try vice(name: "Alcohol")
        let second = try habit(name: "Walk")
        try store.reorder([second, first])
        XCTAssertEqual(second.sortOrder, 0)
        XCTAssertEqual(first.sortOrder, 1)
    }

    func testSuccessfulSavePostsRecoveryDataChanged() throws {
        let expectation = expectation(forNotification: .recoveryDataChanged, object: nil)
        _ = try vice()
        wait(for: [expectation], timeout: 1)
    }

    private func vice(name: String = "Alcohol", started: Date = date(2026, 10, 1, 9)) throws -> Metric {
        try store.addMetric(name: name, habitType: .vice, iconName: "wineglass", startedAt: started, costPerDay: 8, firstReason: nil)
    }

    private func habit(name: String = "Go for a walk") throws -> Metric {
        try store.addMetric(name: name, habitType: .positive, iconName: "figure.walk", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
    }
}
