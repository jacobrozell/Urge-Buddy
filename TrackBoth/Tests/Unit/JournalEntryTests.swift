import SwiftData
import XCTest
@testable import TrackBoth

@MainActor
final class JournalEntryTests: XCTestCase {
    func testSavedNotesCarryTheRideAndSkipEverythingElse() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(
            name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil
        )
        let kept = try store.startUrge(for: alcohol, intensity: 4, now: date(2026, 10, 12, 21, 15))
        try store.finishUrge(kept, outcome: .resisted, triggers: [.tired, .stressed], note: "Mornings.", now: date(2026, 10, 12, 21, 22))
        let older = try store.startUrge(for: alcohol, intensity: 2, now: date(2026, 10, 10, 18))
        try store.finishUrge(older, outcome: .unknown, triggers: [], note: "Not sure why.", now: date(2026, 10, 10, 18, 8))
        let dropped = try store.startUrge(for: alcohol, intensity: 5, now: date(2026, 10, 11, 19))
        try store.finishUrge(dropped, outcome: .slipped, triggers: [.bored], note: nil, now: date(2026, 10, 11, 19, 4))
        let open = try store.startUrge(for: alcohol, intensity: 3, now: date(2026, 10, 13, 9))
        open.note = "Still writing"

        let locale = Locale(identifier: "en_US")
        let entries = JournalEntry.make(urges: [kept, older, dropped, open], metrics: [alcohol], locale: locale)
        XCTAssertEqual(entries.map(\.text), ["Mornings.", "Not sure why."])
        XCTAssertEqual(entries.map(\.id), [kept.id, older.id])

        let first = try XCTUnwrap(entries.first)
        XCTAssertEqual(first.metricName, "Alcohol")
        XCTAssertEqual(first.outcome, RecoveryCopy.rodeItOut)
        XCTAssertEqual(first.strength, "4 of 5")
        XCTAssertEqual(first.triggers, "Tired, Stressed")
        XCTAssertEqual(first.when, date(2026, 10, 12, 21, 15).formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale)))
        XCTAssertEqual(first.ended, date(2026, 10, 12, 21, 22).formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale)))
        XCTAssertEqual(entries[1].outcome, RecoveryCopy.notSureOutcome)
        XCTAssertNil(entries[1].triggers)
    }

    func testAMissingMetricStillShowsTheNote() throws {
        let harness = try TestHarness()
        let urge = UrgeEvent(metricID: UUID(), intensity: 1, startedAt: date(2026, 10, 1, 8))
        urge.outcome = .resisted
        urge.note = "Kept"
        harness.container.mainContext.insert(urge)
        let entries = JournalEntry.make(urges: [urge], metrics: [], locale: Locale(identifier: "en_US"))
        XCTAssertEqual(entries.first?.metricName, "—")
        XCTAssertEqual(entries.first?.text, "Kept")
    }
}
