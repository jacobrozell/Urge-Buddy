import Foundation

enum Mood: Int, CaseIterable, Codable, Identifiable {
    case rough = 1
    case low
    case okay
    case good
    case great

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .rough: "Rough"
        case .low: "Low"
        case .okay: "Okay"
        case .good: "Good"
        case .great: "Great"
        }
    }

    var systemImage: String {
        switch self {
        case .rough: "cloud.bolt.rain"
        case .low: "cloud.drizzle"
        case .okay: "cloud"
        case .good: "cloud.sun"
        case .great: "sun.max"
        }
    }
}
