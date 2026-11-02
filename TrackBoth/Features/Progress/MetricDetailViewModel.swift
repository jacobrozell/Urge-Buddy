import Foundation
import Observation

struct DetailTile: Equatable {
    var label: String
    var value: String
    var caption: String?
}

struct DetailTrigger: Equatable {
    var title: String
    var systemImage: String
    var count: Int
}

struct DetailUrgeSummary: Equatable {
    var beaten: String
    var slipped: String
    var unsure: String
    var average: String?
    var total: Int
}

struct DetailEvent: Equatable, Identifiable {
    var id: String
    var title: String
    var when: String
    var detail: String?
    var systemImage: String
    var usesSlipTint: Bool
}

struct DetailStats: Equatable {
    var primary: String
    var tiles: [DetailTile]
    var plan: String
    var nextMilestone: String?
    /// Cut back: "Down 60% from 20 a day" or the 7-day average.
    var trend: String? = nil
    var startedLine: String
    var atRisk: Bool
    var needsCost: Bool
    var urges: DetailUrgeSummary?
    var triggers: [DetailTrigger]
    var hardestTime: String?
    var hardestDay: String?
    var recent: [DetailEvent]
    var month: Date
}

@MainActor
@Observable
final class MetricDetailViewModel {
    var calendar: Calendar
    var locale: Locale
    private(set) var stats = DetailStats(
        primary: "",
        tiles: [],
        plan: "",
        nextMilestone: nil,
        startedLine: "",
        atRisk: false,
        needsCost: false,
        urges: nil,
        triggers: [],
        hardestTime: nil,
        hardestDay: nil,
        recent: [],
        month: Date()
    )
    var month: Date

    init(calendar: Calendar = .current, locale: Locale = .current, now: Date = Date()) {
        self.calendar = calendar
        self.locale = locale
        self.month = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
    }

    func update(metric: Metric, entries: [MetricEntry], urges: [UrgeEvent], now: Date) {
        let started = formattedDay(metric.startedAt)
        if metric.isCuttingBack {
            stats = cutBackStats(metric: metric, entries: entries, urges: urges, now: now, started: started)
        } else if metric.habitType == .vice {
            let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
            let days = RecoveryMath.currentRunDays(history, now: now, calendar: calendar)
            let window = RecoveryMath.freeDays(inLast: 30, history, now: now, calendar: calendar)
            let freeDays = RecoveryMath.totalFreeDays(history, now: now, calendar: calendar)
            let savedAmount = RecoveryMath.moneySaved(totalFreeDays: freeDays, costPerDay: metric.costPerDay)
            let next = MilestonePolicy.next(after: days, isVice: true)
            let mine = urges.filter { $0.metricID == metric.id }
            let slips = entries.filter { $0.metricID == metric.id && $0.status == .slipped }
            let hardMoments = slips.map(\.occurredAt) + mine.filter { $0.outcome != .resisted }.map(\.startedAt)
            stats = DetailStats(
                primary: RecoveryCopy.daysFree(days),
                tiles: [
                    DetailTile(label: RecoveryCopy.currentRun, value: "\(days)", caption: nil),
                    DetailTile(label: RecoveryCopy.longestRun, value: "\(RecoveryMath.longestRunDays(history, now: now, calendar: calendar))", caption: nil),
                    DetailTile(label: RecoveryCopy.freeLast30Tile, value: "\(window.free)/\(window.counted)", caption: nil),
                    savedTile(amount: savedAmount, cost: metric.costPerDay)
                ],
                plan: metric.ifThenPlan ?? "",
                nextMilestone: RecoveryCopy.nextMilestone(next, inDays: next - days),
                startedLine: started,
                atRisk: false,
                needsCost: metric.costPerDay == nil,
                urges: urgeSummary(mine),
                triggers: patternTriggers(slips: slips, urges: mine),
                hardestTime: PatternInsights.hardestTime(from: hardMoments, calendar: calendar)?.title,
                hardestDay: PatternInsights.hardestWeekday(from: hardMoments, calendar: calendar).map {
                    weekdayName($0)
                },
                recent: recentEvents(slips: slips, urges: mine),
                month: month
            )
        } else {
            let history = Snapshots.habitHistory(for: metric, entries: entries, calendar: calendar)
            let run = HabitMath.currentRun(history, now: now, calendar: calendar)
            let next = MilestonePolicy.next(after: run, isVice: false)
            var tiles = [
                DetailTile(label: RecoveryCopy.currentRun, value: "\(run)", caption: nil),
                DetailTile(label: RecoveryCopy.bestRun, value: "\(HabitMath.bestRun(history, now: now, calendar: calendar))", caption: nil),
                DetailTile(label: RecoveryCopy.doneLast30Tile, value: "\(HabitMath.doneCount(inLast: 30, history, now: now, calendar: calendar))", caption: nil),
                DetailTile(label: RecoveryCopy.doneAllTime, value: "\(history.doneDays.count)", caption: nil)
            ]
            if metric.tracksAmount, let target = metric.dailyTarget {
                let today = Snapshots.amount(for: metric, on: now, entries: entries, calendar: calendar)
                tiles.insert(DetailTile(label: RecoveryCopy.todayTile, value: RecoveryCopy.amountOf(today, target, unit: metric.unitLabel), caption: nil), at: 0)
                tiles.append(DetailTile(label: RecoveryCopy.dailyTarget, value: RecoveryCopy.amountUnit(target, unit: metric.unitLabel), caption: nil))
            }
            stats = DetailStats(
                primary: RecoveryCopy.habitRun(run),
                tiles: tiles,
                plan: "",
                nextMilestone: RecoveryCopy.nextMilestone(next, inDays: next - run),
                startedLine: started,
                atRisk: HabitMath.isAtRisk(history, now: now, calendar: calendar),
                needsCost: false,
                urges: nil,
                triggers: [],
                hardestTime: nil,
                hardestDay: nil,
                recent: [],
                month: month
            )
        }
    }

