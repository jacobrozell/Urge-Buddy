import SwiftData
import SwiftUI

struct OnboardingFlow: View {
    var onFinished: () -> Void
    /// Look through the pages again. Does not save vices, habits, or preferences.
    var review = false

    @Environment(\.modelContext) private var modelContext
    @Environment(AppLock.self) private var appLock
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.persist) private var persist
    @State private var model = OnboardingViewModel()
    @FocusState private var keyboard: Bool

    private var isShortHeight: Bool {
        AdaptiveLayout.isShortHeight(vertical: verticalSizeClass)
    }

    var body: some View {
        Group {
            if isShortHeight {
                VStack(spacing: Spacing.s) {
                    progress
                        .padding(.horizontal, Spacing.l)
                    HStack(alignment: .top, spacing: Spacing.l) {
                        pager.frame(maxWidth: .infinity)
                        ScrollView {
                            controls
                                .padding(.top, Spacing.s)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        .frame(width: AdaptiveLayout.sideColumnWidth)
                    }
                    .padding(.trailing, Spacing.l)
                }
            } else {
                VStack(spacing: Spacing.l) {
                    ReadableColumn { progress }
                    pager
                    ReadableColumn { controls }
                }
            }
        }
        .background(Color.tbBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(RecoveryCopy.done) { keyboard = false }
            }
        }
        .onAppear {
            model.lockAvailable = appLock.isAvailable
            if LaunchConfiguration.startsOnVices {
                model.pageIndex = model.pages.firstIndex(of: .chooseVices) ?? model.pageIndex
            }
        }
        .onChange(of: model.pages.count) { _, count in
            if model.pageIndex >= count { model.pageIndex = max(0, count - 1) }
        }
    }

    /// One page at a time. A paged TabView rebuilt every page whenever the page list changed,
    /// which dropped the keyboard mid-word in Something else, and its swipe skipped the Next checks.
    private var pager: some View {
        ZStack {
            ScrollView {
                ReadableColumn {
                    pageView(model.page)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Spacing.l)
                }
            }
            .id(model.pageIndex)
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.2), value: model.pageIndex)
    }

    private var progress: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Color.tbSurfaceMuted)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.tbBrand)
                        .frame(width: proxy.size.width * progressFraction)
                }
        }
        .frame(height: 6)
        .padding(.top, Spacing.m)
        .accessibilityLabel(RecoveryCopy.onboardingProgress(current: model.pageIndex + 1, total: model.pages.count))
    }

    private var progressFraction: CGFloat {
        guard !model.pages.isEmpty else { return 1 }
        return CGFloat(model.pageIndex + 1) / CGFloat(model.pages.count)
    }

    @ViewBuilder
    private func pageView(_ page: OnboardingViewModel.Page) -> some View {
        switch page {
        case .welcome:
            welcome
        case .urgeSurfing:
            urgeSurfing
        case .chooseVices:
            chooseVices
        case .viceWhen(let id):
            if let vice = model.viceChoices.first(where: { $0.id == id }) {
                viceWhen(vice)
            }
        case .why:
            why
        case .habits:
            habits
        case .reminders:
            reminders
        case .privacy:
            privacy
        case .disclaimer:
            disclaimer
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            BrandMark(size: isShortHeight ? 48 : 72)
            Text(RecoveryCopy.welcomeTitle)
                .font(.title.weight(.bold))
                .foregroundStyle(Color.tbTextPrimary)
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text(RecoveryCopy.welcomeLine1)
                Text(RecoveryCopy.welcomeLine2)
                Text(RecoveryCopy.welcomeLine3)
            }
            .font(.body)
            .foregroundStyle(Color.tbTextSecondary)
        }
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var urgeSurfing: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(RecoveryCopy.urgeSurfingTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.tbTextPrimary)
            UrgeSurfingLesson()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chooseVices: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(RecoveryCopy.whatToQuit)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.tbTextPrimary)
            Text(RecoveryCopy.pickUpToThree)
                .font(.subheadline)
                .foregroundStyle(Color.tbTextSecondary)
            presetGrid(Presets.vices, selected: model.selectedViceIDs, full: model.vicesFull) { preset in
                model.toggleVice(preset.id)
            }
            TextField(RecoveryCopy.somethingElse, text: customViceName)
                .textFieldStyle(.tbField)
                .focused($keyboard)
                .onChange(of: model.customViceName) { _, _ in model.habitOnly = false }
            Button(RecoveryCopy.habitOnlyLink) { model.chooseHabitsOnly() }
                .frame(minHeight: 44)
                .foregroundStyle(Color.tbBrand)
                .accessibilityIdentifier(AccessibilityIdentifiers.onboardingHabitOnly)
        }
    }

    private func viceWhen(_ vice: OnboardingChoice) -> some View {
        let detail = model.detail(for: vice.id, now: Date())
        return VStack(alignment: .leading, spacing: Spacing.l) {
            Text(RecoveryCopy.quitOrCutBack)
                .font(.headline)
                .foregroundStyle(Color.tbTextPrimary)
            HStack(spacing: Spacing.s) {
                whenButton(RecoveryCopy.quitMode, selected: detail.mode == .quit) {
                    update(vice.id, detail) { $0.mode = .quit }
                }
                whenButton(RecoveryCopy.cutBackMode, selected: detail.mode == .cutBack) {
                    update(vice.id, detail) { $0.mode = .cutBack }
                }
            }
            if detail.mode == .cutBack {
                Text(RecoveryCopy.cutBackExplainer)
                    .font(.footnote)
                    .foregroundStyle(Color.tbTextSecondary)
                numberField(RecoveryCopy.howManyNow, unit: vice.unit, text: textBinding(vice.id, \.baselineText))
                numberField(RecoveryCopy.dailyLimitPrompt, unit: vice.unit, text: textBinding(vice.id, \.limitText))
                Text(RecoveryCopy.limitRequired)
                    .font(.footnote)
                    .foregroundStyle(Color.tbTextSecondary)
            } else {
                Text(RecoveryCopy.whenDidYouLast(vice.verb))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.tbTextPrimary)
                whenButtons(viceID: vice.id, detail: detail)
            }
            Text(RecoveryCopy.whatDoesItCost)
                .font(.headline)
                .foregroundStyle(Color.tbTextPrimary)
            TextField(RecoveryCopy.costPerDay, text: textBinding(vice.id, \.costText))
                .keyboardType(.decimalPad)
                .textFieldStyle(.tbField)
                .focused($keyboard)
            Text(RecoveryCopy.optional)
                .font(.footnote)
                .foregroundStyle(Color.tbTextSecondary)
        }
    }

    private var whyTitle: String {
        guard let first = model.viceChoices.first else { return RecoveryCopy.whyQuitNamed("") }
        return model.detail(for: first.id, now: Date()).mode == .cutBack
            ? RecoveryCopy.whyCutBackNamed(first.name)
            : RecoveryCopy.whyQuitNamed(first.name)
    }

    private func numberField(_ title: String, unit: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.tbTextPrimary)
            HStack(spacing: Spacing.s) {
                TextField("0", text: text)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.tbField)
                    .focused($keyboard)
                Text(unit.isEmpty ? AmountMath.defaultUnit : unit)
                    .foregroundStyle(Color.tbTextSecondary)
            }
        }
    }

    private func textBinding(_ id: String, _ keyPath: WritableKeyPath<OnboardingViewModel.ViceDetail, String>) -> Binding<String> {
        Binding(
            get: { model.detail(for: id, now: Date())[keyPath: keyPath] },
            set: { text in
                var next = model.detail(for: id, now: Date())
                next[keyPath: keyPath] = text
                model.setDetail(next, for: id)
            }
        )
    }

    private func whenButtons(viceID: String, detail: OnboardingViewModel.ViceDetail) -> some View {
        VStack(spacing: Spacing.s) {
            whenButton(RecoveryCopy.onboardingToday, selected: detail.when == .today) {
                update(viceID, detail) { $0.when = .today }
            }
            whenButton(RecoveryCopy.yesterday, selected: detail.when == .yesterday) {
                update(viceID, detail) { $0.when = .yesterday }
            }
            whenButton(RecoveryCopy.pickADay, selected: detail.when == .picked) {
                update(viceID, detail) { $0.when = .picked }
            }
            if detail.when == .picked {
                DatePicker(RecoveryCopy.pickADay, selection: pickedBinding(viceID), in: ...Date(), displayedComponents: .date)
            }
        }
    }

    private func whenButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(selected ? Color.tbOnBrand : Color.tbTextPrimary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(selected ? Color.tbBrand : Color.tbSurfaceMuted, in: RoundedRectangle(cornerRadius: Radius.control))
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var why: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(whyTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.tbTextPrimary)
            TextField(RecoveryCopy.yourWhy, text: reasonText, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.tbField)
                .focused($keyboard)
            chipRow
        }
    }

    private var chipRow: some View {
        FlowChips(titles: [
            RecoveryCopy.forMyHealth,
            RecoveryCopy.forMyFamily,
            RecoveryCopy.toSaveMoney,
            RecoveryCopy.toFeelInControl
        ]) { chip in
            if model.reasonText.isEmpty {
                model.reasonText = chip
            } else {
                model.reasonText += " " + chip
            }
        }
    }

    private var habits: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(RecoveryCopy.whatHelps)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.tbTextPrimary)
            Text(RecoveryCopy.pickUpToThree)
                .font(.subheadline)
                .foregroundStyle(Color.tbTextSecondary)
            presetGrid(Presets.habits, selected: model.selectedHabitIDs, full: model.habitsFull) { preset in
                model.toggleHabit(preset.id)
            }
            TextField(RecoveryCopy.somethingElse, text: customHabitName)
                .textFieldStyle(.tbField)
                .focused($keyboard)
        }
    }

    private var reminders: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(RecoveryCopy.dailyCheckInTime)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.tbTextPrimary)
            Text(RecoveryCopy.reminderExplainer)
                .font(.body)
                .foregroundStyle(Color.tbTextSecondary)
            DatePicker(RecoveryCopy.time, selection: reminderDate, displayedComponents: .hourAndMinute)
        }
    }

    private var privacy: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(RecoveryCopy.keepPrivate)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.tbTextPrimary)
            Text(RecoveryCopy.lockPrompt)
                .font(.body)
                .foregroundStyle(Color.tbTextSecondary)
        }
    }

    private var disclaimer: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(RecoveryCopy.important)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.tbTextPrimary)
            Text(RecoveryCopy.disclaimer)
                .font(.body)
                .foregroundStyle(Color.tbTextPrimary)
        }
    }

    private var controls: some View {
        VStack(spacing: Spacing.s) {
            if !review, case .reminders = model.page {
                PrimaryButton(title: RecoveryCopy.turnOnReminders, accessibilityID: AccessibilityIdentifiers.onboardingNext) {
                    Task { await turnOnReminders() }
                }
                SecondaryButton(title: RecoveryCopy.notNow) { model.advance() }
            } else if !review, case .privacy = model.page {
                PrimaryButton(title: RecoveryCopy.turnOn, accessibilityID: AccessibilityIdentifiers.onboardingNext) {
                    model.wantsLock = true
                    model.advance()
                }
                SecondaryButton(title: RecoveryCopy.notNow) { model.advance() }
            } else if model.isLastPage {
                PrimaryButton(title: review ? RecoveryCopy.done : RecoveryCopy.iUnderstand, accessibilityID: AccessibilityIdentifiers.onboardingFinish) {
                    if review {
                        onFinished()
                    } else {
                        model.acceptedDisclaimer = true
                        finish()
                    }
                }
            } else {
                PrimaryButton(
                    title: model.page == .welcome ? RecoveryCopy.getStarted : RecoveryCopy.next,
                    accessibilityID: AccessibilityIdentifiers.onboardingNext
                ) { model.advance() }
                .disabled(!review && !model.canAdvance)
            }
            if model.canGoBack {
                Button(RecoveryCopy.back) { model.goBack() }
                    .frame(minHeight: 44)
                    .foregroundStyle(Color.tbTextSecondary)
            }
        }
        .padding(.bottom, Spacing.l)
    }

    /// When three are picked, the rest dim instead of ignoring taps.
    private func presetGrid(_ presets: [Preset], selected: [String], full: Bool, toggle: @escaping (Preset) -> Void) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Spacing.s)], spacing: Spacing.s) {
            ForEach(presets) { preset in
                let isOn = selected.contains(preset.id)
                Button { toggle(preset) } label: {
                    HStack(spacing: Spacing.s) {
                        Image(systemName: preset.iconName)
                        Text(preset.name)
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(isOn ? Color.tbOnBrand : Color.tbTextPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.s)
                    .background(isOn ? Color.tbBrand : Color.tbSurfaceMuted, in: RoundedRectangle(cornerRadius: Radius.control))
                }
                .buttonStyle(.pressable)
                .disabled(full && !isOn)
                .accessibilityAddTraits(isOn ? .isSelected : [])
                .accessibilityIdentifier(AccessibilityIdentifiers.onboardingVicePreset(preset.id))
            }
        }
    }

    private var customViceName: Binding<String> {
        Binding(get: { model.customViceName }, set: { model.customViceName = $0 })
    }

    private var customHabitName: Binding<String> {
        Binding(get: { model.customHabitName }, set: { model.customHabitName = $0 })
    }

    private var reasonText: Binding<String> {
        Binding(get: { model.reasonText }, set: { model.reasonText = $0 })
    }

    private var reminderDate: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: model.reminderHour, minute: model.reminderMinute)) ?? Date()
            },
            set: { newValue in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                model.reminderHour = parts.hour ?? 20
                model.reminderMinute = parts.minute ?? 0
            }
        )
    }

    private func pickedBinding(_ id: String) -> Binding<Date> {
        Binding(
            get: { model.detail(for: id, now: Date()).pickedDay },
            set: { day in
                var next = model.detail(for: id, now: Date())
                next.when = .picked
                next.pickedDay = day
                model.setDetail(next, for: id)
            }
        )
    }

    private func update(_ id: String, _ detail: OnboardingViewModel.ViceDetail, change: (inout OnboardingViewModel.ViceDetail) -> Void) {
        var next = model.detail(for: id, now: Date())
        if model.viceDetails[id] == nil { next = detail }
        change(&next)
        model.setDetail(next, for: id)
    }

    private func turnOnReminders() async {
        let allowed = await ReminderScheduler.requestAuthorization()
        model.wantsReminders = allowed
        model.advance()
    }

    private func finish() {
        guard model.acceptedDisclaimer else { return }
        let store = RecoveryStore(context: modelContext)
        let drafts = model.drafts(now: Date(), calendar: .current)
        let saved: Void? = persist("finish onboarding") {
            for draft in drafts {
                _ = try store.addMetric(
                    name: draft.name,
                    habitType: draft.habitType,
                    iconName: draft.iconName,
                    startedAt: draft.startedAt,
                    costPerDay: draft.costPerDay,
                    firstReason: draft.firstReason,
                    tracking: draft.tracking
                )
            }
        }
        guard saved != nil else { return }
        Preferences.reminderHour = model.reminderHour
        Preferences.reminderMinute = model.reminderMinute
        Preferences.remindersEnabled = model.wantsReminders
        Preferences.hasAcceptedDisclaimer = true
        Preferences.hasCompletedOnboarding = true
        appLock.isEnabled = model.wantsLock
        appLock.isLocked = false
        if model.wantsReminders {
            Task { await ReminderScheduler.refresh(context: modelContext) }
        }
        onFinished()
    }
}

private struct FlowChips: View {
    var titles: [String]
    var insert: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ForEach(titles, id: \.self) { title in
                Button(title) { insert(title) }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.tbTextPrimary)
                    .padding(.horizontal, Spacing.m)
                    .frame(minHeight: 44)
                    .background(Color.tbSurfaceMuted, in: Capsule())
            }
        }
    }
}
