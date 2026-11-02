import SwiftUI

struct StoreRecoveryBanner: View {
    var body: some View {
        Text("Your data couldn't be loaded. Changes won't be saved. Export or contact support.")
            .font(.footnote)
            .foregroundStyle(Color.tbTextPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.m)
            .background(Color.tbSlipSoft)
            .accessibilityAddTraits(.isStaticText)
    }
}
