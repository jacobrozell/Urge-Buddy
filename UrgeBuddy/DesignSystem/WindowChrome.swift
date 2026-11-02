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

    /// Paints every window with the Background asset so Duo's uncovered edges are not white.
    func tbWindowChrome() -> some View {
        background(TrackBothWindowBackground())
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyBackground()
    }

    func applyBackground() {
        backgroundColor = .clear
        let color = UIColor(named: "Background") ?? .systemBackground
        window?.backgroundColor = color
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for sceneWindow in windowScene.windows {
                sceneWindow.backgroundColor = color
                sceneWindow.rootViewController?.view.backgroundColor = color
            }
        }
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

    var body: some View {
        HStack(spacing: 0) {
            if avoidTrailing {
                button()
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                button()
                Spacer(minLength: 0)
            }
        }
        .padding(.leading, avoidTrailing ? Spacing.l : 0)
        .padding(.bottom, bottomPadding)
    }
}
