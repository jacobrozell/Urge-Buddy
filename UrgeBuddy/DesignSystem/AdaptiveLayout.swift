import SwiftUI

enum AdaptiveLayout {
    static let textColumnWidth: CGFloat = 640
    static let wideColumnWidth: CGFloat = 1_040
    static let twoColumnMinWidth: CGFloat = 700
    static let sideColumnWidth: CGFloat = 300
    /// Minimum width for list + detail split when TabView reports compact horizontal on iPad.
    static let splitNavigationMinWidth: CGFloat = 744

    /// iPad, iPhone Duo inner display, and tall resizable windows. Pro Max landscape is
    /// regular width but compact height, so it keeps the phone stack.
    static func usesSplitNavigation(
        horizontal: UserInterfaceSizeClass?,
        vertical: UserInterfaceSizeClass?,
        containerWidth: CGFloat = 0
    ) -> Bool {
        if horizontal == .regular && vertical == .regular { return true }
        if vertical == .regular && containerWidth >= splitNavigationMinWidth { return true }
        return false
    }

    /// iPhone landscape (including Pro Max), Duo outer landscape, short Stage Manager windows.
    static func isShortHeight(vertical: UserInterfaceSizeClass?) -> Bool {
        vertical == .compact
    }

    /// Measured width, not size class: sheets and resizable windows misreport width.
    /// Landscape phones are shorter than 700pt wide once padding is removed. Detail uses this.
    static let shortHeightColumnMinWidth: CGFloat = 520

    static func usesTwoColumns(
        width: CGFloat,
        dynamicType: DynamicTypeSize,
        minimumWidth: CGFloat = twoColumnMinWidth
    ) -> Bool {
        width >= minimumWidth && !dynamicType.isAccessibilitySize
    }

    static func breathingDiameter(vertical: UserInterfaceSizeClass?) -> CGFloat {
        isShortHeight(vertical: vertical) ? 180 : 280
    }
}

extension View {
    /// iPad and Duo inner: centered form sheet. iPhone: ignored.
    func adaptiveFormSheet() -> some View {
        presentationSizing(.form)
    }

    /// iPad and Duo inner: near-full page sheet for content that uses two columns.
    func adaptivePageSheet() -> some View {
        presentationSizing(.page)
    }

    /// Insets List rows to the readable width on wide windows without clipping the scroll area.
    func readableListMargins() -> some View {
        modifier(ReadableListMargins())
    }
}

private struct ReadableListMargins: ViewModifier {
    @State private var width: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .contentMargins(.horizontal, max(0, (width - AdaptiveLayout.textColumnWidth) / 2), for: .scrollContent)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }
}
