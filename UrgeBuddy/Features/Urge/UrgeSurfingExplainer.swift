import SwiftUI

struct UrgeSurfingLesson: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            block(RecoveryCopy.urgeSurfingWhatTitle, RecoveryCopy.urgeSurfingWhat)
            block(RecoveryCopy.urgeSurfingHowTitle, RecoveryCopy.urgeSurfingHow)
            block(RecoveryCopy.urgeSurfingHereTitle, RecoveryCopy.urgeSurfingHere)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func block(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.tbTextPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(body)
                .font(.body)
                .foregroundStyle(Color.tbTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UrgeSurfingExplainer: View {
    var body: some View {
        ScrollView {
            ReadableColumn {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    Text(RecoveryCopy.urgeSurfingTitle)
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.tbTextPrimary)
                    UrgeSurfingLesson()
                    learnMore
                }
                .padding(.vertical, Spacing.l)
            }
        }
        .background(Color.tbBackground.ignoresSafeArea())
        .tbNavigationBarBackground()
        .navigationTitle(RecoveryCopy.urgeSurfingTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var learnMore: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(RecoveryCopy.urgeSurfingLearnTitle)
                .font(.headline)
                .foregroundStyle(Color.tbTextPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(RecoveryCopy.urgeSurfingLearn)
                .font(.body)
                .foregroundStyle(Color.tbTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Link(RecoveryCopy.urgeSurfingLearnHow, destination: AppLinks.urgeSurfingPractice)
                .frame(minHeight: 44)
            Link(RecoveryCopy.urgeSurfingLearnOrigin, destination: AppLinks.urgeSurfingOrigin)
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UrgeSurfingSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            UrgeSurfingExplainer()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(RecoveryCopy.close) { dismiss() }
                    }
                }
        }
    }
}

#Preview("Light") { UrgeSurfingExplainer() }
#Preview("Dark") { UrgeSurfingExplainer().preferredColorScheme(.dark) }
