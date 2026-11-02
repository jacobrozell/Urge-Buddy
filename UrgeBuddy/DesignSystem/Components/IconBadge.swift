import SwiftUI

struct IconBadge: View {
    var systemImage: String
    var tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 36, height: 36)
            .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview("Light") { ComponentPreview { IconBadge(systemImage: "wineglass", tint: .tbBrand) } }
#Preview("Dark") { ComponentPreview { IconBadge(systemImage: "wineglass", tint: .tbBrand) }.preferredColorScheme(.dark) }
#Preview("AX3") { ComponentPreview { IconBadge(systemImage: "wineglass", tint: .tbBrand) }.dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { ComponentPreview { IconBadge(systemImage: "wineglass", tint: .tbBrand) } }
