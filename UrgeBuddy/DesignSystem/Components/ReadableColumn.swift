import SwiftUI

struct ReadableColumn<Content: View>: View {
    enum Width { case text, wide }

    var width: Width
    @ViewBuilder var content: () -> Content

    init(width: Width = .text, @ViewBuilder content: @escaping () -> Content) {
        self.width = width
        self.content = content
    }

    var body: some View {
        content()
            .frame(maxWidth: width == .text ? AdaptiveLayout.textColumnWidth : AdaptiveLayout.wideColumnWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.l)
    }
}

#Preview("Light") { ComponentPreview { ReadableColumn { Text("Readable column").foregroundStyle(Color.tbTextPrimary) } } }
#Preview("Dark") { ComponentPreview { ReadableColumn { Text("Readable column").foregroundStyle(Color.tbTextPrimary) } }.preferredColorScheme(.dark) }
#Preview("AX3") { ComponentPreview { ReadableColumn { Text("Readable column").foregroundStyle(Color.tbTextPrimary) } }.dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { ComponentPreview { ReadableColumn { Text("A longer line stays inside the readable column.").foregroundStyle(Color.tbTextPrimary) } } }
