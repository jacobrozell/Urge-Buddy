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

    /// Consecutive days the check-in was actually answered.
    /// Today counts only after it is answered. A presumed-free day does not.
    /// A slip counts: they showed up and logged it. The run stops at the first gap,
    /// with no message about the gap.
    static func checkInStreak(metrics: [Metric], entries: [MetricEntry], now: Date, calendar: Calendar = .current) -> Int {
        let context = CheckInLog(metrics: metrics, entries: entries, now: now, calendar: calendar)
        let today = calendar.startOfDay(for: now)
        let start = context.mark(today) == .complete
            ? today
            : (calendar.date(byAdding: .day, value: -1, to: today) ?? today)
        var streak = 0
        var day = start
        for _ in 0..<4000 {
            switch context.mark(day) {
            case .complete:
                streak += 1
                guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { return streak }
                day = previous
            case .missed, .none:
                return streak
            }
        }
        return streak
    }

    /// True when today's check-in is answered. Habits count only when nothing is being quit or cut back.
    static func isCheckedIn(on day: Date, metrics: [Metric], entries: [MetricEntry], now: Date, calendar: Calendar = .current) -> Bool {
        CheckInLog(metrics: metrics, entries: entries, now: now, calendar: calendar).mark(calendar.startOfDay(for: day)) == .complete
    }
}

private struct CheckInLog {
    enum Mark { case complete, missed, none }

    var quit: [(Metric, ViceHistory)]
    var cutBack: [(Metric, CutBackHistory)]
    var habitStarts: [Date]
    var habitLogged: Set<Date>
    var calendar: Calendar
    var now: Date

    init(metrics: [Metric], entries: [MetricEntry], now: Date, calendar: Calendar) {
        self.calendar = calendar
        let active = metrics.filter { !$0.isArchived }
        quit = active.filter(\.isQuitting).map { ($0, Snapshots.viceHistory(for: $0, entries: entries, calendar: calendar)) }
        cutBack = active.filter(\.isCuttingBack).map { ($0, Snapshots.cutBackHistory(for: $0, entries: entries, calendar: calendar)) }
        let habits = active.filter { $0.habitType == .positive }
        habitStarts = habits.map { calendar.startOfDay(for: $0.startedAt) }
        let habitIDs = Set(habits.map(\.id))
        habitLogged = Set(entries.compactMap { entry in
            guard habitIDs.contains(entry.metricID), entry.status == .done || entry.status == .within || entry.status == .over else { return nil }
            return calendar.startOfDay(for: entry.day)
        })
        self.now = now
    }

    func mark(_ day: Date) -> Mark {
        if !quit.isEmpty || !cutBack.isEmpty {
            let applicableQuit = quit.filter { calendar.startOfDay(for: $0.0.startedAt) <= day }
            let applicableCut = cutBack.filter { calendar.startOfDay(for: $0.0.startedAt) <= day }
            if applicableQuit.isEmpty && applicableCut.isEmpty { return habitMark(day) }
            let quitLogged = applicableQuit.allSatisfy { pair in
                let state = RecoveryMath.state(of: day, in: pair.1, now: now, calendar: calendar)
                return state == .confirmedFree || state == .slipped
            }
            let cutLogged = applicableCut.allSatisfy { CutBackMath.isLogged(day, $0.1, calendar: calendar) }
            return quitLogged && cutLogged ? .complete : .missed
        }
        return habitMark(day)
    }

    private func habitMark(_ day: Date) -> Mark {
        let started = habitStarts.filter { $0 <= day }
        if started.isEmpty { return .none }
        return habitLogged.contains(day) ? .complete : .missed
    }
}
