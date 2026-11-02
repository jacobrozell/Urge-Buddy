import Foundation
import Observation

@MainActor
@Observable
final class MetricFormViewModel {
    var name: String
    var habitType: HabitType
    var iconName: String
    var startedAt: Date
    var costText: String
    var isArchived: Bool
    var viceMode: ViceMode
    var unit: String
    var tracksHabitAmount: Bool
    var targetText: String
    var baselineText: String
    let isNew: Bool
    private let originalMode: ViceMode?

    init(metric: Metric?, habitType: HabitType = .vice) {
        if let metric {
            name = metric.name
            self.habitType = metric.habitType
            iconName = metric.iconName
            startedAt = metric.startedAt
            costText = metric.costPerDay.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
            isArchived = metric.isArchived
            viceMode = metric.viceMode
            unit = metric.unit ?? ""
            tracksHabitAmount = metric.habitType == .positive && metric.dailyTarget != nil
            targetText = metric.dailyTarget.map(String.init) ?? ""
            baselineText = metric.baselinePerDay.map(String.init) ?? ""
            isNew = false
            originalMode = metric.habitType == .vice ? metric.viceMode : nil
        } else {
            name = ""
            self.habitType = habitType
            iconName = (habitType == .positive ? Presets.habits.first : Presets.vices.first)?.iconName ?? Presets.fallbackIcon
            startedAt = Date()
            costText = ""
            isArchived = false
            viceMode = .quit
            unit = ""
            tracksHabitAmount = false
            targetText = ""
            baselineText = ""
            isNew = true
            originalMode = nil
        }
    }

    var showsTypePicker: Bool { isNew }
    var showsModePicker: Bool { habitType == .vice }
    var isCuttingBack: Bool { habitType == .vice && viceMode == .cutBack }
    var showsQuitDate: Bool { habitType == .vice && viceMode == .quit }
    var showsCost: Bool { habitType == .vice }
    var showsAmountFields: Bool { isCuttingBack || (habitType == .positive && tracksHabitAmount) }
    var costLabel: String { isCuttingBack ? RecoveryCopy.costAtUsual : RecoveryCopy.costPerDay }
    var targetLabel: String { isCuttingBack ? RecoveryCopy.dailyLimit : RecoveryCopy.dailyTarget }

    var nameError: String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return RecoveryCopy.nameRequired }
        if trimmed.count > 40 { return RecoveryCopy.nameTooLong }
        return nil
    }

    var targetError: String? {
        guard showsAmountFields else { return nil }
        if isCuttingBack {
            return target == nil ? RecoveryCopy.limitRequired : nil
        }
        return (target ?? 0) < 1 ? RecoveryCopy.targetRequired : nil
    }

    var canSave: Bool { nameError == nil && targetError == nil }

    var cost: Decimal? {
        let trimmed = costText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = Decimal(string: trimmed), value > 0 else { return nil }
        return value
    }

    var target: Int? { Self.wholeNumber(targetText) }
    var baseline: Int? { Self.wholeNumber(baselineText).flatMap { $0 > 0 ? $0 : nil } }

    var tracking: MetricTracking {
        switch habitType {
        case .positive:
            MetricTracking(unit: unit, dailyTarget: tracksHabitAmount ? target : nil)
        case .vice:
            viceMode == .cutBack
                ? MetricTracking(viceMode: .cutBack, unit: unit, dailyTarget: target, baselinePerDay: baseline)
                : MetricTracking(viceMode: .quit)
        }
    }

    var icons: [String] {
        var seen = Set<String>()
        return (Presets.vices.map(\.iconName) + Presets.habits.map(\.iconName) + Presets.extraIconNames).filter { seen.insert($0).inserted }
    }

    func save(metric: Metric?, store: RecoveryStore, now: Date) throws -> Metric {
        guard canSave else { throw MetricFormError.invalid }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let metric {
            try store.update(metric, name: trimmed, iconName: iconName, startedAt: startDate(existing: metric, now: now), costPerDay: habitType == .vice ? cost : nil, tracking: tracking)
            if metric.isArchived != isArchived {
                try store.setArchived(metric, isArchived)
            }
            return metric
        }
        return try store.addMetric(name: trimmed, habitType: habitType, iconName: iconName, startedAt: startDate(existing: nil, now: now), costPerDay: habitType == .vice ? cost : nil, firstReason: nil, tracking: tracking)
    }

    func delete(_ metric: Metric, store: RecoveryStore) throws {
        try store.delete(metric)
    }

    /// Quit uses the picked quit date. Cut back starts today when the mode is new; otherwise the start date stays.
    private func startDate(existing: Metric?, now: Date) -> Date {
        if showsQuitDate { return startedAt }
        if isCuttingBack, originalMode != .cutBack { return now }
        return existing?.startedAt ?? now
    }

    private static func wholeNumber(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmed), value >= 0 else { return nil }
        return value
    }
}

enum MetricFormError: Error {
    case invalid
}
