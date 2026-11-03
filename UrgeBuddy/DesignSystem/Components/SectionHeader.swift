import SwiftUI

struct SectionHeader: View {
    var title: String
    var addLabel: String?
    var addID: String?
    var onAdd: (() -> Void)?

    init(_ title: String, addLabel: String? = nil, addID: String? = nil, onAdd: (() -> Void)? = nil) {
        self.title = title
        self.addLabel = addLabel
        self.addID = addID
        self.onAdd = onAdd
    }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.s) {
            Text(title.uppercased())
                .font(TypeScale.section)
                .foregroundStyle(Color.tbTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(title)
            if let onAdd, let addLabel {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .foregroundStyle(Color.tbBrand)
                .accessibilityLabel(addLabel)
                .accessibilityIdentifier(addID ?? "")
            }
        }
    }
}

#Preview("Light") { ComponentPreview { SectionHeader("Quitting") } }
#Preview("Dark") { ComponentPreview { SectionHeader("Quitting") }.preferredColorScheme(.dark) }
#Preview("AX3") { ComponentPreview { SectionHeader("Quitting") }.dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { ComponentPreview { SectionHeader("Quitting") } }
#Preview("Add") {
    ComponentPreview {
        SectionHeader("Quitting", addLabel: "Add something you're quitting", onAdd: {})
    }
}
