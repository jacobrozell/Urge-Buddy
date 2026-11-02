import Foundation
import SwiftData
import UserNotifications

enum ReminderScheduler {
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        @unknown default:
            return false
        }
    }

    @MainActor
    static func refresh(context: ModelContext, now: Date = Date(), calendar: Calendar = .current) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let stale = pending.map(\.identifier).filter { $0.hasPrefix("checkin.") || $0.hasPrefix("milestone.") }
        center.removePendingNotificationRequests(withIdentifiers: stale)
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        default:
            return
        }

        let metrics = (try? context.fetch(FetchDescriptor<Metric>())) ?? []
        let entries = (try? context.fetch(FetchDescriptor<MetricEntry>())) ?? []
        let activeVices = metrics.filter { !$0.isArchived && $0.habitType == .vice }
        let today = calendar.startOfDay(for: now)
        let checkInComplete = activeVices.allSatisfy { metric in
            entries.contains { $0.metricID == metric.id && calendar.isDate($0.day, inSameDayAs: today) }
        }
        let vices = activeVices.filter(\.isQuitting).map { metric in
            let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: calendar)
            return MilestoneReminderInput(
                metricID: metric.id,
                name: metric.name,
                runStart: RecoveryMath.currentRunStart(history),
                runDays: RecoveryMath.currentRunDays(history, now: now, calendar: calendar)
            )
        }
        let planned = ReminderPlan.requests(
            remindersEnabled: Preferences.remindersEnabled,
            hour: Preferences.reminderHour,
            minute: Preferences.reminderMinute,
            milestonesEnabled: Preferences.milestoneNotificationsEnabled,
            discreet: Preferences.discreetNotifications,
            checkInCompleteToday: checkInComplete,
            vices: vices,
            now: now,
            calendar: calendar
        )
        for note in planned {
            let content = UNMutableNotificationContent()
            content.title = note.title
            content.body = note.body
            content.sound = .default
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: note.fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            let request = UNNotificationRequest(identifier: note.identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
