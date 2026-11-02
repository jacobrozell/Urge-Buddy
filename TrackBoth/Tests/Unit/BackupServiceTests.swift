import SwiftData
import XCTest
@testable import TrackBoth

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
            TrackBothBackup.self,
            from: try BackupService.exportData(from: harness.store.context, now: date(2026, 10, 28, 12))
        )
        backup.reasons.append(
            TrackBothBackup.ReasonRecord(
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
}
