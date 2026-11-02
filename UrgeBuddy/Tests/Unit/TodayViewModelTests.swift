import SwiftData
import XCTest
@testable import UrgeBuddy

@MainActor
final class TodayViewModelTests: XCTestCase {
    private var calendar: Calendar { .testNY }

    func testViceCardMatchesDomainAndPromptsBeforeNoon() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(
            name: "Alcohol",
            habitType: .vice,
            iconName: "wineglass",
            startedAt: date(2026, 10, 1, 9),
            costPerDay: 8,
            firstReason: nil
        )
        try store.logSlip(alcohol, occurredAt: date(2026, 10, 5, 20), triggers: [.tired], note: nil)
        let walk = try store.addMetric(
            name: "Go for a walk",
            habitType: .positive,
            iconName: "figure.walk",
            startedAt: date(2026, 10, 1, 9),
            costPerDay: nil,
            firstReason: nil
        )
        try store.setHabitDone(walk, on: date(2026, 10, 10), done: true, now: date(2026, 10, 10, 8))
        try store.setHabitDone(walk, on: date(2026, 10, 11), done: true, now: date(2026, 10, 11, 8))

        let entries = try store.context.fetch(FetchDescriptor<MetricEntry>())
        let model = TodayViewModel(calendar: calendar, locale: Locale(identifier: "en_US"))
        let now = date(2026, 10, 13, 10)
        model.update(metrics: [alcohol, walk], entries: entries, now: now, dismissedYesterday: nil)

        let card = try XCTUnwrap(model.vices.first)
        let history = Snapshots.viceHistory(for: alcohol, entries: entries, calendar: calendar)
        XCTAssertEqual(card.daysFree, RecoveryMath.currentRunDays(history, now: now, calendar: calendar))
        XCTAssertEqual(card.daysFree, 7)
        XCTAssertEqual(card.savedText, "$88.00 saved")
        XCTAssertEqual(card.week.count, 7)
        XCTAssertEqual(card.week.last, .todayPending)
        XCTAssertTrue(card.week.dropLast().allSatisfy { $0 == .presumedFree })
        XCTAssertEqual(card.nextMilestone, RecoveryCopy.nextMilestone(14, inDays: 7))
        XCTAssertEqual(model.checkInRemaining, 1)
        XCTAssertEqual(model.checkInStreak, 0)
        XCTAssertFalse(model.checkInDoneToday)
        XCTAssertEqual(model.yesterdayPrompt?.name, "Alcohol")
        XCTAssertTrue(model.showsSOS)

        let habit = try XCTUnwrap(model.habits.first)
        XCTAssertEqual(habit.run, 2)
        XCTAssertFalse(habit.isDoneToday)
        XCTAssertTrue(habit.isAtRisk)

        model.update(metrics: [alcohol, walk], entries: entries, now: date(2026, 10, 13, 14), dismissedYesterday: nil)
        XCTAssertNil(model.yesterdayPrompt)

        model.update(metrics: [alcohol, walk], entries: entries, now: now, dismissedYesterday: date(2026, 10, 12))
        XCTAssertNil(model.yesterdayPrompt)
    }

    func testConfirmedYesterdayHidesThePrompt() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        try store.markFree(alcohol, on: date(2026, 10, 12), now: date(2026, 10, 12, 18))
        let entries = try store.context.fetch(FetchDescriptor<MetricEntry>())
        let model = TodayViewModel(calendar: calendar)
        model.update(metrics: [alcohol], entries: entries, now: date(2026, 10, 13, 9), dismissedYesterday: nil)
        XCTAssertNil(model.yesterdayPrompt)
        XCTAssertEqual(model.checkInRemaining, 1)
        XCTAssertEqual(model.checkInStreak, 1)
        XCTAssertFalse(model.checkInDoneToday)
    }
}
