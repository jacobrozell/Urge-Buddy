import SwiftUI

struct BrandMark: View {
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.tbBrand, Color.tbHabit],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(Color.tbOnBrand)
        }
        .accessibilityHidden(true)
    }
}

#Preview("Light") { BrandMark().padding() }
#Preview("Dark") { BrandMark().padding().preferredColorScheme(.dark) }
#Preview("AX3") { BrandMark().padding().dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { BrandMark().padding() }
