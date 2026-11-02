import Foundation

enum Snapshots {
    static func viceHistory(for metric: Metric, entries: [MetricEntry], calendar: Calendar = .current) -> ViceHistory {
        let mine = entries.filter { $0.metricID == metric.id }
        let slips = mine.filter { $0.status == .slipped }.map(\.occurredAt)
        let confirmed = Set(mine.filter { $0.status == .free }.map { calendar.startOfDay(for: $0.day) })
        return ViceHistory(startedAt: metric.startedAt, slips: slips, confirmedFreeDays: confirmed)
    }

    static func habitHistory(for metric: Metric, entries: [MetricEntry], calendar: Calendar = .current) -> HabitHistory {
        let done = entries
            .filter { $0.metricID == metric.id && $0.status == .done }
            .map { calendar.startOfDay(for: $0.day) }
        return HabitHistory(startedAt: metric.startedAt, doneDays: Set(done))
    }

    static func cutBackHistory(for metric: Metric, entries: [MetricEntry], calendar: Calendar = .current) -> CutBackHistory {
        var days: [Date: CutBackDay] = [:]
        for entry in entries where entry.metricID == metric.id && (entry.status == .within || entry.status == .over) {
            days[calendar.startOfDay(for: entry.day)] = CutBackDay(amount: entry.amount ?? 0, isOver: entry.status == .over)
        }
        return CutBackHistory(startedAt: metric.startedAt, limit: metric.dailyTarget ?? 0, baseline: metric.baselinePerDay, days: days)
    }

    /// Today's logged amount for an amount-tracked metric.
    static func amount(for metric: Metric, on day: Date, entries: [MetricEntry], calendar: Calendar = .current) -> Int {
        entries.first { $0.metricID == metric.id && calendar.isDate($0.day, inSameDayAs: day) }?.amount ?? 0
    }
}

extension DayVisualState {
    init(dayState: DayState) {
        switch dayState {
        case .confirmedFree: self = .confirmedFree
        case .presumedFree: self = .presumedFree
        case .slipped: self = .slipped
        case .todayPending: self = .todayPending
        case .beforeStart, .future: self = .inactive
        }
    }

    init(cutBackState: CutBackDayState) {
        switch cutBackState {
        case .within: self = .withinLimit
        case .over: self = .overLimit
        case .notLogged: self = .notLogged
        case .todayPending: self = .todayPending
        case .beforeStart, .future: self = .inactive
        }
    }

    /// A habit day. Today is never shown as missed.
    static func habit(isDone: Bool, isPartial: Bool = false, isToday: Bool, isActive: Bool) -> DayVisualState {
        guard isActive else { return .inactive }
        if isDone { return .habitDone }
        if isPartial { return .habitPartial }
        return isToday ? .todayPending : .missed
    }
}
