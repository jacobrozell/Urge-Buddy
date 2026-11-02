import XCTest
@testable import UrgeBuddy

final class DayMathTests: XCTestCase {
    private let calendar = Calendar.testNY

    func testAnchorIsLocalNoon() {
        let anchored = DayMath.anchor(date(2026, 10, 28, 0, 30), calendar: calendar)
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: anchored)
        XCTAssertEqual(parts.year, 2026)
        XCTAssertEqual(parts.month, 10)
        XCTAssertEqual(parts.day, 28)
        XCTAssertEqual(parts.hour, 12)
        XCTAssertEqual(parts.minute, 0)
        XCTAssertEqual(parts.second, 0)
    }

    func testEndOfDayIsLastSecond() {
        let end = DayMath.endOfDay(date(2026, 10, 28, 8), calendar: calendar)
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: end)
        XCTAssertEqual(parts.day, 28)
        XCTAssertEqual(parts.hour, 23)
        XCTAssertEqual(parts.minute, 59)
        XCTAssertEqual(parts.second, 59)
    }

    func testDaysAreInclusive() {
        let days = DayMath.days(from: date(2026, 10, 1), through: date(2026, 10, 3, 23), calendar: calendar)
        XCTAssertEqual(days.count, 3)
        XCTAssertEqual(days.first, calendar.startOfDay(for: date(2026, 10, 1)))
        XCTAssertEqual(days.last, calendar.startOfDay(for: date(2026, 10, 3)))
    }

    func testLeapDayIsIncluded() {
        let days = DayMath.days(from: date(2028, 2, 28), through: date(2028, 3, 1), calendar: calendar)
        XCTAssertEqual(days.count, 3)
        XCTAssertEqual(calendar.component(.day, from: days[1]), 29)
        XCTAssertEqual(calendar.component(.month, from: days[1]), 2)
    }

    func testDSTFallBackStillYieldsOneKeyPerCivilDay() {
        let days = DayMath.days(from: date(2026, 10, 31), through: date(2026, 11, 2), calendar: calendar)
        XCTAssertEqual(days.count, 3)
    }

    func testDSTSpringForwardStillYieldsOneKeyPerCivilDay() {
        let days = DayMath.days(from: date(2026, 3, 7), through: date(2026, 3, 9), calendar: calendar)
        XCTAssertEqual(days.count, 3)
    }

    func testKeyIsStartOfDay() {
        XCTAssertEqual(DayMath.key(date(2026, 10, 28, 18, 40), calendar: calendar), calendar.startOfDay(for: date(2026, 10, 28)))
    }
}
