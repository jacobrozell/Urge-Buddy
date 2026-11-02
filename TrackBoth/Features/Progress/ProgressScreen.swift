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
    @State private var model = ProgressViewModel()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showAdd = false
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
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: dynamicTypeSize.usesAccessibilityLayout ? 280 : 150), spacing: Spacing.s)],
                        alignment: .leading,
                        spacing: Spacing.s
                    ) {
                        if let saved = model.summary.savedValue {
                            StatTile(value: saved, label: RecoveryCopy.totalSaved, systemImage: "dollarsign.circle")
                        }
                        StatTile(value: "\(model.summary.urgesBeaten)", label: RecoveryCopy.urgesBeaten, systemImage: "wind")
                        StatTile(value: "\(model.summary.daysCheckedIn)", label: RecoveryCopy.daysCheckedIn, systemImage: "checkmark.circle")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.s)
                    .listRowBackground(Color.tbBackground)
                    .listRowSeparator(.hidden)
                }
                Section {
                    ForEach(model.active) { card in
                        NavigationLink(value: card.id) {
                            cardRow(card)
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.progressMetricCard(card.id))
                    }
                    .onMove { offsets, destination in
                        try? model.moveActive(from: offsets, to: destination, metrics: metrics, store: RecoveryStore(context: modelContext))
                    }
                }
                if !model.recentDays.isEmpty {
                    Section(RecoveryCopy.recentDays) {
                        ForEach(model.recentDays) { row in
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
                            .listRowBackground(Color.tbSurface)
                        }
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
            .scrollContentBackground(.hidden)
            .background(Color.tbBackground)
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
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
                    .accessibilityIdentifier(AccessibilityIdentifiers.progressDetailPlaceholder)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .environment(\.horizontalSizeClass, usesSplitNavigation ? .regular : .compact)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
        .sheet(isPresented: $showAdd) {
            MetricFormView(metric: nil)
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
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(card.name)
                .font(.headline)
                .foregroundStyle(Color.tbTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(card.line)
                .font(.subheadline)
                .foregroundStyle(Color.tbTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
        try? RecoveryStore(context: modelContext).setArchived(metric, false)
    }

    private var snapshot: String {
        metrics.map { "\($0.id.uuidString):\($0.sortOrder):\($0.isArchived):\($0.name):\($0.viceModeRaw):\($0.dailyTarget ?? -1)" }.joined()
            + entries.map { "\($0.statusRaw):\($0.amount ?? -1)" }.joined()
            + urges.map(\.outcomeRaw).joined()
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
