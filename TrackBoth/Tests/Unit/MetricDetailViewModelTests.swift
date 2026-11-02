import SwiftData
import XCTest
@testable import TrackBoth

@MainActor
final class MetricDetailViewModelTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar.testNY
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }
    private var locale: Locale { Locale(identifier: "en_US") }

    func testViceDetailSurfacesRunsSavingsAndTheLog() throws {
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
        try store.logSlip(alcohol, occurredAt: date(2026, 10, 5, 20), triggers: [.tired, .routine], note: "After dinner")
        let slipped = try store.startUrge(for: alcohol, intensity: 4, now: date(2026, 10, 5, 19, 40))
        try store.finishUrge(slipped, outcome: .slipped, triggers: [.tired], note: nil, now: date(2026, 10, 5, 20))
        let resisted = try store.startUrge(for: alcohol, intensity: 2, now: date(2026, 10, 11, 18))
        try store.finishUrge(resisted, outcome: .resisted, triggers: [.stressed], note: nil, now: date(2026, 10, 11, 18, 10))
        let open = try store.startUrge(for: alcohol, intensity: 5, now: date(2026, 10, 12, 18))
        _ = open

        let entries = try store.entries(for: alcohol.id)
        let urges = try store.urges(for: alcohol.id)
        let model = MetricDetailViewModel(calendar: calendar, locale: locale, now: date(2026, 10, 13, 10))
        let now = date(2026, 10, 13, 10)
        model.update(metric: alcohol, entries: entries, urges: urges, now: now)

        XCTAssertEqual(model.stats.primary, "7 days free")
        XCTAssertEqual(model.stats.nextMilestone, RecoveryCopy.nextMilestone(14, inDays: 7))
        XCTAssertEqual(model.stats.startedLine, "Oct 1, 2026")
        XCTAssertTrue(model.stats.needsCost == false)
        XCTAssertEqual(model.stats.tiles.map(\.label), [
            RecoveryCopy.currentRun, RecoveryCopy.longestRun, RecoveryCopy.freeLast30Tile, RecoveryCopy.savedStat
        ])
        XCTAssertEqual(model.stats.tiles[0].value, "7")
        XCTAssertEqual(model.stats.tiles[3].value, "$88.00")
        XCTAssertEqual(model.stats.tiles[3].caption, "$8.00 a day")
        XCTAssertEqual(model.stats.urges?.beaten, "1 of 2")
        XCTAssertEqual(model.stats.urges?.slipped, "1")
        XCTAssertEqual(model.stats.urges?.unsure, "0")
        XCTAssertEqual(model.stats.urges?.average, "3")
        XCTAssertEqual(model.stats.triggers.map(\.title), ["Tired", "Stressed", "Usual time"])
        XCTAssertEqual(model.stats.triggers.map(\.count), [2, 1, 1])
        XCTAssertEqual(model.stats.recent.map(\.title), [RecoveryCopy.rodeItOut, RecoveryCopy.slipEvent])
        XCTAssertEqual(model.stats.recent[1].detail, "Strength 4 · Tired, Usual time · After dinner")
        XCTAssertEqual(model.stats.recent[0].detail, "Strength 2 · Stressed")
        XCTAssertFalse(model.stats.recent.contains { $0.title == RecoveryCopy.notSureOutcome })
    }

    func testPatternsAppearOnceThreeMomentsShareATimeAndDay() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(
            name: "Alcohol",
            habitType: .vice,
            iconName: "wineglass",
            startedAt: date(2026, 9, 1, 9),
            costPerDay: nil,
            firstReason: nil
        )
        for day in [date(2026, 10, 2, 20), date(2026, 10, 9, 21), date(2026, 10, 16, 18)] {
            try store.logSlip(alcohol, occurredAt: day, triggers: [.bored], note: nil)
        }
        let entries = try store.entries(for: alcohol.id)
        let model = MetricDetailViewModel(calendar: calendar, locale: locale, now: date(2026, 10, 20, 12))
        model.update(metric: alcohol, entries: entries, urges: [], now: date(2026, 10, 20, 12))

        XCTAssertTrue(model.stats.needsCost)
        XCTAssertEqual(model.stats.tiles[3].value, "—")
        XCTAssertNil(model.stats.tiles[3].caption)
        XCTAssertEqual(model.stats.triggers.map(\.title), ["Bored"])
        XCTAssertEqual(model.stats.triggers.map(\.count), [3])
        XCTAssertEqual(model.stats.hardestTime, "Evenings")
        XCTAssertEqual(model.stats.hardestDay, "Friday")
        XCTAssertEqual(model.stats.recent.count, 3)
        XCTAssertEqual(model.stats.urges?.total, 0)
    }

    func testHabitDetailShowsTheNextRunAndAMissWarning() throws {
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
        try store.setHabitDone(walk, on: date(2026, 10, 10), done: true, now: date(2026, 10, 10, 8))
        try store.setHabitDone(walk, on: date(2026, 10, 11), done: true, now: date(2026, 10, 11, 8))
        let entries = try store.entries(for: walk.id)
        let model = MetricDetailViewModel(calendar: calendar, locale: locale, now: date(2026, 10, 13, 10))
        model.update(metric: walk, entries: entries, urges: [], now: date(2026, 10, 13, 10))

        XCTAssertEqual(model.stats.primary, "2-day run")
        XCTAssertEqual(model.stats.nextMilestone, RecoveryCopy.nextMilestone(3, inDays: 1))
        XCTAssertEqual(model.stats.startedLine, "Oct 1, 2026")
        XCTAssertTrue(model.stats.atRisk)
        XCTAssertNil(model.stats.urges)
        XCTAssertTrue(model.stats.recent.isEmpty)
        XCTAssertEqual(model.stats.tiles.map(\.value), ["2", "2", "2", "2"])
    }

    func testMonthPagingStopsAtTheStartMonthAndThisMonth() throws {
        let harness = try TestHarness()
        let now = date(2026, 10, 13, 10)
        let alcohol = try harness.store.addMetric(
            name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil
        )
        let model = MetricDetailViewModel(calendar: calendar, locale: locale, now: now)
        let october = model.month
        XCTAssertFalse(model.canShiftMonth(-1, metric: alcohol, now: now))
        XCTAssertFalse(model.canShiftMonth(1, metric: alcohol, now: now))
        model.shiftMonth(-1, metric: alcohol, now: now)
        model.shiftMonth(1, metric: alcohol, now: now)
        XCTAssertEqual(model.month, october)

        let older = try harness.store.addMetric(
            name: "Older", habitType: .vice, iconName: "smoke", startedAt: date(2026, 8, 2, 9), costPerDay: nil, firstReason: nil
        )
        XCTAssertTrue(model.canShiftMonth(-1, metric: older, now: now))
        model.shiftMonth(-1, metric: older, now: now)
        XCTAssertEqual(calendar.component(.month, from: model.month), 9)
        model.shiftMonth(-1, metric: older, now: now)
        XCTAssertEqual(calendar.component(.month, from: model.month), 8)
        XCTAssertFalse(model.canShiftMonth(-1, metric: older, now: now))
        XCTAssertTrue(model.canShiftMonth(1, metric: older, now: now))
    }
}