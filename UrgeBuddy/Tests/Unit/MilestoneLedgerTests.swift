import XCTest
@testable import UrgeBuddy

final class MilestoneLedgerTests: XCTestCase {
    private let id = UUID()

    override func tearDown() {
        MilestoneLedger.clearAll()
        super.tearDown()
    }

    func testRecordResetAndClear() {
        XCTAssertEqual(MilestoneLedger.highestCelebrated(for: id), 0)
        MilestoneLedger.record(14, for: id)
        XCTAssertEqual(MilestoneLedger.highestCelebrated(for: id), 14)
        MilestoneLedger.record(7, for: id)
        XCTAssertEqual(MilestoneLedger.highestCelebrated(for: id), 7)
        MilestoneLedger.reset(for: id)
        XCTAssertEqual(MilestoneLedger.highestCelebrated(for: id), 0)
        MilestoneLedger.record(30, for: id)
        MilestoneLedger.clearAll()
        XCTAssertEqual(MilestoneLedger.highestCelebrated(for: id), 0)
    }
}
