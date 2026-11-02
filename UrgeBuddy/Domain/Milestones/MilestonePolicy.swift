import Foundation

enum MilestonePolicy {
    static let viceDays = [1, 3, 7, 14, 30, 60, 90, 180, 270, 365]
    static let habitRuns = [3, 7, 14, 30, 60, 100, 200, 365]

    /// Every threshold reached by `value`, including yearly ones after 365 (730, 1095, …).
    static func reached(_ value: Int, isVice: Bool) -> [Int] {
        let base = (isVice ? viceDays : habitRuns).filter { $0 <= value }
        let yearly = value >= 730 ? Array(stride(from: 730, through: value, by: 365)) : []
        return base + yearly
    }

    static func next(after value: Int, isVice: Bool) -> Int {
        let list = isVice ? viceDays : habitRuns
        return list.first { $0 > value } ?? ((value / 365) + 1) * 365
    }

    /// Celebrate only the HIGHEST newly reached threshold (no stacked celebrations after backfills).
    static func pending(value: Int, isVice: Bool, highestCelebrated: Int) -> Int? {
        let effectiveHighest = value < highestCelebrated ? 0 : highestCelebrated
        guard let top = reached(value, isVice: isVice).last, top > effectiveHighest else { return nil }
        return top
    }
}
