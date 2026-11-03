import SwiftData
import SwiftUI

struct ProgressScreen: View {
    @Query(sort: \Metric.sortOrder) private var metrics: [Metric]
    @Query private var entries: [MetricEntry]
    @Query private var urges: [UrgeEvent]
    @Query private var dayNotes: [DayNote]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.persist) private var persist
    @State private var model = ProgressViewModel()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var progressSheet: ProgressSheet?
    @State private var showArchived = false
    @State private var selection: UUID?
    @State private var didOpenDetail = false
    @State private var containerWidth: CGFloat = 0

    private var usesSplitNavigation: Bool {
        AdaptiveLayout.usesSplitNavigation(
            horizontal: horizontalSizeClass,
            vertical: verticalSizeClass,
            containerWidth: containerWidth
        )
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    ProgressSummaryCard(
                        summary: model.summary,
                        stacksStats: dynamicTypeSize.usesAccessibilityLayout
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.tbBackground)
                    .listRowSeparator(.hidden)
                    .selectionDisabled()
                }
                Section {
                    ForEach(model.active) { card in
                        NavigationLink(value: card.id) {
                            cardRow(card)
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.progressMetricCard(card.id))
                    }
                    .onMove { offsets, destination in
                        persist("reorder") { try model.moveActive(from: offsets, to: destination, metrics: metrics, store: RecoveryStore(context: modelContext)) }
                    }
                }
                if !model.recentDays.isEmpty {
                    Section {
                        ForEach(model.recentDays, id: \.day) { row in
                            HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
                                Image(systemName: row.systemImage)
                                    .foregroundStyle(Color.tbBrand)
                                    .frame(width: 24)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(row.day)
                                        .font(.caption)
                                        .foregroundStyle(Color.tbTextSecondary)
                                    Text(row.text)
                                        .font(.body)
                                        .foregroundStyle(Color.tbTextPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier(AccessibilityIdentifiers.progressRecentDay)
                            .listRowBackground(Color.tbSurface)
                            .selectionDisabled()
                        }
                    } header: {
                        Text(RecoveryCopy.recentDays)
                            .selectionDisabled()
                    }
                }
                if !model.journal.isEmpty {
                    Section {
                        Button { progressSheet = .journal } label: {
                            HStack(spacing: Spacing.m) {
                                Image(systemName: "book.closed")
                                    .foregroundStyle(Color.tbBrand)
                                    .frame(width: 24)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(RecoveryCopy.journal)
                                        .font(.headline)
                                        .foregroundStyle(Color.tbTextPrimary)
                                    Text(RecoveryCopy.journalCount(model.journal.count))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.tbTextSecondary)
                                }
                                Spacer(minLength: Spacing.s)
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Color.tbTextSecondary)
                                    .accessibilityHidden(true)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.progressJournal)
                        .listRowBackground(Color.tbSurface)
                        .selectionDisabled()
                    }
                }
                if !model.archived.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $showArchived) {
                            ForEach(model.archived) { card in
                                archivedRow(card)
                            }
                        } label: {
                            Text(RecoveryCopy.archived)
                                .font(.headline)
                                .foregroundStyle(Color.tbTextPrimary)
                        }
                    }
                }
            }
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .background(Color.tbBackground.ignoresSafeArea())
            .tbNavigationBarBackground()
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { progressSheet = .add } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(RecoveryCopy.addSomething)
                }
            }
        } detail: {
            if let id = selection, let metric = metrics.first(where: { $0.id == id }) {
                MetricDetailScreen(metric: metric)
                    .id(metric.id)
            } else {
                ContentUnavailableView(RecoveryCopy.pickSomethingTitle, systemImage: "chart.line.uptrend.xyaxis")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.tbBackground.ignoresSafeArea())
                    .tbNavigationBarBackground()
                    .accessibilityIdentifier(AccessibilityIdentifiers.progressDetailPlaceholder)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .environment(\.horizontalSizeClass, usesSplitNavigation ? .regular : .compact)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
        .sheet(item: $progressSheet) { sheet in
            Group {
                switch sheet {
                case .add:
                    MetricFormView(metric: nil)
                case .journal:
                    JournalScreen(entries: model.journal)
                }
            }
            .persistFailureAlert()
        }
        .onAppear {
            refresh()
            openFirstDetailIfNeeded()
        }
        .onChange(of: snapshot) {
            refresh()
            openFirstDetailIfNeeded()
        }
        .onChange(of: metrics.map(\.id)) { _, ids in
            if let selection, !ids.contains(selection) {
                self.selection = nil
            }
        }
    }

    private func cardRow(_ card: ProgressCardModel) -> some View {
        Group {
            if dynamicTypeSize.usesAccessibilityLayout {
                VStack(alignment: .leading, spacing: Spacing.s) { cardContents(card) }
            } else {
                HStack(alignment: .center, spacing: Spacing.m) { cardContents(card) }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.spoken)
    }

    @ViewBuilder
    private func cardContents(_ card: ProgressCardModel) -> some View {
        IconBadge(systemImage: card.iconName, tint: card.habitType == .vice ? .tbBrand : .tbHabit)
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(card.name)
                .font(.headline)
                .foregroundStyle(Color.tbTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            let parts = card.line.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            Text(String(parts.first ?? ""))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tbTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if parts.count > 1 {
                Text(String(parts[1]))
                    .font(.footnote)
                    .foregroundStyle(Color.tbTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func archivedRow(_ card: ProgressCardModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Button { selection = card.id } label: { cardRow(card) }
                .buttonStyle(.plain)
            Button(RecoveryCopy.restore) { restore(card.id) }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 44)
                .buttonStyle(.bordered)
                .tint(Color.tbBrand)
        }
        .listRowBackground(Color.tbSurface)
    }

    private func restore(_ id: UUID) {
        guard let metric = metrics.first(where: { $0.id == id }) else { return }
        persist("restore") { try RecoveryStore(context: modelContext).setArchived(metric, false) }
    }

    private var snapshot: String {
        metrics.map { "\($0.id.uuidString):\($0.sortOrder):\($0.isArchived):\($0.name):\($0.viceModeRaw):\($0.dailyTarget ?? -1)" }.joined()
            + entries.map { "\($0.statusRaw):\($0.amount ?? -1)" }.joined()
            + urges.map { "\($0.outcomeRaw):\($0.note ?? ""):\($0.triggersRaw)" }.joined()
            + dayNotes.map { "\($0.moodRaw):\($0.text ?? "")" }.joined()
    }

    private func refresh() {
        model.update(metrics: metrics, entries: entries, urges: urges, dayNotes: dayNotes, now: Date())
    }

    private func openFirstDetailIfNeeded() {
        guard LaunchConfiguration.opensFirstDetail, !didOpenDetail, let id = model.active.first?.id else { return }
        didOpenDetail = true
        selection = id
    }
}

private struct ProgressSummaryCard: View {
    var summary: ProgressSummary
    var stacksStats: Bool

    private struct Stat: Identifiable {
        var id: String
        var value: String
        var label: String
        var spoken: String
    }

    private var heroValue: String {
        summary.savedValue ?? "\(summary.checkInStreak)"
    }

    private var heroLabel: String {
        summary.savedValue == nil ? RecoveryCopy.checkInStreakLabel : RecoveryCopy.totalSaved
    }

    private var stats: [Stat] {
        var row = [
            Stat(id: "urges", value: "\(summary.urgesBeaten)", label: RecoveryCopy.urgesBeaten, spoken: "\(RecoveryCopy.urgesBeaten), \(summary.urgesBeaten)"),
            Stat(id: "days", value: "\(summary.daysCheckedIn)", label: RecoveryCopy.checkedIn, spoken: "\(RecoveryCopy.daysCheckedIn), \(summary.daysCheckedIn)")
        ]
        if summary.savedValue != nil {
            row.append(Stat(
                id: "streak",
                value: "\(summary.checkInStreak)",
                label: RecoveryCopy.inARow,
                spoken: "\(RecoveryCopy.checkInStreakLabel), \(summary.checkInStreak)"
            ))
        }
        return row
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(heroValue)
                    .bigNumberStyle()
                    .foregroundStyle(Color.tbTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(heroLabel)
                    .font(.subheadline)
                    .foregroundStyle(Color.tbTextSecondary)
            }
            if stacksStats {
                VStack(alignment: .leading, spacing: Spacing.s) { statRow }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.m) { statRow }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(Color.tbSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    @ViewBuilder
    private var statRow: some View {
        ForEach(stats) { stat in
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.value)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.tbTextPrimary)
                Text(stat.label)
                    .font(.caption)
                    .foregroundStyle(Color.tbTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: stacksStats ? nil : .infinity, alignment: .leading)
        }
    }

    private var spoken: String {
        ([ "\(heroLabel), \(heroValue)" ] + stats.map(\.spoken)).joined(separator: ". ")
    }
}

private enum ProgressSheet: Identifiable {
    case add
    case journal

    var id: String {
        switch self {
        case .add: "add"
        case .journal: "journal"
        }
    }
}
