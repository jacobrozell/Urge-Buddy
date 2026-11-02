import Foundation

/// Amount habits: a day is done once the logged amount reaches the target.
enum AmountMath {
    static let defaultUnit = "times"

    /// How much one tap adds. Larger targets (minutes, pages) move in fives.
    static func step(for target: Int?) -> Int {
        guard let target, target >= 20 else { return 1 }
        return 5
    }

    static func isHabitDone(amount: Int, target: Int) -> Bool {
        amount >= max(target, 1)
    }

    /// A logged zero is within the limit.
    static func isOverLimit(amount: Int, limit: Int) -> Bool {
        amount > max(limit, 0)
    }
}

struct CutBackDay: Equatable {
    var amount: Int
    var isOver: Bool
}

struct CutBackHistory: Equatable {
    var startedAt: Date
    var limit: Int
    var baseline: Int?
    /// Logged days keyed by start of day.
    var days: [Date: CutBackDay]
}

enum CutBackDayState: Equatable {
    case beforeStart, future, notLogged, todayPending, within, over
}

/// Cut-back math. Unlogged days are unknown, never presumed. Today is left out of
/// averages and savings because it isn't over yet.
enum CutBackMath {
    static func amount(on day: Date, _ h: CutBackHistory, calendar: Calendar = .current) -> Int {
        h.days[calendar.startOfDay(for: day)]?.amount ?? 0
    }

    static func isLogged(_ day: Date, _ h: CutBackHistory, calendar: Calendar = .current) -> Bool {
        h.days[calendar.startOfDay(for: day)] != nil
    }

    static func state(of day: Date, in h: CutBackHistory, now: Date, calendar: Calendar = .current) -> CutBackDayState {
        let key = calendar.startOfDay(for: day)
        let today = calendar.startOfDay(for: now)
        if key < calendar.startOfDay(for: h.startedAt) { return .beforeStart }
        if key > today { return .future }
        if let logged = h.days[key] { return logged.isOver ? .over : .within }
        return key == today ? .todayPending : .notLogged
    }

    /// (within, logged) over the `window` days before today.
    static func withinDays(inLast window: Int, _ h: CutBackHistory, now: Date, calendar: Calendar = .current) -> (within: Int, logged: Int) {
        pastLoggedDays(inLast: window, h, now: now, calendar: calendar).reduce(into: (within: 0, logged: 0)) { acc, day in
            acc.logged += 1
            if !day.isOver { acc.within += 1 }
        }
    }

    /// Average per logged day over the `window` days before today.
    static func average(inLast window: Int, _ h: CutBackHistory, now: Date, calendar: Calendar = .current) -> Double? {
        let days = pastLoggedDays(inLast: window, h, now: now, calendar: calendar)
        guard !days.isEmpty else { return nil }
        return Double(days.map(\.amount).reduce(0, +)) / Double(days.count)
    }

    /// Whole percent below the baseline. Nil when there's no baseline or no drop.
    static func reductionPercent(average: Double?, baseline: Int?) -> Int? {
        guard let average, let baseline, baseline > 0, average < Double(baseline) else { return nil }
        return Int(((1 - average / Double(baseline)) * 100).rounded())
    }

    /// Units not used compared with the baseline, over every finished logged day.
    static func unitsAvoided(_ h: CutBackHistory, now: Date, calendar: Calendar = .current) -> Int {
        guard let baseline = h.baseline, baseline > 0 else { return 0 }
        let today = calendar.startOfDay(for: now)
        let start = calendar.startOfDay(for: h.startedAt)
        return h.days
            .filter { $0.key >= start && $0.key < today }
            .map { max(0, baseline - $0.value.amount) }
            .reduce(0, +)
    }

    /// Money saved = units avoided × (cost per day at the baseline ÷ baseline).
    static func moneySaved(unitsAvoided: Int, baseline: Int?, costPerDay: Decimal?) -> Decimal? {
        guard let baseline, baseline > 0, let costPerDay, costPerDay > 0, unitsAvoided > 0 else { return nil }
        return costPerDay * Decimal(unitsAvoided) / Decimal(baseline)
    }

    private static func pastLoggedDays(inLast window: Int, _ h: CutBackHistory, now: Date, calendar: Calendar) -> [CutBackDay] {
        let today = calendar.startOfDay(for: now)
        guard window > 0, let first = calendar.date(byAdding: .day, value: -window, to: today) else { return [] }
        let start = max(first, calendar.startOfDay(for: h.startedAt))
        return h.days.filter { $0.key >= start && $0.key < today }.map(\.value)
    }
}
