import SwiftUI

struct EmptyState: View {
    var systemImage: String
    var title: String
    var message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(Color.tbBrand)
                .accessibilityHidden(true)
            Text(title)
                .font(.title2)
                .foregroundStyle(Color.tbTextPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .foregroundStyle(Color.tbTextSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, systemImage: nil, action: action)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

#Preview("Light") { ComponentPreview { EmptyState(systemImage: "sun.max", title: "Start with one thing", message: "Add a vice or a habit and today gets simpler.", actionTitle: "Add", action: {}) } }
#Preview("Dark") { ComponentPreview { EmptyState(systemImage: "sun.max", title: "Start with one thing", message: "Add a vice or a habit and today gets simpler.", actionTitle: "Add", action: {}) }.preferredColorScheme(.dark) }
#Preview("AX3") { ComponentPreview { EmptyState(systemImage: "sun.max", title: "Start with one thing", message: "Add a vice or a habit and today gets simpler.", actionTitle: "Add", action: {}) }.dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { ComponentPreview { EmptyState(systemImage: "sun.max", title: "Start with one thing", message: "Add a vice or a habit and today gets simpler.", actionTitle: "Add", action: {}) } }
