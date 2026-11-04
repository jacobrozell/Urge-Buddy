import SwiftUI

/// − value + with 44pt targets. VoiceOver swipes up and down to adjust.
struct AmountStepper: View {
    var value: Int
    var unit: String
    var step: Int = 1
    var label: String
    var onChange: (Int) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        control
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(RecoveryCopy.amountUnit(value, unit: unit))
            .accessibilityAddTraits(.isButton)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: onChange(value + step)
                case .decrement: onChange(max(0, value - step))
                @unknown default: break
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: value)
    }

    @ViewBuilder
    private var control: some View {
        if dynamicTypeSize.isAccessibilitySize {
            stacked
        } else {
            clustered
        }
    }

    private var clustered: some View {
        HStack(spacing: Spacing.m) {
            stepButton("minus", title: RecoveryCopy.removeOne, enabled: value > 0) {
                onChange(max(0, value - step))
            }
            valueLabel
            stepButton("plus", title: RecoveryCopy.logOne, enabled: true) {
                onChange(value + step)
            }
        }
    }

    /// Large type: the count sits above the buttons so the words are not crushed between them.
    private var stacked: some View {
        VStack(spacing: Spacing.xs) {
            valueLabel
            HStack(spacing: Spacing.m) {
                stepButton("minus", title: RecoveryCopy.removeOne, enabled: value > 0) {
                    onChange(max(0, value - step))
                }
                stepButton("plus", title: RecoveryCopy.logOne, enabled: true) {
                    onChange(value + step)
                }
            }
        }
    }

    private var valueLabel: some View {
        Text(RecoveryCopy.amountUnit(value, unit: unit))
            .font(.body.weight(.semibold).monospacedDigit())
            .foregroundStyle(Color.tbTextPrimary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func stepButton(_ systemImage: String, title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(enabled ? Color.tbOnBrand : Color.tbTextSecondary)
                .frame(minWidth: 44, minHeight: 44)
                .background(enabled ? Color.tbBrand : Color.tbSurfaceMuted, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(title)
    }
}

/// Five moods. Tapping the selected one clears it.
struct MoodPicker: View {
    var selection: Mood?
    var onSelect: (Mood?) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: Spacing.s)], spacing: Spacing.s) {
            ForEach(Mood.allCases) { mood in
                let isSelected = selection == mood
                Button {
                    onSelect(isSelected ? nil : mood)
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: mood.systemImage)
                            .font(.title3)
                            .accessibilityHidden(true)
                        Text(mood.title)
                            .font(.caption)
                    }
                    .foregroundStyle(isSelected ? Color.tbOnBrand : Color.tbTextPrimary)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(isSelected ? Color.tbBrand : Color.tbSurfaceMuted, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mood.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview("Light") { AmountPreview() }
#Preview("Dark") { AmountPreview().preferredColorScheme(.dark) }
#Preview("AX3") { AmountPreview().dynamicTypeSize(.accessibility3) }

private struct AmountPreview: View {
    @State private var value = 3
    @State private var mood: Mood? = .okay

    var body: some View {
        ComponentPreview {
            VStack(spacing: Spacing.l) {
                AmountStepper(value: value, unit: "cigarettes", label: "Smoking") { value = $0 }
                MoodPicker(selection: mood) { mood = $0 }
            }
        }
    }
}
