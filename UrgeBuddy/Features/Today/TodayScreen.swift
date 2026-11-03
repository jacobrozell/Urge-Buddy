import SwiftData
import SwiftUI

struct TodayScreen: View {
    @Query(filter: #Predicate<Metric> { !$0.isArchived }, sort: \Metric.sortOrder)
    private var metrics: [Metric]
    @Query private var entries: [MetricEntry]

    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.persist) private var persist
    @State private var model = TodayViewModel()
    @State private var sheet: TodaySheet?
    @State private var dismissedYesterday = Preferences.dismissedYesterdayPromptDay
    @State private var surfingTipDismissed = Preferences.hasDismissedUrgeSurfingTip
    @State private var didPresentSlip = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ReadableColumn {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            dateLabel
                            if let prompt = model.yesterdayPrompt {
                                YesterdayPrompt(name: prompt.name) {
                                    confirmYesterday(prompt.metricID)
                                } onSlipped: {
                                    sheet = .slip(prompt.metricID)
                                } onDismiss: {
                                    dismissYesterday()
                                }
                            }
                            if !model.isEmpty {
                                if model.checkInDoneToday {
                                    CheckInStreakCard(streak: model.checkInStreak)
                                } else {
                                    CheckInBanner(remaining: model.checkInRemaining, streak: model.checkInStreak) {
                                        router.present(.checkIn)
                                    }
                                }
                            }
                            if model.showsSOS && !surfingTipDismissed {
                                UrgeSurfingRow {
                                    Preferences.hasDismissedUrgeSurfingTip = true
                                    surfingTipDismissed = true
                                    sheet = .surfing
                                } onDismiss: {
                                    withAnimation(reduceMotion ? nil : UrgeBuddyMotion.spring) {
                                        Preferences.hasDismissedUrgeSurfingTip = true
                                        surfingTipDismissed = true
                                    }
                                }
                            }
                            if model.isEmpty {
                                EmptyState(
                                    systemImage: "sun.max",
                                    title: RecoveryCopy.startWithOneThing,
                                    message: RecoveryCopy.startWithOneThingMessage,
                                    actionTitle: RecoveryCopy.addSomethingToQuit,
                                    action: { sheet = .add(.vice) },
                                    secondaryTitle: RecoveryCopy.addAHabit,
                                    secondaryAction: { sheet = .add(.positive) }
                                )
                            }
                        }
                    }
                    if !model.isEmpty {
                        metricColumns
                            .padding(.horizontal, Spacing.l)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.top, Spacing.s)
                .padding(.bottom, Spacing.m)
                .containerRelativeFrame(.horizontal, alignment: .leading)
            }
            if model.showsSOS {
                VerticalBarFloatingBar {
                    SOSButton {
                        let sheetWasUp = sheet != nil
                        sheet = nil
                        let present = { router.present(.urge(nil)) }
                        if sheetWasUp {
                            PresentationSequence.afterDismiss(present)
                        } else {
                            PresentationSequence.resignKeyboardThen(present)
                        }
                    }
                }
                .padding(.top, Spacing.s)
                .background(Color.tbBackground)
            }
            }
            .background(Color.tbBackground.ignoresSafeArea())
            .tbNavigationBarBackground()
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(
                AdaptiveLayout.isShortHeight(vertical: verticalSizeClass) ? .inline : .large
            )
            .toolbar {
                if !model.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button { sheet = .add(.vice) } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel(RecoveryCopy.addSomething)
                        .accessibilityIdentifier(AccessibilityIdentifiers.todayAdd)
                    }
                }
            }
        }
        .onAppear {
            refresh()
            presentSlipIfNeeded()
        }
        .onChange(of: snapshotToken) {
            refresh()
            presentSlipIfNeeded()
        }
        .sheet(item: $sheet) { sheet in
            Group {
                switch sheet {
                case .surfing:
                    UrgeSurfingSheet()
                case .slip(let id):
                    if let metric = metrics.first(where: { $0.id == id }) {
                        SlipFlowView(
                            metric: metric,
                            prefilledTriggers: [],
                            showSummary: LaunchConfiguration.showsSlipSummary
                        ) { self.sheet = nil }
                    }
                case .add(let habitType):
                    MetricFormView(metric: nil, habitType: habitType)
                case .detail(let id):
                    if let metric = metrics.first(where: { $0.id == id }) {
                        NavigationStack { MetricDetailScreen(metric: metric) }
                            .adaptivePageSheet()
                    }
                }
            }
            .persistFailureAlert()
        }
    }

    private var hasQuittingColumn: Bool {
        !model.vices.isEmpty || !model.cutBacks.isEmpty
    }

    @ViewBuilder
    private var metricColumns: some View {
        if hasQuittingColumn && !model.habits.isEmpty {
            AdaptiveColumns {
                viceSections
            } trailing: {
                buildingSection
            }
        } else {
            VStack(alignment: .leading, spacing: Spacing.l) {
                viceSections
                buildingSection
            }
        }
    }

    private var viceSections: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if !model.vices.isEmpty { quittingSection }
            if !model.cutBacks.isEmpty { cuttingBackSection }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quittingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(RecoveryCopy.quitting)
            VStack(spacing: Spacing.m) {
                ForEach(model.vices) { card in
                    ViceCard(model: card, calendar: model.calendar) { sheet = .detail(card.id) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cuttingBackSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(RecoveryCopy.cuttingBack)
            VStack(spacing: Spacing.m) {
                ForEach(model.cutBacks) { card in
                    CutBackCard(model: card, onChange: { setAmount(card.id, $0) }, onOpen: { sheet = .detail(card.id) })
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var buildingSection: some View {
        if !model.habits.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s) {
                SectionHeader(RecoveryCopy.building)
                VStack(spacing: Spacing.s) {
                    ForEach(model.habits) { row in
                        HabitCheckRow(
                            model: row,
                            onToggle: { toggleHabit(row.id) },
                            onSetAmount: { setAmount(row.id, $0) },
                            onOpen: { sheet = .detail(row.id) }
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dateLabel: some View {
        Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
            .font(.subheadline)
            .foregroundStyle(Color.tbTextSecondary)
            .accessibilityLabel(Date().formatted(date: .complete, time: .omitted))
    }

    private var snapshotToken: String {
        let metricPart = metrics.map {
            "\($0.id.uuidString):\($0.sortOrder):\($0.name):\($0.costPerDayRaw ?? ""):\($0.viceModeRaw):\($0.dailyTarget ?? -1):\($0.unit ?? ""):\($0.baselinePerDay ?? -1)"
        }.joined(separator: "|")
        let entryPart = entries.map { "\($0.metricID.uuidString):\($0.statusRaw):\($0.amount ?? -1):\($0.day.timeIntervalSinceReferenceDate)" }.joined(separator: "|")
        return metricPart + "#" + entryPart + "#\(dismissedYesterday?.timeIntervalSinceReferenceDate ?? 0)"
    }

    private func refresh() {
        model.update(metrics: metrics, entries: entries, now: Date(), dismissedYesterday: dismissedYesterday)
    }

    private func presentSlipIfNeeded() {
        guard (LaunchConfiguration.presentsSlip || LaunchConfiguration.showsSlipSummary), !didPresentSlip,
              let vice = metrics.first(where: { $0.isQuitting && !$0.isArchived }) else { return }
        didPresentSlip = true
        sheet = .slip(vice.id)
    }

    private func toggleHabit(_ id: UUID) {
        guard let metric = metrics.first(where: { $0.id == id }) else { return }
        let store = RecoveryStore(context: modelContext)
        let done = model.habits.first { $0.id == id }?.isDoneToday == false
        persist("habit done") { try store.setHabitDone(metric, on: Date(), done: done, now: Date()) }
    }

    private func setAmount(_ id: UUID, _ amount: Int) {
        guard let metric = metrics.first(where: { $0.id == id }) else { return }
        persist("set amount") { try RecoveryStore(context: modelContext).setAmount(metric, on: Date(), amount: amount, now: Date()) }
    }

    private func confirmYesterday(_ id: UUID) {
        guard let metric = metrics.first(where: { $0.id == id }),
              let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return }
        let store = RecoveryStore(context: modelContext)
        persist("mark yesterday free") { try store.markFree(metric, on: yesterday, now: Date()) }
    }

    private func dismissYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        Preferences.dismissedYesterdayPromptDay = yesterday
        dismissedYesterday = yesterday
        refresh()
    }
}

private enum TodaySheet: Identifiable {
    case slip(UUID)
    case add(HabitType)
    case detail(UUID)
    case surfing

    var id: String {
        switch self {
        case .slip(let id): "slip-\(id.uuidString)"
        case .add(let type): "add-\(type.rawValue)"
        case .detail(let id): id.uuidString
        case .surfing: "surfing"
        }
    }
}
