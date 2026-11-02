import SwiftUI

extension DynamicTypeSize {
    /// True when the user has enabled an accessibility text size (AX1–AX5).
    var usesAccessibilityLayout: Bool {
        isAccessibilitySize
    }

    /// Larger text sizes that need relaxed layouts (accessibility sizes and XLarge+).
    var usesExpandedChrome: Bool {
        isAccessibilitySize || self >= .xLarge
    }

    /// Stacked rows when text is XXXL or an accessibility size.
    var usesRelaxedListLayout: Bool {
        isAccessibilitySize || self >= .xxxLarge
    }
}

extension EnvironmentValues {
    var usesAccessibilityLayout: Bool {
        dynamicTypeSize.usesAccessibilityLayout
    }

    var usesExpandedChrome: Bool {
        dynamicTypeSize.usesExpandedChrome
    }

    var usesRelaxedListLayout: Bool {
        dynamicTypeSize.usesRelaxedListLayout
    }
}
