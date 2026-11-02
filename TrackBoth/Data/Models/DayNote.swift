import Foundation
import SwiftData

/// One mood and note per calendar day, shared across metrics.
@Model
final class DayNote {
    var id: UUID = UUID()
    /// Local-noon anchor of the calendar day (DayMath.anchor).
    var day: Date = Date()
    /// `Mood` raw value. 0 means no mood picked.
    var moodRaw: Int = 0
    var text: String?
    var updatedAt: Date = Date()

    init(day: Date, mood: Mood?, text: String?, updatedAt: Date) {
        self.day = day
        self.moodRaw = mood?.rawValue ?? 0
        self.text = text
        self.updatedAt = updatedAt
    }

    var mood: Mood? {
        get { Mood(rawValue: moodRaw) }
        set { moodRaw = newValue?.rawValue ?? 0 }
    }
}
