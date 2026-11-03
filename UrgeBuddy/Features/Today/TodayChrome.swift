import SwiftUI

struct CheckInBanner: View {
    var remaining: Int
    var streak: Int
    var action: () -> Void

    private var subtitle: String {
        remaining > 0 ? RecoveryCopy.checkInBanner(left: remaining) : RecoveryCopy.checkInAbout
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if streak > 0 {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                            Text("\(streak)")
                                .bigNumberStyle()
                            Text(RecoveryCopy.checkInStreakUnit(streak))
                                .font(.title3.weight(.semibold))
                        }
                    } else {
                        Text(RecoveryCopy.checkInTitle)
                            .font(.title2.weight(.semibold))
                    }
                    Text(subtitle)
                        .font(.subheadline)
                        .opacity(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Color.tbOnBrand)
            .padding(Spacing.l)
            .frame(minHeight: 44)
            .background(Color.tbBrand, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(AccessibilityIdentifiers.todayCheckInBanner)
    }

    private var accessibilityText: String {
        if streak > 0 {
            return "\(RecoveryCopy.checkInTitle), \(RecoveryCopy.checkInStreak(streak)), \(subtitle)"
        }
        return "\(RecoveryCopy.checkInTitle), \(subtitle)"
    }
}

struct CheckInStreakCard: View {
    var streak: Int

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.m) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.tbBrand)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if streak > 0 {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                        Text("\(streak)")
                            .bigNumberStyle()
                            .foregroundStyle(Color.tbBrand)
                        Text(RecoveryCopy.checkInStreakUnit(streak))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.tbTextPrimary)
                    }
                }
                Text(RecoveryCopy.checkedInToday)
                    .font(.subheadline)
                    .foregroundStyle(Color.tbTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.l)
        .frame(minHeight: 44)
        .background(Color.tbBrandSoft, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(streak > 0
            ? "\(RecoveryCopy.checkInStreak(streak)). \(RecoveryCopy.checkedInToday)"
            : RecoveryCopy.checkedInToday)
        .accessibilityIdentifier(AccessibilityIdentifiers.todayCheckInStreak)
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
                .buttonStyle(.pressable)
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
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
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
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .buttonStyle(.pressable)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(RecoveryCopy.urgeSurfingTitle). \(RecoveryCopy.urgeSurfingRow)")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(AccessibilityIdentifiers.todayUrgeSurfing)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(RecoveryCopy.dismiss)
            .foregroundStyle(Color.tbTextSecondary)
        }
        .padding(Spacing.l)
        .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

struct AddPlaceholderRow: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(Color.tbBrand)
                    .accessibilityHidden(true)
                Text(RecoveryCopy.addBuilding)
                    .font(.body)
                    .foregroundStyle(Color.tbTextPrimary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(
                        Color.tbTextSecondary.opacity(0.4),
                        style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                    )
            }
        }
        .buttonStyle(.pressable)
        .accessibilityHidden(true)
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
        .buttonStyle(.pressable)
        .accessibilityLabel(RecoveryCopy.sosButton)
        .accessibilityIdentifier(AccessibilityIdentifiers.todaySOSButton)
    }
}
