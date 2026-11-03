import SwiftData
import XCTest
@testable import UrgeBuddy

@MainActor
final class BackupServiceTests: XCTestCase {
    func testRoundTripKeepsTheVice() throws {
        let harness = try TestHarness()
        let alcohol = try harness.store.addMetric(
            name: "Alcohol",
            habitType: .vice,
            iconName: "wineglass",
            startedAt: date(2026, 10, 1, 9),
            costPerDay: 8,
            firstReason: "For my health"
        )
        let data = try BackupService.exportData(from: harness.store.context, now: date(2026, 10, 28, 12))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(BackupService.fileName(for: date(2026, 10, 28, 12), calendar: .testNY))
        try data.write(to: url)
        try harness.store.delete(alcohol)
        try BackupService.importData(try Data(contentsOf: url), into: harness.store)
        let metrics = try harness.store.context.fetch(FetchDescriptor<Metric>())
        XCTAssertEqual(metrics.map(\.name), ["Alcohol"])
        XCTAssertEqual(metrics.first?.costPerDay, 8)
        let reasons = try harness.store.context.fetch(FetchDescriptor<Reason>())
        XCTAssertEqual(reasons.map(\.text), ["For my health"])
        XCTAssertTrue(Preferences.hasCompletedOnboarding)
    }

