import Foundation
import SwiftData

enum RecoveryStoreError: Error, Equatable {
    case saveFailed
    case slipBeforeStart
}

/// How a metric is logged. Defaults to yes/no (habits) or quit (vices).
struct MetricTracking: Equatable {
    var viceMode: ViceMode = .quit
    var unit: String?
    var dailyTarget: Int?
    var baselinePerDay: Int?

    static let yesNo = MetricTracking()
}

extension Notification.Name {
    static let recoveryDataChanged = Notification.Name("UrgeBuddy.recoveryDataChanged")
}

@MainActor
final class RecoveryStore {
    let context: ModelContext
    var calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    // MARK: Metrics

    @discardableResult
    func addMetric(
        name: String,
        habitType: HabitType,
        iconName: String,
        startedAt: Date,
        costPerDay: Decimal?,
        firstReason: String?,
        tracking: MetricTracking = .yesNo
    ) throws -> Metric {
        let metric = Metric(name: name, habitType: habitType, iconName: iconName, startedAt: startedAt, sortOrder: try nextSortOrder())
        metric.costPerDay = costPerDay
        apply(tracking, to: metric)
        context.insert(metric)
        if let firstReason = trimmed(firstReason) {
            context.insert(Reason(metricID: metric.id, text: firstReason, sortOrder: 0))
        }
        try persist(operation: "addMetric", entity: "Metric")
        return metric
    }

    func update(_ metric: Metric, name: String, iconName: String, startedAt: Date, costPerDay: Decimal?, tracking: MetricTracking? = nil) throws {
        metric.name = name
        metric.iconName = iconName
        metric.startedAt = startedAt
        metric.costPerDay = costPerDay
        if let tracking { apply(tracking, to: metric) }
        try persist(operation: "updateMetric", entity: "Metric")
    }

    func setPlan(_ metric: Metric, plan: String?) throws {
        metric.ifThenPlan = trimmed(plan)
        try persist(operation: "setPlan", entity: "Metric")
    }

    func setArchived(_ metric: Metric, _ archived: Bool) throws {
        metric.isArchived = archived
        try persist(operation: "setArchived", entity: "Metric")
    }

    func reorder(_ metrics: [Metric]) throws {
        for (index, metric) in metrics.enumerated() {
            metric.sortOrder = index
        }
        try persist(operation: "reorder", entity: "Metric")
    }

    func delete(_ metric: Metric) throws {
        let id = metric.id
        for entry in try entries(for: id) { context.delete(entry) }
        for urge in try urges(for: id) { context.delete(urge) }
        for reason in try reasons(for: id) { context.delete(reason) }
        context.delete(metric)
        MilestoneLedger.reset(for: id)
        try persist(operation: "deleteMetric", entity: "Metric")
    }

    // MARK: Days

    func markFree(_ metric: Metric, on day: Date, now: Date = Date()) throws {
        if let existing = try entry(for: metric.id, on: day) {
            guard existing.status != .slipped else { return }
            existing.status = .free
            existing.day = DayMath.anchor(day, calendar: calendar)
            existing.occurredAt = now
        } else {
            context.insert(MetricEntry(
                metricID: metric.id,
                day: DayMath.anchor(day, calendar: calendar),
                status: .free,
                occurredAt: now
            ))
        }
        try persist(operation: "markFree", entity: "MetricEntry")
    }

    func logSlip(_ metric: Metric, occurredAt: Date, triggers: [TriggerTag], note: String?) throws {
        let start = calendar.startOfDay(for: metric.startedAt)
        guard occurredAt >= start else { throw RecoveryStoreError.slipBeforeStart }
        if let existing = try entry(for: metric.id, on: occurredAt) {
            existing.status = .slipped
            existing.day = DayMath.anchor(occurredAt, calendar: calendar)
            existing.occurredAt = occurredAt
            existing.triggers = triggers
            existing.note = trimmed(note)
        } else {
            let entry = MetricEntry(
                metricID: metric.id,
                day: DayMath.anchor(occurredAt, calendar: calendar),
                status: .slipped,
                occurredAt: occurredAt
            )
            entry.triggers = triggers
            entry.note = trimmed(note)
            context.insert(entry)
        }
        try persist(operation: "logSlip", entity: "MetricEntry")
    }

    func setHabitDone(_ metric: Metric, on day: Date, done: Bool, now: Date = Date()) throws {
        if done, metric.tracksAmount {
            let current = try entry(for: metric.id, on: day)?.amount ?? 0
            try setAmount(metric, on: day, amount: max(current, metric.dailyTarget ?? 1), now: now)
            return
        }
        if done {
            if let existing = try entry(for: metric.id, on: day) {
                existing.status = .done
                existing.day = DayMath.anchor(day, calendar: calendar)
                existing.occurredAt = now
            } else {
                context.insert(MetricEntry(
                    metricID: metric.id,
                    day: DayMath.anchor(day, calendar: calendar),
                    status: .done,
                    occurredAt: now
                ))
            }
        } else if let existing = try entry(for: metric.id, on: day) {
            context.delete(existing)
        } else {
            return
        }
        try persist(operation: "setHabitDone", entity: "MetricEntry")
    }

