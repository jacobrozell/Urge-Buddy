import SwiftData
import SwiftUI

struct JournalScreen: View {
    var entries: [JournalEntry]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.persist) private var persist

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        RecoveryCopy.journal,
                        systemImage: "book.closed",
                        description: Text(RecoveryCopy.journalEmpty)
                    )
                } else {
                    List {
                        ForEach(entries) { entry in
                            NavigationLink {
                                JournalEntryScreen(entry: entry) { delete(entry) }
                            } label: {
                                row(entry)
                            }
                            .listRowBackground(Color.tbSurface)
                            .swipeActions {
                                Button(RecoveryCopy.delete, systemImage: "trash", role: .destructive) { delete(entry) }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.tbBackground)
            .navigationTitle(RecoveryCopy.journal)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(RecoveryCopy.close) { dismiss() }
                }
            }
        }
    }

    @discardableResult
    private func delete(_ entry: JournalEntry) -> Bool {
        persist("delete journal note") { try RecoveryStore(context: modelContext).deleteUrgeNote(id: entry.id) } != nil
    }

    private func row(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
                Text(entry.metricName)
                    .font(.headline)
                    .foregroundStyle(Color.tbTextPrimary)
                Spacer(minLength: Spacing.s)
                Text(entry.when)
                    .font(.caption)
                    .foregroundStyle(Color.tbTextSecondary)
                    .multilineTextAlignment(.trailing)
            }
            Text("\(entry.outcome) · \(RecoveryCopy.strengthLabel) \(entry.strength)")
                .font(.subheadline)
                .foregroundStyle(Color.tbTextSecondary)
            Text(entry.text)
                .font(.body)
                .foregroundStyle(Color.tbTextPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

struct JournalEntryScreen: View {
    var entry: JournalEntry
    var onDelete: () -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var askDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                Text(entry.when)
                    .font(.subheadline)
                    .foregroundStyle(Color.tbTextSecondary)
                Text(entry.text)
                    .font(.body)
                    .foregroundStyle(Color.tbTextPrimary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: Spacing.m) {
                    fact(RecoveryCopy.howItWent, entry.outcome)
                    fact(RecoveryCopy.strengthLabel, entry.strength)
                    if let triggers = entry.triggers {
                        fact(RecoveryCopy.whatSetItOff, triggers)
                    }
                    if let ended = entry.ended {
                        fact(RecoveryCopy.endedLabel, ended)
                    }
                }
            }
            .padding(Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.tbBackground)
        .navigationTitle(entry.metricName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(RecoveryCopy.delete, systemImage: "trash") { askDelete = true }
            }
        }
        .confirmationDialog(RecoveryCopy.deleteNoteTitle, isPresented: $askDelete, titleVisibility: .visible) {
            Button(RecoveryCopy.delete, role: .destructive) {
                if onDelete() { dismiss() }
            }
            Button(RecoveryCopy.close, role: .cancel) {}
        } message: {
            Text(RecoveryCopy.deleteNoteMessage)
        }
    }

    private func fact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.tbTextSecondary)
            Text(value)
                .font(.body)
                .foregroundStyle(Color.tbTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
