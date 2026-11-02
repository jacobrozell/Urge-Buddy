import Foundation
import Observation

struct ViceCardModel: Identifiable, Equatable {
    var id: UUID
    var name: String
    var iconName: String
    var daysFree: Int
    var savedText: String?
    var week: [DayVisualState]
    var weekLabels: [String]
    var nextMilestone: String?
    var history: ViceHistory

    func clockLine(at now: Date, calendar: Calendar) -> String {
        let clock = RecoveryCopy.clock(RecoveryMath.currentRunClock(history, now: now, calendar: calendar))
        if let savedText { return "\(clock) · \(savedText)" }
        return clock
    }
}

struct CutBackCardModel: Identifiable, Equatable {
    var id: UUID
    var name: String
    var iconName: String
    var amount: Int
    var limit: Int
    var unit: String
    var isOver: Bool
    var trendLine: String?
    var week: [DayVisualState]
    var weekLabels: [String]

    var accessibilityLabel: String {
        var parts = [name, RecoveryCopy.todayAmount(amount, limit: limit, unit: unit)]
        if isOver { parts.append(RecoveryCopy.overLimitToday) }
        if let trendLine { parts.append(trendLine) }
        return parts.joined(separator: ", ")
    }
}

struct HabitRowModel: Identifiable, Equatable {
    var id: UUID
    var name: String
    var iconName: String
    var run: Int
    var isDoneToday: Bool
    var isAtRisk: Bool
    var amount: Int = 0
    /// Set on amount habits.
    var target: Int?
    var unit: String = AmountMath.defaultUnit

    var tracksAmount: Bool { target != nil }
    var step: Int { AmountMath.step(for: target) }
}

struct YesterdayPromptModel: Equatable {
    var metricID: UUID
    var name: String
}

@MainActor
@Observable
final class TodayViewModel {
    var calendar: Calendar
    var locale: Locale
    private(set) var vices: [ViceCardModel] = []
    private(set) var cutBacks: [CutBackCardModel] = []
    private(set) var habits: [HabitRowModel] = []
    private(set) var checkInRemaining = 0
    private(set) var checkInStreak = 0
    private(set) var checkInDoneToday = false
    private(set) var yesterdayPrompt: YesterdayPromptModel?

    init(calendar: Calendar = .current, locale: Locale = .current) {
        self.calendar = calendar
        self.locale = locale
    }

    var showsSOS: Bool { !vices.isEmpty || !cutBacks.isEmpty }
    var isEmpty: Bool { vices.isEmpty && cutBacks.isEmpty && habits.isEmpty }
    var hasViceSection: Bool { !vices.isEmpty || !cutBacks.isEmpty }

    func update(metrics: [Metric], entries: [MetricEntry], now: Date, dismissedYesterday: Date?) {
        let active = metrics
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
        let today = calendar.startOfDay(for: now)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let weekDays = DayMath.days(from: weekStart, through: today, calendar: calendar)

        vices = active.filter(\.isQuitting).map { metric in
            let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
            let daysFree = RecoveryMath.currentRunDays(history, now: now, calendar: calendar)
            let saved = RecoveryMath.moneySaved(
                totalFreeDays: RecoveryMath.totalFreeDays(history, now: now, calendar: calendar),
                costPerDay: metric.costPerDay
            )
            let next = MilestonePolicy.next(after: daysFree, isVice: true)
            return ViceCardModel(
                id: metric.id,
                name: metric.name,
                iconName: metric.iconName,
                daysFree: daysFree,
                savedText: saved.map { RecoveryCopy.saved($0, locale: locale) },
                week: weekDays.map { DayVisualState(dayState: RecoveryMath.state(of: $0, in: history, now: now, calendar: calendar)) },
                weekLabels: weekDays.map { weekdayName($0) },
                nextMilestone: RecoveryCopy.nextMilestone(next, inDays: next - daysFree),
                history: history
            )
        }

        cutBacks = active.filter(\.isCuttingBack).map { metric in
            let history = Snapshots.cutBackHistory(for: metric, entries: entries, calendar: calendar)
            let amount = CutBackMath.amount(on: today, history, calendar: calendar)
            return CutBackCardModel(
                id: metric.id,
                name: metric.name,
                iconName: metric.iconName,
                amount: amount,
                limit: history.limit,
                unit: metric.unitLabel,
                isOver: AmountMath.isOverLimit(amount: amount, limit: history.limit),
                trendLine: Self.trendLine(history, unit: metric.unitLabel, now: now, calendar: calendar),
                week: weekDays.map { DayVisualState(cutBackState: CutBackMath.state(of: $0, in: history, now: now, calendar: calendar)) },
                weekLabels: weekDays.map { weekdayName($0) }
            )
        }

        habits = active.filter { $0.habitType == .positive }.map { metric in
            let history = Snapshots.habitHistory(for: metric, entries: entries, calendar: calendar)
            return HabitRowModel(
                id: metric.id,
                name: metric.name,
                iconName: metric.iconName,
                run: HabitMath.currentRun(history, now: now, calendar: calendar),
                isDoneToday: history.doneDays.contains(today),
                isAtRisk: HabitMath.isAtRisk(history, now: now, calendar: calendar),
                amount: Snapshots.amount(for: metric, on: today, entries: entries, calendar: calendar),
                target: metric.tracksAmount ? metric.dailyTarget : nil,
                unit: metric.unitLabel
            )
        }

        checkInRemaining = active.filter { metric in
            if metric.isCuttingBack {
                let history = Snapshots.cutBackHistory(for: metric, entries: entries, calendar: calendar)
                return !CutBackMath.isLogged(today, history, calendar: calendar)
            }
            guard metric.isQuitting else { return false }
            let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
            return RecoveryMath.state(of: today, in: history, now: now, calendar: calendar) == .todayPending
        }.count

        checkInStreak = ProgressMath.checkInStreak(metrics: active, entries: entries, now: now, calendar: calendar)
        checkInDoneToday = ProgressMath.isCheckedIn(on: today, metrics: active, entries: entries, now: now, calendar: calendar)

        yesterdayPrompt = makeYesterdayPrompt(vices: active.filter(\.isQuitting), entries: entries, now: now, dismissedYesterday: dismissedYesterday)
    }

    /// "Down 60% from 20 a day" once there's a baseline, else the 7-day average.
    static func trendLine(_ history: CutBackHistory, unit: String, now: Date, calendar: Calendar) -> String? {
        let average = CutBackMath.average(inLast: 7, history, now: now, calendar: calendar)
        if let percent = CutBackMath.reductionPercent(average: average, baseline: history.baseline), let baseline = history.baseline {
            return RecoveryCopy.reduction(percent, baseline: baseline, unit: unit)
        }
        return average.map { RecoveryCopy.averageLine($0, unit: unit) }
    }

    private func makeYesterdayPrompt(vices: [Metric], entries: [MetricEntry], now: Date, dismissedYesterday: Date?) -> YesterdayPromptModel? {
        guard calendar.component(.hour, from: now) < 12,
              let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) else { return nil }
        if let dismissedYesterday, calendar.isDate(dismissedYesterday, inSameDayAs: yesterday) { return nil }
        for metric in vices {
            let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
            if RecoveryMath.state(of: yesterday, in: history, now: now, calendar: calendar) == .presumedFree {
                return YesterdayPromptModel(metricID: metric.id, name: metric.name)
            }
        }
        return nil
    }

    private func weekdayName(_ day: Date) -> String {
        let index = calendar.component(.weekday, from: day) - 1
        let symbols = calendar.weekdaySymbols
        guard symbols.indices.contains(index) else { return "" }
        return symbols[index]
    }
}
