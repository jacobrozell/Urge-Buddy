import Foundation

enum AppAppearance: String, CaseIterable, Codable {
    case system, light, dark
}

enum Preferences {
    private static let defaults = UserDefaults.standard

    static var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Key.onboarding) }
        set { defaults.set(newValue, forKey: Key.onboarding) }
    }

    static var hasAcceptedDisclaimer: Bool {
        get { defaults.bool(forKey: Key.disclaimer) }
        set { defaults.set(newValue, forKey: Key.disclaimer) }
    }

    static var remindersEnabled: Bool {
        get { defaults.bool(forKey: Key.reminders) }
        set { defaults.set(newValue, forKey: Key.reminders) }
    }

    static var reminderHour: Int {
        get { defaults.object(forKey: Key.reminderHour) as? Int ?? 20 }
        set { defaults.set(newValue, forKey: Key.reminderHour) }
    }

    static var reminderMinute: Int {
        get { defaults.object(forKey: Key.reminderMinute) as? Int ?? 0 }
        set { defaults.set(newValue, forKey: Key.reminderMinute) }
    }

    static var milestoneNotificationsEnabled: Bool {
        get {
            if defaults.object(forKey: Key.milestones) == nil { return true }
            return defaults.bool(forKey: Key.milestones)
        }
        set { defaults.set(newValue, forKey: Key.milestones) }
    }

    static var discreetNotifications: Bool {
        get { defaults.bool(forKey: Key.discreet) }
        set { defaults.set(newValue, forKey: Key.discreet) }
    }

    static var appLockEnabled: Bool {
        get { defaults.bool(forKey: Key.appLock) }
        set { defaults.set(newValue, forKey: Key.appLock) }
    }

    static var appearance: AppAppearance {
        get { AppAppearance(rawValue: defaults.string(forKey: Key.appearance) ?? "") ?? .system }
        set { defaults.set(newValue.rawValue, forKey: Key.appearance) }
    }

    static var hasRequestedReview: Bool {
        get { defaults.bool(forKey: Key.review) }
        set { defaults.set(newValue, forKey: Key.review) }
    }

    static var dismissedYesterdayPromptDay: Date? {
        get {
            guard let interval = defaults.object(forKey: Key.yesterday) as? TimeInterval else { return nil }
            return Date(timeIntervalSinceReferenceDate: interval)
        }
        set {
            if let newValue {
                defaults.set(newValue.timeIntervalSinceReferenceDate, forKey: Key.yesterday)
            } else {
                defaults.removeObject(forKey: Key.yesterday)
            }
        }
    }

    static func resetAll() {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("pref.") {
            defaults.removeObject(forKey: key)
        }
    }

    private enum Key {
        static let onboarding = "pref.hasCompletedOnboarding"
        static let disclaimer = "pref.hasAcceptedDisclaimer"
        static let reminders = "pref.remindersEnabled"
        static let reminderHour = "pref.reminderHour"
        static let reminderMinute = "pref.reminderMinute"
        static let milestones = "pref.milestoneNotificationsEnabled"
        static let discreet = "pref.discreetNotifications"
        static let appLock = "pref.appLockEnabled"
        static let appearance = "pref.appearance"
        static let review = "pref.hasRequestedReview"
        static let yesterday = "pref.dismissedYesterdayPromptDay"
    }
}
