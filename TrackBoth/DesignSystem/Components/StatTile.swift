import SwiftUI

struct StatTile: View {
    var value: String
    var label: String
    var systemImage: String
    var caption: String? = nil

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundStyle(Color.tbBrand)
                    .accessibilityHidden(true)
                Text(value)
                    .bigNumberStyle()
                    .foregroundStyle(Color.tbTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(Color.tbTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let caption {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(Color.tbTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var spoken: String {
        if let caption { return "\(label), \(value), \(caption)" }
        return "\(label), \(value)"
    }
}

#Preview("Light") { ComponentPreview { StatTile(value: "12", label: "Days free", systemImage: "sun.max") } }
#Preview("Dark") { ComponentPreview { StatTile(value: "12", label: "Days free", systemImage: "sun.max") }.preferredColorScheme(.dark) }
#Preview("AX3") { ComponentPreview { StatTile(value: "12", label: "Days free", systemImage: "sun.max") }.dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { ComponentPreview { StatTile(value: "12", label: "Days free", systemImage: "sun.max") } }
