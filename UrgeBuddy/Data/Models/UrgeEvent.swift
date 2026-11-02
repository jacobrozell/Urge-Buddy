import Foundation
import SwiftData

@Model
final class UrgeEvent {
    var id: UUID = UUID()
    var metricID: UUID = UUID()
    var startedAt: Date = Date()
    var endedAt: Date?
    var outcomeRaw: String = UrgeOutcome.inProgress.rawValue
    var intensity: Int = 3
    var triggersRaw: String = ""
    var note: String?

    init(metricID: UUID, intensity: Int, startedAt: Date = Date()) {
        self.metricID = metricID
        self.intensity = min(5, max(1, intensity))
        self.startedAt = startedAt
    }

    var outcome: UrgeOutcome {
        get { UrgeOutcome(rawValue: outcomeRaw) ?? .unknown }
        set { outcomeRaw = newValue.rawValue }
    }

    var triggers: [TriggerTag] {
        get { TriggerTag.decode(triggersRaw) }
        set { triggersRaw = TriggerTag.encode(newValue) }
    }
}
