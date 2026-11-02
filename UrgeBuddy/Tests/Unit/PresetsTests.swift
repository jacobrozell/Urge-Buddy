import UIKit
import XCTest
@testable import UrgeBuddy

final class PresetsTests: XCTestCase {
    func testPresetCatalog() {
        XCTAssertEqual(Presets.vices.count, 11)
        XCTAssertEqual(Presets.habits.count, 10)
        XCTAssertEqual(Presets.extraIconNames.count, 12)
        let ids = (Presets.vices + Presets.habits).map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertEqual(Presets.vices.first { $0.id == "alcohol" }?.iconName, "wineglass")
        XCTAssertEqual(Presets.iconName(matching: " alcohol "), "wineglass")
        XCTAssertEqual(Presets.iconName(matching: "Night scrolling"), Presets.fallbackIcon)
        XCTAssertEqual(Presets.customVerb, "do it")
    }

    func testSymbolsExistOnThisOS() {
        let missing = Presets.symbolNames.filter { UIImage(systemName: $0) == nil }
        XCTAssertEqual(missing, [], "Missing SF Symbols: \(missing.joined(separator: ", "))")
    }
}
