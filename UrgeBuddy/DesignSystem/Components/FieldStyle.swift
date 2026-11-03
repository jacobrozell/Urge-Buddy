import SwiftUI

/// Filled field on Surface, matching cards and controls.
struct TBFieldStyle: TextFieldStyle {
    var fill: Color = .tbSurface

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
            .frame(minHeight: 44)
            .background(fill, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
    }
}

extension TextFieldStyle where Self == TBFieldStyle {
    static var tbField: TBFieldStyle { TBFieldStyle() }
}

#Preview("Light") { FieldStylePreview() }
#Preview("Dark") { FieldStylePreview().preferredColorScheme(.dark) }
#Preview("AX3") { FieldStylePreview().dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { FieldStylePreview() }

private struct FieldStylePreview: View {
    @State private var text = "A note"

    var body: some View {
        ComponentPreview {
            VStack(spacing: Spacing.m) {
                TextField("Anything on your mind?", text: $text, axis: .vertical)
                    .textFieldStyle(.tbField)
                TextField("Inside a card", text: $text)
                    .textFieldStyle(TBFieldStyle(fill: .tbSurfaceMuted))
                    .padding(Spacing.l)
                    .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            }
        }
    }
}
