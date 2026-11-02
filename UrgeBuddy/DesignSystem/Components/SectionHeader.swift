import SwiftUI

struct SectionHeader: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(TypeScale.section)
            .foregroundStyle(Color.tbTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(title)
    }
}

#Preview("Light") { ComponentPreview { SectionHeader("Quitting") } }
#Preview("Dark") { ComponentPreview { SectionHeader("Quitting") }.preferredColorScheme(.dark) }
#Preview("AX3") { ComponentPreview { SectionHeader("Quitting") }.dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { ComponentPreview { SectionHeader("Quitting") } }
