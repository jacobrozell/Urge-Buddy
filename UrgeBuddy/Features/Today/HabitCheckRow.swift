import SwiftUI

struct HabitCheckRow: View {
    var model: HabitRowModel
    var onToggle: () -> Void
    var onSetAmount: (Int) -> Void = { _ in }
    var onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.usesAccessibilityLayout {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    control
                    labelButton
                }
            } else {
                HStack(alignment: .center, spacing: Spacing.s) {
                    control
                    labelButton
                }
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.s)
        .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    @ViewBuilder
    private var control: some View {
        if let target = model.target {
            amountButton(target: target)
        } else {
            toggleButton
        }
    }

    private var labelButton: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(model.name)
                    .font(.body)
                    .foregroundStyle(Color.tbTextPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.tbTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if model.isAtRisk {
                    Text(RecoveryCopy.dontMissTwice)
                        .font(.footnote)
                        .foregroundStyle(Color.tbSlip)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(rowLabel)
    }

    private var toggleButton: some View {
        Button(action: onToggle) {
            Image(systemName: model.isDoneToday ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(model.isDoneToday ? Color.tbHabit : Color.tbTextSecondary)
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier(AccessibilityIdentifiers.habitToggle(model.id))
        .accessibilityLabel(model.isDoneToday ? "\(model.name), done" : "\(model.name), not done")
        .sensoryFeedback(model.isDoneToday ? .success : .selection, trigger: model.isDoneToday)
    }

    private func amountButton(target: Int) -> some View {
        Button { onSetAmount(model.amount + model.step) } label: {
            ZStack {
                Circle()
                    .stroke(Color.tbSurfaceMuted, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: min(1, CGFloat(model.amount) / CGFloat(max(target, 1))))
                    .stroke(Color.tbHabit, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: model.isDoneToday ? "checkmark" : "plus")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(model.isDoneToday ? Color.tbHabit : Color.tbTextSecondary)
            }
            .frame(width: 30, height: 30)
            .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.pressable)
        .contextMenu {
            Button(RecoveryCopy.removeOne, systemImage: "minus") { onSetAmount(max(0, model.amount - model.step)) }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.habitToggle(model.id))
        .accessibilityLabel(model.name)
        .accessibilityValue(RecoveryCopy.amountOf(model.amount, target, unit: model.unit))
        .accessibilityHint(RecoveryCopy.logOne)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onSetAmount(model.amount + model.step)
            case .decrement: onSetAmount(max(0, model.amount - model.step))
            @unknown default: break
            }
        }
        .sensoryFeedback(model.isDoneToday ? .success : .selection, trigger: model.amount)
    }

    private var subtitle: String {
        guard let target = model.target else { return RecoveryCopy.habitRun(model.run) }
        return "\(RecoveryCopy.amountOf(model.amount, target, unit: model.unit)) · \(RecoveryCopy.habitRun(model.run))"
    }

    private var rowLabel: String {
        var label = "\(model.name), \(subtitle)"
        if model.isAtRisk { label += ", \(RecoveryCopy.dontMissTwice)" }
        return label
    }
}
