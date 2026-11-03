import SwiftData
import SwiftUI

struct SlipFlowView: View {
    var metric: Metric
    var prefilledTriggers: [TriggerTag]
    /// Set when the day editor opens this flow for a specific day.
    var occurredOn: Date? = nil
    /// Screenshot launch: show the summary from data already stored.
    var showSummary: Bool = false
    var onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.persist) private var persist

    private var pinsActionInToolbar: Bool {
        AdaptiveLayout.isShortHeight(vertical: verticalSizeClass)
    }
    @State private var model: SlipViewModel?
    @State private var pickedDay = Date()
    @State private var showHelp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    ReadableColumn {
                        if let model {
                            if let summary = model.summary {
                                summaryView(summary)
                            } else {
                                form(model)
                            }
                        }
                    }
                    .padding(.top, Spacing.m)
                    .padding(.bottom, Spacing.l)
                }
                if model?.summary != nil, !pinsActionInToolbar {
                    ReadableColumn {
                        summaryActions()
                    }
                    .padding(.top, Spacing.s)
                    .padding(.bottom, Spacing.s)
                    .background(Color.tbBackground)
                } else if model?.summary == nil, !pinsActionInToolbar {
                    ReadableColumn {
                        PrimaryButton(title: RecoveryCopy.save, systemImage: nil, accessibilityID: AccessibilityIdentifiers.slipSave) {
                            persist("save slip") { try model?.save(metric: metric, now: Date()) }
                        }
                    }
                    .padding(.top, Spacing.s)
                    .padding(.bottom, Spacing.s)
                    .background(Color.tbBackground)
                    .sensoryFeedback(.impact(weight: .light), trigger: model?.summary?.body)
                }
            }
            .background(Color.tbBackground.ignoresSafeArea())
            .tbNavigationBarBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if model?.summary == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(RecoveryCopy.close) { dismiss() }
                    }
                }
                if model?.summary != nil, pinsActionInToolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(RecoveryCopy.backToToday, action: onFinish)
                    }
                }
                if model?.summary == nil, pinsActionInToolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(RecoveryCopy.save) {
                            persist("save slip") { try model?.save(metric: metric, now: Date()) }
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.slipSave)
                    }
                }
            }
        }
        .adaptiveFormSheet()
        .onAppear {
            guard model == nil else { return }
            let now = Date()
            let when = occurredOn.map { SlipWhen.forEditing(day: $0, now: now, calendar: calendar) } ?? .justNow
            if case .picked(let day) = when { pickedDay = day }
            model = SlipViewModel(
                store: RecoveryStore(context: modelContext),
                plan: metric.ifThenPlan,
                triggers: prefilledTriggers,
                when: when
            )
            if showSummary {
                try? model?.loadExistingSummary(metric: metric, now: now)
            }
        }
        .sheet(isPresented: $showHelp) {
            CrisisResourcesView()
                .adaptiveFormSheet()
        }
    }

    @ViewBuilder
    private func form(_ model: SlipViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(RecoveryCopy.slipTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.tbTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(RecoveryCopy.slipSubtitle).font(.body).foregroundStyle(Color.tbTextSecondary)
            Text(RecoveryCopy.whenQuestion).font(.headline).foregroundStyle(Color.tbTextPrimary)
            whenButtons(model)
            if case .picked = model.when {
                DatePicker(
                    RecoveryCopy.pickADay,
                    selection: $pickedDay,
                    in: calendar.startOfDay(for: metric.startedAt)...Date(),
                    displayedComponents: .date
                )
                .onChange(of: pickedDay) { _, day in model.when = .picked(day) }
            }
            Text(RecoveryCopy.whatWasGoingOn).font(.headline).foregroundStyle(Color.tbTextPrimary)
            ChipGrid(
                items: TriggerTag.allCases.map { ChipOption(id: $0.rawValue, title: $0.title, systemImage: $0.systemImage) },
                selection: Binding(
                    get: { Set(model.triggers.map(\.rawValue)) },
                    set: { model.triggers = Set($0.compactMap(TriggerTag.init(rawValue:))) }
                )
            )
            Text(RecoveryCopy.anythingElse).font(.headline).foregroundStyle(Color.tbTextPrimary)
            TextField(RecoveryCopy.anythingElse, text: Bindable(model).note, axis: .vertical)
                .textFieldStyle(.tbField)
            Text(RecoveryCopy.nextTimePlan).font(.headline).foregroundStyle(Color.tbTextPrimary)
            TextField(RecoveryCopy.nextTimePlan, text: Bindable(model).plan, axis: .vertical)
                .textFieldStyle(.tbField)
            if let errorMessage = model.errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(Color.tbSlip)
            }
        }
    }

    private func summaryView(_ summary: SlipSummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.tbSlip)
                    .accessibilityHidden(true)
                Text(summary.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.tbTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            summaryStats(summary)

            Text(summary.body)
                .font(.body)
                .foregroundStyle(Color.tbTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let reason = summary.reason {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    SectionHeader(RecoveryCopy.yourWhy)
                    Text(reason)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.tbTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.l)
                .background(Color.tbBrandSoft, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            }

            if pinsActionInToolbar {
                summaryActions()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.slipSummary)
    }

    private func summaryActions() -> some View {
        VStack(spacing: Spacing.s) {
            SecondaryButton(title: RecoveryCopy.needSupport) { showHelp = true }
            if !pinsActionInToolbar {
                PrimaryButton(title: RecoveryCopy.backToToday, systemImage: nil, action: onFinish)
            }
        }
    }

    private func summaryStats(_ summary: SlipSummary) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Spacing.m) {
                summaryStatTiles(summary)
            }
            .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: Spacing.m) {
                summaryStatTiles(summary)
            }
        }
    }

    @ViewBuilder
    private func summaryStatTiles(_ summary: SlipSummary) -> some View {
        summaryStat(
            value: "\(summary.freeDays) of \(summary.countedDays)",
            label: RecoveryCopy.slipRecentDaysFree,
            systemImage: "sun.max"
        )
        if let saved = summary.saved {
            summaryStat(value: saved, label: RecoveryCopy.slipStillSaved, systemImage: "dollarsign.circle")
        }
    }

    private func summaryStat(value: String, label: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tbBrand)
                .accessibilityHidden(true)
            Text(value)
                .font(.title.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color.tbTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.footnote)
                .foregroundStyle(Color.tbTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func whenButtons(_ model: SlipViewModel) -> some View {
        let options: [(String, SlipWhen)] = [
            (RecoveryCopy.justNow, .justNow),
            (RecoveryCopy.earlierToday, .earlierToday),
            (RecoveryCopy.yesterday, .yesterday),
            (RecoveryCopy.pickADay, .picked(pickedDay))
        ]
        // One row when it fits, then two equal columns like the trigger grid below, then one column.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    whenChip(option.0, when: option.1, model: model)
                }
            }
            Grid(horizontalSpacing: Spacing.s, verticalSpacing: Spacing.s) {
                ForEach([0, 2], id: \.self) { start in
                    GridRow {
                        ForEach(options[start...start + 1].indices, id: \.self) { index in
                            whenChip(options[index].0, when: options[index].1, model: model, fills: true)
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    whenChip(option.0, when: option.1, model: model)
                }
            }
        }
    }

    private func whenChip(_ title: String, when: SlipWhen, model: SlipViewModel, fills: Bool = false) -> some View {
        let selected = isSelected(when, model: model)
        return Button { model.when = when } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? Color.tbOnBrand : Color.tbTextPrimary)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s)
                .frame(maxWidth: fills ? .infinity : nil, minHeight: 44)
                .background(selected ? Color.tbBrand : Color.tbSurfaceMuted, in: Capsule())
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func isSelected(_ when: SlipWhen, model: SlipViewModel) -> Bool {
        switch (model.when, when) {
        case (.justNow, .justNow), (.earlierToday, .earlierToday), (.yesterday, .yesterday): true
        case (.picked, .picked): true
        default: false
        }
    }

    private var calendar: Calendar { Calendar.current }
}
