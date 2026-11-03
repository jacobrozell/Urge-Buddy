import SwiftUI

struct Card<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .cardSurface()
    }
}

extension View {
    /// The shared card shape. It always fills the column, so cards stacked together share both edges.
    func cardSurface(_ fill: Color = .tbSurface, vertical: CGFloat = Spacing.l) -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, vertical)
            .background(fill, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

#Preview("Light") { ComponentPreview { Card { Text("A quiet card").foregroundStyle(Color.tbTextPrimary) } } }
#Preview("Dark") { ComponentPreview { Card { Text("A quiet card").foregroundStyle(Color.tbTextPrimary) } }.preferredColorScheme(.dark) }
#Preview("AX3") { ComponentPreview { Card { Text("A quiet card").foregroundStyle(Color.tbTextPrimary) } }.dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { ComponentPreview { Card { Text("A quiet card").foregroundStyle(Color.tbTextPrimary) } } }
