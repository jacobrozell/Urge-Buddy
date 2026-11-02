import Foundation
import SwiftData

enum BackupError: LocalizedError, Equatable {
    case newerVersion
    case invalid

    var errorDescription: String? {
        switch self {
        case .newerVersion:
            "This backup is from a newer version of Urge Buddy."
        case .invalid:
            "This file isn't an Urge Buddy backup."
        }
    }
}

enum BackupService {
    static let currentSchemaVersion = 6

    @MainActor
    static func exportData(from context: ModelContext, now: Date = Date()) throws -> Data {
        let metrics = try context.fetch(FetchDescriptor<Metric>(sortBy: [SortDescriptor(\.sortOrder)]))
        let entries = try context.fetch(FetchDescriptor<MetricEntry>())
        let urges = try context.fetch(FetchDescriptor<UrgeEvent>())
        let reasons = try context.fetch(FetchDescriptor<Reason>())
        let dayNotes = try context.fetch(FetchDescriptor<DayNote>())
        let backup = UrgeBuddyBackup(
            schemaVersion: currentSchemaVersion,
            exportDate: now,
            metrics: metrics.map(metricRecord),
            entries: entries.map(entryRecord),
            urges: urges.map(urgeRecord),
            reasons: reasons.map(reasonRecord),
            dayNotes: dayNotes.map(dayNoteRecord)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(backup)
    }

    static func fileName(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "UrgeBuddy-Backup-%04d-%02d-%02d.json", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    @MainActor
    static func importData(_ data: Data, into store: RecoveryStore) throws {
        let version = try schemaVersion(in: data)
        if version > currentSchemaVersion { throw BackupError.newerVersion }
        let built: BuiltModels
        if (5...currentSchemaVersion).contains(version) {
            built = try models(from: try decodeCurrent(data), calendar: store.calendar)
        } else if (1...4).contains(version) {
            built = try models(from: try decodeLegacy(data), calendar: store.calendar)
        } else {
            throw BackupError.invalid
        }
        try store.replaceAll(metrics: built.metrics, entries: built.entries, urges: built.urges, reasons: built.reasons, dayNotes: built.dayNotes)
        Preferences.hasCompletedOnboarding = true
        Preferences.hasAcceptedDisclaimer = true
    }

    // MARK: Decode

    private struct VersionProbe: Decodable { let schemaVersion: Int }

    private static func schemaVersion(in data: Data) throws -> Int {
        do {
            return try JSONDecoder().decode(VersionProbe.self, from: data).schemaVersion
        } catch {
            throw BackupError.invalid
        }
    }

    private static func decodeCurrent(_ data: Data) throws -> UrgeBuddyBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(UrgeBuddyBackup.self, from: data)
        } catch {
            throw BackupError.invalid
        }
    }

    private static func decodeLegacy(_ data: Data) throws -> LegacyExportV4.Payload {
        do {
            return try legacyDecoder().decode(LegacyExportV4.Payload.self, from: data)
        } catch {
            throw BackupError.invalid
        }
    }