    func testImportSkipsBlankReasonText() throws {
        let harness = try TestHarness()
        _ = try harness.store.addMetric(
            name: "Alcohol",
            habitType: .vice,
            iconName: "wineglass",
            startedAt: date(2026, 10, 1, 9),
            costPerDay: nil,
            firstReason: "Real why"
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var backup = try decoder.decode(
            UrgeBuddyBackup.self,
            from: try BackupService.exportData(from: harness.store.context, now: date(2026, 10, 28, 12))
        )
        backup.reasons.append(
            UrgeBuddyBackup.ReasonRecord(
                id: UUID().uuidString,
                metricID: backup.metrics[0].id,
                text: "   ",
                createdAt: date(2026, 10, 2, 9),
                sortOrder: 99
            )
        )
        let data = try encoder.encode(backup)
        try harness.store.deleteAllData()
        try BackupService.importData(data, into: harness.store)
        let reasons = try harness.store.context.fetch(FetchDescriptor<Reason>())
        XCTAssertEqual(reasons.map(\.text), ["Real why"])
    }

    func testRoundTripKeepsReasonsAddedAfterMetric() throws {
        let harness = try TestHarness()
        let alcohol = try harness.store.addMetric(
            name: "Alcohol",
            habitType: .vice,
            iconName: "wineglass",
            startedAt: date(2026, 10, 1, 9),
            costPerDay: nil,
            firstReason: nil
        )
        try harness.store.addReason("First why", to: alcohol)
        try harness.store.addReason("Second why", to: alcohol)
        let data = try BackupService.exportData(from: harness.store.context, now: date(2026, 10, 28, 12))
        try harness.store.deleteAllData()
        try BackupService.importData(data, into: harness.store)
        let reasons = try harness.store.context.fetch(FetchDescriptor<Reason>(sortBy: [SortDescriptor(\.sortOrder)]))
        XCTAssertEqual(reasons.map(\.text), ["First why", "Second why"])
        XCTAssertEqual(reasons.map(\.sortOrder), [0, 1])
    }

    func testRoundTripKeepsAmountsModesAndDayNotes() throws {
        let harness = try TestHarness()
        let store = harness.store
        let smoking = try store.addMetric(
            name: "Smoking", habitType: .vice, iconName: "smoke", startedAt: date(2026, 10, 1, 9), costPerDay: 10, firstReason: nil,
            tracking: MetricTracking(viceMode: .cutBack, unit: "cigarettes", dailyTarget: 8, baselinePerDay: 20)
        )
        let water = try store.addMetric(
            name: "Water", habitType: .positive, iconName: "drop", startedAt: date(2026, 10, 1, 9), costPerDay: nil, firstReason: nil,
            tracking: MetricTracking(unit: "glasses", dailyTarget: 8)
        )
        try store.setAmount(smoking, on: date(2026, 10, 10), amount: 9)
        try store.setAmount(water, on: date(2026, 10, 10), amount: 5)
        try store.setDayNote(on: date(2026, 10, 10), mood: .low, text: "Long day")
        let data = try BackupService.exportData(from: store.context, now: date(2026, 10, 28, 12))
        try store.deleteAllData()
        try BackupService.importData(data, into: store)

        let metrics = try store.context.fetch(FetchDescriptor<Metric>(sortBy: [SortDescriptor(\.sortOrder)]))
        XCTAssertEqual(metrics.map(\.viceMode), [.cutBack, .quit])
        XCTAssertEqual(metrics.first?.unit, "cigarettes")
        XCTAssertEqual(metrics.first?.dailyTarget, 8)
        XCTAssertEqual(metrics.first?.baselinePerDay, 20)
        XCTAssertEqual(metrics.last?.dailyTarget, 8)
        let entries = try store.context.fetch(FetchDescriptor<MetricEntry>())
        XCTAssertEqual(Set(entries.map(\.status)), [.over, .partial])
        XCTAssertEqual(Set(entries.compactMap(\.amount)), [9, 5])
        let note = try store.dayNote(on: date(2026, 10, 10))
        XCTAssertEqual(note?.mood, .low)
        XCTAssertEqual(note?.text, "Long day")
    }

    func testVersion5BackupStillImports() throws {
        let harness = try TestHarness()
        let json = """
        {"schemaVersion":5,"exportDate":"2026-10-28T12:00:00Z","metrics":[{"id":"6E0B2C3A-1D7B-4A4E-9C1F-2B8F0F6A7E11","name":"Alcohol","habitType":"vice","iconName":"wineglass","createdAt":"2026-10-01T12:00:00Z","startedAt":"2026-10-01T12:00:00Z","sortOrder":0,"isArchived":false}],"entries":[],"urges":[],"reasons":[]}
        """
        try BackupService.importData(Data(json.utf8), into: harness.store)
        let metrics = try harness.store.context.fetch(FetchDescriptor<Metric>())
        XCTAssertEqual(metrics.map(\.name), ["Alcohol"])
        XCTAssertEqual(metrics.first?.viceMode, .quit)
    }

    func testNewerBackupIsRejectedAndLeavesData() throws {
        let harness = try TestHarness()
        _ = try harness.store.addMetric(name: "Walk", habitType: .positive, iconName: "figure.walk", startedAt: date(2026, 10, 1), costPerDay: nil, firstReason: nil)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("newer-backup.json")
        try Data("{\"schemaVersion\":7,\"exportDate\":\"2026-10-28T12:00:00Z\",\"metrics\":[],\"entries\":[],\"urges\":[],\"reasons\":[]}".utf8).write(to: url)
        XCTAssertThrowsError(try BackupService.importData(try Data(contentsOf: url), into: harness.store)) { error in
            XCTAssertEqual(error as? BackupError, .newerVersion)
        }
        let metrics = try harness.store.context.fetch(FetchDescriptor<Metric>())
        XCTAssertEqual(metrics.map(\.name), ["Walk"])
    }

    func testLegacyV1BackupImportsDaysAndSlips() throws {
        let harness = try TestHarness()
        try BackupService.importData(try fixture("legacy-v1"), into: harness.store)

        let metrics = try harness.store.context.fetch(FetchDescriptor<Metric>(sortBy: [SortDescriptor(\.sortOrder)]))
        XCTAssertEqual(metrics.map(\.name), ["Go for a walk", "Alcohol"])
        XCTAssertEqual(metrics.map(\.habitType), [.positive, .vice])
        XCTAssertEqual(metrics.map(\.iconName), ["figure.walk", "wineglass"])
        XCTAssertEqual(metrics.map(\.startedAt), [date(2026, 10, 1, 9), date(2026, 10, 1, 9)])
        XCTAssertEqual(metrics.map(\.viceMode), [.quit, .quit])
        XCTAssertNil(metrics[1].costPerDay)
        let walk = metrics[0], alcohol = metrics[1]
        XCTAssertEqual(try statusByDay(walk, in: harness.store), [
            date(2026, 10, 10): .done, date(2026, 10, 11): .done, date(2026, 10, 12): .done,
        ])
        XCTAssertEqual(try statusByDay(alcohol, in: harness.store), [date(2026, 10, 2): .free, date(2026, 10, 5): .slipped])
        let slip = try XCTUnwrap(try harness.store.entries(for: alcohol.id).first { $0.status == .slipped })
        XCTAssertEqual(slip.occurredAt, DayMath.endOfDay(date(2026, 10, 5), calendar: .testNY))
        XCTAssertEqual(try harness.store.context.fetchCount(FetchDescriptor<MetricEntry>()), 5)
        XCTAssertEqual(try harness.store.context.fetchCount(FetchDescriptor<Reason>()), 0)
        XCTAssertEqual(try harness.store.context.fetchCount(FetchDescriptor<UrgeEvent>()), 0)
        XCTAssertTrue(Preferences.hasCompletedOnboarding)
        XCTAssertTrue(Preferences.hasAcceptedDisclaimer)
    }

    func testLegacyV3BackupImportsReasonsAndNotesAndSkipsBlankReasons() throws {
        let harness = try TestHarness()
        try BackupService.importData(try fixture("legacy-v3"), into: harness.store)

        let metrics = try harness.store.context.fetch(FetchDescriptor<Metric>(sortBy: [SortDescriptor(\.sortOrder)]))
        XCTAssertEqual(metrics.map(\.name), ["Go for a walk", "Alcohol"])
        let walk = metrics[0], alcohol = metrics[1]
        XCTAssertNil(alcohol.costPerDay)
        XCTAssertEqual(try harness.store.reasons(for: walk.id).map(\.text), [])
        let reasons = try harness.store.reasons(for: alcohol.id)
        XCTAssertEqual(reasons.map(\.text), ["For my health", "Remember my kids", "I want to feel clear"])
        XCTAssertEqual(reasons.map(\.sortOrder), [0, 1, 2])
        XCTAssertEqual(try statusByDay(alcohol, in: harness.store), [date(2026, 10, 2): .free, date(2026, 10, 5): .slipped])
        XCTAssertEqual(try noteByDay(walk, in: harness.store), [date(2026, 10, 12): "Morning loop"])
        XCTAssertEqual(try noteByDay(alcohol, in: harness.store), [date(2026, 10, 2): "Stayed in", date(2026, 10, 5): "After dinner"])
        XCTAssertEqual(try harness.store.context.fetchCount(FetchDescriptor<MetricEntry>()), 5)
    }

    func testLegacyV4BackupImportsCostAndSkipsUndoneHabitDays() throws {
        let harness = try TestHarness()
        try BackupService.importData(try fixture("legacy-v4"), into: harness.store)

        let metrics = try harness.store.context.fetch(FetchDescriptor<Metric>(sortBy: [SortDescriptor(\.sortOrder)]))
        XCTAssertEqual(metrics.map(\.name), ["Go for a walk", "Alcohol"])
        let walk = metrics[0], alcohol = metrics[1]
        XCTAssertEqual(alcohol.costPerDay, 8)
        XCTAssertNil(walk.costPerDay)
        XCTAssertEqual(try statusByDay(walk, in: harness.store), [
            date(2026, 10, 10): .done, date(2026, 10, 11): .done, date(2026, 10, 12): .done,
        ])
        XCTAssertEqual(try statusByDay(alcohol, in: harness.store), [date(2026, 10, 2): .free, date(2026, 10, 5): .slipped])
        XCTAssertEqual(
            try harness.store.reasons(for: alcohol.id).map(\.text),
            ["For my health", "Remember my kids", "I want to feel clear"]
        )
        XCTAssertEqual(try harness.store.context.fetchCount(FetchDescriptor<MetricEntry>()), 5)
    }

    func testTruncatedBackupFailsAndLeavesData() throws {
        let harness = try TestHarness()
        try seedWalk(in: harness.store)
        let data = try fixture("legacy-v4")
        try assertImportFails(data.prefix(data.count / 2), leavesWalkIn: harness.store)
    }

    func testLegacyBackupWithUnknownHabitTypeFailsWithoutPartialWrites() throws {
        let harness = try TestHarness()
        try seedWalk(in: harness.store)
        let json = String(decoding: try fixture("legacy-v4"), as: UTF8.self)
            .replacingOccurrences(of: "\"habitType\": \"vice\"", with: "\"habitType\": \"sometimes\"")
        try assertImportFails(Data(json.utf8), leavesWalkIn: harness.store)
    }

    func testBackupWithOrphanEntryFailsWithoutPartialWrites() throws {
        let harness = try TestHarness()
        try seedWalk(in: harness.store)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var backup = try decoder.decode(
            UrgeBuddyBackup.self,
            from: try BackupService.exportData(from: harness.store.context, now: date(2026, 10, 28, 12))
        )
        backup.entries.append(
            UrgeBuddyBackup.EntryRecord(
                id: UUID().uuidString,
                metricID: UUID().uuidString,
                day: date(2026, 10, 2),
                status: EntryStatus.free.rawValue,
                occurredAt: date(2026, 10, 2),
                note: nil,
                triggers: [],
                amount: nil
            )
        )
        try assertImportFails(try encoder.encode(backup), leavesWalkIn: harness.store)
    }

    private func fixture(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle(for: BackupServiceTests.self).url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }

    private func statusByDay(_ metric: Metric, in store: RecoveryStore) throws -> [Date: EntryStatus] {
        Dictionary(try store.entries(for: metric.id).map { ($0.day, $0.status) }, uniquingKeysWith: { first, _ in first })
    }

    private func noteByDay(_ metric: Metric, in store: RecoveryStore) throws -> [Date: String] {
        Dictionary(
            try store.entries(for: metric.id).compactMap { entry in entry.note.map { (entry.day, $0) } },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private func seedWalk(in store: RecoveryStore) throws {
        let walk = try store.addMetric(
            name: "Walk", habitType: .positive, iconName: "figure.walk", startedAt: date(2026, 10, 1), costPerDay: nil, firstReason: "Clear head"
        )
        try store.setHabitDone(walk, on: date(2026, 10, 3), done: true, now: date(2026, 10, 3))
    }

    private func assertImportFails(_ data: Data, leavesWalkIn store: RecoveryStore, line: UInt = #line) throws {
        XCTAssertThrowsError(try BackupService.importData(data, into: store), line: line) { error in
            XCTAssertEqual(error as? BackupError, .invalid, line: line)
        }
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Metric>()).map(\.name), ["Walk"], line: line)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Reason>()).map(\.text), ["Clear head"], line: line)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<MetricEntry>()).map(\.day), [date(2026, 10, 3)], line: line)
    }
}
