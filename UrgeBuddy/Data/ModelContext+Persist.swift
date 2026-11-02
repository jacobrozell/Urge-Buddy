import Foundation
import SwiftData

// MARK: - ModelContext Persistence
extension ModelContext {
    /// Persists pending changes and logs success or failure.
    @discardableResult
    func saveChanges(operation: String, entity: String = "Model") -> Bool {
        do {
            try save()
            logger.logDataOperation("SAVE", entity: entity, success: true)
            return true
        } catch {
            logger.logError(error, context: "Failed to save: \(operation)")
            logger.logDataOperation("SAVE", entity: entity, success: false)
            return false
        }
    }
}
