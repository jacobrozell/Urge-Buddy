import XCTest
@testable import UrgeBuddy

final class PreferencesTests: XCTestCase {
    override func tearDown() {
        Preferences.resetAll()
        super.tearDown()
    }

    func testDefaultsAndRoundTrip() {
        Preferences.resetAll()
        XCTAssertFalse(Preferences.hasCompletedOnboarding)
        XCTAssertEqual(Preferences.reminderHour, 20)
        XCTAssertEqual(Preferences.reminderMinute, 0)
        XCTAssertTrue(Preferences.milestoneNotificationsEnabled)
        XCTAssertEqual(Preferences.appearance, .system)

        Preferences.hasCompletedOnboarding = true
        Preferences.reminderHour = 7
        Preferences.reminderMinute = 30
        Preferences.milestoneNotificationsEnabled = false
        Preferences.appearance = .dark
        Preferences.discreetNotifications = true
        Preferences.appLockEnabled = true
        let day = date(2026, 10, 27)
        Preferences.dismissedYesterdayPromptDay = day

        XCTAssertTrue(Preferences.hasCompletedOnboarding)
        XCTAssertEqual(Preferences.reminderHour, 7)
        XCTAssertEqual(Preferences.reminderMinute, 30)
        XCTAssertFalse(Preferences.milestoneNotificationsEnabled)
        XCTAssertEqual(Preferences.appearance, .dark)
        XCTAssertTrue(Preferences.discreetNotifications)
        XCTAssertTrue(Preferences.appLockEnabled)
        XCTAssertEqual(Preferences.dismissedYesterdayPromptDay, day)

        Preferences.resetAll()
        XCTAssertFalse(Preferences.hasCompletedOnboarding)
        XCTAssertEqual(Preferences.reminderHour, 20)
        XCTAssertTrue(Preferences.milestoneNotificationsEnabled)
        XCTAssertNil(Preferences.dismissedYesterdayPromptDay)
    }
}
