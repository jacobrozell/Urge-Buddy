import SwiftData
import XCTest
@testable import TrackBoth

@MainActor
final class UrgeViewModelTests: XCTestCase {
    func testTimerExtendsFromTheLaterOfNowAndEnd() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        let model = UrgeViewModel(store: store)
        let now = date(2026, 10, 13, 10)
        model.start(metrics: [alcohol], preferredID: nil, now: now)
        try model.begin(metrics: [alcohol], now: now)
        XCTAssertEqual(model.remaining(at: now), 5 * 60, accuracy: 0.1)
        model.addFiveMinutes(now: now)
        XCTAssertEqual(model.remaining(at: now), 10 * 60, accuracy: 0.1)
        let later = now.addingTimeInterval(20 * 60)
        model.addFiveMinutes(now: later)
        XCTAssertEqual(model.remaining(at: later), 5 * 60, accuracy: 0.1)
    }

    func testPassedWritesResisted() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        let model = UrgeViewModel(store: store)
        let now = date(2026, 10, 13, 10)
        model.start(metrics: [alcohol], preferredID: nil, now: now)
        try model.begin(metrics: [alcohol], now: now)
        try model.passed(now: now)
        XCTAssertEqual(model.step, .passed)
        XCTAssertEqual(model.beaten, 1)
        let urge = try XCTUnwrap(try store.context.fetch(FetchDescriptor<UrgeEvent>()).first)
        XCTAssertEqual(urge.outcome, .resisted)
        XCTAssertNil(urge.note)
    }

    func testSavedJournalKeepsTheNoteAndTriggersPickedAfterward() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        let model = UrgeViewModel(store: store)
        let now = date(2026, 10, 13, 10)
        model.start(metrics: [alcohol], preferredID: nil, now: now)
        try model.begin(metrics: [alcohol], now: now)
        model.journalText = "  I want mornings back.  "
        try model.passed(now: now)
        model.triggers = [.tired, .stressed]
        model.journalChoice = .save
        try model.commitReflection(keepJournal: true)

        let urge = try XCTUnwrap(try store.context.fetch(FetchDescriptor<UrgeEvent>()).first)
        XCTAssertEqual(urge.note, "I want mornings back.")
        XCTAssertEqual(Set(urge.triggers), [.tired, .stressed])
        XCTAssertEqual(urge.outcome, .resisted)
        XCTAssertEqual(urge.endedAt, now)
    }

    func testDiscardedJournalIsCleared() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        let model = UrgeViewModel(store: store)
        let now = date(2026, 10, 13, 10)
        model.start(metrics: [alcohol], preferredID: nil, now: now)
        try model.begin(metrics: [alcohol], now: now)
        model.journalText = "Let this go"
        try model.passed(now: now)
        try model.commitReflection(keepJournal: false)
        let urge = try XCTUnwrap(try store.context.fetch(FetchDescriptor<UrgeEvent>()).first)
        XCTAssertNil(urge.note)
        XCTAssertEqual(model.journalText, "Let this go")
    }

    func testBlankJournalIsNotAChoice() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        let model = UrgeViewModel(store: store)
        let now = date(2026, 10, 13, 10)
        model.start(metrics: [alcohol], preferredID: nil, now: now)
        try model.begin(metrics: [alcohol], now: now)
        model.journalText = "   \n"
        XCTAssertFalse(model.hasJournal)
        XCTAssertFalse(model.needsJournalChoice)
        try model.markNotSure(now: now, keepJournal: true)
        let urge = try XCTUnwrap(try store.context.fetch(FetchDescriptor<UrgeEvent>()).first)
        XCTAssertNil(urge.note)
        XCTAssertEqual(urge.outcome, .unknown)
    }

    func testSlippedJournalIsStoredWithTheUrge() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil)
        let model = UrgeViewModel(store: store)
        let now = date(2026, 10, 13, 10, 4)
        model.start(metrics: [alcohol], preferredID: nil, now: now)
        try model.begin(metrics: [alcohol], now: now)
        model.journalText = "I was tired and it won."
        try model.markSlipped(now: now.addingTimeInterval(120), keepJournal: true)
        let urge = try XCTUnwrap(try store.context.fetch(FetchDescriptor<UrgeEvent>()).first)
        XCTAssertEqual(urge.outcome, .slipped)
        XCTAssertEqual(urge.note, "I was tired and it won.")
        XCTAssertEqual(urge.startedAt, now)
        XCTAssertEqual(urge.endedAt, now.addingTimeInterval(120))
    }
}

