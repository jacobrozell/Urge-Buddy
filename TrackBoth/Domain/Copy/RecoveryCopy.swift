import Foundation

enum RecoveryCopy {
    static func daysFree(_ count: Int) -> String {
        count == 1 ? "1 day free" : "\(count) days free"
    }

    static func clock(days: Int, hours: Int, minutes: Int) -> String {
        if days > 0 {
            var parts = ["\(days)d"]
            if hours > 0 { parts.append("\(hours)h") }
            if minutes > 0 { parts.append("\(minutes)m") }
            return parts.joined(separator: " ")
        }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "Just started"
    }

    static func clock(_ components: DateComponents) -> String {
        clock(days: components.day ?? 0, hours: components.hour ?? 0, minutes: components.minute ?? 0)
    }

    static func money(_ amount: Decimal, locale: Locale = .current) -> String {
        let code = locale.currency?.identifier ?? "USD"
        return amount.formatted(.currency(code: code).locale(locale))
    }

    static func saved(_ amount: Decimal, locale: Locale = .current) -> String {
        "\(money(amount, locale: locale)) saved"
    }

    static func freeOfLast(free: Int, counted: Int) -> String {
        "\(free) of last \(counted) days free"
    }

    static func habitRun(_ count: Int) -> String {
        count == 1 ? "1-day run" : "\(count)-day run"
    }

    static let dontMissTwice = "Don't miss twice"

    static func nextMilestone(_ threshold: Int, inDays: Int) -> String {
        let unit = inDays == 1 ? "day" : "days"
        return "Next: \(threshold) days (in \(inDays) \(unit))"
    }

    static func checkInBanner(left: Int) -> String {
        "\(left) to go · about 10 seconds"
    }

    static let sosButton = "I'm having an urge"
    static let urgeIntro = "Urges rise, peak, and pass, like a wave. Let's ride this one out."

    static func urgePassed(_ count: Int) -> String {
        let noun = count == 1 ? "urge" : "urges"
        return "You rode it out. That's \(count) \(noun) you've beaten."
    }

    static let slipTitle = "Thanks for being honest."
    static let slipSubtitle = "A slip is information, not failure. Let's learn from it."
    static let slipSummaryTitle = "Your free clock restarts from here."

    static func slipSummaryBody(free: Int, counted: Int, saved: String?) -> String {
        let savings = saved.map { " and \($0) saved" } ?? ""
        return "You still have \(free) of your last \(counted) days free\(savings). That progress is real and it stays."
    }

    static func milestoneVice(_ threshold: Int, name: String) -> String {
        threshold == 1 ? "Your first day free from \(name)." : "\(threshold) days free from \(name)."
    }

    static func milestoneHabit(_ threshold: Int, name: String) -> String {
        "\(threshold)-day run: \(name)."
    }

    static let disclaimer = "TrackBoth is a self-help tool, not medical treatment. Stopping some substances suddenly, like alcohol, benzodiazepines, or opioids, can be dangerous. Talk to a doctor. If you're in crisis, help is in Settings → Get help now."

    static let checkInTitle = "Daily check-in"
    static let freeToday = "Free today"
    static let iSlipped = "I slipped"
    static let quitting = "Quitting"
    static let building = "Building"
    static let startWithOneThing = "Start with one thing"
    static let startWithOneThingMessage = "Add a vice or a habit and today gets simpler."
    static let addSomething = "Add something"
    static let yesterdayYes = "Yes"
    static let dismiss = "Dismiss"
    static let slipLoggedThanks = "Slip logged · thanks for being honest"
    static let havingAnUrge = "Having an urge right now?"
    static let done = "Done"
    static let backToToday = "Back to Today"
    static let close = "Close"

    static func yesterdayPrompt(_ name: String) -> String {
        "Yesterday: were you free from \(name)?"
    }

    static func checkInSummary(days: Int, saved: String?) -> String {
        if let saved { return "\(daysFree(days)) · \(saved)" }
        return daysFree(days)
    }

