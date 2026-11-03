import StoreKit
import SwiftUI

struct CelebrationView: View {
    var request: CelebrationRequest
    var onDone: () -> Void

    @Environment(\.requestReview) private var requestReview
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 120
    @State private var shown = false

    private var isShortHeight: Bool {
        AdaptiveLayout.isShortHeight(vertical: verticalSizeClass)
    }

    var body: some View {
        ScrollView {
            ReadableColumn {
                Group {
                    if isShortHeight {
                        HStack(alignment: .center, spacing: Spacing.xl) {
                            heroBadge
                            messageStack
                        }
                    } else {
                        VStack(spacing: Spacing.l) {
                            heroBadge
                            messageStack
                        }
                    }
                }
                .padding(.vertical, Spacing.xl)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(.center, for: .alignment)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tbBackground.ignoresSafeArea())
        .urgeBuddyCelebration(isPresented: shown, reduceMotion: reduceMotion)
        .onAppear { shown = true }
        .adaptiveFormSheet()
    }

    private var heroBadge: some View {
        ZStack {
            Circle().fill(request.isVice ? Color.tbBrandSoft : Color.tbHabitSoft)
            VStack(spacing: 0) {
                Text("\(request.threshold)")
                    .font(.system(size: heroSize * 0.42, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(RecoveryCopy.daysUnit(request.threshold))
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(request.isVice ? Color.tbBrand : Color.tbHabit)
        }
        .frame(width: heroSize, height: heroSize)
        .accessibilityHidden(true)
    }

    private var messageStack: some View {
        VStack(spacing: Spacing.l) {
            Text(request.isVice ? RecoveryCopy.milestoneVice(request.threshold, name: request.name) : RecoveryCopy.milestoneHabit(request.threshold, name: request.name))
                .font(.title2)
                .multilineTextAlignment(isShortHeight ? .leading : .center)
                .foregroundStyle(Color.tbTextPrimary)
            if let reason = request.reason {
                Text("\(RecoveryCopy.rememberWhy) \(reason)")
                    .font(.body)
                    .multilineTextAlignment(isShortHeight ? .leading : .center)
                    .foregroundStyle(Color.tbTextSecondary)
            }
            PrimaryButton(title: RecoveryCopy.keepGoing, systemImage: nil, accessibilityID: AccessibilityIdentifiers.celebrationContinue) {
                MilestoneLedger.record(request.threshold, for: request.metricID)
                if request.isVice, request.threshold == 7, !Preferences.hasRequestedReview {
                    Preferences.hasRequestedReview = true
                    requestReview()
                }
                onDone()
            }
        }
        .frame(maxWidth: .infinity, alignment: isShortHeight ? .leading : .center)
    }
}
