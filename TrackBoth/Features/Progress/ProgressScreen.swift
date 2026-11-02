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
    @State private var showAdd = false
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
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        if let saved = model.summary.savedText {
                            summaryLine(saved, systemImage: "dollarsign.circle")
                        }
                        summaryLine(RecoveryCopy.urgesBeatenCount(model.summary.urgesBeaten), systemImage: "wind")
                        summaryLine("\(model.summary.daysCheckedIn) \(RecoveryCopy.daysCheckedIn.lowercased())", systemImage: "checkmark.circle")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.s)
                    .listRowBackground(Color.tbSurface)
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
                    Section(RecoveryCopy.archived) {
                        ForEach(model.archived) { card in
                            NavigationLink(value: card.id) { cardRow(card) }
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

    private func summaryLine(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.tbTextPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Spacing.xs)
            .accessibilityLabel(text)
    }

    private func cardRow(_ card: ProgressCardModel) -> some View {
        HStack(spacing: Spacing.m) {
            IconBadge(systemImage: card.iconName, tint: card.habitType == .vice ? .tbBrand : .tbHabit)
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(card.name).font(.headline).foregroundStyle(Color.tbTextPrimary)
                Text(card.line).font(.subheadline).foregroundStyle(Color.tbTextSecondary)
            }
        }
        .frame(minHeight: 44)
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
