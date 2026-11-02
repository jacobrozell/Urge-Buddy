import XCTest
@testable import UrgeBuddy

final class HabitMathTests: XCTestCase {
    private let calendar = Calendar.testNY
    private var now: Date { date(2026, 10, 13, 10, 0) }

    private func history(_ days: [Date], started: Date = date(2026, 10, 1, 9, 0)) -> HabitHistory {
        HabitHistory(startedAt: started, doneDays: Set(days.map { calendar.startOfDay(for: $0) }))
    }

    func testH1ThreeDoneDays() {
        let h = history([date(2026, 10, 10), date(2026, 10, 11), date(2026, 10, 12)])
        XCTAssertEqual(HabitMath.currentRun(h, now: now, calendar: calendar), 3)
        XCTAssertFalse(HabitMath.isAtRisk(h, now: now, calendar: calendar))
    }

    func testH2SingleMissPauses() {
        let h = history([date(2026, 10, 9), date(2026, 10, 10), date(2026, 10, 12)])
        XCTAssertEqual(HabitMath.currentRun(h, now: now, calendar: calendar), 3)
    }

    func testH3TwoMissesEndTheRun() {
        let h = history([date(2026, 10, 8), date(2026, 10, 9), date(2026, 10, 10)])
        XCTAssertEqual(HabitMath.currentRun(h, now: now, calendar: calendar), 0)
        XCTAssertFalse(HabitMath.isAtRisk(h, now: now, calendar: calendar))
    }

    func testH4AtRiskAfterOneMiss() {
        let h = history([date(2026, 10, 10), date(2026, 10, 11)])
        XCTAssertEqual(HabitMath.currentRun(h, now: now, calendar: calendar), 2)
        XCTAssertTrue(HabitMath.isAtRisk(h, now: now, calendar: calendar))
    }

    func testH5StartedToday() {
        let h = history([], started: date(2026, 10, 13, 8, 0))
        XCTAssertEqual(HabitMath.currentRun(h, now: now, calendar: calendar), 0)
        XCTAssertFalse(HabitMath.isAtRisk(h, now: now, calendar: calendar))
    }

    func testBestRunResetsAfterTwoMisses() {
        let days = [date(2026, 10, 2), date(2026, 10, 3), date(2026, 10, 6), date(2026, 10, 7), date(2026, 10, 8)]
        let h = history(days)
        let moment = date(2026, 10, 8, 18, 0)
        XCTAssertEqual(HabitMath.bestRun(h, now: moment, calendar: calendar), 3)
        XCTAssertEqual(HabitMath.currentRun(h, now: moment, calendar: calendar), 3)
    }

    func testDoneCountWindowEdges() {
        let h = history([date(2026, 9, 13), date(2026, 9, 14), date(2026, 10, 13)])
        XCTAssertEqual(HabitMath.doneCount(inLast: 30, h, now: now, calendar: calendar), 2)
        XCTAssertEqual(HabitMath.doneCount(inLast: 31, h, now: now, calendar: calendar), 3)
        XCTAssertEqual(HabitMath.doneCount(inLast: 1, h, now: now, calendar: calendar), 1)
        XCTAssertEqual(HabitMath.doneCount(inLast: 0, h, now: now, calendar: calendar), 0)
    }

    func testBestRunDoesNotTreatTodayAsAMiss() {
        let h = history([date(2026, 10, 11), date(2026, 10, 12)])
        XCTAssertEqual(HabitMath.bestRun(h, now: now, calendar: calendar), 2)
        XCTAssertEqual(HabitMath.currentRun(h, now: now, calendar: calendar), 2)
    }
}
