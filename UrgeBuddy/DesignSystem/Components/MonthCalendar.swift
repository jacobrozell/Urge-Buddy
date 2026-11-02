import SwiftUI

struct MonthCalendar: View {
    var month: Date
    var stateFor: (Date) -> DayVisualState
    var onSelect: (Date) -> Void

    @Environment(\.calendar) private var calendar

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(monthTitle)
                .font(.headline)
                .foregroundStyle(Color.tbTextPrimary)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(Color.tbTextSecondary)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(minHeight: 44)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 7)
    }

    private var monthTitle: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    private var cells: [Date?] {
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let range = calendar.range(of: .day, in: .month, for: start) else { return [] }
        let weekday = calendar.component(.weekday, from: start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var result = Array<Date?>(repeating: nil, count: leading)
        for offset in range {
            result.append(calendar.date(byAdding: .day, value: offset - 1, to: start))
        }
        return result
    }

    private func dayCell(_ day: Date) -> some View {
        let state = stateFor(day)
        let number = calendar.component(.day, from: day)
        return Button {
            onSelect(day)
        } label: {
            VStack(spacing: Spacing.xs) {
                Text("\(number)")
                    .font(.caption)
                    .foregroundStyle(state == .inactive ? Color.tbTextSecondary : Color.tbTextPrimary)
                DayMark(state: state, size: 12)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(state == .slipped ? Color.tbSlipSoft : Color.clear, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)), \(state.accessibilityName)")
        .accessibilityIdentifier(AccessibilityIdentifiers.calendarDay(day, calendar: calendar))
    }
}

#Preview("Light") { MonthCalendarPreview() }
#Preview("Dark") { MonthCalendarPreview().preferredColorScheme(.dark) }
#Preview("AX3") { MonthCalendarPreview().dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { MonthCalendarPreview() }

private struct MonthCalendarPreview: View {
    var body: some View {
        ComponentPreview {
            MonthCalendar(month: Date(timeIntervalSince1970: 1_760_000_000), stateFor: { date in
                let day = Calendar.current.component(.day, from: date)
                switch day {
                case 3: return .slipped
                case 4: return .presumedFree
                case 5: return .habitDone
                case 6: return .todayPending
                default: return day % 2 == 0 ? .confirmedFree : .inactive
                }
            }, onSelect: { _ in })
        }
    }
}