    static let whichOne = "Which one?"
    static let howStrong = "How strong is it?"
    static let mild = "Mild"
    static let intense = "Intense"
    static let skip = "Skip"
    static let theUrgePassed = "The urge passed"
    static let notSure = "Not sure"
    static let howDidItGo = "How did it go?"
    static let addFiveMinutes = "+5 min"
    static let stillWithIt = "Still with it? You can add 5 minutes, or check in with yourself."
    static let yourWhy = "Your why"
    static let yourPlanPrefix = "When I feel the urge, I will:"
    static let tryOneInstead = "Try one instead"
    static let whatSetItOff = "What set it off?"
    static let whenQuestion = "When?"
    static let justNow = "Just now"
    static let earlierToday = "Earlier today"
    static let yesterday = "Yesterday"
    static let pickADay = "Pick a day…"
    static let whatWasGoingOn = "What was going on?"
    static let anythingElse = "Anything else?"
    static let nextTimePlan = "Next time I feel the urge, I will…"
    static let save = "Save"
    static let rememberWhy = "Remember why:"
    static let keepGoing = "Keep going"
    static let needSupport = "Need more support?"
    static let getHelpNow = "Get help now"
    static let noViceForUrge = "Add something you're quitting first."
    static let slipBeforeStart = "That day is before this quit date."
    static let urgesBeaten = "Urges beaten"
    static func intensityLabel(_ level: Int) -> String {
        switch level {
        case 1: "1 \(mild)"
        case 5: "5 \(intense)"
        default: "\(level)"
        }
    }

    static func urgesBeatenCount(_ count: Int) -> String { "\(urgesBeaten) \(count)" }

    static func viceProgress(days: Int, longest: Int, free: Int, counted: Int) -> String {
        "\(daysFree(days))\nLongest \(longest) days · \(free)/\(counted) days"
    }

    static func habitProgress(run: Int, best: Int, done: Int, counted: Int) -> String {
        "\(habitRun(run))\nBest \(best) days · \(done)/\(counted) days"
    }

    static let totalSaved = "Total saved"
    static let daysCheckedIn = "Days checked in"
    static let pickSomethingTitle = "Pick something to see its progress"
    static let archived = "Archived"
    static let yourReasons = "Your reasons"
    static let reasonOrderHint = "The first one is what you see when you slip."
    static let reasonsEmpty = "Add one you can read when an urge hits."
    static let primaryReason = "Primary"
    static let yourPlan = "Your plan"
    static let patterns = "Patterns"
    static let hardestTime = "Hardest time"
    static let hardestDay = "Hardest day"
    static let addReason = "Add a reason"
    static let editReason = "Edit reason"
    static let moveUp = "Move up"
    static let moveDown = "Move down"
    static let urges = "Urges"
    static let slippedStat = "Slipped"
    static let averageStrengthLabel = "Average strength"
    static let noUrgesYet = "Urges you ride out show up here."
    static let recent = "Recent"
    static let rodeItOut = "Rode it out"
    static let slipEvent = "Slip"
    static let notSureOutcome = "Not sure"
    static let addDailyCost = "Add a daily cost"
    static let legendCheckedFree = "Checked in free"
    static let legendCountedFree = "Counted as free"
    static let legendSlip = "Slip"
    static let legendToday = "Not checked in"
    static let legendDone = "Done"
    static let legendMissed = "Not done"
    static let freeLast30Tile = "Free, last 30"
    static let doneLast30Tile = "Done, last 30"

    static func perDay(_ amount: Decimal, locale: Locale = .current) -> String {
        "\(money(amount, locale: locale)) a day"
    }
    static func strength(_ level: Int) -> String { "Strength \(level)" }
    static func averageStrength(_ average: Double) -> String {
        let tenths = (average * 10).rounded() / 10
        if tenths == tenths.rounded() { return String(Int(tenths)) }
        return String(format: "%.1f", tenths)
    }
    static let edit = "Edit"
    static let quitDate = "Quit date"
    static let startedLabel = "Started"
    static let nameField = "Name"
    static let nameRequired = "Add a name."
    static let nameTooLong = "Keep the name under 40 characters."
    static let costPerDay = "Cost per day"
    static let archive = "Archive"
    static let restore = "Restore"
    static let delete = "Delete"
    static func deleteConfirm(_ name: String) -> String { "Delete \(name) and all of its history? This can't be undone." }
    static let currentRun = "Current run"
    static let longestRun = "Longest run"
    static let freeLast30 = "Free days"
    static let savedStat = "Saved"
    static let bestRun = "Best run"
    static let doneLast30 = "Done"
    static let doneAllTime = "Done, all time"
    static let free = "Free"
    static let clearDay = "Clear"
    static let notDone = "Not done"
    static let beatenOf = "Beaten"

