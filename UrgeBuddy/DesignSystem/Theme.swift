import SwiftUI
import UIKit

/// The accent family. Brand, habit, and the urge screen all come from one theme so the app reads
/// as one hue. Neutrals (background, surface, text) and Slip stay in the asset catalog for every theme.
/// To offer another theme, add a case and its palette; a picker sets `current` and redraws the root.
enum AppTheme: String, CaseIterable, Identifiable {
    case teal

    var id: String { rawValue }

    static var current: AppTheme = .teal

    var palette: ThemePalette {
        switch self {
        case .teal: .teal
        }
    }
}

struct ThemeColor {
    var light: UInt32
    var dark: UInt32

    /// Same in both appearances.
    init(_ both: UInt32) {
        light = both
        dark = both
    }

    init(light: UInt32, dark: UInt32) {
        self.light = light
        self.dark = dark
    }

    var color: Color {
        Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

struct ThemePalette {
    /// Buttons, banners, confirmed-free days.
    var brand: ThemeColor
    /// Soft fills behind brand text.
    var brandSoft: ThemeColor
    /// Text and icons on `brand`.
    var onBrand: ThemeColor
    /// Habit done. A neighbor of `brand`, so habits read as their own thing without a second hue.
    var habit: ThemeColor
    var habitSoft: ThemeColor
    /// The urge flow background: a deep shade of `brand` with white text in both appearances.
    var calm: ThemeColor

    /// Every text-on-fill pair the app draws from this palette. `WCAGContrastTests` checks each one.
    var contrastPairs: [(foreground: UInt32, background: UInt32)] {
        [
            (onBrand.light, brand.light), (onBrand.dark, brand.dark),
            (brand.light, brandSoft.light), (brand.dark, brandSoft.dark),
            (habit.light, habitSoft.light), (habit.dark, habitSoft.dark),
            (0xFFFFFF, calm.light), (0xFFFFFF, calm.dark),
        ]
    }

    static let teal = ThemePalette(
        brand: ThemeColor(light: 0x0F766E, dark: 0x2DD4BF),
        brandSoft: ThemeColor(light: 0xCCFBF1, dark: 0x134E4A),
        onBrand: ThemeColor(light: 0xFFFFFF, dark: 0x042F2E),
        habit: ThemeColor(light: 0x047857, dark: 0x34D399),
        habitSoft: ThemeColor(light: 0xD1FAE5, dark: 0x064E3B),
        calm: ThemeColor(0x0C3532)
    )
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
