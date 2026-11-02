import SwiftUI

struct Card<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.l)
            .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

#Preview("Light") { ComponentPreview { Card { Text("A quiet card").foregroundStyle(Color.tbTextPrimary) } } }
#Preview("Dark") { ComponentPreview { Card { Text("A quiet card").foregroundStyle(Color.tbTextPrimary) } }.preferredColorScheme(.dark) }
#Preview("AX3") { ComponentPreview { Card { Text("A quiet card").foregroundStyle(Color.tbTextPrimary) } }.dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { ComponentPreview { Card { Text("A quiet card").foregroundStyle(Color.tbTextPrimary) } } }
