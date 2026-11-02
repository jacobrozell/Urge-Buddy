import Foundation
import Observation
import SwiftData

enum CheckInAnswer: Equatable {
    case unanswered, free, slipped
}

struct CheckInViceRow: Identifiable, Equatable {
    var id: UUID
    var name: String
    var answer: CheckInAnswer
}

struct CheckInAmountRow: Identifiable, Equatable {
    var id: UUID
    var name: String
    var amount: Int
    /// Cut back: the limit. Habit: the target.
    var goal: Int
    var unit: String
    var step: Int
}

struct CheckInHabitRow: Identifiable, Equatable {
    var id: UUID
    var name: String
    var isDone: Bool
}

struct CheckInSummaryLine: Identifiable, Equatable {
    var id: UUID
    var name: String
    var detail: String
    var milestone: String?
}

@MainActor
@Observable
final class CheckInViewModel {
    private let store: RecoveryStore
    private(set) var vices: [CheckInViceRow] = []
    private(set) var cutBacks: [CheckInAmountRow] = []
    private(set) var habits: [CheckInHabitRow] = []
    private(set) var amountHabits: [CheckInAmountRow] = []
    private(set) var lines: [CheckInSummaryLine] = []
    private(set) var checkInStreak = 0
    var mood: Mood?
    var noteText = ""
    var showComplete = false
    private var didLoadNote = false

    var calendar: Calendar { store.calendar }
    var canFinish: Bool { vices.allSatisfy { $0.answer != .unanswered } }

    init(store: RecoveryStore) {
        self.store = store
    }

    func load(metrics: [Metric], entries: [MetricEntry], now: Date) {
        let active = metrics.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
        let today = calendar.startOfDay(for: now)
        vices = active.filter(\.isQuitting).map { metric in
            let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
            let answer: CheckInAnswer
            switch RecoveryMath.state(of: today, in: history, now: now, calendar: calendar) {
            case .confirmedFree: answer = .free
            case .slipped: answer = .slipped
            default: answer = .unanswered
            }
            return CheckInViceRow(id: metric.id, name: metric.name, answer: answer)
        }
        cutBacks = active.filter(\.isCuttingBack).map { amountRow($0, entries: entries, today: today) }
        let positives = active.filter { $0.habitType == .positive }
        amountHabits = positives.filter(\.tracksAmount).map { amountRow($0, entries: entries, today: today) }
        habits = positives.filter { !$0.tracksAmount }.map { metric in
            let history = Snapshots.habitHistory(for: metric, entries: entries, calendar: calendar)
            return CheckInHabitRow(id: metric.id, name: metric.name, isDone: history.doneDays.contains(today))
        }
        if !didLoadNote {
            let note = try? store.dayNote(on: now)
            mood = note?.mood
            noteText = note?.text ?? ""
            didLoadNote = true
        }
    }

    func markFree(_ id: UUID, metrics: [Metric], now: Date) throws {
        guard let metric = metrics.first(where: { $0.id == id }) else { return }
        try store.markFree(metric, on: now, now: now)
        setVice(id, answer: .free)
    }

    func toggleHabit(_ id: UUID, metrics: [Metric], now: Date) throws {
        guard let metric = metrics.first(where: { $0.id == id }),
              let row = habits.first(where: { $0.id == id }) else { return }
        try store.setHabitDone(metric, on: now, done: !row.isDone, now: now)
        if let index = habits.firstIndex(where: { $0.id == id }) {
            habits[index].isDone.toggle()
        }
    }

    func setAmount(_ id: UUID, _ amount: Int, metrics: [Metric], now: Date) throws {
        guard let metric = metrics.first(where: { $0.id == id }) else { return }
        try store.setAmount(metric, on: now, amount: amount, now: now)
        let value = max(0, amount)
        if let index = cutBacks.firstIndex(where: { $0.id == id }) { cutBacks[index].amount = value }
        if let index = amountHabits.firstIndex(where: { $0.id == id }) { amountHabits[index].amount = value }
    }

    func saveDayNote(now: Date) throws {
        try store.setDayNote(on: now, mood: mood, text: noteText, now: now)
    }

    func finish(metrics: [Metric], now: Date, locale: Locale = .current, celebrated: [UUID: Int]) throws {
        guard canFinish else { return }
        for row in cutBacks {
            guard let metric = metrics.first(where: { $0.id == row.id }),
                  try store.entry(for: metric.id, on: now) == nil else { continue }
            try store.setAmount(metric, on: now, amount: row.amount, now: now)
        }
        try saveDayNote(now: now)
        let entries = try store.context.fetch(FetchDescriptor<MetricEntry>())
        let active = metrics.filter { $0.habitType == .vice && !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
        lines = active.map { metric in
            metric.isCuttingBack
                ? cutBackLine(metric, entries: entries, now: now, locale: locale)
                : quitLine(metric, entries: entries, now: now, locale: locale, highest: celebrated[metric.id] ?? 0)
        }
        checkInStreak = ProgressMath.checkInStreak(metrics: metrics, entries: entries, now: now, calendar: calendar)
        showComplete = true
    }

    private func quitLine(_ metric: Metric, entries: [MetricEntry], now: Date, locale: Locale, highest: Int) -> CheckInSummaryLine {
        let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
        let days = RecoveryMath.currentRunDays(history, now: now, calendar: calendar)
        let saved = RecoveryMath.moneySaved(
            totalFreeDays: RecoveryMath.totalFreeDays(history, now: now, calendar: calendar),
            costPerDay: metric.costPerDay
        ).map { RecoveryCopy.saved($0, locale: locale) }
        let milestone = MilestonePolicy.pending(value: days, isVice: true, highestCelebrated: highest)
            .map { RecoveryCopy.milestoneVice($0, name: metric.name) }
        return CheckInSummaryLine(
            id: metric.id,
            name: metric.name,
            detail: RecoveryCopy.checkInSummary(days: days, saved: saved),
            milestone: milestone
        )
    }

    private func cutBackLine(_ metric: Metric, entries: [MetricEntry], now: Date, locale: Locale) -> CheckInSummaryLine {
        let history = Snapshots.cutBackHistory(for: metric, entries: entries, calendar: calendar)
        let saved = CutBackMath.moneySaved(
            unitsAvoided: CutBackMath.unitsAvoided(history, now: now, calendar: calendar),
            baseline: history.baseline,
            costPerDay: metric.costPerDay
        ).map { RecoveryCopy.saved($0, locale: locale) }
        return CheckInSummaryLine(
            id: metric.id,
            name: metric.name,
            detail: RecoveryCopy.cutBackSummary(
                amount: CutBackMath.amount(on: now, history, calendar: calendar),
                limit: history.limit,
                unit: metric.unitLabel,
                saved: saved
            ),
            milestone: TodayViewModel.trendLine(history, unit: metric.unitLabel, now: now, calendar: calendar)
        )
    }

    private func amountRow(_ metric: Metric, entries: [MetricEntry], today: Date) -> CheckInAmountRow {
        CheckInAmountRow(
            id: metric.id,
            name: metric.name,
            amount: Snapshots.amount(for: metric, on: today, entries: entries, calendar: calendar),
            goal: metric.dailyTarget ?? 0,
            unit: metric.unitLabel,
            step: metric.isCuttingBack ? 1 : AmountMath.step(for: metric.dailyTarget)
        )
    }

    private func setVice(_ id: UUID, answer: CheckInAnswer) {
        guard let index = vices.firstIndex(where: { $0.id == id }) else { return }
        vices[index].answer = answer
    }
}
