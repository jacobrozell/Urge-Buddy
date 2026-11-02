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
                }
                .padding(.vertical, Spacing.l)
            }
        }
        .background(Color.tbBackground)
        .navigationTitle(RecoveryCopy.urgeSurfingTitle)
        .navigationBarTitleDisplayMode(.inline)
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
