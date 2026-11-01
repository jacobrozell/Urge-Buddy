import Foundation

enum TimeOfDay: String, CaseIterable, Equatable {
    case morning, afternoon, evening, night

    var title: String {
        switch self {
        case .morning: "Morning"
        case .afternoon: "Afternoon"
        case .evening: "Evenings"
        case .night: "Night"
        }
    }

    static func bucket(for date: Date, calendar: Calendar) -> TimeOfDay {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default: return .night
        }
    }
}

enum PatternInsights {
    /// Count across slips and urges. Sort by count, then `TriggerTag.allCases` order.
    /// `.other` is dropped unless it is the only tag present.
    static func topTriggers(from groups: [[TriggerTag]], limit: Int = 3) -> [(TriggerTag, Int)] {
        var counts: [TriggerTag: Int] = [:]
        for group in groups {
            for tag in group {
                counts[tag, default: 0] += 1
            }
        }
        let order = TriggerTag.allCases
        let ranked = counts.keys.sorted { lhs, rhs in
            let leftCount = counts[lhs, default: 0]
            let rightCount = counts[rhs, default: 0]
            if leftCount != rightCount { return leftCount > rightCount }
            return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
        }
        let withoutOther = ranked.filter { $0 != .other }
        let chosen = withoutOther.isEmpty ? ranked : withoutOther
        return chosen.prefix(limit).map { ($0, counts[$0, default: 0]) }
    }

    /// The busiest bucket among slips and non-resisted urges.
    /// `nil` when there are fewer than 3 timestamps or a tie for first.
    static func hardestTime(from timestamps: [Date], calendar: Calendar = .current) -> TimeOfDay? {
        guard timestamps.count >= 3 else { return nil }
        var counts: [TimeOfDay: Int] = [:]
        for timestamp in timestamps {
            let bucket = TimeOfDay.bucket(for: timestamp, calendar: calendar)
            counts[bucket, default: 0] += 1
        }
        let maxCount = counts.values.max() ?? 0
        let leaders = TimeOfDay.allCases.filter { (counts[$0] ?? 0) == maxCount }
        return leaders.count == 1 ? leaders[0] : nil
    }

    static func urgeSummary(_ outcomes: [UrgeOutcome]) -> (beaten: Int, total: Int) {
        let breakdown = urgeBreakdown(outcomes.map { UrgeSample(outcome: $0, intensity: 0) })
        return (breakdown.beaten, breakdown.total)
    }

    /// Finished urges only. In-progress events are left out of every count.
    static func urgeBreakdown(_ samples: [UrgeSample]) -> UrgeBreakdown {
        let finished = samples.filter { $0.outcome != .inProgress }
        let average: Double? = finished.isEmpty
            ? nil
            : Double(finished.map(\.intensity).reduce(0, +)) / Double(finished.count)
        return UrgeBreakdown(
            beaten: finished.filter { $0.outcome == .resisted }.count,
            slipped: finished.filter { $0.outcome == .slipped }.count,
            unsure: finished.filter { $0.outcome == .unknown }.count,
            total: finished.count,
            averageIntensity: average
        )
    }

    /// Weekday (`Calendar` component) with the most slips and non-resisted urges.
    /// `nil` when there are fewer than 3 timestamps or a tie for first.
    static func hardestWeekday(from timestamps: [Date], calendar: Calendar = .current) -> Int? {
        guard timestamps.count >= 3 else { return nil }
        var counts: [Int: Int] = [:]
        for timestamp in timestamps {
            let weekday = calendar.component(.weekday, from: timestamp)
            counts[weekday, default: 0] += 1
        }
        let maxCount = counts.values.max() ?? 0
        let leaders = counts.filter { $0.value == maxCount }.map(\.key)
        return leaders.count == 1 ? leaders[0] : nil
    }
}

struct UrgeSample: Equatable {
    var outcome: UrgeOutcome
    var intensity: Int
}

struct UrgeBreakdown: Equatable {
    var beaten: Int
    var slipped: Int
    var unsure: Int
    var total: Int
    var averageIntensity: Double?
}
