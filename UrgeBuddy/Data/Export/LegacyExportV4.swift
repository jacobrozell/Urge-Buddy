import Foundation

enum LegacyExportV4 {
    struct Payload: Codable, Equatable {
        let schemaVersion: Int
        let metrics: [MetricRecord]
        let entries: [EntryRecord]
        let goals: [GoalRecord]?
        let exportDate: Date
    }

    struct MetricRecord: Codable, Equatable {
        let id: String
        let name: String
        let createdAt: Date
        let habitType: String
        let hasBeenLogged: Bool?
        let primaryMotivation: String?
        let costPerUnit: String?
    }

    struct GoalRecord: Codable, Equatable {
        let id: String
        let metricID: String
        let goalType: String
        let period: String
        let target: Int
        let createdAt: Date
        let quantityGoalType: String?
        let defaultUnit: String?
        let maxDailyQuantity: Int?
    }

    struct EntryRecord: Codable, Equatable {
        let id: String
        let metricID: String
        let date: Date
        let value: Bool
        let details: String?
        let motivation: String?
        let starred: Bool?
        let quantity: Int?
        let unit: String?
        let mood: String?
        let hasBeenLogged: Bool?
    }
}
