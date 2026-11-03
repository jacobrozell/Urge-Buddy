import SwiftData
import SwiftUI

struct CheckInCompleteView: View {
    var lines: [CheckInSummaryLine]
    var streak: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.tbBrand)
                .frame(maxWidth: .infinity)
                .symbolEffect(.bounce, value: reduceMotion ? false : appeared)
                .accessibilityHidden(true)
            if streak > 0 {
                Text("\(streak)")
                    .bigNumberStyle()
                    .foregroundStyle(Color.tbBrand)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(RecoveryCopy.checkInStreak(streak))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.tbTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(RecoveryCopy.checkedInToday)
                    .font(.body)
                    .foregroundStyle(Color.tbTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text(RecoveryCopy.checkInTitle)
                    .font(.title2)
                    .foregroundStyle(Color.tbTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            ForEach(lines) { line in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(line.name)
                        .font(.headline)
                        .foregroundStyle(Color.tbTextPrimary)
                    Text(line.detail)
                        .font(.body)
                        .foregroundStyle(Color.tbTextSecondary)
                    if let milestone = line.milestone {
                        Text(milestone)
                            .font(.body)
                            .foregroundStyle(Color.tbTextPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear { appeared = true }
        .sensoryFeedback(.success, trigger: appeared)
    }
}

struct CheckInSheet: View {
    var metrics: [Metric]
    var entries: [MetricEntry]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.persist) private var persist

    private var pinsActionInToolbar: Bool {
        AdaptiveLayout.isShortHeight(vertical: verticalSizeClass)
    }
    @State private var model: CheckInViewModel?
    @State private var slippingID: UUID?
    @State private var detent: PresentationDetent = .large

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    ReadableColumn {
                        VStack(alignment: .leading, spacing: Spacing.m) {
                            if let model, model.showComplete {
                                CheckInCompleteView(lines: model.lines, streak: model.checkInStreak)
                            } else if let model {
                                form(model)
                            }
                        }
                        .padding(.top, Spacing.s)
                        .padding(.bottom, Spacing.m)
                    }
                }
                if let model, !pinsActionInToolbar {
                    ReadableColumn {
                        PrimaryButton(
                            title: doneTitle(model),
                            systemImage: nil,
                            accessibilityID: AccessibilityIdentifiers.checkInDone,
                            action: { finish(model) }
                        )
                        .disabled(!model.showComplete && !model.canFinish)
                    }
                    .padding(.top, Spacing.s)
                    .padding(.bottom, Spacing.s)
                    .background(Color.tbBackground)
                }
            }
            .background(Color.tbBackground.ignoresSafeArea())
            .tbNavigationBarBackground()
            .navigationTitle(RecoveryCopy.checkInTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(RecoveryCopy.close) {
                        guard slippingID == nil else { return }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text(Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .font(.subheadline)
                        .foregroundStyle(Color.tbTextSecondary)
                }
                if let model, pinsActionInToolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(doneTitle(model)) { finish(model) }
                            .disabled(!model.showComplete && !model.canFinish)
                            .accessibilityIdentifier(AccessibilityIdentifiers.checkInDone)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .adaptiveFormSheet()
        .onAppear { prepare() }
        .onDisappear {
            do {
                try model?.saveDayNote(now: Date())
            } catch {
                logger.logError(error, context: "Couldn't save: day note on dismiss")
            }
        }
        .onChange(of: entryToken) { prepare() }
        .sheet(isPresented: slippingPresented) {
            if let slippingID, let metric = metrics.first(where: { $0.id == slippingID }) {
                SlipFlowView(metric: metric, prefilledTriggers: []) { self.slippingID = nil }
                    .persistFailureAlert()
            }
        }
    }

    private var entryToken: String {
        entries.map { "\($0.metricID.uuidString):\($0.statusRaw):\($0.amount ?? -1)" }.joined()
    }

    private func form(_ model: CheckInViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            ForEach(model.vices) { row in
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text(row.name)
                        .font(.headline)
                        .foregroundStyle(Color.tbTextPrimary)
                    if row.answer == .slipped {
                        Text(RecoveryCopy.slipLoggedThanks)
                            .font(.body)
                            .foregroundStyle(Color.tbTextSecondary)
                    } else {
                        answerRow(row)
                    }
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.m)
                .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            }
            if !model.cutBacks.isEmpty {
                SectionHeader(RecoveryCopy.cuttingBack)
                ForEach(model.cutBacks) { row in
                    amountRow(row, model: model, subtitle: RecoveryCopy.howManyToday(limit: row.goal))
                }
            }
            if !model.habits.isEmpty || !model.amountHabits.isEmpty {
                SectionHeader(RecoveryCopy.building)
                ForEach(model.amountHabits) { row in
                    amountRow(row, model: model, subtitle: RecoveryCopy.amountOf(row.amount, row.goal, unit: row.unit))
                }
                ForEach(model.habits) { row in
                    Button {
                        toggleHabit(row.id)
                    } label: {
                        HStack(spacing: Spacing.s) {
                            Image(systemName: row.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(row.isDone ? Color.tbHabit : Color.tbTextSecondary)
                                .frame(minWidth: 44, minHeight: 44)
                            Text(row.name)
                                .foregroundStyle(Color.tbTextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, Spacing.s)
                        .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(row.isDone ? "\(row.name), done" : "\(row.name), not done")
                }
            }
            moodSection(model)
            Button(RecoveryCopy.havingAnUrge) {
                PresentationSequence.resignKeyboardThen { router.present(.urge(nil)) }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    private func amountRow(_ row: CheckInAmountRow, model: CheckInViewModel, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(row.name)
                .font(.headline)
                .foregroundStyle(Color.tbTextPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.tbTextSecondary)
            AmountStepper(value: row.amount, unit: row.unit, step: row.step, label: row.name) { value in
                persist("set amount") { try model.setAmount(row.id, value, metrics: metrics, now: Date()) }
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.checkInAmount(row.id))
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func moodSection(_ model: CheckInViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(RecoveryCopy.howAreYouFeeling)
            MoodPicker(selection: model.mood) { mood in
                model.mood = mood
                persist("save day note") { try model.saveDayNote(now: Date()) }
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.checkInMood)
            TextField(RecoveryCopy.noteField, text: Bindable(model).noteText, axis: .vertical)
                .lineLimit(2...5)
                .textFieldStyle(.tbField)
                .textInputAutocapitalization(.sentences)
                .accessibilityIdentifier(AccessibilityIdentifiers.checkInNote)
        }
    }

    private func answerRow(_ row: CheckInViceRow) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s) {
                freeButton(row)
                slippedButton(row)
            }
            VStack(spacing: Spacing.s) {
                freeButton(row)
                slippedButton(row)
            }
        }
    }

    private func freeButton(_ row: CheckInViceRow) -> some View {
        Button(RecoveryCopy.freeToday) { markFree(row.id) }
            .buttonStyle(.borderedProminent)
            .tint(Color.tbBrand)
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityIdentifier(AccessibilityIdentifiers.checkInFree(row.id))
            .accessibilityAddTraits(row.answer == .free ? .isSelected : [])
    }

    private func slippedButton(_ row: CheckInViceRow) -> some View {
        Button(RecoveryCopy.iSlipped) {
            PresentationSequence.resignKeyboardThen { slippingID = row.id }
        }
            .buttonStyle(.bordered)
            .tint(Color.tbSlip)
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityIdentifier(AccessibilityIdentifiers.checkInSlipped(row.id))
    }

    private func prepare() {
        let store = RecoveryStore(context: modelContext)
        if model == nil {
            model = CheckInViewModel(store: store)
        }
        model?.load(metrics: metrics, entries: entries, now: Date())
    }

    private func markFree(_ id: UUID) {
        guard let model else { return }
        persist("mark free") { try model.markFree(id, metrics: metrics, now: Date()) }
    }

    private func toggleHabit(_ id: UUID) {
        guard let model else { return }
        persist("toggle habit") { try model.toggleHabit(id, metrics: metrics, now: Date()) }
    }

    private func doneTitle(_ model: CheckInViewModel) -> String {
        model.showComplete ? RecoveryCopy.backToToday : RecoveryCopy.done
    }

    private func finish(_ model: CheckInViewModel) {
        guard slippingID == nil else { return }
        if model.showComplete {
            dismiss()
        } else {
            let celebrated = Dictionary(uniqueKeysWithValues: metrics.map { metric in
                (metric.id, MilestoneLedger.highestCelebrated(for: metric.id))
            })
            persist("finish check-in") { try model.finish(metrics: metrics, now: Date(), celebrated: celebrated) }
        }
    }

    private var slippingPresented: Binding<Bool> {
        Binding(get: { slippingID != nil }, set: { if !$0 { slippingID = nil } })
    }
}
