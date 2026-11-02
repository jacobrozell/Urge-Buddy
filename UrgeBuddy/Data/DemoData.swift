import Foundation
import SwiftData

enum LaunchConfiguration {
    static func applyArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) {
        if arguments.contains("-skip_onboarding") {
            Preferences.hasCompletedOnboarding = true
            Preferences.hasAcceptedDisclaimer = true
        }
    }

    static var shouldSeedDemo: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("-seed_demo") || arguments.contains("-screenshot_demo")
    }

    static var initialTab: AppTab? {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-tab_progress") { return .progress }
        if arguments.contains("-tab_settings") { return .settings }
        return nil
    }

    static var opensFirstDetail: Bool {
        ProcessInfo.processInfo.arguments.contains("-open_first_detail")
    }

    static var presentsSlip: Bool {
        ProcessInfo.processInfo.arguments.contains("-present_slip")
    }

    static var startsOnVices: Bool {
        ProcessInfo.processInfo.arguments.contains("-onboarding_vices")
    }

    static var initialPresentation: PresentedFlow? {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-present_checkin") { return .checkIn }
        if arguments.contains("-present_urge") { return .urge(nil) }
        return nil
    }
}

enum DemoData {
    @MainActor
    static func seedIfEmpty(context: ModelContext, now: Date = Date(), calendar: Calendar = .current) throws {
        let existing = try context.fetch(FetchDescriptor<Metric>())
        guard existing.isEmpty else { return }
        try seed(context: context, now: now, calendar: calendar)
    }

    @MainActor
    static func seed(context: ModelContext, now: Date = Date(), calendar: Calendar = .current) throws {
        let store = RecoveryStore(context: context, calendar: calendar)
        let alcoholStart = calendar.date(byAdding: .day, value: -23, to: now) ?? now
        let socialDay = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        let socialStart = calendar.date(bySettingHour: 9, minute: 15, second: 0, of: socialDay) ?? socialDay
        let slipAt = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -9, to: now) ?? now) ?? now

        let alcohol = try store.addMetric(
            name: "Alcohol",
            habitType: .vice,
            iconName: "wineglass",
            startedAt: alcoholStart,
            costPerDay: 8,
            firstReason: "For my health"
        )
        try store.setPlan(alcohol, plan: "When I feel the urge, I will go for a walk.")
        try store.addReason("For my family", to: alcohol)
        try store.addReason("To feel in control", to: alcohol)
        try store.logSlip(alcohol, occurredAt: slipAt, triggers: [.tired, .routine], note: nil)
        for offset in [-1, -2, -3, -4] {
            if let day = calendar.date(byAdding: .day, value: offset, to: now) {
                try store.markFree(alcohol, on: day, now: day)
            }
        }

        _ = try store.addMetric(
            name: "Social media",
            habitType: .vice,
            iconName: "iphone",
            startedAt: socialStart,
            costPerDay: nil,
            firstReason: nil
        )

        let smoking = try store.addMetric(
            name: "Smoking",
            habitType: .vice,
            iconName: "smoke",
            startedAt: alcoholStart,
            costPerDay: 10,
            firstReason: "To breathe easier on runs",
            tracking: MetricTracking(viceMode: .cutBack, unit: "cigarettes", dailyTarget: 8, baselinePerDay: 20)
        )
        for (offset, amount) in [(-1, 7), (-2, 9), (-3, 8), (-4, 6), (-5, 10), (-6, 8)] {
            if let day = calendar.date(byAdding: .day, value: offset, to: now) {
                try store.setAmount(smoking, on: day, amount: amount, now: day)
            }
        }
        try store.setAmount(smoking, on: now, amount: 3, now: now)

        let water = try store.addMetric(
            name: "Drink water",
            habitType: .positive,
            iconName: "drop",
            startedAt: alcoholStart,
            costPerDay: nil,
            firstReason: nil,
            tracking: MetricTracking(unit: "glasses", dailyTarget: 8)
        )
        for (offset, amount) in [(0, 5), (-1, 8), (-2, 6), (-3, 8)] {
            if let day = calendar.date(byAdding: .day, value: offset, to: now) {
                try store.setAmount(water, on: day, amount: amount, now: day)
            }
        }

        let notes: [(Int, Mood, String?)] = [(-1, .good, "Long walk after work helped."), (-2, .low, "Rough meeting. Rode out two urges."), (-3, .okay, nil)]
        for (offset, mood, text) in notes {
            if let day = calendar.date(byAdding: .day, value: offset, to: now) {
                try store.setDayNote(on: day, mood: mood, text: text, now: day)
            }
        }

        let walk = try store.addMetric(
            name: "Go for a walk",
            habitType: .positive,
            iconName: "figure.walk",
            startedAt: alcoholStart,
            costPerDay: nil,
            firstReason: nil
        )
        let call = try store.addMetric(
            name: "Call a friend",
            habitType: .positive,
            iconName: "phone",
            startedAt: alcoholStart,
            costPerDay: nil,
            firstReason: nil
        )
        for offset in [-1, -2, -3, -4, -6] {
            if let day = calendar.date(byAdding: .day, value: offset, to: now) {
                try store.setHabitDone(walk, on: day, done: true, now: day)
            }
        }
        for offset in [-2, -3, -4] {
            if let day = calendar.date(byAdding: .day, value: offset, to: now) {
                try store.setHabitDone(call, on: day, done: true, now: day)
            }
        }

        let outcomes: [UrgeOutcome] = [.resisted, .resisted, .resisted, .resisted, .slipped, .unknown]
        for (index, outcome) in outcomes.enumerated() {
            let started = calendar.date(byAdding: .day, value: -(index + 1), to: now) ?? now
            let urge = try store.startUrge(for: alcohol, intensity: (index % 5) + 1, now: started)
            let note = index == 0 ? "The wave peaked and passed. I stayed because I want mornings back." : nil
            try store.finishUrge(urge, outcome: outcome, triggers: index.isMultiple(of: 2) ? [.stressed] : [], note: note, now: started)
        }
        let seededMetrics = try context.fetch(FetchDescriptor<Metric>())
        let seededEntries = try context.fetch(FetchDescriptor<MetricEntry>())
        let seededReasons = try context.fetch(FetchDescriptor<Reason>())
        for request in MilestoneCenter.pending(metrics: seededMetrics, entries: seededEntries, reasons: seededReasons, now: now, calendar: calendar) {
            MilestoneLedger.record(request.threshold, for: request.metricID)
        }
    }
}
