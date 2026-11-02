import Foundation
import SwiftData

@Model
final class Reason {
    var id: UUID = UUID()
    var metricID: UUID = UUID()
    var text: String = ""
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    init(metricID: UUID, text: String, sortOrder: Int) {
        self.metricID = metricID
        self.text = text
        self.sortOrder = sortOrder
    }
}
