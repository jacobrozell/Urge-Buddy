import Foundation

enum AccessibilityIdentifiers {
    static let tabToday = "tab.today"
    static let tabProgress = "tab.progress"
    static let progressDetailPlaceholder = "progress.detailPlaceholder"
    static let tabSettings = "tab.settings"
    static let todayCheckInBanner = "today.checkInBanner"
    static let todaySOSButton = "today.sosButton"
    static let todayUrgeSurfing = "today.urgeSurfing"
    static let urgeSurfingLearn = "urge.surfing.learn"
    static let settingsUrgeSurfing = "settings.urgeSurfing"
    static let settingsViewOnboarding = "settings.viewOnboarding"
    static let checkInDone = "checkIn.done"
    static let urgePassed = "urge.passed"
    static let urgeSlipped = "urge.slipped"
    static let urgeDone = "urge.done"
    static let urgeWhyPager = "urge.whyPager"
    static let urgeAddWhy = "urge.addWhy"
    static let urgeSaveWhy = "urge.saveWhy"
    static let urgeJournal = "urge.journal"
    static let urgeJournalSave = "urge.journal.save"
    static let urgeJournalDelete = "urge.journal.delete"
    static let progressJournal = "progress.journal"
    static let slipSave = "slip.save"
    static let slipSummary = "slip.summary"
    static let celebrationContinue = "celebration.continue"
    static let dayEditorFree = "dayEditor.free"
    static let dayEditorSlipped = "dayEditor.slipped"
    static let dayEditorClear = "dayEditor.clear"
    static let settingsCrisisResources = "settings.crisisResources"
    static let settingsDeleteAll = "settings.deleteAll"
    static let onboardingNext = "onboarding.next"
    static let onboardingHabitOnly = "onboarding.habitOnly"
    static let onboardingFinish = "onboarding.finish"

    static func viceCard(_ id: UUID) -> String { "today.viceCard.\(id.uuidString)" }
    static func habitToggle(_ id: UUID) -> String { "today.habitToggle.\(id.uuidString)" }
    static func cutBackCard(_ id: UUID) -> String { "today.cutBackCard.\(id.uuidString)" }
    static func cutBackStepper(_ id: UUID) -> String { "today.cutBackStepper.\(id.uuidString)" }
    static func checkInAmount(_ id: UUID) -> String { "checkIn.amount.\(id.uuidString)" }
    static let checkInMood = "checkIn.mood"
    static let checkInNote = "checkIn.note"
    static let dayEditorAmount = "dayEditor.amount"
    static let dayEditorSaveNote = "dayEditor.saveNote"
    static func checkInFree(_ id: UUID) -> String { "checkIn.free.\(id.uuidString)" }
    static func checkInSlipped(_ id: UUID) -> String { "checkIn.slipped.\(id.uuidString)" }
    static func urgeIntensity(_ level: Int) -> String { "urge.intensity.\(level)" }
    static func progressMetricCard(_ id: UUID) -> String { "progress.metricCard.\(id.uuidString)" }
    static func calendarDay(_ day: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return String(format: "detail.calendarDay.%04d-%02d-%02d", year, month, day)
    }
    static func onboardingVicePreset(_ id: String) -> String { "onboarding.vicePreset.\(id)" }
}
