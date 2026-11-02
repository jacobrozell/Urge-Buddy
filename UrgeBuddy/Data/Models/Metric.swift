import Foundation
import SwiftData

@Model
final class Metric {
    var id: UUID = UUID()
    var name: String = ""
    var habitType: HabitType = HabitType.vice
    var iconName: String = "circle.dashed"
    var createdAt: Date = Date()
    /// Vice: when the current quit attempt began. Habit: when tracking began.
    var startedAt: Date = Date()
    /// Vice only. Money the vice cost per day, decimal string, e.g. "12.50".
    var costPerDayRaw: String?
    /// Vice only. "When I feel the urge, I will …"
    var ifThenPlan: String?
    var sortOrder: Int = 0
    var isArchived: Bool = false
    /// Vice only. `ViceMode` raw value.
    var viceModeRaw: String = ViceMode.quit.rawValue
    /// What an amount counts, e.g. "cigarettes" or "glasses".
    var unit: String?
    /// Habit: the amount that completes a day. Cut back: the most per day. Nil on yes/no habits and quit vices.
    var dailyTarget: Int?
    /// Cut back only. How many a day before cutting back.
    var baselinePerDay: Int?

    init(name: String, habitType: HabitType, iconName: String, startedAt: Date = Date(), sortOrder: Int = 0) {
        self.name = name
        self.habitType = habitType
        self.iconName = iconName
        self.startedAt = startedAt
        self.sortOrder = sortOrder
    }

    var costPerDay: Decimal? {
        get {
            guard let costPerDayRaw, let value = Decimal(string: costPerDayRaw), value > 0 else { return nil }
            return value
        }
        set {
            if let newValue, newValue > 0 {
                costPerDayRaw = NSDecimalNumber(decimal: newValue).stringValue
            } else {
                costPerDayRaw = nil
            }
        }
    }

    var viceMode: ViceMode {
        get { ViceMode(rawValue: viceModeRaw) ?? .quit }
        set { viceModeRaw = newValue.rawValue }
    }

    var isQuitting: Bool { habitType == .vice && viceMode == .quit }
    var isCuttingBack: Bool { habitType == .vice && viceMode == .cutBack }

    /// Logged as a count each day instead of yes/no.
    var tracksAmount: Bool {
        isCuttingBack || (habitType == .positive && dailyTarget != nil)
    }

    var unitLabel: String {
        let trimmed = unit?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? AmountMath.defaultUnit : trimmed
    }
}
