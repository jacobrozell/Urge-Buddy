import SwiftUI

struct ViceCard: View {
    var model: ViceCardModel
    var calendar: Calendar
    var onOpen: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(spacing: Spacing.m) {
                        IconBadge(systemImage: model.iconName, tint: .tbBrand)
                        Text(model.name)
                            .font(.headline)
                            .foregroundStyle(Color.tbTextPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: Spacing.s)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.tbTextSecondary)
                            .accessibilityHidden(true)
                    }
                    Text(RecoveryCopy.daysFree(model.daysFree))
                        .bigNumberStyle()
                        .foregroundStyle(Color.tbTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(model.clockLine(at: context.date, calendar: calendar))
                        .font(.subheadline)
                        .foregroundStyle(Color.tbTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    DayDots(states: model.week, labels: model.weekLabels)
                    if let nextMilestone = model.nextMilestone {
                        Text(nextMilestone)
                            .font(.footnote)
                            .foregroundStyle(Color.tbTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.m)
                .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            }
            .buttonStyle(.pressable)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spoken(at: context.date))
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(AccessibilityIdentifiers.viceCard(model.id))
        }
    }

    /// Clock is part of the label so VoiceOver reads it on focus, not as a live region.
    private func spoken(at date: Date) -> String {
        var parts = [model.name, RecoveryCopy.daysFree(model.daysFree), model.clockLine(at: date, calendar: calendar)]
        if let nextMilestone = model.nextMilestone { parts.append(nextMilestone) }
        return parts.joined(separator: ", ")
    }
}
