import XCTest
@testable import TrackBoth

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    func testNeedsAViceOrTheHabitOnlyPath() {
        let model = OnboardingViewModel()
        model.pageIndex = 1
        XCTAssertEqual(model.page, .chooseVices)
        XCTAssertFalse(model.canAdvance)
        model.chooseHabitsOnly()
        XCTAssertTrue(model.canAdvance)
    }

    func testPastQuitDateIsEndOfThatDay() {
        let model = OnboardingViewModel()
        model.toggleVice("alcohol")
        var detail = model.detail(for: "alcohol", now: date(2026, 10, 28, 15))
        detail.when = .yesterday
        let start = model.startedAt(detail, now: date(2026, 10, 28, 15), calendar: .testNY)
        XCTAssertEqual(start, date(2026, 10, 27, 23, 59).addingTimeInterval(59))
    }

    func testTodayQuitDateIsNowAndHabitStartsNow() {
        let model = OnboardingViewModel()
        model.toggleVice("alcohol")
        model.reasonText = "For my health"
        model.toggleHabit("walk")
        let now = date(2026, 10, 28, 15, 30)
        let drafts = model.drafts(now: now, calendar: .testNY)
        XCTAssertEqual(drafts.map(\.name), ["Alcohol", "Go for a walk"])
        XCTAssertEqual(drafts[0].startedAt, now)
        XCTAssertEqual(drafts[0].firstReason, "For my health")
        XCTAssertEqual(drafts[1].habitType, .positive)
        XCTAssertEqual(drafts[1].startedAt, now)
        XCTAssertNil(drafts[1].firstReason)
    }

    func testCutBackDraftUsesPresetUnitAndDefaultsLimitToUsual() {
        let model = OnboardingViewModel()
        model.toggleVice("smoking")
        model.toggleHabit("water")
        let now = date(2026, 10, 28, 15)
        var detail = model.detail(for: "smoking", now: now)
        detail.mode = .cutBack
        detail.when = .yesterday
        detail.baselineText = "20"
        model.setDetail(detail, for: "smoking")
        let drafts = model.drafts(now: now, calendar: .testNY)
        XCTAssertEqual(drafts[0].startedAt, now)
        XCTAssertEqual(drafts[0].tracking, MetricTracking(viceMode: .cutBack, unit: "cigarettes", dailyTarget: 20, baselinePerDay: 20))
        XCTAssertEqual(drafts[1].tracking, MetricTracking(unit: "glasses", dailyTarget: 8))
    }

    func testHabitOnlySkipsVicePages() {
        let model = OnboardingViewModel()
        model.chooseHabitsOnly()
        XCTAssertFalse(model.pages.contains(.why))
        XCTAssertTrue(model.drafts(now: date(2026, 10, 28), calendar: .testNY).isEmpty)
    }
}
