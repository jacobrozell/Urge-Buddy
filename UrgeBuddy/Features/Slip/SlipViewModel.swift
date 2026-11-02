import Foundation

enum SlipWhen: Equatable {
    case justNow
    case earlierToday
    case yesterday
    case picked(Date)

    func occurredAt(now: Date, calendar: Calendar) -> Date {
        switch self {
        case .justNow, .earlierToday:
            return now
        case .yesterday:
            let start = calendar.startOfDay(for: now)
            return calendar.date(byAdding: .second, value: -1, to: start) ?? now
        case .picked(let day):
            if calendar.isDate(day, inSameDayAs: now) { return now }
            return DayMath.endOfDay(day, calendar: calendar)
        }
    }

    /// The slip flow opened from a calendar day. Today stays "just now".
    static func forEditing(day: Date, now: Date, calendar: Calendar) -> SlipWhen {
        if calendar.isDate(day, inSameDayAs: now) { return .justNow }
        let today = calendar.startOfDay(for: now)
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(day, inSameDayAs: yesterday) {
            return .yesterday
        }
        return .picked(day)
    }
}

struct SlipSummary: Equatable {
    var title: String
    var body: String
    var reason: String?
}

@MainActor
@Observable
final class SlipViewModel {
    private let store: RecoveryStore
    var when: SlipWhen = .justNow
    var triggers: Set<TriggerTag>
    var note: String = ""
    var plan: String
    var summary: SlipSummary?
    var errorMessage: String?

    private let originalPlan: String

    init(store: RecoveryStore, plan: String?, triggers: [TriggerTag], when: SlipWhen = .justNow) {
        self.store = store
        self.plan = plan ?? ""
        self.originalPlan = plan ?? ""
        self.triggers = Set(triggers)
        self.when = when
    }

    var calendar: Calendar { store.calendar }

    func save(metric: Metric, now: Date, locale: Locale = .current) throws {
        let moment = when.occurredAt(now: now, calendar: calendar)
        do {
            try store.logSlip(metric, occurredAt: moment, triggers: triggers.sorted { $0.rawValue < $1.rawValue }, note: note)
        } catch RecoveryStoreError.slipBeforeStart {
            errorMessage = RecoveryCopy.slipBeforeStart
            throw RecoveryStoreError.slipBeforeStart
        }
        let updated = plan.trimmingCharacters(in: .whitespacesAndNewlines)
        if updated != originalPlan {
            try store.setPlan(metric, plan: updated.isEmpty ? nil : updated)
        }
        summary = try makeSummary(metric: metric, now: now, locale: locale)
    }

    /// Summary from the days already stored. Does not log a new slip.
    func loadExistingSummary(metric: Metric, now: Date, locale: Locale = .current) throws {
        summary = try makeSummary(metric: metric, now: now, locale: locale)
    }

    private func makeSummary(metric: Metric, now: Date, locale: Locale) throws -> SlipSummary {
        let entries = try store.entries(for: metric.id)
        let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
        let window = RecoveryMath.freeDays(inLast: 30, history, now: now, calendar: calendar)
        let saved = RecoveryMath.moneySaved(
            totalFreeDays: RecoveryMath.totalFreeDays(history, now: now, calendar: calendar),
            costPerDay: metric.costPerDay
        ).map { RecoveryCopy.money($0, locale: locale) }
        let reason = try store.reasons(for: metric.id).sorted { $0.sortOrder < $1.sortOrder }.first?.text
        return SlipSummary(
            title: RecoveryCopy.slipSummaryTitle,
            body: RecoveryCopy.slipSummaryBody(free: window.free, counted: window.counted, saved: saved),
            reason: reason
        )
    }
}
