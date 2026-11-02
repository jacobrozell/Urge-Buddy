import Foundation

struct UrgeBuddyBackup: Codable, Equatable {
    var schemaVersion: Int
    var exportDate: Date
    var metrics: [MetricRecord]
    var entries: [EntryRecord]
    var urges: [UrgeRecord]
    var reasons: [ReasonRecord]
    /// v6+. Missing in v5 files.
    var dayNotes: [DayNoteRecord]?

    struct MetricRecord: Codable, Equatable {
        var id: String
        var name: String
        var habitType: String
        var iconName: String
        var createdAt: Date
        var startedAt: Date
        var costPerDay: String?
        var ifThenPlan: String?
        var sortOrder: Int
        var isArchived: Bool
        var viceMode: String?
        var unit: String?
        var dailyTarget: Int?
        var baselinePerDay: Int?
    }

    struct EntryRecord: Codable, Equatable {
        var id: String
        var metricID: String
        var day: Date
        var status: String
        var occurredAt: Date
        var note: String?
        var triggers: [String]
        var amount: Int?
    }

    struct DayNoteRecord: Codable, Equatable {
        var id: String
        var day: Date
        var mood: Int?
        var text: String?
        var updatedAt: Date
    }

    struct UrgeRecord: Codable, Equatable {
        var id: String
        var metricID: String
        var startedAt: Date
        var endedAt: Date?
        var outcome: String
        var intensity: Int
        var triggers: [String]
        var note: String?
    }

    struct ReasonRecord: Codable, Equatable {
        var id: String
        var metricID: String
        var text: String
        var createdAt: Date
        var sortOrder: Int
    }
}
