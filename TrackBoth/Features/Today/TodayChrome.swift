import SwiftUI

struct CheckInBanner: View {
    var remaining: Int
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(Color.tbBrand)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(RecoveryCopy.checkInTitle)
                        .font(.headline)
                        .foregroundStyle(Color.tbTextPrimary)
                    Text(RecoveryCopy.checkInBanner(left: remaining))
                        .font(.subheadline)
                        .foregroundStyle(Color.tbTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.tbTextSecondary)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.l)
            .frame(minHeight: 44)
            .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(RecoveryCopy.checkInTitle), \(RecoveryCopy.checkInBanner(left: remaining))")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(AccessibilityIdentifiers.todayCheckInBanner)
    }
}

struct YesterdayPrompt: View {
    var name: String
    var onYes: () -> Void
    var onSlipped: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .top) {
                Text(RecoveryCopy.yesterdayPrompt(name))
                    .font(.body)
                    .foregroundStyle(Color.tbTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(RecoveryCopy.dismiss)
                .foregroundStyle(Color.tbTextSecondary)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.s) { actions }
                VStack(spacing: Spacing.s) { actions }
            }
        }
        .padding(Spacing.l)
        .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    @ViewBuilder
    private var actions: some View {
        Button(RecoveryCopy.yesterdayYes, action: onYes)
            .buttonStyle(.borderedProminent)
            .tint(Color.tbBrand)
            .frame(minHeight: 44)
        Button(RecoveryCopy.iSlipped, action: onSlipped)
            .buttonStyle(.bordered)
            .frame(minHeight: 44)
    }
}

struct SOSButton: View {
    var isCompact = false
    var action: () -> Void

    var body: some View {
        PrimaryButton(title: RecoveryCopy.sosButton, systemImage: "wind", accessibilityID: AccessibilityIdentifiers.todaySOSButton, action: action)
            .padding(.horizontal, Spacing.l)
            .padding(.top, isCompact ? Spacing.xs : Spacing.s)
            .padding(.bottom, isCompact ? Spacing.xs : Spacing.s)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
            .background(Color.tbBackground)
    }
}
