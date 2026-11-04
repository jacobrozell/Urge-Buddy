import XCTest

final class UrgeBuddyUITests: UrgeBuddyUITestCase {
    func testLaunchShowsThreeTabs() {
        launchApp()
        XCTAssertTrue(tab(named: "Today", identifier: "tab.today").waitForExistence(timeout: 8))
        XCTAssertTrue(tab(named: "Progress", identifier: "tab.progress").exists)
        XCTAssertTrue(tab(named: "Settings", identifier: "tab.settings").exists)
    }

    func testCheckInMarksVicesFree() {
        launchApp()
        let banner = app.buttons["today.checkInBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 8))
        banner.tap()

        let freeButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'checkIn.free.'"))
        XCTAssertTrue(freeButtons.firstMatch.waitForExistence(timeout: 4))
        let identifiers = freeButtons.allElementsBoundByIndex.map(\.identifier)
        XCTAssertEqual(identifiers.count, 2)
        for identifier in identifiers {
            app.buttons[identifier].tap()
        }

        let done = app.buttons["checkIn.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 4))
        done.tap()
        done.tap()
        XCTAssertTrue(banner.waitForNonExistence(timeout: 6))
    }

    func testVoiceOverTodayAndCheckIn() {
        launchApp()
        let alcohol = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'today.viceCard.' AND label BEGINSWITH 'Alcohol'")
        )
        XCTAssertEqual(alcohol.count, 1)
        let card = alcohol.firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 8))
        XCTAssertTrue(card.label.contains("days free"), card.label)
        XCTAssertTrue(card.label.contains("hour") || card.label.contains("minute"), card.label)

        let dismiss = app.buttons["today.urgeSurfing.dismiss"]
        XCTAssertTrue(dismiss.waitForExistence(timeout: 4))
        XCTAssertGreaterThanOrEqual(dismiss.frame.width, 44, dismiss.debugDescription)
        XCTAssertGreaterThanOrEqual(dismiss.frame.height, 44, dismiss.debugDescription)

        let smoking = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'today.cutBackCard.'")).firstMatch
        XCTAssertTrue(smoking.waitForExistence(timeout: 4))
        XCTAssertGreaterThanOrEqual(smoking.frame.height, 44, smoking.debugDescription)

        let toggles = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'today.habitToggle.'"))
        XCTAssertGreaterThan(toggles.count, 0)
        for index in 0..<toggles.count {
            let toggle = toggles.element(boundBy: index)
            XCTAssertGreaterThanOrEqual(toggle.frame.width, 44, toggle.debugDescription)
            XCTAssertGreaterThanOrEqual(toggle.frame.height, 44, toggle.debugDescription)
        }

