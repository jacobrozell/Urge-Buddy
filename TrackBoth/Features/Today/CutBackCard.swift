import SwiftUI

struct CutBackCard: View {
    var model: CutBackCardModel
    var onChange: (Int) -> Void
    var onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(spacing: Spacing.m) {
                        IconBadge(systemImage: model.iconName, tint: .tbBrand)
                        Text(model.name)
                            .font(.headline)
                            .foregroundStyle(Color.tbTextPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(RecoveryCopy.todayAmount(model.amount, limit: model.limit, unit: model.unit))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.tbTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    LimitBar(amount: model.amount, limit: model.limit)
                    if model.isOver {
                        Text(RecoveryCopy.overLimitToday)
                            .font(.subheadline)
                            .foregroundStyle(Color.tbTextPrimary)
                    }
                    if let trendLine = model.trendLine {
                        Text(trendLine)
                            .font(.subheadline)
                            .foregroundStyle(Color.tbTextSecondary)
                    }
                    DayDots(states: model.week, labels: model.weekLabels)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.accessibilityLabel)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(AccessibilityIdentifiers.cutBackCard(model.id))

            AmountStepper(value: model.amount, unit: model.unit, label: model.name, onChange: onChange)
                .accessibilityIdentifier(AccessibilityIdentifiers.cutBackStepper(model.id))
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

/// Fill toward the limit. Amber once over it.
struct LimitBar: View {
    var amount: Int
    var limit: Int

    private var fraction: CGFloat {
        guard limit > 0 else { return amount > 0 ? 1 : 0 }
        return min(1, CGFloat(amount) / CGFloat(limit))
    }

    var body: some View {
        Capsule()
            .fill(Color.tbSurfaceMuted)
            .frame(height: 8)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(AmountMath.isOverLimit(amount: amount, limit: limit) ? Color.tbSlip : Color.tbBrand)
                    .scaleEffect(x: fraction, y: 1, anchor: .leading)
            }
            .clipShape(Capsule())
            .accessibilityHidden(true)
    }
}
