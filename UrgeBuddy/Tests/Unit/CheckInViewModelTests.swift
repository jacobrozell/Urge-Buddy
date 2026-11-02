import SwiftData
import XCTest
@testable import UrgeBuddy

@MainActor
final class CheckInViewModelTests: XCTestCase {
    func testMarkFreeCompletesCheckInAndSummarizes() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: 8, firstReason: nil)
        try store.logSlip(alcohol, occurredAt: date(2026, 10, 5, 20), triggers: [], note: nil)
        let walk = try store.addMetric(name: "Walk", habitType: .positive, iconName: "figure.walk", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        let now = date(2026, 10, 13, 10)
        let model = CheckInViewModel(store: store)
        model.load(metrics: [alcohol, walk], entries: [], now: now)
        XCTAssertEqual(model.vices.first?.answer, .unanswered)
        XCTAssertFalse(model.canFinish)

        try model.markFree(alcohol.id, metrics: [alcohol], now: now)
        XCTAssertEqual(model.vices.first?.answer, .free)
        XCTAssertTrue(model.canFinish)

        try model.toggleHabit(walk.id, metrics: [walk], now: now)
        XCTAssertEqual(model.habits.first?.isDone, true)
        try model.toggleHabit(walk.id, metrics: [walk], now: now)
        XCTAssertEqual(model.habits.first?.isDone, false)

        try model.finish(metrics: [alcohol, walk], now: now, locale: Locale(identifier: "en_US"), celebrated: [alcohol.id: 0])
        XCTAssertTrue(model.showComplete)
        let line = try XCTUnwrap(model.lines.first)
        XCTAssertEqual(line.detail, "7 days free · $96.00 saved")
        XCTAssertEqual(line.milestone, RecoveryCopy.milestoneVice(7, name: "Alcohol"))
        XCTAssertFalse(line.detail.localizedCaseInsensitiveContains("fail"))
    }

    func testFinishDoesNothingUntilEveryViceIsAnswered() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        _ = try store.addMetric(name: "Social media", habitType: .vice, iconName: "iphone", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        let metrics = try store.context.fetch(FetchDescriptor<Metric>())
        let model = CheckInViewModel(store: store)
        let now = date(2026, 10, 13, 10)
        model.load(metrics: metrics, entries: [], now: now)
        try model.markFree(alcohol.id, metrics: metrics, now: now)
        XCTAssertFalse(model.canFinish)
        try model.finish(metrics: metrics, now: now, celebrated: [:])
        XCTAssertFalse(model.showComplete)
    }

    func testFinishLogsUntouchedCutBackAsZeroAndSavesTheMood() throws {
        let harness = try TestHarness()
        let store = harness.store
        let smoking = try store.addMetric(
            name: "Smoking", habitType: .vice, iconName: "smoke", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil,
            tracking: MetricTracking(viceMode: .cutBack, unit: "cigarettes", dailyTarget: 5)
        )
        let now = date(2026, 10, 13, 20)
        let model = CheckInViewModel(store: store)
        model.load(metrics: [smoking], entries: [], now: now)
        XCTAssertTrue(model.canFinish)
        XCTAssertEqual(model.cutBacks.first?.amount, 0)
        model.mood = .good
        model.noteText = "Calm day"
        try model.finish(metrics: [smoking], now: now, locale: Locale(identifier: "en_US"), celebrated: [:])
        XCTAssertEqual(try store.entry(for: smoking.id, on: now)?.status, .within)
        XCTAssertEqual(model.lines.first?.detail, "0 of 5 cigarettes today")
        XCTAssertEqual(try store.dayNote(on: now)?.mood, .good)
        XCTAssertEqual(try store.dayNote(on: now)?.text, "Calm day")
    }
}
