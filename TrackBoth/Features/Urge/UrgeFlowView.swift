import SwiftData
import SwiftUI

struct UrgeFlowView: View {
    var metrics: [Metric]
    var preferredID: UUID?
    var onClose: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var model: UrgeViewModel?
    @State private var showSlip = false
    @State private var askClose = false
    @State private var reasonIndex = 0

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    if model.step == .ride && AdaptiveLayout.isShortHeight(vertical: verticalSizeClass) {
                        rideSideBySide(model)
                    } else {
                        ScrollView {
                            ReadableColumn {
                                content(model)
                            }
                            .padding(.vertical, Spacing.l)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.tbCalm.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(RecoveryCopy.close) {
                        if model?.step == .ride {
                            askClose = true
                        } else {
                            onClose()
                        }
                    }
                    .foregroundStyle(Color.tbOnCalm)
                }
            }
            .confirmationDialog(RecoveryCopy.howDidItGo, isPresented: $askClose, titleVisibility: .visible) {
                Button(RecoveryCopy.theUrgePassed) { try? model?.passed(now: Date()) }
                Button(slipTitle) { slipped() }
                Button(RecoveryCopy.notSure) { try? model?.markNotSure(now: Date()); onClose() }
                Button(RecoveryCopy.close, role: .cancel) {}
            }
            .sheet(isPresented: $showSlip) {
                if let metric = selectedMetric {
                    SlipFlowView(metric: metric, prefilledTriggers: Array(model?.triggers ?? [])) {
                        try? model?.markSlipped(now: Date())
                        showSlip = false
                        onClose()
                    }
                }
            }
        }
        .onAppear { prepare() }
    }

    @ViewBuilder
    private func content(_ model: UrgeViewModel) -> some View {
        switch model.step {
        case .empty:
            Text(RecoveryCopy.noViceForUrge)
                .font(.title2)
                .foregroundStyle(Color.tbOnCalm)
        case .choose:
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text(RecoveryCopy.whichOne)
                    .font(.title2)
                    .foregroundStyle(Color.tbOnCalm)
                ForEach(model.vices) { metric in
                    calmChoice(metric.name) { model.choose(metric.id) }
                }
            }
        case .intensity:
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(RecoveryCopy.howStrong)
                    .font(.title2)
                    .foregroundStyle(Color.tbOnCalm)
                    .padding(.bottom, Spacing.s)
                ForEach(1...5, id: \.self) { level in
                    Button(RecoveryCopy.intensityLabel(level)) {
                        model.intensity = level
                        try? model.begin(metrics: metrics, now: Date())
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .padding(.horizontal, Spacing.l)
                    .background(Color.tbOnCalm.opacity(model.intensity == level ? 0.2 : 0.12), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                    .foregroundStyle(Color.tbOnCalm)
                    .accessibilityIdentifier(AccessibilityIdentifiers.urgeIntensity(level))
                }
                Button(RecoveryCopy.skip) {
                    model.intensity = 3
                    try? model.begin(metrics: metrics, now: Date())
                }
                .frame(minHeight: 44)
                .foregroundStyle(Color.tbOnCalm)
            }
        case .ride:
            VStack(spacing: Spacing.l) {
                rideFocus(model)
                rideSupport(model)
            }
        case .passed:
            passed(model)
        case .unsure:
            EmptyView()
        }
    }

    private func calmChoice(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.tbOnCalm)
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.s)
                .background(Color.tbOnCalm.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func rideSideBySide(_ model: UrgeViewModel) -> some View {
        HStack(alignment: .top, spacing: Spacing.l) {
            VStack(spacing: Spacing.m) {
                rideFocus(model)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    rideSupport(model)
                }
                .padding(.vertical, Spacing.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Spacing.l)
    }

    @ViewBuilder
    private func rideFocus(_ model: UrgeViewModel) -> some View {
        BreathingCircle(maxDiameter: AdaptiveLayout.breathingDiameter(vertical: verticalSizeClass))
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = model.remaining(at: context.date)
            VStack(spacing: Spacing.s) {
                Text(clock(remaining))
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.tbOnCalm)
                if remaining == 0 {
                    Text(RecoveryCopy.stillWithIt)
                        .font(.body)
                        .foregroundStyle(Color.tbOnCalm)
                        .multilineTextAlignment(.center)
                }
            }
        }
        Button(RecoveryCopy.addFiveMinutes) { model.addFiveMinutes(now: Date()) }
            .frame(minHeight: 44)
            .foregroundStyle(Color.tbOnCalm)
    }

    @ViewBuilder
    private func rideSupport(_ model: UrgeViewModel) -> some View {
        Text(RecoveryCopy.urgeIntro)
            .font(.body)
            .foregroundStyle(Color.tbOnCalm)
            .multilineTextAlignment(.center)
        if let plan = selectedMetric?.ifThenPlan, !plan.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(RecoveryCopy.yourPlanPrefix).font(.headline)
                Text(plan).font(.body)
            }
            .foregroundStyle(Color.tbOnCalm)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        reasons
        habitChips
        PrimaryButton(title: RecoveryCopy.theUrgePassed, systemImage: nil, accessibilityID: AccessibilityIdentifiers.urgePassed) {
            try? model.passed(now: Date())
        }
        Button(slipTitle) { slipped() }
            .frame(minHeight: 44)
            .foregroundStyle(Color.tbOnCalm)
            .accessibilityIdentifier(AccessibilityIdentifiers.urgeSlipped)
    }

    private func passed(_ model: UrgeViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(RecoveryCopy.urgePassed(model.beaten))
                .font(.title2)
                .foregroundStyle(Color.tbOnCalm)
            Text(RecoveryCopy.whatSetItOff)
                .font(.headline)
                .foregroundStyle(Color.tbOnCalm)
            triggerGrid
            PrimaryButton(title: RecoveryCopy.done, systemImage: nil, accessibilityID: AccessibilityIdentifiers.urgeDone, action: onClose)
        }
    }

    private var reasons: some View {
        let items = selectedReasons
        return VStack(alignment: .leading, spacing: Spacing.s) {
            if !items.isEmpty {
                Text(RecoveryCopy.yourWhy)
                    .font(.headline)
                    .foregroundStyle(Color.tbOnCalm)
                if reduceMotion {
                    ForEach(items, id: \.self) { text in
                        Text(text).foregroundStyle(Color.tbOnCalm)
                    }
                } else if reasonIndex < items.count {
                    Text(items[reasonIndex])
                        .font(.title2)
                        .foregroundStyle(Color.tbOnCalm)
                        .task(id: items.count) {
                            while !Task.isCancelled {
                                try? await Task.sleep(for: .seconds(8))
                                reasonIndex = (reasonIndex + 1) % max(items.count, 1)
                            }
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var habitChips: some View {
        let habits = metrics.filter { $0.habitType == .positive && !$0.isArchived }
        if !habits.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(RecoveryCopy.tryOneInstead)
                    .font(.headline)
                    .foregroundStyle(Color.tbOnCalm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(habits) { habit in
                    calmChoice(habit.name) {
                        try? RecoveryStore(context: modelContext).setHabitDone(habit, on: Date(), done: true, now: Date())
                    }
                }
            }
        }
    }

    private var triggerGrid: some View {
        let binding = Binding<Set<String>>(
            get: { Set((model?.triggers ?? []).map(\.rawValue)) },
            set: { raw in model?.triggers = Set(raw.compactMap(TriggerTag.init(rawValue:))) }
        )
        return ChipGrid(
            items: TriggerTag.allCases.map { ChipOption(id: $0.rawValue, title: $0.title, systemImage: $0.systemImage) },
            selection: binding
        )
    }

    private var selectedMetric: Metric? {
        metrics.first { $0.id == model?.selectedID }
    }

    private var slipTitle: String {
        selectedMetric?.isCuttingBack == true ? RecoveryCopy.iHadOne : RecoveryCopy.iSlipped
    }

    /// Quit opens the slip flow. Cut back logs one more for today and closes.
    private func slipped() {
        guard let metric = selectedMetric, metric.isCuttingBack else {
            showSlip = true
            return
        }
        try? RecoveryStore(context: modelContext).addAmount(metric, 1, on: Date(), now: Date())
        try? model?.markSlipped(now: Date())
        onClose()
    }

    private var selectedReasons: [String] {
        guard let id = model?.selectedID else { return [] }
        let store = RecoveryStore(context: modelContext)
        return (try? store.reasons(for: id).sorted { $0.sortOrder < $1.sortOrder }.map(\.text)) ?? []
    }

    private func prepare() {
        if model == nil {
            model = UrgeViewModel(store: RecoveryStore(context: modelContext))
        }
        model?.start(metrics: metrics, preferredID: preferredID, now: Date())
    }

    private func clock(_ remaining: TimeInterval) -> String {
        let total = Int(remaining)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
