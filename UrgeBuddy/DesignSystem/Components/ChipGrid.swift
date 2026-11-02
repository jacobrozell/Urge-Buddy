import SwiftUI

struct ChipOption: Identifiable, Hashable {
    var id: String
    var title: String
    var systemImage: String?
}

struct ChipGrid: View {
    var items: [ChipOption]
    @Binding var selection: Set<String>

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: Spacing.s)], alignment: .leading, spacing: Spacing.s) {
            ForEach(items) { item in
                let isSelected = selection.contains(item.id)
                Button {
                    if isSelected {
                        selection.remove(item.id)
                    } else {
                        selection.insert(item.id)
                    }
                } label: {
                    chipLabel(item, isSelected: isSelected)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private func chipLabel(_ item: ChipOption, isSelected: Bool) -> some View {
        HStack(spacing: Spacing.xs) {
            if let systemImage = item.systemImage {
                Image(systemName: systemImage).accessibilityHidden(true)
            }
            Text(item.title)
                .multilineTextAlignment(.center)
        }
        .font(.subheadline)
        .foregroundStyle(isSelected ? Color.tbOnBrand : Color.tbTextPrimary)
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(isSelected ? Color.tbBrand : Color.tbSurfaceMuted, in: Capsule())
    }
}

#Preview("Light") { ChipGridPreview() }
#Preview("Dark") { ChipGridPreview().preferredColorScheme(.dark) }
#Preview("AX3") { ChipGridPreview().dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { ChipGridPreview() }

private struct ChipGridPreview: View {
    @State private var selection: Set<String> = ["tired"]

    var body: some View {
        ComponentPreview {
            ChipGrid(
                items: [
                    ChipOption(id: "tired", title: "Tired", systemImage: "moon"),
                    ChipOption(id: "stress", title: "Stress", systemImage: "bolt"),
                    ChipOption(id: "people", title: "People", systemImage: "person.2")
                ],
                selection: $selection
            )
        }
    }
}