    func state(for day: Date, metric: Metric, entries: [MetricEntry], now: Date) -> DayVisualState {
        if metric.isCuttingBack {
            let history = Snapshots.cutBackHistory(for: metric, entries: entries, calendar: calendar)
            return DayVisualState(cutBackState: CutBackMath.state(of: day, in: history, now: now, calendar: calendar))
        }
        if metric.habitType == .vice {
            let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
            return DayVisualState(dayState: RecoveryMath.state(of: day, in: history, now: now, calendar: calendar))
        }
        let key = calendar.startOfDay(for: day)
        let history = Snapshots.habitHistory(for: metric, entries: entries, calendar: calendar)
        let today = calendar.startOfDay(for: now)
        let started = calendar.startOfDay(for: metric.startedAt)
        let active = key >= started && key <= today
        let isPartial = entries.contains { $0.metricID == metric.id && $0.status == .partial && calendar.isDate($0.day, inSameDayAs: key) }
        return .habit(isDone: history.doneDays.contains(key), isPartial: isPartial, isToday: key == today, isActive: active)
    }

    func canEdit(_ day: Date, metric: Metric, now: Date) -> Bool {
        let key = calendar.startOfDay(for: day)
        let today = calendar.startOfDay(for: now)
        return key >= calendar.startOfDay(for: metric.startedAt) && key <= today
    }

