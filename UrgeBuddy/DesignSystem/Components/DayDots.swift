import SwiftUI

struct DayDots: View {
    var states: [DayVisualState]
    var labels: [String] = []

    var body: some View {
        HStack(spacing: Spacing.m) {
            ForEach(Array(states.enumerated()), id: \.offset) { index, state in
                DayMark(state: state, size: 16)
                    .accessibilityLabel(spoken(index: index, state: state))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true)
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
