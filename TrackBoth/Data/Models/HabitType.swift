import Foundation

enum HabitType: String, CaseIterable, Codable {
    case positive = "positive"
    case vice = "vice"
}

/// How a vice is tracked. Quit runs a free clock that a slip restarts. Cut back counts each day against a limit.
enum ViceMode: String, CaseIterable, Codable {
    case quit
    case cutBack
}
