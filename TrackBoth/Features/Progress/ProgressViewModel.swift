import Foundation
import Observation

struct ProgressSummary: Equatable {
    var savedText: String?
    var urgesBeaten: Int
    var daysCheckedIn: Int
}

struct ProgressCardModel: Identifiable, Equatable {
    var id: UUID
    var name: String
    var iconName: String
    var habitType: HabitType
    var line: String
    var isArchived: Bool
}

struct DayNoteRow: Identifiable, Equatable {
    var id: UUID
    var day: String
    var systemImage: String
    var text: String
}

@MainActor
@Observable
final class ProgressViewModel {
    var calendar: Calendar
    var locale: Locale
    private(set) var summary = ProgressSummary(savedText: nil, urgesBeaten: 0, daysCheckedIn: 0)
    private(set) var active: [ProgressCardModel] = []
    private(set) var archived: [ProgressCardModel] = []
    private(set) var recentDays: [DayNoteRow] = []

    init(calendar: Calendar = .current, locale: Locale = .current) {
        self.calendar = calendar
        self.locale = locale
    }

    func update(metrics: [Metric], entries: [MetricEntry], urges: [UrgeEvent], dayNotes: [DayNote] = [], now: Date) {
        recentDays = dayNotes
            .sorted { $0.day > $1.day }
            .prefix(5)
            .map { note in
                DayNoteRow(
                    id: note.id,
                    day: note.day.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(locale)),
                    systemImage: note.mood?.systemImage ?? "note.text",
                    text: RecoveryCopy.moodLine(note.mood, note: note.text)
                )
            }
        let ordered = metrics.sorted { $0.sortOrder < $1.sortOrder }
        active = ordered.filter { !$0.isArchived }.map { card(for: $0, entries: entries, now: now) }
        archived = ordered.filter(\.isArchived).map { card(for: $0, entries: entries, now: now) }

        let savedValues = ordered.filter { !$0.isArchived && $0.habitType == .vice }.compactMap { metric -> Decimal? in
            if metric.isCuttingBack {
                let history = Snapshots.cutBackHistory(for: metric, entries: entries, calendar: calendar)
                return CutBackMath.moneySaved(
                    unitsAvoided: CutBackMath.unitsAvoided(history, now: now, calendar: calendar),
                    baseline: history.baseline,
                    costPerDay: metric.costPerDay
                )
            }
            let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
            return RecoveryMath.moneySaved(totalFreeDays: RecoveryMath.totalFreeDays(history, now: now, calendar: calendar), costPerDay: metric.costPerDay)
        }
        let saved = savedValues.reduce(Decimal(0), +)
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -29, to: today) ?? today
        let window = Set(DayMath.days(from: start, through: today, calendar: calendar))
        let logged = Set(entries.map { calendar.startOfDay(for: $0.day) })
        summary = ProgressSummary(
            savedText: saved > 0 ? RecoveryCopy.saved(saved, locale: locale) : nil,
            urgesBeaten: PatternInsights.urgeSummary(urges.map(\.outcome)).beaten,
            daysCheckedIn: logged.intersection(window).count
        )
    }

    func moveActive(from offsets: IndexSet, to destination: Int, metrics: [Metric], store: RecoveryStore) throws {
        var rows = active
        rows.move(fromOffsets: offsets, toOffset: destination)
        let byID = Dictionary(uniqueKeysWithValues: metrics.map { ($0.id, $0) })
        let ordered = rows.compactMap { byID[$0.id] } + archived.compactMap { byID[$0.id] }
        try store.reorder(ordered)
        active = rows
    }

    private func card(for metric: Metric, entries: [MetricEntry], now: Date) -> ProgressCardModel {
        let line: String
        if metric.isCuttingBack {
            let history = Snapshots.cutBackHistory(for: metric, entries: entries, calendar: calendar)
            let window = CutBackMath.withinDays(inLast: 30, history, now: now, calendar: calendar)
            line = RecoveryCopy.cutBackProgress(
                today: RecoveryCopy.todayAmount(CutBackMath.amount(on: now, history, calendar: calendar), limit: history.limit, unit: metric.unitLabel),
                average: CutBackMath.average(inLast: 7, history, now: now, calendar: calendar).map { RecoveryCopy.averageShort($0) },
                within: window.within,
                logged: window.logged
            )
        } else if metric.habitType == .vice {
            let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
            let window = RecoveryMath.freeDays(inLast: 30, history, now: now, calendar: calendar)
            line = RecoveryCopy.viceProgress(
                days: RecoveryMath.currentRunDays(history, now: now, calendar: calendar),
                longest: RecoveryMath.longestRunDays(history, now: now, calendar: calendar),
                free: window.free,
                counted: window.counted
            )
        } else {
            let history = Snapshots.habitHistory(for: metric, entries: entries, calendar: calendar)
            line = RecoveryCopy.habitProgress(
                run: HabitMath.currentRun(history, now: now, calendar: calendar),
                best: HabitMath.bestRun(history, now: now, calendar: calendar),
                done: HabitMath.doneCount(inLast: 30, history, now: now, calendar: calendar),
                counted: 30
            )
        }
        return ProgressCardModel(id: metric.id, name: metric.name, iconName: metric.iconName, habitType: metric.habitType, line: line, isArchived: metric.isArchived)
    }
}
