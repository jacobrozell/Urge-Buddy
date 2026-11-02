import Foundation
import SwiftData

enum StoreRecoveryMode: Equatable {
    case normal
    case inMemoryFallback
}

struct BootstrapStoreRecovery {
    private(set) static var mode: StoreRecoveryMode = .normal

    static func makeContainer() -> ModelContainer {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ui_testing") {
            clearDefaultsForUITesting()
            mode = .normal
            return makeInMemoryContainer(schema: schema)
        }
        return makeContainer(opening: { try openPersistentStore() })
    }

    static func makeContainer(opening: () throws -> ModelContainer) -> ModelContainer {
        do {
            let container = try opening()
            mode = .normal
            return container
        } catch {
            logger.error("SwiftData persistent store failed: \(error.localizedDescription)", category: .data)
            logger.warn("Falling back to in-memory store", category: .data)
            mode = .inMemoryFallback
            return makeInMemoryContainer(schema: schema)
        }
    }

    static func resetModeForTesting() {
        mode = .normal
    }

    private static var schema: Schema {
        Schema(versionedSchema: UrgeBuddySchemaV2.self)
    }

    private static func openPersistentStore() throws -> ModelContainer {
        let config = ModelConfiguration("TrackBothV2", schema: schema)
        return try ModelContainer(for: schema, migrationPlan: UrgeBuddyMigrationPlan.self, configurations: [config])
    }

    private static func makeInMemoryContainer(schema: Schema) -> ModelContainer {
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            logger.fatal("In-memory store failed: \(error.localizedDescription)", category: .data)
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private static func clearDefaultsForUITesting() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        Preferences.resetAll()
        MilestoneLedger.clearAll()
    }
}
