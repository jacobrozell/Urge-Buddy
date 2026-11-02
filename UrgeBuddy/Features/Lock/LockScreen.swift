import SwiftUI

struct LockScreen: View {
    @Environment(AppLock.self) private var appLock

    var body: some View {
        ScrollView {
            ReadableColumn {
                VStack(spacing: Spacing.xl) {
                    BrandMark(size: 72)
                    Text(RecoveryCopy.lockedTitle)
                        .font(.title2)
                        .foregroundStyle(Color.tbTextPrimary)
                        .multilineTextAlignment(.center)
                    PrimaryButton(title: RecoveryCopy.unlock, action: {
                        Task { await appLock.unlock() }
                    })
                }
                .padding(Spacing.xl)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(.center, for: .alignment)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tbBackground.ignoresSafeArea())
        .task { await appLock.unlock() }
    }
}

struct PrivacyCover: View {
    var body: some View {
        VStack {
            BrandMark(size: 72)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tbBackground.ignoresSafeArea())
        .accessibilityHidden(true)
    }
}
