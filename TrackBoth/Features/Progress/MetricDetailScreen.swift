import SwiftData
import SwiftUI

struct MetricDetailScreen: View {
    var metric: Metric

    init(metric: Metric) {
        self.metric = metric
        _planText = State(initialValue: metric.ifThenPlan ?? "")
        _didLoadPlan = State(initialValue: true)
    }

    @Query private var entries: [MetricEntry]
    @Query private var urges: [UrgeEvent]
    @Query private var reasons: [Reason]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var model = MetricDetailViewModel()
    @State private var sheet: DetailSheet?
    @State private var pendingSlip = false
    @State private var planText = ""
    @State private var didLoadPlan = false
    @State private var newReason = ""
    @State private var editingReason: Reason?
    @State private var reasonDraft = ""

    var body: some View {
        ScrollView {
            ReadableColumn(width: .wide) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    if metric.habitType == .vice {
                        AdaptiveColumns(spacing: Spacing.m, minimumWidth: columnMinimum) {
                            summaryPanel
                            calendar
                        } trailing: {
                            if showsRecord {
                                recordPanel
                            }
                            reasonsSection
                            planSection
                        }
                    } else {
                        AdaptiveColumns(spacing: Spacing.m, minimumWidth: columnMinimum) {
                            summaryPanel
                        } trailing: {
                            calendar
                        }
                    }
                }
                .padding(.top, Spacing.s)
                .padding(.bottom, Spacing.l)
            }
        }
        .contentMargins(.bottom, Spacing.xl, for: .scrollContent)
        .background(Color.tbBackground)
        .navigationTitle(metric.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(RecoveryCopy.edit) { sheet = .form }
            }
        }
        .onAppear { refresh() }
        .onChange(of: refreshToken) { refresh() }
        .sheet(item: $sheet, onDismiss: {
            if pendingSlip {
                pendingSlip = false
                sheet = .slip
            }
        }) { sheet in
            switch sheet {
            case .editor(let day):
                DayEditorSheet(metric: metric, day: day) { pendingSlip = true }
            case .slip:
                SlipFlowView(metric: metric, prefilledTriggers: []) { self.sheet = nil }
            case .form:
                MetricFormView(metric: metric)
            }
        }
        .alert(RecoveryCopy.editReason, isPresented: reasonEditorPresented) {
            TextField(RecoveryCopy.addReason, text: $reasonDraft)
            Button(RecoveryCopy.save) { saveReasonEdit() }
            Button(RecoveryCopy.close, role: .cancel) {}
        }
    }

    private var columnMinimum: CGFloat {
        AdaptiveLayout.isShortHeight(vertical: verticalSizeClass)
            ? AdaptiveLayout.shortHeightColumnMinWidth
            : AdaptiveLayout.twoColumnMinWidth
    }

    private var showsPatterns: Bool {
        !model.stats.triggers.isEmpty || model.stats.hardestTime != nil || model.stats.hardestDay != nil
    }

    private var showsRecord: Bool {
        (model.stats.urges?.total ?? 0) > 0 || showsPatterns || !model.stats.recent.isEmpty
    }

    private var reasonEditorPresented: Binding<Bool> {
        Binding(
            get: { editingReason != nil },
            set: { if !$0 { editingReason = nil } }
        )
    }

    private var summaryPanel: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack(alignment: .center, spacing: Spacing.m) {
                    IconBadge(systemImage: metric.iconName, tint: metric.habitType == .vice ? .tbBrand : .tbHabit)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(model.stats.primary).bigNumberStyle().foregroundStyle(Color.tbTextPrimary)
                        if metric.habitType == .vice {
                            TimelineView(.periodic(from: .now, by: 60)) { context in
                                let history = Snapshots.viceHistory(for: metric, entries: entries, calendar: model.calendar)
                                Text(RecoveryCopy.clock(RecoveryMath.currentRunClock(history, now: context.date, calendar: model.calendar)))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.tbTextSecondary)
                            }
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                if model.stats.atRisk {
                    Text(RecoveryCopy.dontMissTwice)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.tbTextPrimary)
                }
                ForEach(Array(model.stats.tiles.enumerated()), id: \.offset) { _, tile in
                    detailRow(label: tile.label, value: tile.value, caption: tile.caption)
                }
                if let nextMilestone = model.stats.nextMilestone {
                    Text(nextMilestone)
                        .font(.subheadline)
                        .foregroundStyle(Color.tbTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !model.stats.startedLine.isEmpty {
                    detailRow(
                        label: metric.habitType == .vice ? RecoveryCopy.quitDate : RecoveryCopy.startedLabel,
                        value: model.stats.startedLine
                    )
                }
                if metric.habitType == .vice, (model.stats.urges?.total ?? 0) == 0 {
                    detailRow(label: RecoveryCopy.urges, value: RecoveryCopy.noUrgesYet)
                }
                if model.stats.needsCost {
                    Button { sheet = .form } label: {
                        Text(RecoveryCopy.addDailyCost)
                            .font(.headline)
                            .foregroundStyle(Color.tbBrand)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var calendar: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Button { model.shiftMonth(-1, metric: metric, now: Date()) } label: {
                    Image(systemName: "chevron.left")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Previous month")
                Spacer()
                Button { model.shiftMonth(1, metric: metric, now: Date()) } label: {
                    Image(systemName: "chevron.right")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Next month")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.tbBrand)
            MonthCalendar(month: model.month, stateFor: { day in
                model.state(for: day, metric: metric, entries: entries, now: Date())
            }, onSelect: { day in
                guard model.canEdit(day, metric: metric, now: Date()) else { return }
                sheet = .editor(day)
            })
            calendarLegend
        }
        .padding(Spacing.l)
        .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private var calendarLegend: some View {
        let items: [(DayVisualState, String)] = metric.habitType == .vice
            ? [
                (.confirmedFree, RecoveryCopy.legendCheckedFree),
                (.presumedFree, RecoveryCopy.legendCountedFree),
                (.slipped, RecoveryCopy.legendSlip),
                (.todayPending, RecoveryCopy.legendToday)
            ]
            : [
                (.habitDone, RecoveryCopy.legendDone),
                (.missed, RecoveryCopy.legendMissed),
                (.todayPending, RecoveryCopy.legendToday)
            ]
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Spacing.s)], alignment: .leading, spacing: Spacing.s) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: Spacing.s) {
                    DayMark(state: item.0, size: 12)
                    Text(item.1)
                        .font(.caption)
                        .foregroundStyle(Color.tbTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.top, Spacing.s)
    }

    private var recordPanel: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.m) {
                if let urges = model.stats.urges, urges.total > 0 {
                    detailRow(label: RecoveryCopy.beatenOf, value: urges.beaten)
                    detailRow(label: RecoveryCopy.slippedStat, value: urges.slipped)
                    detailRow(label: RecoveryCopy.notSureOutcome, value: urges.unsure)
                    if let average = urges.average {
                        detailRow(label: RecoveryCopy.averageStrengthLabel, value: average)
                    }
                }
                if showsPatterns {
                    SectionHeader(RecoveryCopy.patterns)
                    let maxCount = model.stats.triggers.map(\.count).max() ?? 1
                    ForEach(Array(model.stats.triggers.enumerated()), id: \.offset) { _, trigger in
                        triggerBar(trigger, maxCount: maxCount)
                    }
                    if let hardest = model.stats.hardestTime {
                        detailRow(label: RecoveryCopy.hardestTime, value: hardest)
                    }
                    if let hardestDay = model.stats.hardestDay {
                        detailRow(label: RecoveryCopy.hardestDay, value: hardestDay)
                    }
                }
                if !model.stats.recent.isEmpty {
                    SectionHeader(RecoveryCopy.recent)
                    ForEach(model.stats.recent) { event in
                        recentRow(event)
                    }
                }
            }
        }
    }

    private func recentRow(_ event: DetailEvent) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Image(systemName: event.systemImage)
                .foregroundStyle(event.usesSlipTint ? Color.tbSlip : Color.tbBrand)
                .frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.tbTextPrimary)
                    Spacer(minLength: Spacing.s)
                    Text(event.when)
                        .font(.caption)
                        .foregroundStyle(Color.tbTextSecondary)
                        .multilineTextAlignment(.trailing)
                }
                if let detail = event.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color.tbTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func triggerBar(_ trigger: DetailTrigger, maxCount: Int) -> some View {
        let fraction = CGFloat(trigger.count) / CGFloat(max(maxCount, 1))
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.s) {
                Image(systemName: trigger.systemImage)
                    .foregroundStyle(Color.tbBrand)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                Text(trigger.title)
                    .font(.body)
                    .foregroundStyle(Color.tbTextPrimary)
                Spacer(minLength: Spacing.s)
                Text("\(trigger.count)")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Color.tbTextSecondary)
            }
            Capsule()
                .fill(Color.tbSurfaceMuted)
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.tbBrand)
                        .scaleEffect(x: fraction, y: 1, anchor: .leading)
                }
                .clipShape(Capsule())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(trigger.title), \(trigger.count)")
    }

    private func detailRow(label: String, value: String, caption: String? = nil) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(Color.tbTextSecondary)
                    valueStack(value, caption: caption, alignment: .leading)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(Color.tbTextSecondary)
                    Spacer(minLength: Spacing.m)
                    valueStack(value, caption: caption, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption.map { "\(label), \(value), \($0)" } ?? "\(label), \(value)")
    }

    private func valueStack(_ value: String, caption: String?, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: Spacing.xs) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tbTextPrimary)
                .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
                .fixedSize(horizontal: false, vertical: true)
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Color.tbTextSecondary)
                    .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
            }
        }
    }

    private var reasonsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(RecoveryCopy.yourReasons)
            Card {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text(metricReasons.isEmpty ? RecoveryCopy.reasonsEmpty : RecoveryCopy.reasonOrderHint)
                        .font(metricReasons.isEmpty ? .body : .caption)
                        .foregroundStyle(Color.tbTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(Array(metricReasons.enumerated()), id: \.element.id) { index, reason in
                        reasonRow(reason, index: index)
                    }
                    TextField(RecoveryCopy.addReason, text: $newReason)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.sentences)
                    Button(RecoveryCopy.addReason) { addReason() }
                        .font(.headline)
                        .foregroundStyle(Color.tbBrand)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
        }
    }

    private func reasonRow(_ reason: Reason, index: Int) -> some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            Button {
                reasonDraft = reason.text
                editingReason = reason
            } label: {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if index == 0 {
                        Text(RecoveryCopy.primaryReason)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.tbBrand)
                    }
                    Text(reason.text)
                        .font(.body)
                        .foregroundStyle(Color.tbTextPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            Menu {
                Button(RecoveryCopy.edit) {
                    reasonDraft = reason.text
                    editingReason = reason
                }
                if index > 0 {
                    Button(RecoveryCopy.moveUp) { moveReason(reason, by: -1) }
                }
                if index < metricReasons.count - 1 {
                    Button(RecoveryCopy.moveDown) { moveReason(reason, by: 1) }
                }
                Button(RecoveryCopy.delete, role: .destructive) {
                    try? RecoveryStore(context: modelContext).deleteReason(reason)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.body)
                    .foregroundStyle(Color.tbTextSecondary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel(RecoveryCopy.edit)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: RecoveryCopy.edit) {
            reasonDraft = reason.text
            editingReason = reason
        }
        .accessibilityAction(named: RecoveryCopy.moveUp) { moveReason(reason, by: -1) }
        .accessibilityAction(named: RecoveryCopy.moveDown) { moveReason(reason, by: 1) }
        .accessibilityAction(named: RecoveryCopy.delete) {
            try? RecoveryStore(context: modelContext).deleteReason(reason)
        }
    }

    private var planSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(RecoveryCopy.yourPlan)
            Card {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text(RecoveryCopy.yourPlanPrefix)
                        .font(.subheadline)
                        .foregroundStyle(Color.tbTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    TextField(RecoveryCopy.nextTimePlan, text: $planText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...6)
                    if planDirty {
                        Button(RecoveryCopy.save) { savePlan() }
                            .font(.headline)
                            .foregroundStyle(Color.tbBrand)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
        }
    }

    private var planDirty: Bool {
        planText.trimmingCharacters(in: .whitespacesAndNewlines) != (metric.ifThenPlan ?? "")
    }

    private var metricReasons: [Reason] {
        reasons.filter { $0.metricID == metric.id }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var refreshToken: String {
        entries.map { "\($0.statusRaw):\($0.note ?? ""):\($0.triggersRaw)" }.joined(separator: "|")
            + "#" + urges.map { "\($0.outcomeRaw):\($0.intensity):\($0.triggersRaw)" }.joined(separator: "|")
            + "#" + (metric.costPerDayRaw ?? "")
            + "#" + String(metric.startedAt.timeIntervalSinceReferenceDate)
    }

    private func refresh() {
        model.update(metric: metric, entries: entries, urges: urges, now: Date())
        if !didLoadPlan {
            planText = model.stats.plan
            didLoadPlan = true
        }
    }

    private func addReason() {
        try? RecoveryStore(context: modelContext).addReason(newReason, to: metric)
        newReason = ""
    }

    private func saveReasonEdit() {
        guard let editingReason else { return }
        try? RecoveryStore(context: modelContext).updateReason(editingReason, text: reasonDraft)
        self.editingReason = nil
    }

    private func moveReason(_ reason: Reason, by delta: Int) {
        var ordered = metricReasons
        guard let index = ordered.firstIndex(where: { $0.id == reason.id }) else { return }
        let target = index + delta
        guard ordered.indices.contains(target) else { return }
        ordered.move(fromOffsets: IndexSet(integer: index), toOffset: delta > 0 ? target + 1 : target)
        try? RecoveryStore(context: modelContext).reorderReasons(ordered)
    }

    private func savePlan() {
        let trimmed = planText.trimmingCharacters(in: .whitespacesAndNewlines)
        try? RecoveryStore(context: modelContext).setPlan(metric, plan: trimmed.isEmpty ? nil : trimmed)
        planText = metric.ifThenPlan ?? ""
    }
}

private enum DetailSheet: Identifiable {
    case editor(Date)
    case slip
    case form

    var id: String {
        switch self {
        case .editor(let day): "editor-\(day.timeIntervalSinceReferenceDate)"
        case .slip: "slip"
        case .form: "form"
        }
    }
}

struct DayEditorSheet: View {
    var metric: Metric
    var day: Date
    var onSlip: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                ReadableColumn {
                    VStack(spacing: Spacing.s) {
                        if metric.habitType == .vice {
                            editorButton(RecoveryCopy.free, id: AccessibilityIdentifiers.dayEditorFree, prominent: true, action: markFree)
                            editorButton(RecoveryCopy.iSlipped, id: AccessibilityIdentifiers.dayEditorSlipped) { onSlip(); dismiss() }
                            editorButton(RecoveryCopy.clearDay, id: AccessibilityIdentifiers.dayEditorClear, action: clear)
                        } else {
                            editorButton(RecoveryCopy.done, prominent: true) { setDone(true) }
                            editorButton(RecoveryCopy.notDone) { setDone(false) }
                        }
                    }
                    .padding(.vertical, Spacing.l)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color.tbBackground)
            .navigationTitle(day.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button(RecoveryCopy.close) { dismiss() } }
        }
        .presentationDetents([.medium, .large])
        .adaptiveFormSheet()
    }

    private func editorButton(_ title: String, id: String? = nil, prominent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(prominent ? Color.tbOnBrand : Color.tbTextPrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.s)
                .background(prominent ? Color.tbBrand : Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id ?? "")
    }

    private func markFree() {
        try? RecoveryStore(context: modelContext).markFree(metric, on: day, now: Date())
        dismiss()
    }

    private func clear() {
        try? RecoveryStore(context: modelContext).clearDay(metric, on: day)
        dismiss()
    }

    private func setDone(_ done: Bool) {
        try? RecoveryStore(context: modelContext).setHabitDone(metric, on: day, done: done, now: Date())
        dismiss()
    }
}
