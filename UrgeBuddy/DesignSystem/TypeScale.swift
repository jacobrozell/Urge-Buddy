import SwiftUI

enum TypeScale {
    static let bigNumber = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let section = Font.footnote.weight(.semibold)
}

extension View {
    func bigNumberStyle() -> some View {
        font(TypeScale.bigNumber).monospacedDigit()
    }
}