    /// Amount habits and cut-back vices. A cut-back zero is still a logged day. An amount habit at zero has no entry.
    func setAmount(_ metric: Metric, on day: Date, amount: Int, now: Date = Date()) throws {
        guard metric.tracksAmount else { return }
        let amount = max(0, amount)
        let existing = try entry(for: metric.id, on: day)
        let status: EntryStatus?
        if metric.isCuttingBack {
            status = AmountMath.isOverLimit(amount: amount, limit: metric.dailyTarget ?? 0) ? .over : .within
        } else if amount > 0 {
            status = AmountMath.isHabitDone(amount: amount, target: metric.dailyTarget ?? 1) ? .done : .partial
        } else {
            status = nil
        }
        if let status {
            let entry = existing ?? MetricEntry(metricID: metric.id, day: DayMath.anchor(day, calendar: calendar), status: status, occurredAt: now)
            if existing == nil { context.insert(entry) }
            entry.status = status
            entry.amount = amount
            entry.day = DayMath.anchor(day, calendar: calendar)
            entry.occurredAt = now
        } else if let existing {
            context.delete(existing)
        } else {
            return
        }
        try persist(operation: "setAmount", entity: "MetricEntry")
    }

    func addAmount(_ metric: Metric, _ delta: Int, on day: Date, now: Date = Date()) throws {
        let current = try entry(for: metric.id, on: day)?.amount ?? 0
        try setAmount(metric, on: day, amount: current + delta, now: now)
    }

    func clearDay(_ metric: Metric, on day: Date) throws {
        guard let existing = try entry(for: metric.id, on: day) else { return }
        context.delete(existing)
        try persist(operation: "clearDay", entity: "MetricEntry")
    }

    // MARK: Urges

    @discardableResult
    func startUrge(for metric: Metric, intensity: Int, now: Date = Date()) throws -> UrgeEvent {
        let urge = UrgeEvent(metricID: metric.id, intensity: intensity, startedAt: now)
        context.insert(urge)
        try persist(operation: "startUrge", entity: "UrgeEvent")
        return urge
    }

    func finishUrge(_ urge: UrgeEvent, outcome: UrgeOutcome, triggers: [TriggerTag], note: String?, now: Date = Date()) throws {
        urge.outcome = outcome
        urge.endedAt = now
        urge.triggers = triggers
        urge.note = trimmed(note)
        try persist(operation: "finishUrge", entity: "UrgeEvent")
    }

    /// Writes the ride-out note and the triggers picked after the timer. Does not change the outcome.
    func updateUrgeReflection(_ urge: UrgeEvent, triggers: [TriggerTag], note: String?) throws {
        urge.triggers = triggers
        urge.note = trimmed(note)
        try persist(operation: "updateUrgeReflection", entity: "UrgeEvent")
    }

    /// Removes a saved ride note. The urge and its outcome stay in the record.
    func deleteUrgeNote(id: UUID) throws {
        let predicate = #Predicate<UrgeEvent> { $0.id == id }
        guard let urge = try context.fetch(FetchDescriptor<UrgeEvent>(predicate: predicate)).first else { return }
        urge.note = nil
        try persist(operation: "deleteUrgeNote", entity: "UrgeEvent")
    }

    /// In-progress urges older than two hours become unknown. Called when the app becomes active.
    func resolveAbandonedUrges(now: Date = Date(), maxAge: TimeInterval = 2 * 60 * 60) throws {
        let cutoff = now.addingTimeInterval(-maxAge)
        let raw = UrgeOutcome.inProgress.rawValue
        let predicate = #Predicate<UrgeEvent> { $0.outcomeRaw == raw && $0.startedAt < cutoff }
        let stale = try context.fetch(FetchDescriptor<UrgeEvent>(predicate: predicate))
        guard !stale.isEmpty else { return }
        for urge in stale {
            urge.outcome = .unknown
            urge.endedAt = now
        }
        try persist(operation: "resolveAbandonedUrges", entity: "UrgeEvent")
    }

    // MARK: Reasons

    func addReason(_ text: String, to metric: Metric) throws {
        guard let text = trimmed(text) else { return }
        let next = (try reasons(for: metric.id).map(\.sortOrder).max() ?? -1) + 1
        context.insert(Reason(metricID: metric.id, text: text, sortOrder: next))
        try persist(operation: "addReason", entity: "Reason")
    }

    func updateReason(_ reason: Reason, text: String) throws {
        guard let text = trimmed(text) else { return }
        reason.text = text
        try persist(operation: "updateReason", entity: "Reason")
    }

    func deleteReason(_ reason: Reason) throws {
        context.delete(reason)
        try persist(operation: "deleteReason", entity: "Reason")
    }

    func reorderReasons(_ reasons: [Reason]) throws {
        for (index, reason) in reasons.enumerated() {
            reason.sortOrder = index
        }
        try persist(operation: "reorderReasons", entity: "Reason")
    }

    // MARK: Day notes

