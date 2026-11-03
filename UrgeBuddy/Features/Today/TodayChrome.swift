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
    var dateLine: String
    var dateAccessibility: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    summary
                    dateText
                }
            } else {
                HStack(alignment: .center, spacing: Spacing.m) {
                    summary
                        .frame(maxWidth: .infinity, alignment: .leading)
                    dateText
                        .multilineTextAlignment(.trailing)
                        .layoutPriority(1)
                }
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(Color.tbBrandSoft, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .accessibilityIdentifier(AccessibilityIdentifiers.todayCheckInStreak)
    }

    private var summary: some View {
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
        }
    }

    private var dateText: some View {
        Text(dateLine)
            .font(.subheadline)
            .foregroundStyle(Color.tbTextSecondary)
    }

    private var spoken: String {
        let status = streak > 0
            ? "\(RecoveryCopy.checkInStreak(streak)). \(RecoveryCopy.checkedInToday)"
            : RecoveryCopy.checkedInToday
        return "\(status) \(dateAccessibility)"
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
        .cardSurface()
    }

    @ViewBuilder
    private var actions: some View {
        ChoiceButton(title: RecoveryCopy.yesterdayYes, action: onYes)
        ChoiceButton(title: RecoveryCopy.iSlipped, action: onSlipped)
    }
}

struct UrgeSurfingRow: View {
    var action: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Button(action: action) {
                HStack(alignment: .top, spacing: Spacing.m) {
                    IconBadge(systemImage: "wind", tint: .tbBrand)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(RecoveryCopy.urgeSurfingTitle)
                            .font(.headline)
                            .foregroundStyle(Color.tbTextPrimary)
                        Text(RecoveryCopy.urgeSurfingRow)
                            .font(.subheadline)
                            .foregroundStyle(Color.tbTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.leading, Spacing.l)
                .padding(.vertical, Spacing.l)
                .padding(.trailing, Spacing.s)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .buttonStyle(.pressable)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(RecoveryCopy.urgeSurfingTitle). \(RecoveryCopy.urgeSurfingRow)")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(AccessibilityIdentifiers.todayUrgeSurfing)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(RecoveryCopy.dismiss)
            .foregroundStyle(Color.tbTextSecondary)
            .padding(.top, Spacing.xs)
            .padding(.trailing, Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

/// The urge button as a compact nav bar item, for a phone in landscape.
struct SOSToolbarButton: View {
    var action: () -> Void

    var body: some View {
        // A Label collapses to its icon in a nav bar. This is the main action, so it keeps its words.
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "wind")
                    .accessibilityHidden(true)
                Text(RecoveryCopy.sosButton)
            }
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.tbBrand)
        .accessibilityLabel(RecoveryCopy.sosButton)
        .accessibilityIdentifier(AccessibilityIdentifiers.todaySOSButton)
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
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.headline)
            .foregroundStyle(Color.tbOnBrand)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background(Color.tbBrand, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(RecoveryCopy.sosButton)
        .accessibilityIdentifier(AccessibilityIdentifiers.todaySOSButton)
    }
}
