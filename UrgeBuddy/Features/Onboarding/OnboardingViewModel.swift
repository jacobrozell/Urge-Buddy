import Foundation
import Observation

struct OnboardingChoice: Identifiable, Equatable {
    var id: String
    var name: String
    var iconName: String
    var verb: String
    var unit: String = ""
    var dailyTarget: Int? = nil
}

struct OnboardingMetricDraft: Equatable {
    var name: String
    var habitType: HabitType
    var iconName: String
    var startedAt: Date
    var costPerDay: Decimal?
    var firstReason: String?
    var tracking: MetricTracking = .yesNo
}

@MainActor
@Observable
final class OnboardingViewModel {
    enum When: String, Equatable {
        case today, yesterday, picked
    }

    struct ViceDetail: Equatable {
        var mode: ViceMode = .quit
        var when: When = .today
        var pickedDay: Date
        var costText: String = ""
        var baselineText: String = ""
        var limitText: String = ""
    }

    enum Page: Equatable {
        case welcome
        case urgeSurfing
        case chooseVices
        case viceWhen(String)
        case why
        case habits
        case reminders
        case privacy
        case disclaimer
    }

    var habitOnly = false
    var selectedViceIDs: [String] = []
    var customViceName = ""
    var viceDetails: [String: ViceDetail] = [:]
    var reasonText = ""
    var selectedHabitIDs: [String] = []
    var customHabitName = ""
    var reminderHour = 20
    var reminderMinute = 0
    var wantsReminders = false
    var wantsLock = false
    var acceptedDisclaimer = false
    var pageIndex = 0
    var lockAvailable = true

    private let maxChoices = 3

    var pages: [Page] {
        var result: [Page] = [.welcome, .urgeSurfing, .chooseVices]
        if !habitOnly {
            result.append(contentsOf: viceChoices.map { .viceWhen($0.id) })
            result.append(.why)
        }
        result.append(contentsOf: [.habits, .reminders])
        if lockAvailable { result.append(.privacy) }
        result.append(.disclaimer)
        return result
    }

    var page: Page { pages[min(pageIndex, pages.count - 1)] }
    var canGoBack: Bool { pageIndex > 0 }
    var isLastPage: Bool { pageIndex >= pages.count - 1 }

    var viceChoices: [OnboardingChoice] {
        var result: [OnboardingChoice] = []
        for id in selectedViceIDs {
            guard let preset = Presets.vices.first(where: { $0.id == id }) else { continue }
            result.append(OnboardingChoice(id: preset.id, name: preset.name, iconName: preset.iconName, verb: preset.lastUseVerb, unit: preset.unit))
        }
        let custom = customViceName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty, result.count < maxChoices {
            result.append(OnboardingChoice(id: "custom", name: custom, iconName: Presets.fallbackIcon, verb: Presets.customVerb))
        }
        return result
    }

    var habitChoices: [OnboardingChoice] {
        var result: [OnboardingChoice] = []
        for id in selectedHabitIDs {
            guard let preset = Presets.habits.first(where: { $0.id == id }) else { continue }
            result.append(OnboardingChoice(id: preset.id, name: preset.name, iconName: preset.iconName, verb: "", unit: preset.unit, dailyTarget: preset.dailyTarget))
        }
        let custom = customHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty, result.count < maxChoices {
            result.append(OnboardingChoice(id: "custom-habit", name: custom, iconName: Presets.fallbackIcon, verb: ""))
        }
        return result
    }

    var vicesFull: Bool { viceChoices.count >= maxChoices }
    var habitsFull: Bool { habitChoices.count >= maxChoices }

    var canAdvance: Bool {
        switch page {
        case .chooseVices:
            return habitOnly || !viceChoices.isEmpty
        case .viceWhen(let id):
            let detail = detail(for: id, now: Date())
            guard detail.mode == .cutBack else { return true }
            return wholeNumber(detail.limitText) != nil
        default:
            return true
        }
    }

    func toggleVice(_ id: String) {
        habitOnly = false
        if let index = selectedViceIDs.firstIndex(of: id) {
            selectedViceIDs.remove(at: index)
        } else if viceChoices.count < maxChoices {
            selectedViceIDs.append(id)
        }
    }

    func toggleHabit(_ id: String) {
        if let index = selectedHabitIDs.firstIndex(of: id) {
            selectedHabitIDs.remove(at: index)
        } else if habitChoices.count < maxChoices {
            selectedHabitIDs.append(id)
        }
    }

    func chooseHabitsOnly() {
        habitOnly = true
        selectedViceIDs = []
        customViceName = ""
    }

    func detail(for id: String, now: Date) -> ViceDetail {
        if let existing = viceDetails[id] { return existing }
        return ViceDetail(pickedDay: now)
    }

    func setDetail(_ detail: ViceDetail, for id: String) {
        viceDetails[id] = detail
    }

    func goBack() {
        pageIndex = max(0, pageIndex - 1)
    }

    func advance() {
        guard canAdvance else { return }
        pageIndex = min(pages.count - 1, pageIndex + 1)
    }

    func drafts(now: Date, calendar: Calendar) -> [OnboardingMetricDraft] {
        var drafts: [OnboardingMetricDraft] = []
        if !habitOnly {
            let reason = reasonText.trimmingCharacters(in: .whitespacesAndNewlines)
            for (index, vice) in viceChoices.enumerated() {
                let detail = detail(for: vice.id, now: now)
                let cuttingBack = detail.mode == .cutBack
                drafts.append(OnboardingMetricDraft(
                    name: vice.name,
                    habitType: .vice,
                    iconName: vice.iconName,
                    startedAt: cuttingBack ? now : startedAt(detail, now: now, calendar: calendar),
                    costPerDay: cost(detail.costText),
                    firstReason: index == 0 && !reason.isEmpty ? reason : nil,
                    tracking: cuttingBack ? cutBackTracking(detail, unit: vice.unit) : .yesNo
                ))
            }
        }
        for habit in habitChoices {
            drafts.append(OnboardingMetricDraft(
                name: habit.name,
                habitType: .positive,
                iconName: habit.iconName,
                startedAt: now,
                costPerDay: nil,
                firstReason: nil,
                tracking: habit.dailyTarget.map { MetricTracking(unit: habit.unit, dailyTarget: $0) } ?? .yesNo
            ))
        }
        return drafts
    }

    /// No limit typed: start at the usual amount, or zero.
    func cutBackTracking(_ detail: ViceDetail, unit: String) -> MetricTracking {
        let baseline = wholeNumber(detail.baselineText).flatMap { $0 > 0 ? $0 : nil }
        let limit = wholeNumber(detail.limitText) ?? baseline ?? 0
        return MetricTracking(viceMode: .cutBack, unit: unit.isEmpty ? nil : unit, dailyTarget: limit, baselinePerDay: baseline)
    }

    private func wholeNumber(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmed), value >= 0 else { return nil }
        return value
    }

    func startedAt(_ detail: ViceDetail, now: Date, calendar: Calendar) -> Date {
        switch detail.when {
        case .today:
            return now
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            return DayMath.endOfDay(yesterday, calendar: calendar)
        case .picked:
            if calendar.isDate(detail.pickedDay, inSameDayAs: now) { return now }
            return DayMath.endOfDay(detail.pickedDay, calendar: calendar)
        }
    }

    private func cost(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = Decimal(string: trimmed), value > 0 else { return nil }
        return value
    }
}
