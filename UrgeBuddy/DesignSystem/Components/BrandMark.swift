import SwiftUI

/// The app icon drawn in SwiftUI: two overlapping circles on a deep tile. It always uses the
/// theme's dark-appearance accents so the mark looks the same as the home-screen icon in light and dark.
struct BrandMark: View {
    var size: CGFloat = 96

    private var palette: ThemePalette { AppTheme.current.palette }

    var body: some View {
        let radius = size * 0.215
        let offset = size * 0.098
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.markTile.darkColor, palette.calm.darkColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .fill(palette.iconBrand.darkColor)
                .frame(width: radius * 2, height: radius * 2)
                .offset(x: -offset)
            Circle()
                .fill(palette.habit.darkColor)
                .frame(width: radius * 2, height: radius * 2)
                .offset(x: offset)
            // The overlap reads lighter, like two lights crossing.
            Circle()
                .fill(palette.brandSoft.lightColor)
                .frame(width: radius * 2, height: radius * 2)
                .offset(x: offset)
                .mask(
                    Circle()
                        .frame(width: radius * 2, height: radius * 2)
                        .offset(x: -offset)
                )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview("Light") { BrandMark().padding() }
#Preview("Dark") { BrandMark().padding().preferredColorScheme(.dark) }
#Preview("AX3") { BrandMark().padding().dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { BrandMark().padding() }
