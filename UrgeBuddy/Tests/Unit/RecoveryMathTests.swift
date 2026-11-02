import XCTest
@testable import UrgeBuddy

final class RecoveryMathTests: XCTestCase {
    private let calendar = Calendar.testNY
    private var now: Date { date(2026, 10, 13, 10, 0) }

    private func history(slips: [Date] = [], confirmed: [Date] = [], started: Date = date(2026, 10, 1, 9, 0)) -> ViceHistory {
        ViceHistory(
            startedAt: started,
            slips: slips,
            confirmedFreeDays: Set(confirmed.map { calendar.startOfDay(for: $0) })
        )
    }

    func testV1NoSlips() {
        let h = history()
        XCTAssertEqual(RecoveryMath.currentRunDays(h, now: now, calendar: calendar), 12)
        XCTAssertEqual(RecoveryMath.totalFreeDays(h, now: now, calendar: calendar), 12)
        XCTAssertEqual(RecoveryMath.freeDays(inLast: 30, h, now: now, calendar: calendar).free, 12)
        XCTAssertEqual(RecoveryMath.freeDays(inLast: 30, h, now: now, calendar: calendar).counted, 12)
        XCTAssertEqual(RecoveryMath.state(of: date(2026, 10, 13), in: h, now: now, calendar: calendar), .todayPending)
        XCTAssertEqual(RecoveryMath.state(of: date(2026, 10, 12), in: h, now: now, calendar: calendar), .presumedFree)
    }

    func testV2SlipOnOctober10() {
        let slip = date(2026, 10, 10, 20, 0)
        let h = history(slips: [slip])
        XCTAssertEqual(RecoveryMath.currentRunStart(h), slip)
        XCTAssertEqual(RecoveryMath.currentRunDays(h, now: now, calendar: calendar), 2)
        XCTAssertEqual(RecoveryMath.longestRunDays(h, now: now, calendar: calendar), 9)
        XCTAssertEqual(RecoveryMath.totalFreeDays(h, now: now, calendar: calendar), 11)
        let window = RecoveryMath.freeDays(inLast: 30, h, now: now, calendar: calendar)
        XCTAssertEqual(window.free, 11)
        XCTAssertEqual(window.counted, 12)
    }

    func testV3ConfirmedToday() {
        let h = history(slips: [date(2026, 10, 10, 20, 0)], confirmed: [date(2026, 10, 13)])
        let window = RecoveryMath.freeDays(inLast: 30, h, now: now, calendar: calendar)
        XCTAssertEqual(window.free, 12)
        XCTAssertEqual(window.counted, 13)
        XCTAssertEqual(RecoveryMath.state(of: date(2026, 10, 13), in: h, now: now, calendar: calendar), .confirmedFree)
    }

    func testV4SlipBeforeStartIsIgnored() {
        let h = history(slips: [date(2026, 9, 20, 20, 0)])
        XCTAssertEqual(RecoveryMath.currentRunDays(h, now: now, calendar: calendar), 12)
        XCTAssertEqual(RecoveryMath.totalFreeDays(h, now: now, calendar: calendar), 12)
        XCTAssertEqual(RecoveryMath.relevantSlips(h), [])
    }

    func testV5MoneySavedUsesTotalFreeDays() {
        XCTAssertEqual(RecoveryMath.moneySaved(totalFreeDays: 11, costPerDay: 8), 88)
    }

    func testV6PartialFirstDay() {
        let started = calendar.date(byAdding: .hour, value: -3, to: date(2026, 10, 13, 15, 0))!
        let moment = date(2026, 10, 13, 15, 0)
        let h = history(started: started)
        XCTAssertEqual(RecoveryMath.currentRunDays(h, now: moment, calendar: calendar), 0)
        let clock = RecoveryMath.currentRunClock(h, now: moment, calendar: calendar)
        XCTAssertEqual(clock.day, 0)
        XCTAssertEqual(clock.hour, 3)
        XCTAssertEqual(clock.minute, 0)
    }

    func testV7DSTFallBack() {
        let h = history(started: date(2026, 10, 31, 12, 0))
        let moment = date(2026, 11, 2, 12, 0)
        XCTAssertEqual(RecoveryMath.currentRunDays(h, now: moment, calendar: calendar), 2)
        XCTAssertEqual(RecoveryMath.totalFreeDays(h, now: moment, calendar: calendar), 2)
    }

    func testV8DSTSpringForward() {
        let h = history(started: date(2026, 3, 7, 12, 0))
        let moment = date(2026, 3, 9, 12, 0)
        XCTAssertEqual(RecoveryMath.currentRunDays(h, now: moment, calendar: calendar), 2)
        XCTAssertEqual(RecoveryMath.totalFreeDays(h, now: moment, calendar: calendar), 2)
    }

    func testSlipExactlyAtStartCounts() {
        let started = date(2026, 10, 1, 9, 0)
        let h = history(slips: [started], started: started)
        XCTAssertEqual(RecoveryMath.currentRunStart(h), started)
        XCTAssertEqual(RecoveryMath.relevantSlips(h), [started])
    }

    func testMultipleSlipsOnTheSameDayUseTheLatestInstant() {
        let morning = date(2026, 10, 10, 8, 0)
        let evening = date(2026, 10, 10, 20, 0)
        let h = history(slips: [evening, morning])
        XCTAssertEqual(RecoveryMath.currentRunStart(h), evening)
        XCTAssertEqual(RecoveryMath.state(of: date(2026, 10, 10), in: h, now: now, calendar: calendar), .slipped)
        XCTAssertEqual(RecoveryMath.totalFreeDays(h, now: now, calendar: calendar), 11)
    }

    func testWindowLargerThanHistoryExcludesBeforeStartAndTodayPending() {
        let h = history(started: date(2026, 10, 10, 9, 0))
        let window = RecoveryMath.freeDays(inLast: 30, h, now: now, calendar: calendar)
        XCTAssertEqual(window.free, 3)
        XCTAssertEqual(window.counted, 3)
        XCTAssertEqual(RecoveryMath.state(of: date(2026, 9, 1), in: h, now: now, calendar: calendar), .beforeStart)
        XCTAssertEqual(RecoveryMath.state(of: date(2026, 10, 14), in: h, now: now, calendar: calendar), .future)
    }

    func testMoneySavedIsNilWithoutAPositiveCostOrFreeDays() {
        XCTAssertNil(RecoveryMath.moneySaved(totalFreeDays: 4, costPerDay: nil))
        XCTAssertNil(RecoveryMath.moneySaved(totalFreeDays: 4, costPerDay: 0))
        XCTAssertNil(RecoveryMath.moneySaved(totalFreeDays: 0, costPerDay: 8))
    }

    func testCurrentRunDaysIsZeroWhenNowIsNotAfterStart() {
        let started = date(2026, 10, 13, 10, 0)
        let h = history(started: started)
        XCTAssertEqual(RecoveryMath.currentRunDays(h, now: started, calendar: calendar), 0)
    }

    func testFreeDaysWindowOfZero() {
        let window = RecoveryMath.freeDays(inLast: 0, history(), now: now, calendar: calendar)
        XCTAssertEqual(window.free, 0)
        XCTAssertEqual(window.counted, 0)
    }
}