    static let checkInNotificationTitle = "Daily check-in"
    static let checkInNotificationBody = "How did today go? It takes 10 seconds."
    static let discreetCheckInTitle = "TrackBoth"
    static let discreetCheckInBody = "Time for your check-in."
    static let discreetMilestoneBody = "You reached a new milestone."

    static func milestoneNotificationTitle(_ threshold: Int) -> String {
        "\(threshold) days free"
    }

    static func milestoneNotificationBody(_ threshold: Int, name: String) -> String {
        "You reached \(threshold) days free from \(name). Open TrackBoth to celebrate."
    }

    static let welcomeTitle = "Quit what's hurting you. Build what helps."
    static let welcomeLine1 = "Check in once a day. It takes about 10 seconds."
    static let welcomeLine2 = "When an urge hits, ride it out."
    static let welcomeLine3 = "A slip restarts the clock. It does not erase your progress."
    static let getStarted = "Get started"
    static let whatToQuit = "What do you want to quit?"
    static let somethingElse = "Something else…"
    static let habitOnlyLink = "I only want to build habits"
    static let pickUpToThree = "Pick up to 3."
    static let whatDoesItCost = "What does it cost you per day?"
    static let optional = "Optional"
    static let forMyHealth = "For my health…"
    static let forMyFamily = "For my family…"
    static let toSaveMoney = "To save money…"
    static let toFeelInControl = "To feel in control…"
    static let whatHelps = "What helps you?"
    static let dailyCheckInTime = "Daily check-in time"
    static let reminderExplainer = "We'll send one gentle reminder a day. Nothing else."
    static let turnOnReminders = "Turn on reminders"
    static let notNow = "Not now"
    static let keepPrivate = "Keep it private?"
    static let lockPrompt = "Lock TrackBoth when you leave the app."
    static let turnOn = "Turn on"
    static let important = "Important"
    static let iUnderstand = "I understand"
    static let next = "Next"
    static let back = "Back"
    static let onboardingToday = "Today"
    static func whenDidYouLast(_ verb: String) -> String { "When did you last \(verb)?" }
    static func whyQuitNamed(_ name: String) -> String {
        name.isEmpty ? "Why does this matter?" : "Why do you want to quit \(name)?"
    }
    static func whyCutBackNamed(_ name: String) -> String { "Why do you want to cut back on \(name)?" }
    static func onboardingProgress(current: Int, total: Int) -> String { "Step \(current) of \(total)" }

    static let settingsReminders = "Reminders"
    static let dailyCheckInToggle = "Daily check-in"
    static let time = "Time"
    static let milestoneNotifications = "Milestone notifications"
    static let discreetNotifications = "Discreet notifications"
    static let discreetFooter = "Hides habit and vice names on your lock screen."
    static let privacySection = "Privacy"
    static let lockFaceID = "Lock with Face ID"
    static let lockTouchID = "Lock with Touch ID"
    static let lockOpticID = "Lock with Optic ID"
    static let lockPasscode = "Lock with passcode"
    static let noPasscodeNote = "Set a device passcode to lock TrackBoth."
    static let appearanceSection = "Appearance"
    static let systemAppearance = "System"
    static let lightAppearance = "Light"
    static let darkAppearance = "Dark"
    static let yourData = "Your data"
    static let exportBackup = "Export backup"
    static let importBackup = "Import backup"
    static let deleteAll = "Delete all data"
    static let deleteAllConfirm = "Delete everything on this device?"
    static let deleteAllSecond = "This removes your vices, habits, and history. This can't be undone."
    static let continueDelete = "Continue"
    static let supportSection = "Support"
    static let contactSupport = "Contact support"
    static let privacyPolicy = "Privacy policy"
    static let rateTrackBoth = "Rate TrackBoth"
    static let aboutSection = "About"
    static let version = "Version"
    static let accessibilityStatement = "Accessibility statement"
    static let replaceBackup = "This replaces everything on this device with the backup."
    static let newerBackup = "This backup is from a newer version of TrackBoth."
    static let invalidBackup = "This file isn't a TrackBoth backup."
    static let backupProblem = "Backup"
    static let lockedTitle = "TrackBoth is locked"
    static let unlock = "Unlock"
    static let unlockReason = "Unlock TrackBoth"
    static let crisisImmediate = "If you're in immediate danger, call 911 or your local emergency number."
    static let crisis988 = "988 Suicide & Crisis Lifeline"
    static let call988 = "Call 988"
    static let text988 = "Text 988"
    static let crisisSAMHSA = "SAMHSA National Helpline"
    static let crisisSAMHSADetail = "1-800-662-4357. Free, confidential, 24/7, English and Spanish."
    static let callSAMHSA = "Call 1-800-662-4357"
    static let crisisOutside = "Outside the US, find a helpline"
    static let crisisMedical = "Stopping alcohol, benzodiazepines, or opioids suddenly can be dangerous. Talk to a doctor or pharmacist."

