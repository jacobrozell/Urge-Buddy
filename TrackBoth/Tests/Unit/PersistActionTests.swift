import XCTest
@testable import TrackBoth

@MainActor
final class PersistActionTests: XCTestCase {
    func testFailureReturnsNilAndReports() {
        var reported = false
        let persist = PersistAction { _ in reported = true }
        let result: Int? = persist("test") { throw RecoveryStoreError.saveFailed }
        XCTAssertNil(result)
        XCTAssertTrue(reported)
    }

    func testSuccessReturnsValueAndStaysQuiet() {
        var reported = false
        let persist = PersistAction { _ in reported = true }
        XCTAssertEqual(persist("test") { 5 }, 5)
        XCTAssertFalse(reported)
    }
}
