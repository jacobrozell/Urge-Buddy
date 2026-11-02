import XCTest
@testable import UrgeBuddy

final class WCAGContrastTests: XCTestCase {
    func testPalettePairsMeetBodyContrast() {
        let pairs: [(UInt32, UInt32)] = [
            (0x111827, 0xF6F7F5),
            (0xF3F4F6, 0x0B0F10),
            (0x111827, 0xFFFFFF),
            (0xF3F4F6, 0x161B1D),
            (0x4B5563, 0xF6F7F5),
            (0xA3AAB5, 0x0B0F10),
            (0x4B5563, 0xFFFFFF),
            (0xA3AAB5, 0x161B1D),
            (0xFFFFFF, 0x0F766E),
            (0x042F2E, 0x2DD4BF),
            (0xB45309, 0xFFFFFF),
            (0xFBBF24, 0x161B1D),
            (0xFFFFFF, 0x1E3A5F)
        ]
        for (foreground, background) in pairs {
            let ratio = WCAGContrast.ratio(foregroundHex: foreground, backgroundHex: background)
            XCTAssertGreaterThanOrEqual(ratio, WCAGContrast.minimumBodyRatio, String(format: "%06X on %06X", foreground, background))
        }
    }
}