@MainActor
final class SlipViewModelTests: XCTestCase {
    func testOccurredAtRules() {
        let calendar = Calendar.testNY
        let now = date(2026, 10, 13, 15, 30)
        XCTAssertEqual(SlipWhen.justNow.occurredAt(now: now, calendar: calendar), now)
        XCTAssertEqual(SlipWhen.earlierToday.occurredAt(now: now, calendar: calendar), now)
        XCTAssertEqual(SlipWhen.yesterday.occurredAt(now: now, calendar: calendar), date(2026, 10, 12, 23, 59, calendar: calendar).addingTimeInterval(59))
        XCTAssertEqual(SlipWhen.picked(date(2026, 10, 10)).occurredAt(now: now, calendar: calendar), date(2026, 10, 10, 23, 59).addingTimeInterval(59))
        XCTAssertEqual(SlipWhen.picked(now).occurredAt(now: now, calendar: calendar), now)
    }

    func testSlipBeforeStartIsRejected() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 13, 9), costPerDay: nil, firstReason: nil)
        let model = SlipViewModel(store: store, plan: nil, triggers: [])
        model.when = .picked(date(2026, 10, 1))
        XCTAssertThrowsError(try model.save(metric: alcohol, now: date(2026, 10, 13, 15))) { error in
            XCTAssertEqual(error as? RecoveryStoreError, .slipBeforeStart)
        }
        XCTAssertEqual(model.errorMessage, RecoveryCopy.slipBeforeStart)
    }

    func testEditingAPastDayUsesThatDay() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(
            name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil
        )
        let now = date(2026, 10, 13, 15)
        let day = date(2026, 10, 10, 8)
        let yesterday = date(2026, 10, 12, 9)
        XCTAssertEqual(SlipWhen.forEditing(day: now, now: now, calendar: .testNY), .justNow)
        XCTAssertEqual(SlipWhen.forEditing(day: yesterday, now: now, calendar: .testNY), .yesterday)

        let model = SlipViewModel(store: store, plan: nil, triggers: [], when: SlipWhen.forEditing(day: day, now: now, calendar: .testNY))
        XCTAssertEqual(model.when, .picked(day))
        try model.save(metric: alcohol, now: now)
        let entry = try XCTUnwrap(try store.entries(for: alcohol.id).first)
        XCTAssertTrue(Calendar.testNY.isDate(entry.occurredAt, inSameDayAs: day))
        XCTAssertFalse(Calendar.testNY.isDate(entry.occurredAt, inSameDayAs: now))
    }
}

@MainActor
final class MilestoneCenterTests: XCTestCase {
    func testOnlyTheHighestNewMilestoneIsPresented() throws {
        let harness = try TestHarness()
        let store = harness.store
        let alcohol = try store.addMetric(name: "Alcohol", habitType: .vice, iconName: "wineglass", startedAt: date(2026, 10, 1, 0), costPerDay: nil, firstReason: "For my health")
        let reasons = try store.reasons(for: alcohol.id)
        let pending = MilestoneCenter.pending(metrics: [alcohol], entries: [], reasons: reasons, now: date(2026, 10, 11, 0), calendar: .testNY)
        XCTAssertEqual(pending.map(\.threshold), [7])
        MilestoneLedger.record(7, for: alcohol.id)
        let after = MilestoneCenter.pending(metrics: [alcohol], entries: [], reasons: reasons, now: date(2026, 10, 11, 0), calendar: .testNY)
        XCTAssertTrue(after.isEmpty)
        MilestoneLedger.reset(for: alcohol.id)
    }
}
