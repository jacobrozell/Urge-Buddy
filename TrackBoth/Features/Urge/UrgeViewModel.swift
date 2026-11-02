import Foundation
import Observation
import SwiftData

enum UrgeStep: Equatable {
    case choose
    case intensity
    case ride
    case passed
    case unsure
    case empty
}

enum JournalChoice: Equatable {
    case undecided
    case save
    case discard
}

@MainActor
@Observable
final class UrgeViewModel {
    private let store: RecoveryStore
    private(set) var step: UrgeStep = .choose
    private(set) var vices: [Metric] = []
    var selectedID: UUID?
    var intensity = 3
    var endDate = Date()
    private(set) var duration: TimeInterval = 5 * 60
    var triggers: Set<TriggerTag> = []
    var journalText = ""
    var journalChoice: JournalChoice = .undecided
    private(set) var urge: UrgeEvent?
    private(set) var beaten = 0

    var trimmedJournal: String? {
        let value = journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var hasJournal: Bool { trimmedJournal != nil }

    /// True when they wrote something and have not chosen save or delete yet.
    var needsJournalChoice: Bool {
        hasJournal && journalChoice == .undecided
    }

    init(store: RecoveryStore) {
        self.store = store
    }

    var calendar: Calendar { store.calendar }

    func start(metrics: [Metric], preferredID: UUID?, now: Date) {
        vices = metrics.filter { $0.habitType == .vice && !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
        if vices.isEmpty {
            step = .empty
            return
        }
        if let preferredID, vices.contains(where: { $0.id == preferredID }) {
            selectedID = preferredID
            step = .intensity
        } else if vices.count == 1 {
            selectedID = vices[0].id
            step = .intensity
        } else {
            step = .choose
        }
        endDate = now.addingTimeInterval(5 * 60)
    }

    func choose(_ id: UUID) {
        selectedID = id
        step = .intensity
    }

    func begin(metrics: [Metric], now: Date) throws {
        guard let metric = metrics.first(where: { $0.id == selectedID }) else { return }
        urge = try store.startUrge(for: metric, intensity: intensity, now: now)
        endDate = now.addingTimeInterval(5 * 60)
        duration = 5 * 60
        step = .ride
    }

    func remaining(at now: Date) -> TimeInterval {
        max(0, endDate.timeIntervalSince(now))
    }

    /// 1 when the timer starts or is topped up, 0 when it runs out.
    func progress(at now: Date) -> Double {
        duration > 0 ? remaining(at: now) / duration : 0
    }

    func addFiveMinutes(now: Date) {
        let base = max(endDate, now)
        endDate = base.addingTimeInterval(5 * 60)
        duration = endDate.timeIntervalSince(now)
    }

    func passed(now: Date) throws {
        try finish(.resisted, now: now)
        step = .passed
    }

    func markNotSure(now: Date, keepJournal: Bool = false) throws {
        try finish(.unknown, now: now, keepJournal: keepJournal)
        step = .unsure
    }

    func markSlipped(now: Date, keepJournal: Bool = false) throws {
        try finish(.slipped, now: now, keepJournal: keepJournal)
    }

    /// Saves or clears the ride note, and stores triggers picked on the outcome screen.
    func commitReflection(keepJournal: Bool) throws {
        guard let urge else { return }
        try store.updateUrgeReflection(urge, triggers: Array(triggers), note: keepJournal ? journalText : nil)
    }

    private func finish(_ outcome: UrgeOutcome, now: Date, keepJournal: Bool = false) throws {
        guard let urge else { return }
        try store.finishUrge(
            urge,
            outcome: outcome,
            triggers: Array(triggers),
            note: keepJournal ? journalText : nil,
            now: now
        )
        let urges = try store.context.fetch(FetchDescriptor<UrgeEvent>())
        beaten = PatternInsights.urgeSummary(urges.map(\.outcome)).beaten
    }
}
