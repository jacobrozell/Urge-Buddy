import SwiftUI

/// Neutrals and Slip come from the asset catalog. Accent colors come from `AppTheme`.
extension Color {
    static let tbBackground = Color("Background")
    static let tbSurface = Color("Surface")
    static let tbSurfaceMuted = Color("SurfaceMuted")
    static let tbTextPrimary = Color("TextPrimary")
    static let tbTextSecondary = Color("TextSecondary")
    static var tbBrand: Color { AppTheme.current.palette.brand.color }
    static var tbBrandSoft: Color { AppTheme.current.palette.brandSoft.color }
    static var tbOnBrand: Color { AppTheme.current.palette.onBrand.color }
    static var tbHabit: Color { AppTheme.current.palette.habit.color }
    static var tbHabitSoft: Color { AppTheme.current.palette.habitSoft.color }
    static let tbSlip = Color("Slip")
    static let tbSlipSoft = Color("SlipSoft")
    static var tbCalm: Color { AppTheme.current.palette.calm.color }
    /// White text on `Calm` in both appearances. Calm does not change with the color scheme.
    static let tbOnCalm = Color.white
}
