import SwiftUI

struct DayDots: View {
    var states: [DayVisualState]
    var labels: [String] = []
    var showsInitials: Bool = true

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var showsLetters: Bool {
        showsInitials && !dynamicTypeSize.usesAccessibilityLayout
    }

    var body: some View {
        HStack(spacing: Spacing.m) {
            ForEach(Array(states.enumerated()), id: \.offset) { index, state in
                VStack(spacing: 2) {
                    DayMark(state: state, size: 16)
                        .accessibilityLabel(spoken(index: index, state: state))
                    if showsLetters, labels.indices.contains(index), !labels[index].isEmpty {
                        Text(initial(for: labels[index]))
                            .font(.caption2)
                            .foregroundStyle(Color.tbTextSecondary)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true)
    }

    /// Weekday names use the locale's short symbol. Anything else uses its first character.
    private func initial(for label: String) -> String {
        let calendar = Calendar.current
        if let index = calendar.weekdaySymbols.firstIndex(of: label),
           calendar.veryShortWeekdaySymbols.indices.contains(index) {
            return calendar.veryShortWeekdaySymbols[index]
        }
        return String(label.prefix(1))
    }

    private func spoken(index: Int, state: DayVisualState) -> String {
        if labels.indices.contains(index), !labels[index].isEmpty {
            return "\(labels[index]), \(state.accessibilityName)"
        }
        return state.accessibilityName
    }
}

private let previewWeek: [DayVisualState] = [
    .confirmedFree, .confirmedFree, .presumedFree, .slipped, .habitDone, .missed, .todayPending
]
private let previewWeekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

#Preview("Light") { ComponentPreview { DayDots(states: previewWeek, labels: previewWeekdays) } }
#Preview("Dark") { ComponentPreview { DayDots(states: previewWeek, labels: previewWeekdays) }.preferredColorScheme(.dark) }
#Preview("AX3") { ComponentPreview { DayDots(states: previewWeek, labels: previewWeekdays) }.dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { ComponentPreview { DayDots(states: previewWeek, labels: previewWeekdays) } }
