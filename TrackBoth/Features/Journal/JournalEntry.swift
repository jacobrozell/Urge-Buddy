import Foundation

struct JournalEntry: Identifiable, Equatable {
    var id: UUID
    var startedAt: Date
    var metricName: String
    var when: String
    var ended: String?
    var outcome: String
    var strength: String
    var triggers: String?
    var text: String

    static func make(urges: [UrgeEvent], metrics: [Metric], locale: Locale) -> [JournalEntry] {
        let names = Dictionary(metrics.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        return urges.compactMap { urge in
            guard urge.outcome != .inProgress else { return nil }
            guard let text = urge.note?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
            let triggers = urge.triggers.map(\.title)
            return JournalEntry(
                id: urge.id,
                startedAt: urge.startedAt,
                metricName: names[urge.metricID] ?? "—",
                when: stamp(urge.startedAt, locale: locale),
                ended: urge.endedAt.map { endStamp($0, startedAt: urge.startedAt, locale: locale) },
                outcome: outcomeTitle(urge.outcome),
                strength: RecoveryCopy.strengthOutOfFive(urge.intensity),
                triggers: triggers.isEmpty ? nil : triggers.joined(separator: ", "),
                text: text
            )
        }
        .sorted { $0.startedAt > $1.startedAt }
    }

    private static func outcomeTitle(_ outcome: UrgeOutcome) -> String {
        switch outcome {
        case .resisted: RecoveryCopy.rodeItOut
        case .slipped: RecoveryCopy.slipEvent
        case .unknown: RecoveryCopy.notSureOutcome
        case .inProgress: ""
        }
    }

    private static func stamp(_ date: Date, locale: Locale) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale))
    }

    private static func endStamp(_ date: Date, startedAt: Date, locale: Locale) -> String {
        guard Calendar.current.isDate(date, inSameDayAs: startedAt) else { return stamp(date, locale: locale) }
        return date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
    }
}