    // MARK: Amounts and cutting back

    static let cuttingBack = "Cutting back"
    static let quitMode = "Quit"
    static let cutBackMode = "Cut back"
    static let quitOrCutBack = "Quit or cut back?"
    static let cutBackExplainer = "Cutting back sets a daily limit. You can switch to quitting any time."
    static let unitField = "Counted in"
    static let unitPlaceholder = "e.g. cigarettes, drinks, minutes"
    static let usualPerDay = "Usual amount per day"
    static let howManyNow = "How many a day right now?"
    static let dailyLimit = "Daily limit"
    static let dailyLimitPrompt = "What's your daily limit to start?"
    static let dailyTarget = "Daily target"
    static let trackAnAmount = "Track an amount"
    static let trackAnAmountFooter = "Count toward a daily target, like 8 glasses of water or 30 minutes."
    static let costAtUsual = "Cost per day at your usual amount"
    static let limitRequired = "Set a daily limit. Zero is fine."
    static let targetRequired = "Set a daily target of at least 1."
    static let logOne = "Log one"
    static let removeOne = "Remove one"
    static let iHadOne = "I had one"
    static let overLimitToday = "Over your limit today. Tomorrow is a fresh start."
    static let todayTile = "Today"
    static let averageLast7 = "Average, last 7"
    static let withinLast30Tile = "Within limit, last 30"
    static let usualTile = "Before cutting back"
    static let legendWithin = "Within limit"
    static let legendOver = "Over limit"
    static let legendNotLogged = "Not logged"
    static let legendPartial = "Partly done"
    static func howManyToday(limit: Int) -> String { "How many today? Your limit is \(limit)." }
    static let amount = "Amount"
    static let saveAmount = "Save amount"

    static func amountOf(_ amount: Int, _ limit: Int, unit: String) -> String {
        "\(amount) of \(limit) \(unit)"
    }

    static func amountUnit(_ amount: Int, unit: String) -> String {
        "\(amount) \(unit)"
    }

    static func todayAmount(_ amount: Int, limit: Int, unit: String) -> String {
        "\(amountOf(amount, limit, unit: unit)) today"
    }

    static func perDayAmount(_ amount: Int, unit: String) -> String {
        "\(amount) \(unit) a day"
    }

    static func average(_ value: Double) -> String {
        let tenths = (value * 10).rounded() / 10
        if tenths == tenths.rounded() { return String(Int(tenths)) }
        return String(format: "%.1f", tenths)
    }

    static func averageLine(_ value: Double, unit: String) -> String {
        "\(average(value)) \(unit) a day, last 7"
    }

    static func averageShort(_ value: Double) -> String {
        "Avg \(average(value)) a day"
    }

    static func reduction(_ percent: Int, baseline: Int, unit: String) -> String {
        "Down \(percent)% from \(perDayAmount(baseline, unit: unit))"
    }

    static func cutBackProgress(today: String, average: String?, within: Int, logged: Int) -> String {
        var second: [String] = []
        if let average { second.append(average) }
        if logged > 0 { second.append("\(within)/\(logged) within limit") }
        return second.isEmpty ? today : "\(today)\n\(second.joined(separator: " · "))"
    }

    static func cutBackSummary(amount: Int, limit: Int, unit: String, saved: String?) -> String {
        let line = todayAmount(amount, limit: limit, unit: unit)
        if let saved { return "\(line) · \(saved)" }
        return line
    }
    // MARK: Mood and notes

    static let howAreYouFeeling = "How are you feeling?"
    static let noteField = "Anything on your mind? (optional)"
    static let yourDay = "Your day"
    static let saveNote = "Save note"
    static let recentDays = "Recent days"

    static func moodLine(_ mood: Mood?, note: String?) -> String {
        [mood?.title, note].compactMap { $0 }.joined(separator: " · ")
    }
}
