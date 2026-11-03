import XCTest
@testable import UrgeBuddy

final class RecoveryCopyTests: XCTestCase {
    func testPlurals() {
        XCTAssertEqual(RecoveryCopy.daysFree(1), "1 day free")
        XCTAssertEqual(RecoveryCopy.daysFree(12), "12 days free")
        XCTAssertEqual(RecoveryCopy.habitRun(1), "1-day run")
        XCTAssertEqual(RecoveryCopy.habitRun(5), "5-day run")
        XCTAssertEqual(RecoveryCopy.urgePassed(1), "You rode it out. That's 1 urge you've beaten.")
        XCTAssertEqual(RecoveryCopy.urgePassed(6), "You rode it out. That's 6 urges you've beaten.")
        XCTAssertEqual(RecoveryCopy.nextMilestone(14, inDays: 1), "Next: 14 days (in 1 day)")
        XCTAssertEqual(RecoveryCopy.nextMilestone(14, inDays: 2), "Next: 14 days (in 2 days)")
    }

    func testClockFormats() {
        XCTAssertEqual(RecoveryCopy.clock(days: 12, hours: 4, minutes: 13), "12d 4h 13m")
        XCTAssertEqual(RecoveryCopy.clock(days: 6, hours: 0, minutes: 0), "6d")
        XCTAssertEqual(RecoveryCopy.clock(days: 9, hours: 0, minutes: 40), "9d 40m")
        XCTAssertEqual(RecoveryCopy.clock(days: 0, hours: 3, minutes: 0), "3h 0m")
        XCTAssertEqual(RecoveryCopy.clock(days: 0, hours: 0, minutes: 6), "6m")
        XCTAssertEqual(RecoveryCopy.clock(days: 0, hours: 0, minutes: 0), "Just started")
    }

    func testSavedFormattingUsesEnUSCurrency() {
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(RecoveryCopy.saved(88, locale: locale), "$88.00 saved")
        XCTAssertEqual(RecoveryCopy.saved(Decimal(string: "12.50")!, locale: locale), "$12.50 saved")
    }

    func testRemainingDeckStrings() {
        XCTAssertEqual(RecoveryCopy.freeOfLast(free: 27, counted: 30), "27 of last 30 days free")
        XCTAssertEqual(RecoveryCopy.dontMissTwice, "Don't miss twice")
        XCTAssertEqual(RecoveryCopy.checkInBanner(left: 3), "Check in · 3 things left · about 10 seconds")
        XCTAssertEqual(RecoveryCopy.checkInBanner(left: 1), "Check in · 1 thing left · about 10 seconds")
        XCTAssertEqual(RecoveryCopy.checkInStreak(1), "1 day in a row")
        XCTAssertEqual(RecoveryCopy.checkInStreak(4), "4 days in a row")
        XCTAssertEqual(RecoveryCopy.sosButton, "I'm having an urge")
        XCTAssertEqual(RecoveryCopy.urgeSurfingTitle, "Urge surfing")
        XCTAssertTrue(RecoveryCopy.urgeSurfingRow.contains("wave"))
        XCTAssertTrue(RecoveryCopy.urgeIntro.contains("urge surfing"))
        XCTAssertTrue(RecoveryCopy.urgeSurfingWhat.contains("wave"))
        XCTAssertTrue(RecoveryCopy.urgeSurfingHow.contains("watch"))
        XCTAssertFalse(RecoveryCopy.urgeSurfingHere.isEmpty)
        XCTAssertEqual(AppLinks.urgeSurfingPractice.scheme, "https")
        XCTAssertEqual(AppLinks.urgeSurfingOrigin.scheme, "https")
        XCTAssertTrue(RecoveryCopy.welcomeLine2.contains("surf"))
        XCTAssertEqual(RecoveryCopy.slipTitle, "Thanks for being honest.")
        XCTAssertEqual(RecoveryCopy.slipSummaryTitle, "Your free clock restarts from here.")
        XCTAssertEqual(RecoveryCopy.milestoneVice(1, name: "Alcohol"), "Your first day free from Alcohol.")
        XCTAssertEqual(RecoveryCopy.milestoneVice(7, name: "Alcohol"), "7 days free from Alcohol.")
        XCTAssertEqual(RecoveryCopy.milestoneHabit(3, name: "Walk"), "3-day run: Walk.")
        XCTAssertEqual(RecoveryCopy.milestoneNotificationTitle(7), "7 days free")
        XCTAssertTrue(RecoveryCopy.milestoneNotificationBody(7, name: "Alcohol").contains("Alcohol"))
        XCTAssertFalse(RecoveryCopy.disclaimer.isEmpty)
        var components = DateComponents()
        components.day = 1
        components.hour = 2
        components.minute = 3
        XCTAssertEqual(RecoveryCopy.clock(components), "1d 2h 3m")
    }

    func testSlipSummaryIncludesSavingsWhenPresent() {
        XCTAssertEqual(
            RecoveryCopy.slipSummaryBody(free: 27, counted: 30, saved: "$135"),
            "You still have 27 of your last 30 days free and $135 saved. That progress is real and it stays."
        )
        XCTAssertEqual(
            RecoveryCopy.slipSummaryBody(free: 27, counted: 30, saved: nil),
            "You still have 27 of your last 30 days free. That progress is real and it stays."
        )
    }
}
