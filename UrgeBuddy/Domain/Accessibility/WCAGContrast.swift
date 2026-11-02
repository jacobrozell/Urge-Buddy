import Foundation

enum WCAGContrast {
    static let minimumBodyRatio = 4.5

    static func ratio(foreground: (r: Double, g: Double, b: Double), background: (r: Double, g: Double, b: Double)) -> Double {
        let l1 = relativeLuminance(foreground)
        let l2 = relativeLuminance(background)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func ratio(foregroundHex: UInt32, backgroundHex: UInt32) -> Double {
        ratio(foreground: rgb(foregroundHex), background: rgb(backgroundHex))
    }

    static func rgb(_ hex: UInt32) -> (r: Double, g: Double, b: Double) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        return (red, green, blue)
    }

    private static func relativeLuminance(_ rgb: (r: Double, g: Double, b: Double)) -> Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(rgb.r) + 0.7152 * channel(rgb.g) + 0.0722 * channel(rgb.b)
    }
}
