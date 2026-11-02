import Foundation
import SwiftData

enum TrackBothSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Metric.self, MetricEntry.self, UrgeEvent.self, Reason.self, DayNote.self]
    }
}

enum TrackBothMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [TrackBothSchemaV2.self] }
    static var stages: [MigrationStage] { [] }
}