    static func legacyDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let seconds = try? container.decode(Double.self) {
                return Date(timeIntervalSinceReferenceDate: seconds)
            }
            let string = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: string) { return date }
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date")
        }
        return decoder
    }

    // MARK: Map

    private struct BuiltModels {
        var metrics: [Metric]
        var entries: [MetricEntry]
        var urges: [UrgeEvent]
        var reasons: [Reason]
        var dayNotes: [DayNote] = []
    }

    private static func models(from backup: UrgeBuddyBackup, calendar: Calendar) throws -> BuiltModels {
        var metrics: [Metric] = []
        var ids = Set<UUID>()
        for record in backup.metrics {
            guard let id = UUID(uuidString: record.id), let habitType = HabitType(rawValue: record.habitType), ids.insert(id).inserted else {
                throw BackupError.invalid
            }
            let metric = Metric(name: record.name, habitType: habitType, iconName: record.iconName, startedAt: record.startedAt, sortOrder: record.sortOrder)
            metric.id = id
            metric.createdAt = record.createdAt
            metric.costPerDayRaw = record.costPerDay
            metric.ifThenPlan = record.ifThenPlan
            metric.isArchived = record.isArchived
            if let mode = record.viceMode {
                guard let viceMode = ViceMode(rawValue: mode) else { throw BackupError.invalid }
                metric.viceMode = viceMode
            }
            metric.unit = record.unit
            metric.dailyTarget = record.dailyTarget
            metric.baselinePerDay = record.baselinePerDay
            metrics.append(metric)
        }
        var seenDays = Set<String>()
        var entries: [MetricEntry] = []
        for record in backup.entries {
            guard let id = UUID(uuidString: record.id),
                  let metricID = UUID(uuidString: record.metricID),
                  ids.contains(metricID),
                  let status = EntryStatus(rawValue: record.status) else { throw BackupError.invalid }
            let dayKey = "\(metricID.uuidString)|\(calendar.startOfDay(for: record.day).timeIntervalSinceReferenceDate)"
            guard seenDays.insert(dayKey).inserted else { throw BackupError.invalid }
            let entry = MetricEntry(metricID: metricID, day: record.day, status: status, occurredAt: record.occurredAt)
            entry.id = id
            entry.note = record.note
            entry.triggers = record.triggers.compactMap(TriggerTag.init(rawValue:))
            entry.amount = record.amount
            entries.append(entry)
        }
        var urges: [UrgeEvent] = []
        for record in backup.urges {
            guard let id = UUID(uuidString: record.id),
                  let metricID = UUID(uuidString: record.metricID),
                  ids.contains(metricID),
                  let outcome = UrgeOutcome(rawValue: record.outcome) else { throw BackupError.invalid }
            let urge = UrgeEvent(metricID: metricID, intensity: record.intensity, startedAt: record.startedAt)
            urge.id = id
            urge.endedAt = record.endedAt
            urge.outcome = outcome
            urge.note = record.note
            urge.triggers = record.triggers.compactMap(TriggerTag.init(rawValue:))
            urges.append(urge)
        }
        var reasons: [Reason] = []
        for record in backup.reasons {
            guard let id = UUID(uuidString: record.id), let metricID = UUID(uuidString: record.metricID), ids.contains(metricID) else {
                throw BackupError.invalid
            }
            let text = record.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            let reason = Reason(metricID: metricID, text: text, sortOrder: record.sortOrder)
            reason.id = id
            reason.createdAt = record.createdAt
            reasons.append(reason)
        }
        var dayNotes: [DayNote] = []
        var seenNoteDays = Set<Date>()
        for record in backup.dayNotes ?? [] {
            guard let id = UUID(uuidString: record.id),
                  seenNoteDays.insert(calendar.startOfDay(for: record.day)).inserted else { throw BackupError.invalid }
            let note = DayNote(day: record.day, mood: record.mood.flatMap(Mood.init(rawValue:)), text: record.text, updatedAt: record.updatedAt)
            note.id = id
            dayNotes.append(note)
        }
        return BuiltModels(metrics: metrics, entries: entries, urges: urges, reasons: reasons, dayNotes: dayNotes)
    }

    private static func models(from payload: LegacyExportV4.Payload, calendar: Calendar) throws -> BuiltModels {
        var metrics: [Metric] = []
        var metricIDs = Set<UUID>()
        var habitByID: [UUID: Bool] = [:]
        for record in payload.metrics {
            guard let id = UUID(uuidString: record.id), let habitType = HabitType(rawValue: record.habitType) else { throw BackupError.invalid }
            let loggedDates = payload.entries
                .filter { $0.metricID == record.id && $0.hasBeenLogged == true }
                .map(\.date)
            let startedAt: Date
            if habitType == .vice, let earliest = loggedDates.min() {
                startedAt = min(record.createdAt, earliest)
            } else {
                startedAt = record.createdAt
            }
            let metric = Metric(
                name: record.name,
                habitType: habitType,
                iconName: Presets.iconName(matching: record.name),
                startedAt: startedAt,
                sortOrder: metrics.count
            )
            metric.id = id
            metric.createdAt = record.createdAt
            if let cost = record.costPerUnit, Decimal(string: cost) != nil {
                metric.costPerDayRaw = cost
            }
            metrics.append(metric)
            metricIDs.insert(id)
            habitByID[id] = habitType == .positive
        }

        var entries: [MetricEntry] = []
        var reasons: [Reason] = []
        var reasonOrder: [UUID: Int] = [:]
        for metric in metrics {
            if let text = payload.metrics.first(where: { $0.id == metric.id.uuidString })?.primaryMotivation?.trimmingCharacters(in: .whitespacesAndNewlines),
               !text.isEmpty {
                reasons.append(Reason(metricID: metric.id, text: text, sortOrder: 0))
                reasonOrder[metric.id] = 1
            }
        }

        for record in payload.entries {
            guard let metricID = UUID(uuidString: record.metricID), metricIDs.contains(metricID) else { continue }
            let isHabit = habitByID[metricID] == true
            if record.hasBeenLogged != true {
                if let motivation = record.motivation?.trimmingCharacters(in: .whitespacesAndNewlines), !motivation.isEmpty {
                    let order = reasonOrder[metricID] ?? 0
                    reasons.append(Reason(metricID: metricID, text: motivation, sortOrder: order))
                    reasonOrder[metricID] = order + 1
                }
                continue
            }
            guard let id = UUID(uuidString: record.id) else { continue }
            if isHabit {
                guard record.value else { continue }
                let entry = MetricEntry(metricID: metricID, day: DayMath.anchor(record.date, calendar: calendar), status: .done, occurredAt: record.date)
                entry.id = id
                entry.note = record.details
                entries.append(entry)
            } else if record.value {
                let entry = MetricEntry(
                    metricID: metricID,
                    day: DayMath.anchor(record.date, calendar: calendar),
                    status: .slipped,
                    occurredAt: DayMath.endOfDay(record.date, calendar: calendar)
                )
                entry.id = id
                entry.note = record.details
                entries.append(entry)
            } else {
                let entry = MetricEntry(metricID: metricID, day: DayMath.anchor(record.date, calendar: calendar), status: .free, occurredAt: record.date)
                entry.id = id
                entry.note = record.details
                entries.append(entry)
            }
        }
        return BuiltModels(metrics: metrics, entries: entries, urges: [], reasons: reasons)
    }

    private static func metricRecord(_ metric: Metric) -> UrgeBuddyBackup.MetricRecord {
        UrgeBuddyBackup.MetricRecord(
            id: metric.id.uuidString,
            name: metric.name,
            habitType: metric.habitType.rawValue,
            iconName: metric.iconName,
            createdAt: metric.createdAt,
            startedAt: metric.startedAt,
            costPerDay: metric.costPerDayRaw,
            ifThenPlan: metric.ifThenPlan,
            sortOrder: metric.sortOrder,
            isArchived: metric.isArchived,
            viceMode: metric.habitType == .vice ? metric.viceMode.rawValue : nil,
            unit: metric.unit,
            dailyTarget: metric.dailyTarget,
            baselinePerDay: metric.baselinePerDay
        )
    }

    private static func entryRecord(_ entry: MetricEntry) -> UrgeBuddyBackup.EntryRecord {
        UrgeBuddyBackup.EntryRecord(
            id: entry.id.uuidString,
            metricID: entry.metricID.uuidString,
            day: entry.day,
            status: entry.status.rawValue,
            occurredAt: entry.occurredAt,
            note: entry.note,
            triggers: entry.triggers.map(\.rawValue),
            amount: entry.amount
        )
    }

    private static func urgeRecord(_ urge: UrgeEvent) -> UrgeBuddyBackup.UrgeRecord {
        UrgeBuddyBackup.UrgeRecord(
            id: urge.id.uuidString,
            metricID: urge.metricID.uuidString,
            startedAt: urge.startedAt,
            endedAt: urge.endedAt,
            outcome: urge.outcome.rawValue,
            intensity: urge.intensity,
            triggers: urge.triggers.map(\.rawValue),
            note: urge.note
        )
    }

    private static func dayNoteRecord(_ note: DayNote) -> UrgeBuddyBackup.DayNoteRecord {
        UrgeBuddyBackup.DayNoteRecord(
            id: note.id.uuidString,
            day: note.day,
            mood: note.mood?.rawValue,
            text: note.text,
            updatedAt: note.updatedAt
        )
    }

    private static func reasonRecord(_ reason: Reason) -> UrgeBuddyBackup.ReasonRecord {
        UrgeBuddyBackup.ReasonRecord(
            id: reason.id.uuidString,
            metricID: reason.metricID.uuidString,
            text: reason.text,
            createdAt: reason.createdAt,
            sortOrder: reason.sortOrder
        )
    }
}
