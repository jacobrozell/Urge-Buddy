import SwiftUI

struct AdaptiveColumns<Leading: View, Trailing: View>: View {
    var spacing: CGFloat = Spacing.l
    var minimumWidth: CGFloat = AdaptiveLayout.twoColumnMinWidth
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var width: CGFloat = 0

    var body: some View {
        Group {
            if AdaptiveLayout.usesTwoColumns(width: width, dynamicType: dynamicTypeSize, minimumWidth: minimumWidth) {
                HStack(alignment: .top, spacing: spacing) {
                    VStack(alignment: .leading, spacing: spacing) { leading() }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    VStack(alignment: .leading, spacing: spacing) { trailing() }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            } else {
                VStack(alignment: .leading, spacing: spacing) {
                    leading()
                    trailing()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }
}

#Preview("Light") {
    ComponentPreview {
        AdaptiveColumns {
            Text("Quitting").foregroundStyle(Color.tbTextPrimary)
        } trailing: {
            Text("Building").foregroundStyle(Color.tbTextPrimary)
        }
    }
}

#Preview("Dark") {
    ComponentPreview {
        AdaptiveColumns {
            Text("Quitting").foregroundStyle(Color.tbTextPrimary)
        } trailing: {
            Text("Building").foregroundStyle(Color.tbTextPrimary)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("AX3") {
    ComponentPreview {
        AdaptiveColumns {
            Text("Quitting").foregroundStyle(Color.tbTextPrimary)
        } trailing: {
            Text("Building").foregroundStyle(Color.tbTextPrimary)
        }
    }
    .dynamicTypeSize(.accessibility3)
}

#Preview("Landscape", traits: .landscapeLeft) {
    ComponentPreview {
        AdaptiveColumns {
            Text("Quitting column").foregroundStyle(Color.tbTextPrimary)
        } trailing: {
            Text("Building column").foregroundStyle(Color.tbTextPrimary)
        }
    }
}