        let banner = app.buttons["today.checkInBanner"]
        banner.tap()
        let free = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'checkIn.free.'")).firstMatch
        XCTAssertTrue(free.waitForExistence(timeout: 4))
        XCTAssertFalse(accessibilityLine(free).contains("Selected"), accessibilityLine(free))
        free.tap()
        XCTAssertTrue(accessibilityLine(free).contains("Selected"), accessibilityLine(free))
    }

    func testCutBackStepperLogsOneMore() {
        launchApp()
        let stepper = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'today.cutBackStepper.'")).firstMatch
        for _ in 0..<4 where !stepper.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(stepper.waitForExistence(timeout: 8))
        XCTAssertEqual(stepper.value as? String, "3 cigarettes")
        stepper.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        let card = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'today.cutBackCard.'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 4))
        XCTAssertTrue(card.label.contains("4 of 8 cigarettes"))
    }

    func testCutBackDetailShowsLimitAndTrend() {
        launchApp()
        openProgressMetric(named: "Smoking")
        assertStaticTextExists("Daily limit")
        assertStaticTextExists("Down")
    }

    func testCheckInSavesTheMoodToRecentDays() {
        launchApp()
        let banner = app.buttons["today.checkInBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 8))
        banner.tap()
        let great = app.buttons["Great"]
        for _ in 0..<4 where !great.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(great.waitForExistence(timeout: 4))
        great.tap()
        app.buttons["Close"].firstMatch.tap()
        tab(named: "Progress", identifier: "tab.progress").tap()
        let greatRow = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Great'")).firstMatch
        for _ in 0..<6 where !greatRow.exists {
            app.swipeUp()
        }
        XCTAssertTrue(greatRow.waitForExistence(timeout: 6))
    }

    func testRecentDayStaysOnTheProgressList() {
        launchApp(extraArguments: ["-tab_progress"])
        let row = app.descendants(matching: .any)["progress.recentDay"].firstMatch
        for _ in 0..<6 where !row.exists {
            app.swipeUp()
        }
        XCTAssertTrue(row.waitForExistence(timeout: 8))
        row.tap()
        app.staticTexts["Recent days"].firstMatch.tap()
        XCTAssertFalse(app.staticTexts["Pick something to see its progress"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.navigationBars["Progress"].exists)
    }

    func testUrgeAddWhyDuringRide() {
        launchApp()
        app.buttons["today.sosButton"].tap()
        app.buttons["Alcohol"].tap()
        app.buttons["urge.intensity.3"].tap()
        let field = app.textFields["urge.addWhy"].exists ? app.textFields["urge.addWhy"] : app.textViews["urge.addWhy"]
        for _ in 0..<8 where !field.exists {
            app.swipeUp()
        }
        XCTAssertTrue(field.waitForExistence(timeout: 6))
        field.tap()
        field.typeText("For my kids")
        app.buttons["urge.saveWhy"].tap()
        assertStaticTextExists("For my kids", timeout: 4)
        app.buttons["urge.passed"].tap()
        app.buttons["urge.done"].tap()
        openProgressMetric(named: "Alcohol")
        let saved = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'detail.reason' AND label CONTAINS %@", "For my kids")
        ).firstMatch
        XCTAssertTrue(scrollUntilExists(saved), "Missing reason For my kids")
    }

    func testUrgeFlowResisted() {
        launchApp()
        let sos = app.buttons["today.sosButton"]
        XCTAssertTrue(sos.waitForExistence(timeout: 8))
        sos.tap()
        let alcohol = app.buttons["Alcohol"]
        XCTAssertTrue(alcohol.waitForExistence(timeout: 4))
        alcohol.tap()
        app.buttons["urge.intensity.3"].tap()
        app.buttons["urge.passed"].tap()
        app.buttons["urge.done"].tap()
        tab(named: "Progress", identifier: "tab.progress").tap()
        assertStaticTextExists("Urges beaten", timeout: 8)
    }

    func testUrgeJournalNoteSavesToJournal() {
        launchApp()
        let sos = app.buttons["today.sosButton"]
        XCTAssertTrue(sos.waitForExistence(timeout: 8))
        sos.tap()
        app.buttons["Alcohol"].tap()
        app.buttons["urge.intensity.3"].tap()
        app.buttons["urge.writeItDown"].tap()
        let field = app.textFields["urge.journal"].exists ? app.textFields["urge.journal"] : app.textViews["urge.journal"]
        XCTAssertTrue(field.waitForExistence(timeout: 4))
        field.tap()
        field.typeText("Rough call at work")
        XCTAssertEqual(field.value as? String, "Rough call at work")
        let passed = app.buttons["urge.passed"]
        for _ in 0..<6 where !passed.isHittable {
            app.swipeUp()
        }
        passed.tap()
        app.buttons["urge.journal.save"].tap()
        app.buttons["urge.done"].tap()
        tab(named: "Progress", identifier: "tab.progress").tap()
        let journal = app.buttons["progress.journal"]
        for _ in 0..<6 where !journal.isHittable {
            app.swipeUp()
        }
        journal.tap()
        assertStaticTextExists("Rough call at work", timeout: 6)
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Rough call at work'")).firstMatch.tap()
        app.navigationBars.buttons["Delete"].tap()
        app.sheets.buttons["Delete"].firstMatch.tap()
        let gone = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Rough call at work'")).firstMatch
        XCTAssertTrue(gone.waitForNonExistence(timeout: 4))
    }

    func testSlipFlowShowsCompassionateSummary() {
        launchApp()
        let banner = app.buttons["today.checkInBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 8))
        banner.tap()
        let slipped = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'checkIn.slipped.'"))
        XCTAssertTrue(slipped.firstMatch.waitForExistence(timeout: 4))
        slipped.firstMatch.tap()
        XCTAssertTrue(app.buttons["slip.save"].waitForExistence(timeout: 6))
        app.buttons["slip.save"].tap()
        let summary = app.otherElements["slip.summary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 6))
        XCTAssertTrue(summary.staticTexts.matching(NSPredicate(format: "label CONTAINS 'restarts'")).firstMatch.exists
            || app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'restarts'")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'of your last'")).firstMatch.exists)
    }

    func testEditPastDayToSlipUpdatesStats() {
        launchApp()
        openProgressMetric(named: "Alcohol")

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        tapCalendarDay(yesterday)

        XCTAssertTrue(app.buttons["dayEditor.slipped"].waitForExistence(timeout: 4))
        app.buttons["dayEditor.slipped"].tap()

        let save = app.buttons["slip.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 8))
        save.tap()

        assertStaticTextExists("0 days free", timeout: 12)
    }

    func testSettingsReplaysOnboarding() {
        launchApp()
        tab(named: "Settings", identifier: "tab.settings").tap()
        let replay = app.buttons["settings.viewOnboarding"]
        XCTAssertTrue(scrollUntilExists(replay), "See the introduction is below the Settings fold")
        replay.tap()
        XCTAssertTrue(app.staticTexts["Quit what's hurting you. Build what helps."].waitForExistence(timeout: 4))
        app.buttons["onboarding.next"].tap()
        XCTAssertTrue(app.staticTexts["What it is"].waitForExistence(timeout: 4))
        app.buttons["Close"].tap()
        XCTAssertTrue(replay.waitForExistence(timeout: 4))
    }

    func testOnboardingTeachesUrgeSurfing() {
        app.launchArguments = ["-ui_testing"]
        app.launch()

        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 8))
        next.tap()

        XCTAssertTrue(app.staticTexts["What it is"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["What you do"].exists)
        XCTAssertTrue(app.staticTexts["When an urge hits"].exists)
    }

    func testOnboardingCreatesViceAndLandsOnToday() {
        launchFreshOnboarding()
        advanceOnboarding(to: "What it is")
        advanceOnboarding(to: "What do you want to quit?")
        let alcohol = app.buttons["onboarding.vicePreset.alcohol"]
        XCTAssertTrue(alcohol.waitForExistence(timeout: 4))
        alcohol.tap()
        advanceOnboarding(to: "When did you last drink?")
        advanceOnboarding(to: "Why do you want to quit Alcohol?")
        advanceOnboarding(to: "What helps you?")
        advanceOnboarding(to: "Daily check-in time")
        declineOptionalPromptsAndFinish()

        XCTAssertTrue(tab(named: "Today", identifier: "tab.today").waitForExistence(timeout: 8))
        assertStaticTextExists("Alcohol")
    }

    func testOnboardingCustomViceKeepsKeyboardWhileTyping() {
        launchFreshOnboarding()
        advanceOnboarding(to: "What it is")
        advanceOnboarding(to: "What do you want to quit?")
        let alcohol = app.buttons["onboarding.vicePreset.alcohol"]
        XCTAssertTrue(alcohol.waitForExistence(timeout: 4))
        alcohol.tap()
        XCTAssertTrue(alcohol.isSelected)
        let field = app.textFields["Something else…"]
        XCTAssertTrue(field.waitForExistence(timeout: 4))
        field.tap()
        field.typeText("Vaping")
        XCTAssertEqual(field.value as? String, "Vaping")
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        advanceOnboarding(to: "When did you last drink?")
        advanceOnboarding(to: "When did you last do it?")
    }

    func testOnboardingHabitOnlyPath() {
        launchFreshOnboarding()
        advanceOnboarding(to: "What it is")
        advanceOnboarding(to: "What do you want to quit?")
        let habitsOnly = app.buttons["onboarding.habitOnly"]
        XCTAssertTrue(habitsOnly.waitForExistence(timeout: 4))
        habitsOnly.tap()
        advanceOnboarding(to: "What helps you?")
        let walk = app.buttons["onboarding.vicePreset.walk"]
        XCTAssertTrue(walk.waitForExistence(timeout: 4))
        walk.tap()
        advanceOnboarding(to: "Daily check-in time")
        declineOptionalPromptsAndFinish()

        XCTAssertTrue(tab(named: "Today", identifier: "tab.today").waitForExistence(timeout: 8))
        assertStaticTextExists("Go for a walk")
        XCTAssertFalse(app.staticTexts["Alcohol"].waitForExistence(timeout: 1))
    }

    func testSettingsOpensCrisisResources() {
        launchApp()
        tab(named: "Settings", identifier: "tab.settings").tap()
        let help = app.buttons["settings.crisisResources"]
        XCTAssertTrue(scrollUntilExists(help), "Get help now is below the Settings fold")
        help.tap()
        let bar = app.navigationBars["Get help now"]
        XCTAssertTrue(bar.waitForExistence(timeout: 4))
        assertCrisisResourcesShown()
        bar.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(bar.waitForNonExistence(timeout: 4))
        XCTAssertTrue(help.isHittable)
    }

    func testSlipSummaryOpensCrisisResources() {
        launchApp()
        let banner = app.buttons["today.checkInBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 8))
        banner.tap()
        let slipped = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'checkIn.slipped.'"))
        XCTAssertTrue(slipped.firstMatch.waitForExistence(timeout: 4))
        slipped.firstMatch.tap()
        XCTAssertTrue(app.buttons["slip.save"].waitForExistence(timeout: 6))
        app.buttons["slip.save"].tap()
        let support = app.buttons["Need more support?"]
        XCTAssertTrue(support.waitForExistence(timeout: 6))
        support.tap()
        assertCrisisResourcesShown()
        app.swipeDown(velocity: .fast)
        XCTAssertTrue(app.staticTexts["988 Suicide & Crisis Lifeline"].waitForNonExistence(timeout: 4))
        XCTAssertTrue(app.otherElements["slip.summary"].exists)
    }

    func testDeleteAllReturnsToOnboarding() {
        launchApp()
        tab(named: "Settings", identifier: "tab.settings").tap()
        let delete = app.buttons["settings.deleteAll"]
        XCTAssertTrue(scrollUntilExists(delete), "Delete all data is below the Settings fold")
        delete.tap()
        tapConfirmation("Continue")
        XCTAssertTrue(app.staticTexts["This removes your vices, habits, and history. This can't be undone."].waitForExistence(timeout: 4))
        tapConfirmation("Delete all data")

        XCTAssertTrue(app.staticTexts["Quit what's hurting you. Build what helps."].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["tab.today"].exists)
    }

    private func assertCrisisResourcesShown() {
        let resources = [
            "call 911", "988 Suicide & Crisis Lifeline", "Call 988", "Text 988",
            "SAMHSA National Helpline", "Call 1-800-662-4357", "Outside the US, find a helpline",
        ]
        for label in resources {
            let match = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
            XCTAssertTrue(match.waitForExistence(timeout: 4), "Missing crisis resource \(label)")
        }
    }

    private func launchFreshOnboarding() {
        app.launchArguments = ["-ui_testing"]
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 8))
    }

    private func advanceOnboarding(to text: String) {
        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 4))
        next.tap()
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 4), "Missing onboarding step \(text)")
    }

    /// Reminders, and privacy when the device can lock, both offer Not now. Turning either on would leave the test.
    private func declineOptionalPromptsAndFinish() {
        let notNow = app.buttons["Not now"]
        let finish = app.buttons["onboarding.finish"]
        for _ in 0..<3 {
            if finish.waitForExistence(timeout: 2) {
                finish.tap()
                return
            }
            XCTAssertTrue(notNow.waitForExistence(timeout: 4))
            notNow.tap()
        }
        XCTFail("Onboarding did not reach the disclaimer")
    }

    private func tapConfirmation(_ title: String) {
        let candidates = [app.alerts.buttons[title], app.sheets.buttons[title], app.popovers.buttons[title]]
        let deadline = Date().addingTimeInterval(4)
        while Date() < deadline {
            if let match = candidates.first(where: \.exists) {
                match.tap()
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTFail("Missing confirmation \(title)")
    }

    /// First line of the snapshot. The rest of `debugDescription` includes other elements, such as the selected tab.
    private func accessibilityLine(_ element: XCUIElement) -> String {
        String(element.debugDescription.split(separator: "\n", maxSplits: 1).first ?? "")
    }
}
