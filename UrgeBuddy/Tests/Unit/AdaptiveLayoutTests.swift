import XCTest
@testable import UrgeBuddy

final class AdaptiveLayoutTests: XCTestCase {
    func testUsesSplitNavigationOnlyWhenBothRegular() {
        XCTAssertTrue(AdaptiveLayout.usesSplitNavigation(horizontal: .regular, vertical: .regular))
        XCTAssertFalse(AdaptiveLayout.usesSplitNavigation(horizontal: .regular, vertical: .compact))
        XCTAssertFalse(AdaptiveLayout.usesSplitNavigation(horizontal: .compact, vertical: .regular))
        XCTAssertFalse(AdaptiveLayout.usesSplitNavigation(horizontal: .compact, vertical: .compact))
        XCTAssertFalse(AdaptiveLayout.usesSplitNavigation(horizontal: nil, vertical: .regular))
        XCTAssertFalse(AdaptiveLayout.usesSplitNavigation(horizontal: .regular, vertical: nil))
    }

    func testUsesSplitNavigationOnWideContainerWhenVerticalRegular() {
        XCTAssertTrue(
            AdaptiveLayout.usesSplitNavigation(
                horizontal: .compact,
                vertical: .regular,
                containerWidth: AdaptiveLayout.splitNavigationMinWidth
            )
        )
        XCTAssertFalse(
            AdaptiveLayout.usesSplitNavigation(
                horizontal: .compact,
                vertical: .regular,
                containerWidth: 700
            )
        )
    }

    func testIsShortHeightOnCompactVertical() {
        XCTAssertTrue(AdaptiveLayout.isShortHeight(vertical: .compact))
        XCTAssertTrue(AdaptiveLayout.isShortHeight(vertical: .compact))
        XCTAssertFalse(AdaptiveLayout.isShortHeight(vertical: .regular))
        XCTAssertFalse(AdaptiveLayout.isShortHeight(vertical: nil))
    }

    func testUsesTwoColumnsByWidthAndDynamicType() {
        XCTAssertFalse(AdaptiveLayout.usesTwoColumns(width: 699, dynamicType: .large))
        XCTAssertTrue(AdaptiveLayout.usesTwoColumns(width: 700, dynamicType: .large))
        XCTAssertFalse(AdaptiveLayout.usesTwoColumns(width: 1_200, dynamicType: .accessibility1))
        XCTAssertTrue(AdaptiveLayout.usesTwoColumns(width: 520, dynamicType: .large, minimumWidth: AdaptiveLayout.shortHeightColumnMinWidth))
        XCTAssertFalse(AdaptiveLayout.usesTwoColumns(width: 519, dynamicType: .large, minimumWidth: AdaptiveLayout.shortHeightColumnMinWidth))
    }

    func testBreathingDiameter() {
        XCTAssertEqual(AdaptiveLayout.breathingDiameter(vertical: .compact), 180)
        XCTAssertEqual(AdaptiveLayout.breathingDiameter(vertical: .regular), 280)
        XCTAssertEqual(AdaptiveLayout.breathingDiameter(vertical: nil), 280)
    }
}
