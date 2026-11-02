import XCTest

class UrgeBuddyUITestCase: XCTestCase {
    private(set) var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        resetOrientation()
        app = XCUIApplication()
        app.launchArguments = defaultLaunchArguments
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
        resetOrientation()
    }

    var defaultLaunchArguments: [String] {
        ["-ui_testing", "-skip_onboarding", "-seed_demo"]
    }

    func resetOrientation() {
        XCUIDevice.shared.orientation = .portrait
    }

    @discardableResult
    func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        app.launchArguments = defaultLaunchArguments + extraArguments
        app.launch()
        return app
    }

    func tab(named label: String, identifier: String) -> XCUIElement {
        // iPad's floating tab bar exposes the same identifier on the cell and its child.
        let identified = app.buttons.matching(NSPredicate(format: "identifier == %@", identifier)).firstMatch
        if identified.waitForExistence(timeout: 2) { return identified }
        let tabButton = app.tabBars.buttons[label].firstMatch
        if tabButton.waitForExistence(timeout: 2) { return tabButton }
        return app.buttons[label].firstMatch
    }

    func openProgressMetric(named name: String) {
        tab(named: "Progress", identifier: "tab.progress").tap()
        let card = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'progress.metricCard.' AND label CONTAINS %@", name)
        ).firstMatch
        if card.waitForExistence(timeout: 4) {
            card.tap()
        } else {
            let title = app.staticTexts[name]
            XCTAssertTrue(title.waitForExistence(timeout: 8))
            title.tap()
        }
        XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 10))
    }

    func tapCalendarDay(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let identifier = String(
            format: "detail.calendarDay.%04d-%02d-%02d",
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0
        )
        var dayButton = app.buttons[identifier]
        if !calendar.isDate(date, equalTo: Date(), toGranularity: .month) {
            let previous = app.buttons["Previous month"]
            for _ in 0..<6 where !previous.isHittable {
                app.swipeUp()
            }
            previous.tap()
        }
        for _ in 0..<6 {
            if dayButton.waitForExistence(timeout: 2) { break }
            app.swipeUp()
            dayButton = app.buttons[identifier]
        }
        XCTAssertTrue(dayButton.waitForExistence(timeout: 4), "Missing calendar day \(identifier)")
        dayButton.tap()
    }

    func assertStaticTextExists(_ text: String, timeout: TimeInterval = 10, scroll: Bool = false) {
        if scroll {
            XCTAssertTrue(scrollUntilLabel(text), "Missing text \(text)")
        } else {
            let match = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
            XCTAssertTrue(match.waitForExistence(timeout: timeout))
        }
    }

    @discardableResult
    func scrollUntilExists(_ element: XCUIElement, maxSwipes: Int = 12) -> Bool {
        if element.waitForExistence(timeout: 2) { return true }
        for _ in 0..<maxSwipes {
            app.swipeUp(velocity: .fast)
            if element.waitForExistence(timeout: 0.5) { return true }
        }
        return false
    }

    /// Reasons on a metric sit in a button below the calendar, so either element type can hold the label.
    func scrollUntilLabel(_ text: String, maxSwipes: Int = 14) -> Bool {
        func found() -> Bool {
            let pred = NSPredicate(format: "label CONTAINS %@", text)
            return app.staticTexts.matching(pred).firstMatch.exists
                || app.buttons.matching(pred).firstMatch.exists
        }
        if found() { return true }
        for _ in 0..<maxSwipes {
            app.swipeUp(velocity: .fast)
            if found() { return true }
        }
        return false
    }
}
