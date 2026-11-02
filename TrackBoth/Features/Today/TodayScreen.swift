import SwiftData
import SwiftUI

struct TodayScreen: View {
    @Query(filter: #Predicate<Metric> { !$0.isArchived }, sort: \Metric.sortOrder)
    private var metrics: [Metric]
    @Query private var entries: [MetricEntry]

    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var model = TodayViewModel()
    @State private var sheet: TodaySheet?
    @State private var dismissedYesterday = Preferences.dismissedYesterdayPromptDay
    @State private var didPresentSlip = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    ReadableColumn(width: .wide) {
                        VStack(alignment: .leading, spacing: Spacing.m) {
                            if let prompt = model.yesterdayPrompt {
                                YesterdayPrompt(name: prompt.name) {
                                    confirmYesterday(prompt.metricID)
                                } onSlipped: {
                                    sheet = .slip(prompt.metricID)
                                } onDismiss: {
                                    dismissYesterday()
                                }
                                .frame(maxWidth: AdaptiveLayout.textColumnWidth, alignment: .leading)
                            }
                            if model.checkInRemaining > 0 {
                                CheckInBanner(remaining: model.checkInRemaining) { router.present(.checkIn) }
                                    .frame(maxWidth: AdaptiveLayout.textColumnWidth, alignment: .leading)
                            }
                            if model.isEmpty {
                                EmptyState(
                                    systemImage: "sun.max",
                                    title: RecoveryCopy.startWithOneThing,
                                    message: RecoveryCopy.startWithOneThingMessage,
                                    actionTitle: RecoveryCopy.addSomething
                                ) { sheet = .add }
                                .frame(maxWidth: AdaptiveLayout.textColumnWidth, alignment: .leading)
                            }
                            if model.hasViceSection && !model.habits.isEmpty {
                                AdaptiveColumns {
                                    viceSections
                                } trailing: {
                                    buildingSection
                                }
                            } else {
                                if model.hasViceSection { viceSections }
                                if !model.habits.isEmpty { buildingSection }
                            }
                        }
                        .padding(.top, Spacing.s)
                        .padding(.bottom, Spacing.m)
                    }
                }
                if model.showsSOS {
                    SOSButton(isCompact: AdaptiveLayout.isShortHeight(vertical: verticalSizeClass)) {
                        router.present(.urge(nil))
                    }
                }
            }
            .background(Color.tbBackground)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(
                AdaptiveLayout.isShortHeight(vertical: verticalSizeClass) ? .inline : .large
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .font(.subheadline)
                        .foregroundStyle(Color.tbTextSecondary)
                        .accessibilityLabel(Date().formatted(date: .complete, time: .omitted))
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
            switch sheet {
            case .slip(let id):
                if let metric = metrics.first(where: { $0.id == id }) {
                    SlipFlowView(metric: metric, prefilledTriggers: []) { self.sheet = nil }
                }
            case .add:
                MetricFormView(metric: nil)
            case .detail(let id):
                if let metric = metrics.first(where: { $0.id == id }) {
                    NavigationStack { MetricDetailScreen(metric: metric) }
                        .adaptivePageSheet()
                }
            }
        }
    }

    private var viceSections: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if !model.vices.isEmpty { quittingSection }
            if !model.cutBacks.isEmpty { cuttingBackSection }
        }
    }

    @ViewBuilder
    private var quittingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(RecoveryCopy.quitting)
            VStack(spacing: Spacing.m) {
                ForEach(model.vices) { card in
                    ViceCard(model: card, calendar: model.calendar) { sheet = .detail(card.id) }
                }
            }
        }
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
    }

    @ViewBuilder
    private var buildingSection: some View {
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
        guard LaunchConfiguration.presentsSlip, !didPresentSlip,
              let vice = metrics.first(where: { $0.isQuitting && !$0.isArchived }) else { return }
        didPresentSlip = true
        sheet = .slip(vice.id)
    }

    private func toggleHabit(_ id: UUID) {
        guard let metric = metrics.first(where: { $0.id == id }) else { return }
        let store = RecoveryStore(context: modelContext)
        let done = model.habits.first { $0.id == id }?.isDoneToday == false
        try? store.setHabitDone(metric, on: Date(), done: done, now: Date())
    }

    private func setAmount(_ id: UUID, _ amount: Int) {
        guard let metric = metrics.first(where: { $0.id == id }) else { return }
        try? RecoveryStore(context: modelContext).setAmount(metric, on: Date(), amount: amount, now: Date())
    }

    private func confirmYesterday(_ id: UUID) {
        guard let metric = metrics.first(where: { $0.id == id }),
              let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return }
        let store = RecoveryStore(context: modelContext)
        try? store.markFree(metric, on: yesterday, now: Date())
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
    case add
    case detail(UUID)

    var id: String {
        switch self {
        case .slip(let id): "slip-\(id.uuidString)"
        case .add: "add"
        case .detail(let id): id.uuidString
        }
    }
}
