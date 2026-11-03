import SwiftUI
import UIKit

/// iOS 26+ draws navigation and tab bars in Liquid Glass. An opaque toolbar fill
/// leaves a white strip on iPhone Duo, where the status bar sits on the trailing edge.
enum SystemNavigationPolicy {
    static var usesSystemLiquidGlassNav: Bool {
        if #available(iOS 26, *) { return true }
        return false
    }
}

extension View {
    /// Brand fill behind Liquid Glass bars. No-op on iOS 18–25, which already use the system material.
    @ViewBuilder
    func tbNavigationBarBackground() -> some View {
        if SystemNavigationPolicy.usesSystemLiquidGlassNav {
            containerBackground(Color.tbBackground, for: .navigation)
        } else {
            self
        }
    }

    /// Paints the app's windows with the Background asset so Duo's uncovered edges are not white.
    func tbWindowChrome() -> some View {
        background(TrackBothWindowBackground())
    }
}

enum PresentationSequence {
    /// Drops the keyboard, then runs `action` once it has had time to leave.
    /// A sheet that starts while the keyboard scene is still up is what blanks Duo.
    @MainActor
    static func resignKeyboardThen(_ action: @escaping @MainActor () -> Void) {
        let wasTyping = UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
        )
        Task { @MainActor in
            if wasTyping {
                try? await Task.sleep(for: .milliseconds(350))
            }
            action()
        }
    }

    /// Runs after a sheet, cover, or dialog has finished dismissing.
    @MainActor
    static func afterDismiss(_ action: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            action()
        }
    }
}

private struct TrackBothWindowBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> TrackBothWindowBackgroundView {
        TrackBothWindowBackgroundView()
    }

    func updateUIView(_ uiView: TrackBothWindowBackgroundView, context: Context) {
        uiView.applyBackground()
    }
}

private final class TrackBothWindowBackgroundView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyBackground()
    }

    private var alphaRestore: DispatchWorkItem?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyBackground()
        // UIKit drops the hosting view to alpha 0 for a presentation and, on Duo,
        // sometimes never brings it back. Wait until that presentation is gone
        // before restoring, or the restore fights the animation.
        alphaRestore?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.restoreHostAlpha() }
        alphaRestore = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    func applyBackground() {
        backgroundColor = .clear
        let color = UIColor(named: "Background") ?? .systemBackground
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for sceneWindow in windowScene.windows where Self.isAppWindow(sceneWindow) {
                sceneWindow.backgroundColor = color
            }
        }
    }

    private func restoreHostAlpha() {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for sceneWindow in windowScene.windows where Self.isAppWindow(sceneWindow) {
                guard let root = sceneWindow.rootViewController else { continue }
                guard root.presentedViewController == nil else { continue }
                guard !root.isBeingPresented, !root.isBeingDismissed else { continue }
                guard root.view.alpha < 1 else { continue }
                root.view.alpha = 1
            }
        }
    }

    /// Keyboard and input hosts are their own windows. Painting them, or a
    /// collapsed Duo display, is what blanks the visible screen.
    private static func isAppWindow(_ window: UIWindow) -> Bool {
        guard window.windowLevel == .normal else { return false }
        guard window.bounds.width > 20, window.bounds.height > 20 else { return false }
        let name = NSStringFromClass(type(of: window))
        if name.contains("TextEffects") || name.contains("Keyboard") || name.contains("Remote") {
            return false
        }
        if let rootName = window.rootViewController.map({ NSStringFromClass(type(of: $0)) }) {
            if rootName.contains("Input") || rootName.contains("Keyboard") || rootName.contains("Text") {
                return false
            }
        }
        return true
    }
}

/// Keeps a floating control on the opposite side of a vertical Duo tab bar.
/// On iPhone the control stays centered above the bottom tab bar.
struct VerticalBarFloatingBar<Button: View>: View {
    var bottomPadding: CGFloat = Spacing.s
    @ViewBuilder var button: () -> Button

    var body: some View {
        if #available(iOS 27.1, *) {
            VerticalBarFloatingBarOn27(bottomPadding: bottomPadding, button: button)
        } else {
            VerticalBarFloatingBarLayout(avoidTrailing: false, bottomPadding: bottomPadding, button: button)
        }
    }
}

@available(iOS 27.1, *)
private struct VerticalBarFloatingBarOn27<Button: View>: View {
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    var bottomPadding: CGFloat
    @ViewBuilder var button: () -> Button

    var body: some View {
        VerticalBarFloatingBarLayout(
            avoidTrailing: toolbarVerticalEdge == .trailing,
            bottomPadding: bottomPadding,
            button: button
        )
    }
}

private struct VerticalBarFloatingBarLayout<Button: View>: View {
    var avoidTrailing: Bool
    var bottomPadding: CGFloat
    @ViewBuilder var button: () -> Button

    /// Spans the wide readable column, so the button lines up with the cards above it.
    var body: some View {
        ReadableColumn(width: .wide) {
            button()
                .frame(maxWidth: .infinity)
        }
        .padding(.trailing, avoidTrailing ? VerticalTabBarClearance.width : 0)
        .padding(.bottom, bottomPadding)
    }
}

extension View {
    /// Keeps content out from under a vertical Duo tab bar, which is not in the safe area.
    func verticalTabBarClearance() -> some View {
        modifier(VerticalTabBarClearance())
    }
}

private struct VerticalTabBarClearance: ViewModifier {
    static let width: CGFloat = 64

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.modifier(VerticalTabBarClearanceOn27())
        } else {
            content
        }
    }
}

@available(iOS 27.1, *)
private struct VerticalTabBarClearanceOn27: ViewModifier {
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge

    func body(content: Content) -> some View {
        content.padding(.trailing, toolbarVerticalEdge == .trailing ? VerticalTabBarClearance.width : 0)
    }
}
