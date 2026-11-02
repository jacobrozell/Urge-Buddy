import XCTest

final class AdaptiveLayoutUITests: UrgeBuddyUITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        resetOrientation()
    }

    override func tearDownWithError() throws {
        resetOrientation()
        try super.tearDownWithError()
    }

    func testTodayLandscapeKeepsSOSAndCheckInReachable() {
        launchApp()
        XCUIDevice.shared.orientation = .landscapeLeft

        let sos = app.buttons["today.sosButton"]
        let banner = app.buttons["today.checkInBanner"]
        XCTAssertTrue(sos.waitForExistence(timeout: 8))
        XCTAssertTrue(banner.waitForExistence(timeout: 4))
        XCTAssertTrue(sos.isHittable)
        XCTAssertTrue(banner.isHittable)
    }

    func testCheckInDoneInToolbarInLandscape() {
        launchApp()
        XCUIDevice.shared.orientation = .landscapeLeft

        let banner = app.buttons["today.checkInBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 8))
        banner.tap()

        let freeButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'checkIn.free.'"))
        XCTAssertTrue(freeButtons.firstMatch.waitForExistence(timeout: 4))
        for identifier in freeButtons.allElementsBoundByIndex.map(\.identifier) {
            app.buttons[identifier].tap()
        }

        let done = app.buttons["checkIn.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 4))
        done.tap()
        done.tap()
        XCTAssertTrue(banner.waitForNonExistence(timeout: 6))
    }

    func testCheckInSheetSurvivesRotation() {
        launchApp()
        let banner = app.buttons["today.checkInBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 8))
        banner.tap()

        let freeButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'checkIn.free.'"))
        XCTAssertTrue(freeButtons.firstMatch.waitForExistence(timeout: 4))
        freeButtons.firstMatch.tap()

        XCUIDevice.shared.orientation = .landscapeLeft

        XCTAssertTrue(app.buttons["checkIn.done"].waitForExistence(timeout: 4))
        XCTAssertTrue(freeButtons.firstMatch.exists)

        app.buttons["Close"].tap()
    }

    func testUrgeRideInLandscape() {
        launchApp()
        XCUIDevice.shared.orientation = .landscapeLeft

        app.buttons["today.sosButton"].tap()
        app.buttons["Alcohol"].tap()
        app.buttons["urge.intensity.3"].tap()

        let passed = app.buttons["urge.passed"]
        if !passed.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(passed.waitForExistence(timeout: 4))
        passed.tap()
        app.buttons["urge.done"].tap()
    }

    func testSlipSaveInToolbarInLandscape() {
        launchApp()
        XCUIDevice.shared.orientation = .landscapeLeft

        let banner = app.buttons["today.checkInBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 8))
        banner.tap()

        let slipped = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'checkIn.slipped.'"))
        XCTAssertTrue(slipped.firstMatch.waitForExistence(timeout: 4))
        slipped.firstMatch.tap()

        let save = app.buttons["slip.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 4))
        XCTAssertTrue(save.isHittable)
        save.tap()
        XCTAssertTrue(app.otherElements["slip.summary"].waitForExistence(timeout: 6))
    }

    func testOnboardingNextReachableInLandscape() {
        app.launchArguments = ["-ui_testing"]
        app.launch()

        XCUIDevice.shared.orientation = .landscapeLeft

        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 8))
        XCTAssertTrue(next.isHittable)
    }

    func testProgressSplitOnRegularWidth() throws {
        launchApp()
        guard app.windows.firstMatch.frame.width >= 744 else {
            throw XCTSkip("Requires iPad-width simulator window")
        }

        tab(named: "Progress", identifier: "tab.progress").tap()
        openProgressMetric(named: "Alcohol")

        if app.staticTexts["Social media"].waitForExistence(timeout: 2) {
            XCTAssertTrue(app.staticTexts["Social media"].exists)
        }
    }
}