    func shiftMonth(_ delta: Int, metric: Metric, now: Date) {
        guard let next = calendar.date(byAdding: .month, value: delta, to: month) else { return }
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: metric.startedAt)) ?? metric.startedAt
        let current = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        if next < start || next > current { return }
        month = next
    }

    private func cutBackStats(metric: Metric, entries: [MetricEntry], urges: [UrgeEvent], now: Date, started: String) -> DetailStats {
        let history = Snapshots.cutBackHistory(for: metric, entries: entries, calendar: calendar)
        let unit = metric.unitLabel
        let today = CutBackMath.amount(on: now, history, calendar: calendar)
        let average = CutBackMath.average(inLast: 7, history, now: now, calendar: calendar)
        let window = CutBackMath.withinDays(inLast: 30, history, now: now, calendar: calendar)
        let saved = CutBackMath.moneySaved(
            unitsAvoided: CutBackMath.unitsAvoided(history, now: now, calendar: calendar),
            baseline: history.baseline,
            costPerDay: metric.costPerDay
        )
        let mine = urges.filter { $0.metricID == metric.id }
        let hardMoments = mine.filter { $0.outcome != .resisted }.map(\.startedAt)
        var tiles = [
            DetailTile(label: RecoveryCopy.dailyLimit, value: RecoveryCopy.amountUnit(history.limit, unit: unit), caption: nil),
            DetailTile(label: RecoveryCopy.averageLast7, value: average.map { RecoveryCopy.average($0) } ?? "—", caption: nil),
            DetailTile(label: RecoveryCopy.withinLast30Tile, value: "\(window.within)/\(window.logged)", caption: nil)
        ]
        if let baseline = history.baseline {
            tiles.append(DetailTile(label: RecoveryCopy.usualTile, value: RecoveryCopy.perDayAmount(baseline, unit: unit), caption: nil))
            tiles.append(savedTile(amount: saved, cost: metric.costPerDay))
        }
        return DetailStats(
            primary: RecoveryCopy.todayAmount(today, limit: history.limit, unit: unit),
            tiles: tiles,
            plan: metric.ifThenPlan ?? "",
            nextMilestone: nil,
            trend: TodayViewModel.trendLine(history, unit: unit, now: now, calendar: calendar),
            startedLine: started,
            atRisk: false,
            needsCost: history.baseline != nil && metric.costPerDay == nil,
            urges: urgeSummary(mine),
            triggers: patternTriggers(slips: [], urges: mine),
            hardestTime: PatternInsights.hardestTime(from: hardMoments, calendar: calendar)?.title,
            hardestDay: PatternInsights.hardestWeekday(from: hardMoments, calendar: calendar).map { weekdayName($0) },
            recent: recentEvents(slips: [], urges: mine),
            month: month
        )
    }

    private func savedTile(amount: Decimal?, cost: Decimal?) -> DetailTile {
        let value = cost == nil ? "—" : RecoveryCopy.money(amount ?? 0, locale: locale)
        return DetailTile(label: RecoveryCopy.savedStat, value: value, caption: cost.map { RecoveryCopy.perDay($0, locale: locale) })
    }

    private func urgeSummary(_ urges: [UrgeEvent]) -> DetailUrgeSummary {
        let breakdown = PatternInsights.urgeBreakdown(urges.map { UrgeSample(outcome: $0.outcome, intensity: $0.intensity) })
        return DetailUrgeSummary(
            beaten: "\(breakdown.beaten) of \(breakdown.total)",
            slipped: "\(breakdown.slipped)",
            unsure: "\(breakdown.unsure)",
            average: breakdown.averageIntensity.map { RecoveryCopy.averageStrength($0) },
            total: breakdown.total
        )
    }

    private func patternTriggers(slips: [MetricEntry], urges: [UrgeEvent]) -> [DetailTrigger] {
        guard slips.count + urges.count >= 3 else { return [] }
        let groups = slips.map(\.triggers) + urges.map(\.triggers)
        return PatternInsights.topTriggers(from: groups).map {
            DetailTrigger(title: $0.0.title, systemImage: $0.0.systemImage, count: $0.1)
        }
    }

    private func recentEvents(slips: [MetricEntry], urges: [UrgeEvent]) -> [DetailEvent] {
        var events: [(Date, DetailEvent)] = []
        for slip in slips {
            let strength = slippedStrength(near: slip, urges: urges)
            events.append((slip.occurredAt, DetailEvent(
                id: "slip-\(slip.id.uuidString)",
                title: RecoveryCopy.slipEvent,
                when: formattedWhen(slip.occurredAt),
                detail: detailLine(triggers: slip.triggers, strength: strength, note: slip.note),
                systemImage: "arrow.uturn.backward",
                usesSlipTint: true
            )))
        }
        for urge in urges where urge.outcome == .resisted || urge.outcome == .unknown {
            let rodeItOut = urge.outcome == .resisted
            events.append((urge.startedAt, DetailEvent(
                id: "urge-\(urge.id.uuidString)",
                title: rodeItOut ? RecoveryCopy.rodeItOut : RecoveryCopy.notSureOutcome,
                when: formattedWhen(urge.startedAt),
                detail: detailLine(triggers: urge.triggers, strength: urge.intensity, note: urge.note),
                systemImage: rodeItOut ? "wind" : "questionmark.circle",
                usesSlipTint: false
            )))
        }
        return events
            .sorted { $0.0 > $1.0 }
            .prefix(8)
            .map(\.1)
    }

    /// Strength from the slipped urge closest to this slip, on the same day.
    private func slippedStrength(near slip: MetricEntry, urges: [UrgeEvent]) -> Int? {
        let matches = urges.filter { urge in
            urge.outcome == .slipped && calendar.isDate(urge.startedAt, inSameDayAs: slip.occurredAt)
        }
        return matches.min {
            abs($0.startedAt.timeIntervalSince(slip.occurredAt)) < abs($1.startedAt.timeIntervalSince(slip.occurredAt))
        }?.intensity
    }

    private func detailLine(triggers: [TriggerTag], strength: Int?, note: String?) -> String? {
        var parts: [String] = []
        if let strength { parts.append(RecoveryCopy.strength(strength)) }
        let tags = triggers.map(\.title)
        if !tags.isEmpty { parts.append(tags.joined(separator: ", ")) }
        if let note = note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            parts.append(note)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func formattedDay(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(locale))
    }

    private func formattedWhen(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale))
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = calendar.weekdaySymbols
        let index = weekday - 1
        guard symbols.indices.contains(index) else { return "" }
        return symbols[index]
    }
}
