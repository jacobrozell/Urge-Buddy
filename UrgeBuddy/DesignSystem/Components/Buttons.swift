import SwiftUI

struct PrimaryButton: View {
    var title: String
    var systemImage: String? = nil
    var accessibilityID: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            buttonLabel
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.tbOnBrand)
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.s)
                .background(Color.tbBrand, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .modifier(AccessibilityIDModifier(id: accessibilityID))
    }

    @ViewBuilder
    private var buttonLabel: some View {
        if let systemImage {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.s) {
                    Image(systemName: systemImage).accessibilityHidden(true)
                    Text(title)
                }
                VStack(spacing: Spacing.xs) {
                    Image(systemName: systemImage).accessibilityHidden(true)
                    Text(title)
                }
            }
        } else {
            Text(title)
        }
    }
}

struct SecondaryButton: View {
    var title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            buttonLabel
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.tbTextPrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.s)
                .background(Color.tbSurfaceMuted, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var buttonLabel: some View {
        if let systemImage {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.s) {
                    Image(systemName: systemImage).accessibilityHidden(true)
                    Text(title)
                }
                VStack(spacing: Spacing.xs) {
                    Image(systemName: systemImage).accessibilityHidden(true)
                    Text(title)
                }
            }
        } else {
            Text(title)
        }
    }
}

#Preview("Light") {
    ComponentPreview {
        VStack(spacing: Spacing.m) {
            PrimaryButton(title: "Check in", systemImage: "checkmark", action: {})
            SecondaryButton(title: "Not now", systemImage: "clock", action: {})
        }
    }
}
#Preview("Dark") {
    ComponentPreview {
        VStack(spacing: Spacing.m) {
            PrimaryButton(title: "Check in", systemImage: "checkmark", action: {})
            SecondaryButton(title: "Not now", systemImage: "clock", action: {})
        }
    }
    .preferredColorScheme(.dark)
}
#Preview("AX3") {
    ComponentPreview {
        VStack(spacing: Spacing.m) {
            PrimaryButton(title: "Check in", systemImage: "checkmark", action: {})
            SecondaryButton(title: "Not now", systemImage: "clock", action: {})
        }
    }
    .dynamicTypeSize(.accessibility3)
}
#Preview("Landscape", traits: .landscapeLeft) {
    ComponentPreview {
        VStack(spacing: Spacing.m) {
            PrimaryButton(title: "Check in", systemImage: "checkmark", action: {})
            SecondaryButton(title: "Not now", systemImage: "clock", action: {})
        }
    }
}

private struct AccessibilityIDModifier: ViewModifier {
    var id: String?

    func body(content: Content) -> some View {
        if let id {
            content.accessibilityIdentifier(id)
        } else {
            content
        }
    }
}
