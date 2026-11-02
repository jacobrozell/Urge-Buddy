import Foundation

struct CelebrationRequest: Identifiable, Equatable {
    var metricID: UUID
    var name: String
    var threshold: Int
    var isVice: Bool
    var reason: String?
    var id: UUID { metricID }
}

enum MilestoneCenter {
    /// One celebration per metric: the highest threshold newly reached. Vices first, then habits, in sort order.
    static func pending(metrics: [Metric], entries: [MetricEntry], reasons: [Reason], now: Date, calendar: Calendar) -> [CelebrationRequest] {
        let active = metrics.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
        let vices = active.filter(\.isQuitting)
        let habits = active.filter { $0.habitType == .positive }
        return (vices + habits).compactMap { metric in
            let isVice = metric.habitType == .vice
            let value = isVice
                ? RecoveryMath.currentRunDays(Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar), now: now, calendar: calendar)
                : HabitMath.currentRun(Snapshots.habitHistory(for: metric, entries: entries, calendar: calendar), now: now, calendar: calendar)
            guard let threshold = MilestonePolicy.pending(
                value: value,
                isVice: isVice,
                highestCelebrated: MilestoneLedger.highestCelebrated(for: metric.id)
            ) else { return nil }
            let reason = reasons.filter { $0.metricID == metric.id }.sorted { $0.sortOrder < $1.sortOrder }.first?.text
            return CelebrationRequest(metricID: metric.id, name: metric.name, threshold: threshold, isVice: isVice, reason: reason)
        }
    }
}