    func dayNote(on day: Date) throws -> DayNote? {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        let predicate = #Predicate<DayNote> { $0.day >= start && $0.day < end }
        return try context.fetch(FetchDescriptor<DayNote>(predicate: predicate)).first
    }

    /// Saves the day's mood and note. Clearing both removes the note.
    func setDayNote(on day: Date, mood: Mood?, text: String?, now: Date = Date()) throws {
        let text = trimmed(text)
        let existing = try dayNote(on: day)
        if mood == nil && text == nil {
            guard let existing else { return }
            context.delete(existing)
        } else if let existing {
            guard existing.mood != mood || existing.text != text else { return }
            existing.mood = mood
            existing.text = text
            existing.updatedAt = now
        } else {
            context.insert(DayNote(day: DayMath.anchor(day, calendar: calendar), mood: mood, text: text, updatedAt: now))
        }
        try persist(operation: "setDayNote", entity: "DayNote")
    }

    // MARK: Everything

    func deleteAllData() throws {
        try deleteAllObjects()
        guard context.saveChanges(operation: "deleteAllData", entity: "Store") else {
            throw RecoveryStoreError.saveFailed
        }
        Preferences.resetAll()
        MilestoneLedger.clearAll()
        NotificationCenter.default.post(name: .recoveryDataChanged, object: nil)
    }

    func replaceAll(metrics: [Metric], entries: [MetricEntry], urges: [UrgeEvent], reasons: [Reason], dayNotes: [DayNote] = []) throws {
        try deleteAllObjects()
        for metric in metrics { context.insert(metric) }
        for entry in entries { context.insert(entry) }
        for urge in urges { context.insert(urge) }
        for reason in reasons { context.insert(reason) }
        for note in dayNotes { context.insert(note) }
        guard context.saveChanges(operation: "replaceAll", entity: "Store") else {
            throw RecoveryStoreError.saveFailed
        }
        Preferences.resetAll()
        MilestoneLedger.clearAll()
        NotificationCenter.default.post(name: .recoveryDataChanged, object: nil)
    }

    // MARK: Fetch

    func entry(for metricID: UUID, on day: Date) throws -> MetricEntry? {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        let predicate = #Predicate<MetricEntry> { entry in
            entry.metricID == metricID && entry.day >= start && entry.day < end
        }
        return try context.fetch(FetchDescriptor<MetricEntry>(predicate: predicate)).first
    }

    func entries(for metricID: UUID) throws -> [MetricEntry] {
        let predicate = #Predicate<MetricEntry> { $0.metricID == metricID }
        return try context.fetch(FetchDescriptor<MetricEntry>(predicate: predicate))
    }

    func urges(for metricID: UUID) throws -> [UrgeEvent] {
        let predicate = #Predicate<UrgeEvent> { $0.metricID == metricID }
        return try context.fetch(FetchDescriptor<UrgeEvent>(predicate: predicate))
    }

    func reasons(for metricID: UUID) throws -> [Reason] {
        let predicate = #Predicate<Reason> { $0.metricID == metricID }
        return try context.fetch(FetchDescriptor<Reason>(predicate: predicate)).sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: Private

    private func nextSortOrder() throws -> Int {
        let metrics = try context.fetch(FetchDescriptor<Metric>())
        return (metrics.map(\.sortOrder).max() ?? -1) + 1
    }

    private func deleteAllObjects() throws {
        for metric in try context.fetch(FetchDescriptor<Metric>()) { context.delete(metric) }
        for entry in try context.fetch(FetchDescriptor<MetricEntry>()) { context.delete(entry) }
        for urge in try context.fetch(FetchDescriptor<UrgeEvent>()) { context.delete(urge) }
        for reason in try context.fetch(FetchDescriptor<Reason>()) { context.delete(reason) }
        for note in try context.fetch(FetchDescriptor<DayNote>()) { context.delete(note) }
    }

    private func apply(_ tracking: MetricTracking, to metric: Metric) {
        let unit = trimmed(tracking.unit)
        switch (metric.habitType, tracking.viceMode) {
        case (.positive, _):
            metric.viceMode = .quit
            metric.dailyTarget = tracking.dailyTarget.map { max(1, $0) }
            metric.unit = metric.dailyTarget == nil ? nil : unit
            metric.baselinePerDay = nil
        case (.vice, .quit):
            metric.viceMode = .quit
            metric.unit = nil
            metric.dailyTarget = nil
            metric.baselinePerDay = nil
        case (.vice, .cutBack):
            metric.viceMode = .cutBack
            metric.unit = unit
            metric.dailyTarget = max(0, tracking.dailyTarget ?? 0)
            metric.baselinePerDay = tracking.baselinePerDay.flatMap { $0 > 0 ? $0 : nil }
        }
    }

    private func persist(operation: String, entity: String) throws {
        guard context.saveChanges(operation: operation, entity: entity) else {
            throw RecoveryStoreError.saveFailed
        }
        NotificationCenter.default.post(name: .recoveryDataChanged, object: nil)
    }

    private func trimmed(_ text: String?) -> String? {
        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }
}
