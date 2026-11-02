import XCTest
@testable import UrgeBuddy

@MainActor
final class BootstrapStoreRecoveryTests: XCTestCase {
    override func tearDown() {
        BootstrapStoreRecovery.resetModeForTesting()
        super.tearDown()
    }

    func testOpeningFailureFallsBackToMemory() {
        let container = BootstrapStoreRecovery.makeContainer {
            throw CocoaError(.fileWriteUnknown)
        }
        XCTAssertEqual(BootstrapStoreRecovery.mode, .inMemoryFallback)
        XCTAssertNotNil(container.mainContext)
    }
}
