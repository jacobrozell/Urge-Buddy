import Foundation

struct HabitHistory: Equatable {
    var startedAt: Date
    var doneDays: Set<Date>
}

enum HabitMath {
    /// "Never miss twice": one missed day pauses the run; two missed days in a row end it.
    /// Today never counts as a miss because the day isn't over.
    static func currentRun(_ h: HabitHistory, now: Date, calendar: Calendar = .current) -> Int {
        let firstDay = calendar.startOfDay(for: h.startedAt)
        var cursor = calendar.startOfDay(for: now)
        let today = cursor
        var run = 0
        var consecutiveMisses = 0
        while cursor >= firstDay {
            if h.doneDays.contains(cursor) {
                run += 1
                consecutiveMisses = 0
            } else if cursor != today {
                consecutiveMisses += 1
                if consecutiveMisses >= 2 { break }
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return run
    }

    /// Yesterday was missed and today isn't done yet. Show the gentle "Don't miss twice" hint.
    static func isAtRisk(_ h: HabitHistory, now: Date, calendar: Calendar = .current) -> Bool {
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              yesterday >= calendar.startOfDay(for: h.startedAt) else { return false }
        return !h.doneDays.contains(today)
            && !h.doneDays.contains(yesterday)
            && currentRun(h, now: now, calendar: calendar) > 0
    }

    /// Longest run ever, using the same never-miss-twice rule walking forward.
    static func bestRun(_ h: HabitHistory, now: Date, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        var best = 0
        var run = 0
        var consecutiveMisses = 0
        for day in DayMath.days(from: h.startedAt, through: now, calendar: calendar) {
            if h.doneDays.contains(day) {
                run += 1
                consecutiveMisses = 0
            } else if day != today {
                consecutiveMisses += 1
                if consecutiveMisses >= 2 { run = 0 }
            }
            best = max(best, run)
        }
        return best
    }

    static func doneCount(inLast window: Int, _ h: HabitHistory, now: Date, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        guard window > 0, let first = calendar.date(byAdding: .day, value: -(window - 1), to: today) else { return 0 }
        return h.doneDays.filter { $0 >= first && $0 <= today }.count
    }
}
