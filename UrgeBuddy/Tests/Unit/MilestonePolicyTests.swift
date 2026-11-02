import XCTest
@testable import UrgeBuddy

final class MilestonePolicyTests: XCTestCase {
    func testReachedIncludesYearlyThresholds() {
        XCTAssertEqual(MilestonePolicy.reached(400, isVice: true), [1, 3, 7, 14, 30, 60, 90, 180, 270, 365])
        XCTAssertEqual(
            MilestonePolicy.reached(1095, isVice: true),
            [1, 3, 7, 14, 30, 60, 90, 180, 270, 365, 730, 1095]
        )
        XCTAssertEqual(MilestonePolicy.reached(800, isVice: false).suffix(2), [365, 730])
    }

    func testNextThreshold() {
        XCTAssertEqual(MilestonePolicy.next(after: 0, isVice: true), 1)
        XCTAssertEqual(MilestonePolicy.next(after: 10, isVice: true), 14)
        XCTAssertEqual(MilestonePolicy.next(after: 400, isVice: true), 730)
        XCTAssertEqual(MilestonePolicy.next(after: 0, isVice: false), 3)
        XCTAssertEqual(MilestonePolicy.next(after: 400, isVice: false), 730)
    }

    func testPendingPicksTheHighestNewThreshold() {
        XCTAssertEqual(MilestonePolicy.pending(value: 40, isVice: true, highestCelebrated: 7), 30)
        XCTAssertNil(MilestonePolicy.pending(value: 12, isVice: true, highestCelebrated: 7))
        XCTAssertEqual(MilestonePolicy.pending(value: 14, isVice: true, highestCelebrated: 7), 14)
    }

    func testPendingIsReEarnableAfterTheRunDrops() {
        XCTAssertEqual(MilestonePolicy.pending(value: 5, isVice: true, highestCelebrated: 30), 3)
        XCTAssertEqual(MilestonePolicy.pending(value: 3, isVice: false, highestCelebrated: 100), 3)
    }

    func testHabitList() {
        XCTAssertEqual(MilestonePolicy.reached(2, isVice: false), [])
        XCTAssertEqual(MilestonePolicy.reached(14, isVice: false), [3, 7, 14])
        XCTAssertNil(MilestonePolicy.pending(value: 2, isVice: false, highestCelebrated: 0))
    }
}
