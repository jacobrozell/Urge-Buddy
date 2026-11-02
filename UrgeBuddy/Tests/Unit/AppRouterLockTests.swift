import XCTest
@testable import UrgeBuddy

@MainActor
final class AppRouterLockTests: XCTestCase {
    func testPresentQueuesUntilUnlocked() {
        let lock = AppLock.shared
        let router = AppRouter.shared
        let wasEnabled = lock.isEnabled
        let wasLocked = lock.isLocked
        let wasPresented = router.presented
        let wasPending = router.pendingQuickAction
        defer {
            lock.isEnabled = wasEnabled
            lock.isLocked = wasLocked
            router.presented = wasPresented
            router.pendingQuickAction = wasPending
        }

        lock.isEnabled = true
        lock.isLocked = true
        router.presented = nil
        router.pendingQuickAction = nil

        router.present(.checkIn)

        XCTAssertNil(router.presented)
        XCTAssertEqual(router.pendingQuickAction, .checkIn)

        lock.isLocked = false
        router.flushPending()

        XCTAssertEqual(router.presented, .checkIn)
        XCTAssertNil(router.pendingQuickAction)
    }

    func testHoldForLockHidesTheVisibleFlow() {
        let lock = AppLock.shared
        let router = AppRouter.shared
        let wasEnabled = lock.isEnabled
        let wasLocked = lock.isLocked
        let wasPresented = router.presented
        let wasPending = router.pendingQuickAction
        defer {
            lock.isEnabled = wasEnabled
            lock.isLocked = wasLocked
            router.presented = wasPresented
            router.pendingQuickAction = wasPending
        }

        lock.isEnabled = true
        lock.isLocked = true
        router.presented = .urge(nil)
        router.pendingQuickAction = nil

        router.holdForLock()

        XCTAssertNil(router.presented)
        XCTAssertEqual(router.pendingQuickAction, .urge(nil))
    }

    func testUrgeOpenedFromCheckInReturnsToCheckIn() {
        let lock = AppLock.shared
        let router = AppRouter.shared
        let wasEnabled = lock.isEnabled
        let wasLocked = lock.isLocked
        let wasPresented = router.presented
        let wasPending = router.pendingQuickAction
        let wasResume = router.resumeCheckInAfterUrge
        defer {
            lock.isEnabled = wasEnabled
            lock.isLocked = wasLocked
            router.presented = wasPresented
            router.pendingQuickAction = wasPending
            router.resumeCheckInAfterUrge = wasResume
        }

        lock.isEnabled = false
        lock.isLocked = false
        router.presented = .checkIn
        router.resumeCheckInAfterUrge = false

        router.present(.urge(nil))
        XCTAssertEqual(router.presented, .urge(nil))
        XCTAssertTrue(router.resumeCheckInAfterUrge)

        router.finishUrge()
        XCTAssertEqual(router.presented, .checkIn)
        XCTAssertFalse(router.resumeCheckInAfterUrge)
    }
}
