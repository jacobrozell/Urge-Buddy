import Foundation

/// Progress summary math that is not tied to one vice or habit.
enum ProgressMath {
    /// Distinct days in the last `window` days, including today, that have a log.
    /// A day counts once even when several metrics were logged.
    static func daysCheckedIn(loggedDays: [Date], inLast window: Int = 30, now: Date, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        guard window > 0, let start = calendar.date(byAdding: .day, value: -(window - 1), to: today) else { return 0 }
        let windowDays = Set(DayMath.days(from: start, through: today, calendar: calendar))
        let logged = Set(loggedDays.map { calendar.startOfDay(for: $0) })
        return logged.intersection(windowDays).count
    }
}
