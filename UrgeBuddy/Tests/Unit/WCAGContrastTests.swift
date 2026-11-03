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
            (0xB45309, 0xFFFFFF),
            (0xFBBF24, 0x161B1D)
        ]
        for (foreground, background) in pairs {
            let ratio = WCAGContrast.ratio(foregroundHex: foreground, backgroundHex: background)
            XCTAssertGreaterThanOrEqual(ratio, WCAGContrast.minimumBodyRatio, String(format: "%06X on %06X", foreground, background))
        }
    }

    func testEveryThemeMeetsBodyContrast() {
        for theme in AppTheme.allCases {
            for (foreground, background) in theme.palette.contrastPairs {
                let ratio = WCAGContrast.ratio(foregroundHex: foreground, backgroundHex: background)
                XCTAssertGreaterThanOrEqual(ratio, WCAGContrast.minimumBodyRatio, String(format: "\(theme): %06X on %06X", foreground, background))
            }
        }
    }
}
