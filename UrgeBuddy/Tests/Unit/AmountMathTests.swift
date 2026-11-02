import XCTest
@testable import UrgeBuddy

final class AmountMathTests: XCTestCase {
    private let calendar = Calendar.testNY

    func testStepGrowsForLargeTargets() {
        XCTAssertEqual(AmountMath.step(for: nil), 1)
        XCTAssertEqual(AmountMath.step(for: 8), 1)
        XCTAssertEqual(AmountMath.step(for: 30), 5)
    }

    func testHabitDoneAndLimitRules() {
        XCTAssertFalse(AmountMath.isHabitDone(amount: 7, target: 8))
        XCTAssertTrue(AmountMath.isHabitDone(amount: 8, target: 8))
        XCTAssertFalse(AmountMath.isOverLimit(amount: 8, limit: 8))
        XCTAssertTrue(AmountMath.isOverLimit(amount: 9, limit: 8))
        XCTAssertFalse(AmountMath.isOverLimit(amount: 0, limit: 0))
    }

    func testUnloggedDaysAreUnknownNotPresumed() {
        let h = history(days: [(10, 6, false)])
        let now = date(2026, 10, 12, 15)
        XCTAssertEqual(CutBackMath.state(of: date(2026, 10, 10), in: h, now: now, calendar: calendar), .within)
        XCTAssertEqual(CutBackMath.state(of: date(2026, 10, 11), in: h, now: now, calendar: calendar), .notLogged)
        XCTAssertEqual(CutBackMath.state(of: date(2026, 10, 12), in: h, now: now, calendar: calendar), .todayPending)
        XCTAssertEqual(CutBackMath.state(of: date(2026, 10, 1), in: h, now: now, calendar: calendar), .beforeStart)
    }

    func testWindowLeavesOutTodayAndUnloggedDays() {
        let h = history(days: [(9, 10, true), (10, 6, false), (11, 7, false), (12, 30, true)])
        let now = date(2026, 10, 12, 15)
        let window = CutBackMath.withinDays(inLast: 7, h, now: now, calendar: calendar)
        XCTAssertEqual(window.within, 2)
        XCTAssertEqual(window.logged, 3)
        XCTAssertEqual(CutBackMath.average(inLast: 7, h, now: now, calendar: calendar) ?? 0, 23.0 / 3.0, accuracy: 0.001)
    }

    func testReductionAndSavingsUseTheBaseline() {
        let h = history(days: [(10, 6, false), (11, 8, false)], baseline: 20)
        let now = date(2026, 10, 12, 9)
        XCTAssertEqual(CutBackMath.unitsAvoided(h, now: now, calendar: calendar), 26)
        XCTAssertEqual(CutBackMath.moneySaved(unitsAvoided: 26, baseline: 20, costPerDay: 10), 13)
        XCTAssertEqual(CutBackMath.reductionPercent(average: 7, baseline: 20), 65)
        XCTAssertNil(CutBackMath.reductionPercent(average: 21, baseline: 20))
        XCTAssertNil(CutBackMath.moneySaved(unitsAvoided: 26, baseline: nil, costPerDay: 10))
    }

    private func history(days: [(Int, Int, Bool)], baseline: Int? = nil) -> CutBackHistory {
        var map: [Date: CutBackDay] = [:]
        for (day, amount, isOver) in days {
            map[calendar.startOfDay(for: date(2026, 10, day))] = CutBackDay(amount: amount, isOver: isOver)
        }
        return CutBackHistory(startedAt: date(2026, 10, 5, 9), limit: 8, baseline: baseline, days: map)
    }
}
