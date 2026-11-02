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

struct UrgeSurfingRow: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                Image(systemName: "wind")
                    .font(.title2)
                    .foregroundStyle(Color.tbBrand)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(RecoveryCopy.urgeSurfingTitle)
                        .font(.headline)
                        .foregroundStyle(Color.tbTextPrimary)
                    Text(RecoveryCopy.urgeSurfingRow)
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
        .accessibilityLabel("\(RecoveryCopy.urgeSurfingTitle). \(RecoveryCopy.urgeSurfingRow)")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(AccessibilityIdentifiers.todayUrgeSurfing)
    }
}

struct SOSButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s) {
                Image(systemName: "wind")
                    .accessibilityHidden(true)
                Text(RecoveryCopy.sosButton)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.tbOnBrand)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: 44)
            .frame(maxWidth: 320)
            .background(Color.tbBrand, in: Capsule())
            .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(RecoveryCopy.sosButton)
        .accessibilityIdentifier(AccessibilityIdentifiers.todaySOSButton)
    }
}
