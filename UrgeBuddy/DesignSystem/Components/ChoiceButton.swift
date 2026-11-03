import SwiftUI

/// One answer in a pair ("Free today" / "I slipped"). Selected = Brand fill with a checkmark.
struct ChoiceButton: View {
    var title: String
    var isSelected: Bool = false
    var accessibilityID: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if isSelected {
                    Image(systemName: "checkmark").accessibilityHidden(true)
                }
                Text(title).multilineTextAlignment(.center)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? Color.tbOnBrand : Color.tbTextPrimary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, Spacing.m)
            .background(
                isSelected ? Color.tbBrand : Color.tbSurfaceMuted,
                in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
            )
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(accessibilityID ?? "")
    }
}

#Preview("Light") { ChoiceButtonPreview() }
#Preview("Dark") { ChoiceButtonPreview().preferredColorScheme(.dark) }
#Preview("AX3") { ChoiceButtonPreview().dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { ChoiceButtonPreview() }

private struct ChoiceButtonPreview: View {
    var body: some View {
        ComponentPreview {
            VStack(spacing: Spacing.m) {
                ChoiceButton(title: "Free today", isSelected: true, action: {})
                ChoiceButton(title: "I slipped", action: {})
            }
        }
    }
}
