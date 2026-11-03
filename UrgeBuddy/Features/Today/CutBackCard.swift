import SwiftUI

struct CutBackCard: View {
    var model: CutBackCardModel
    var onChange: (Int) -> Void
    var onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Button(action: onOpen) {
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
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .buttonStyle(.pressable)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.accessibilityLabel)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(AccessibilityIdentifiers.cutBackCard(model.id))

            VStack(alignment: .leading, spacing: Spacing.s) {
                amountLine
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    barRow
                    if model.isOver {
                        Text(RecoveryCopy.overLimitToday)
                            .font(.subheadline)
                            .foregroundStyle(Color.tbTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let trendLine = model.trendLine {
                        Text(trendLine)
                            .font(.subheadline)
                            .foregroundStyle(Color.tbTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    DayDots(states: model.week, labels: model.weekLabels)
                    if !legendStates.isEmpty {
                        WeekLegend(states: legendStates)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
            .accessibilityHidden(true)

            HStack {
                Spacer(minLength: 0)
                AmountStepper(value: model.amount, unit: model.unit, label: model.name, onChange: onChange)
                    .fixedSize()
                    .accessibilityIdentifier(AccessibilityIdentifiers.cutBackStepper(model.id))
                Spacer(minLength: 0)
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private var amountLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            amountNumber
            amountContext
        }
    }

    private var amountNumber: some View {
        Text("\(model.amount)")
            .font(.title2.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(model.isOver ? Color.tbSlip : Color.tbTextPrimary)
    }

    private var amountContext: some View {
        Text("of \(model.limit) \(model.unit) today")
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.tbTextSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var barRow: some View {
        HStack(alignment: .center, spacing: Spacing.m) {
            LimitBar(amount: model.amount, limit: model.limit)
                .frame(maxWidth: .infinity)
            if !model.isOver {
                Text(RecoveryCopy.leftToday(max(0, model.limit - model.amount)))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.tbBrand)
                    .fixedSize()
            }
        }
    }

    private var legendStates: [DayVisualState] {
        let order: [DayVisualState] = [.withinLimit, .overLimit, .notLogged, .todayPending]
        return order.filter { model.week.contains($0) }
    }
}

/// Shape key for the week strip. Only states that appear in this week are shown.
private struct WeekLegend: View {
    var states: [DayVisualState]

    var body: some View {
        HStack(spacing: Spacing.m) { items }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var items: some View {
        ForEach(states, id: \.self) { state in
            HStack(spacing: Spacing.xs) {
                DayMark(state: state, size: 12)
                Text(title(state))
                    .font(.caption2)
                    .foregroundStyle(Color.tbTextSecondary)
            }
        }
    }

    private func title(_ state: DayVisualState) -> String {
        switch state {
        case .withinLimit: RecoveryCopy.legendWithin
        case .overLimit: RecoveryCopy.legendOver
        case .notLogged: RecoveryCopy.legendNotLogged
        default: state.accessibilityName
        }
    }
}

#Preview("Light") { CutBackPreview() }
#Preview("Dark") { CutBackPreview().preferredColorScheme(.dark) }
#Preview("AX3") { CutBackPreview().dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { CutBackPreview() }

private struct CutBackPreview: View {
    var body: some View {
        ComponentPreview {
            CutBackCard(
                model: CutBackCardModel(
                    id: UUID(),
                    name: "Smoking",
                    iconName: "smoke",
                    amount: 3,
                    limit: 8,
                    unit: "cigarettes",
                    isOver: false,
                    trendLine: "Down 60% from 20 cigarettes a day",
                    week: [.withinLimit, .overLimit, .withinLimit, .withinLimit, .overLimit, .withinLimit, .withinLimit],
                    weekLabels: ["Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday", "Monday"]
                ),
                onChange: { _ in },
                onOpen: {}
            )
        }
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
            .frame(height: 12)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(AmountMath.isOverLimit(amount: amount, limit: limit) ? Color.tbSlip : Color.tbBrand)
                    .scaleEffect(x: fraction, y: 1, anchor: .leading)
            }
            .clipShape(Capsule())
            .accessibilityHidden(true)
    }
}
