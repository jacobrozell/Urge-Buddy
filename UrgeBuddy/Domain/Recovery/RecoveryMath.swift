import Foundation

struct ViceHistory: Equatable {
    var startedAt: Date
    var slips: [Date]
    var confirmedFreeDays: Set<Date>
}

enum DayState: Equatable {
    case beforeStart, future, slipped, confirmedFree, presumedFree, todayPending
}

enum RecoveryMath {
    static func relevantSlips(_ h: ViceHistory) -> [Date] {
        h.slips.filter { $0 >= h.startedAt }.sorted()
    }

    /// When the current free run began: the latest slip, or the quit date.
    static func currentRunStart(_ h: ViceHistory) -> Date {
        relevantSlips(h).last ?? h.startedAt
    }

    /// Whole 24-hour periods in the current run. Drives "N days free" and milestones.
    static func currentRunDays(_ h: ViceHistory, now: Date, calendar: Calendar = .current) -> Int {
        let start = currentRunStart(h)
        guard now > start else { return 0 }
        return calendar.dateComponents([.day], from: start, to: now).day ?? 0
    }

    /// Day/hour/minute components for the live clock.
    static func currentRunClock(_ h: ViceHistory, now: Date, calendar: Calendar = .current) -> DateComponents {
        let start = currentRunStart(h)
        return calendar.dateComponents([.day, .hour, .minute], from: start, to: max(now, start))
    }

    static func longestRunDays(_ h: ViceHistory, now: Date, calendar: Calendar = .current) -> Int {
        let points = [h.startedAt] + relevantSlips(h) + [max(now, h.startedAt)]
        return zip(points, points.dropFirst())
            .map { calendar.dateComponents([.day], from: $0, to: $1).day ?? 0 }
            .max() ?? 0
    }

    static func state(of day: Date, in h: ViceHistory, now: Date, calendar: Calendar = .current) -> DayState {
        state(of: calendar.startOfDay(for: day), in: h, slipDays: slipDays(h, calendar), now: now, calendar: calendar)
    }

    /// (free, counted) over the last `window` days ending today.
    static func freeDays(inLast window: Int, _ h: ViceHistory, now: Date, calendar: Calendar = .current) -> (free: Int, counted: Int) {
        let today = calendar.startOfDay(for: now)
        guard window > 0, let first = calendar.date(byAdding: .day, value: -(window - 1), to: today) else { return (0, 0) }
        return tally(DayMath.days(from: first, through: today, calendar: calendar), h, now: now, calendar: calendar)
    }

    /// Free days since the quit date. Never reset by a slip.
    static func totalFreeDays(_ h: ViceHistory, now: Date, calendar: Calendar = .current) -> Int {
        tally(DayMath.days(from: h.startedAt, through: now, calendar: calendar), h, now: now, calendar: calendar).free
    }

    /// Money saved = total free days × cost per day. Not reset by a slip.
    static func moneySaved(totalFreeDays: Int, costPerDay: Decimal?) -> Decimal? {
        guard let costPerDay, costPerDay > 0, totalFreeDays > 0 else { return nil }
        return costPerDay * Decimal(totalFreeDays)
    }

    // MARK: - Private

    private static func slipDays(_ h: ViceHistory, _ calendar: Calendar) -> Set<Date> {
        Set(relevantSlips(h).map { calendar.startOfDay(for: $0) })
    }

    private static func state(of key: Date, in h: ViceHistory, slipDays: Set<Date>, now: Date, calendar: Calendar) -> DayState {
        let today = calendar.startOfDay(for: now)
        if key < calendar.startOfDay(for: h.startedAt) { return .beforeStart }
        if key > today { return .future }
        if slipDays.contains(key) { return .slipped }
        if h.confirmedFreeDays.contains(key) { return .confirmedFree }
        return key == today ? .todayPending : .presumedFree
    }

    private static func tally(_ days: [Date], _ h: ViceHistory, now: Date, calendar: Calendar) -> (free: Int, counted: Int) {
        let slips = slipDays(h, calendar)
        return days.reduce(into: (free: 0, counted: 0)) { acc, day in
            switch state(of: day, in: h, slipDays: slips, now: now, calendar: calendar) {
            case .confirmedFree, .presumedFree:
                acc.free += 1
                acc.counted += 1
            case .slipped:
                acc.counted += 1
            case .beforeStart, .future, .todayPending:
                break
            }
        }
    }
}
