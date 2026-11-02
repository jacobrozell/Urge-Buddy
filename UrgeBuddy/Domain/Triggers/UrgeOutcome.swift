import Foundation

/// Lives in Domain so insights stay Foundation-only. The SwiftData model stores the raw value.
enum UrgeOutcome: String, Codable, CaseIterable, Equatable {
    case inProgress, resisted, slipped, unknown
}
