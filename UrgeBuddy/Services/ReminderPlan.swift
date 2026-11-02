import Foundation

struct PlannedNotification: Equatable {
    var identifier: String
    var title: String
    var body: String
    var fire: Date
}

struct MilestoneReminderInput: Equatable {
    var metricID: UUID
    var name: String
    var runStart: Date
    var runDays: Int
}

enum ReminderPlan {
    static func requests(
        remindersEnabled: Bool,
        hour: Int,
        minute: Int,
        milestonesEnabled: Bool,
        discreet: Bool,
        checkInCompleteToday: Bool,
        vices: [MilestoneReminderInput],
        now: Date,
        calendar: Calendar = .current
    ) -> [PlannedNotification] {
        var planned: [PlannedNotification] = []
        if remindersEnabled {
            planned.append(contentsOf: checkIns(
                hour: hour,
                minute: minute,
                discreet: discreet,
                checkInCompleteToday: checkInCompleteToday,
                now: now,
                calendar: calendar
            ))
        }
        if milestonesEnabled {
            let room = max(0, 27 - planned.count)
            planned.append(contentsOf: milestones(vices: vices, discreet: discreet, now: now, calendar: calendar, limit: room))
        }
        return planned
    }

    private static func checkIns(
        hour: Int,
        minute: Int,
        discreet: Bool,
        checkInCompleteToday: Bool,
        now: Date,
        calendar: Calendar
    ) -> [PlannedNotification] {
        let start = calendar.startOfDay(for: now)
        var notes: [PlannedNotification] = []
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            var parts = calendar.dateComponents([.year, .month, .day], from: day)
            parts.hour = hour
            parts.minute = minute
            guard let fire = calendar.date(from: parts) else { continue }
            if offset == 0, checkInCompleteToday || fire <= now { continue }
            let key = String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
            notes.append(PlannedNotification(
                identifier: "checkin.\(key)",
                title: discreet ? RecoveryCopy.discreetCheckInTitle : RecoveryCopy.checkInNotificationTitle,
                body: discreet ? RecoveryCopy.discreetCheckInBody : RecoveryCopy.checkInNotificationBody,
                fire: fire
            ))
        }
        return notes
    }

    private static func milestones(
        vices: [MilestoneReminderInput],
        discreet: Bool,
        now: Date,
        calendar: Calendar,
        limit: Int
    ) -> [PlannedNotification] {
        guard let horizon = calendar.date(byAdding: .day, value: 30, to: now) else { return [] }
        var notes: [PlannedNotification] = []
        for vice in vices.prefix(10) {
            var cursor = vice.runDays
            for _ in 0..<2 {
                let threshold = MilestonePolicy.next(after: cursor, isVice: true)
                cursor = threshold
                guard let fire = calendar.date(byAdding: .day, value: threshold, to: vice.runStart),
                      fire > now, fire <= horizon else { continue }
                notes.append(PlannedNotification(
                    identifier: "milestone.\(vice.metricID.uuidString).\(threshold)",
                    title: discreet ? RecoveryCopy.discreetCheckInTitle : RecoveryCopy.milestoneNotificationTitle(threshold),
                    body: discreet ? RecoveryCopy.discreetMilestoneBody : RecoveryCopy.milestoneNotificationBody(threshold, name: vice.name),
                    fire: fire
                ))
                if notes.count >= limit { return notes }
            }
        }
        return notes
    }
}
