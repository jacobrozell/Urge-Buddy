import XCTest
@testable import UrgeBuddy

final class ReminderPlanTests: XCTestCase {
    func testSkipsTodayWhenTheCheckInIsDone() {
        let now = date(2026, 10, 28, 12)
        let notes = ReminderPlan.requests(
            remindersEnabled: true,
            hour: 20,
            minute: 0,
            milestonesEnabled: false,
            discreet: false,
            checkInCompleteToday: true,
            vices: [],
            now: now,
            calendar: .testNY
        )
        XCTAssertEqual(notes.count, 6)
        XCTAssertFalse(notes.contains { $0.identifier == "checkin.2026-10-28" })
        XCTAssertEqual(notes.first?.identifier, "checkin.2026-10-29")
        XCTAssertEqual(notes.first?.body, RecoveryCopy.checkInNotificationBody)
    }

    func testSkipsTodayWhenTheTimeHasPassed() {
        let now = date(2026, 10, 28, 21)
        let notes = ReminderPlan.requests(
            remindersEnabled: true,
            hour: 20,
            minute: 0,
            milestonesEnabled: false,
            discreet: true,
            checkInCompleteToday: false,
            vices: [],
            now: now,
            calendar: .testNY
        )
        XCTAssertEqual(notes.count, 6)
        XCTAssertEqual(notes.first?.title, RecoveryCopy.discreetCheckInTitle)
        XCTAssertEqual(notes.first?.body, RecoveryCopy.discreetCheckInBody)
    }

    func testMilestoneLandsOnTheThresholdDay() {
        let start = date(2026, 10, 21, 9)
        let now = date(2026, 10, 28, 12)
        let notes = ReminderPlan.requests(
            remindersEnabled: false,
            hour: 20,
            minute: 0,
            milestonesEnabled: true,
            discreet: false,
            checkInCompleteToday: false,
            vices: [MilestoneReminderInput(metricID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Alcohol", runStart: start, runDays: 7)],
            now: now,
            calendar: .testNY
        )
        XCTAssertEqual(notes.map(\.identifier), [
            "milestone.00000000-0000-0000-0000-000000000001.14",
            "milestone.00000000-0000-0000-0000-000000000001.30"
        ])
        XCTAssertEqual(notes[0].title, "14 days free")
        XCTAssertTrue(notes[0].body.contains("Alcohol"))
    }
}
