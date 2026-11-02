import StoreKit
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppLock.self) private var appLock
    @Environment(\.requestReview) private var requestReview
    @Environment(\.persist) private var persist

    @AppStorage("pref.remindersEnabled") private var remindersEnabled = false
    @AppStorage("pref.milestoneNotificationsEnabled") private var milestonesEnabled = true
    @AppStorage("pref.discreetNotifications") private var discreet = false
    @AppStorage("pref.appearance") private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage("pref.reminderHour") private var reminderHour = 20
    @AppStorage("pref.reminderMinute") private var reminderMinute = 0

    @State private var confirmDelete = false
    @State private var confirmDeleteAgain = false
    @State private var showImporter = false
    @State private var confirmImport = false
    @State private var pendingImport: URL?
    @State private var exportURL: URL?
    @State private var showShare = false
    @State private var message: String?
    @State private var showIntroduction = false

    var body: some View {
        NavigationStack {
            List {
                    reminders
                    privacy
                    appearance
                    yourData
                    support
                    about
                    if ProductSurface.showsDebugTools {
                        Section("Debug") {
                            Button("Seed demo data") {
                                try? DemoData.seedIfEmpty(context: modelContext)
                            }
                            Button("Reset onboarding") {
                                Preferences.hasCompletedOnboarding = false
                                NotificationCenter.default.post(name: .recoveryDataChanged, object: nil)
                            }
                        }
                    }
            }
            .scrollContentBackground(.hidden)
            .readableListMargins()
            .contentMargins(.bottom, Spacing.xl, for: .scrollContent)
            .background(Color.tbBackground.ignoresSafeArea())
            .tbNavigationBarBackground()
            .navigationTitle("Settings")
            .alert(RecoveryCopy.backupProblem, isPresented: messagePresented) {
                Button(RecoveryCopy.close, role: .cancel) { message = nil }
            } message: {
                Text(message ?? "")
            }
            .confirmationDialog(RecoveryCopy.deleteAllConfirm, isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(RecoveryCopy.continueDelete, role: .destructive) { confirmDeleteAgain = true }
                Button(RecoveryCopy.close, role: .cancel) {}
            }
            .confirmationDialog(RecoveryCopy.deleteAllSecond, isPresented: $confirmDeleteAgain, titleVisibility: .visible) {
                Button(RecoveryCopy.deleteAll, role: .destructive) { deleteAll() }
                Button(RecoveryCopy.close, role: .cancel) {}
            }
            .confirmationDialog(RecoveryCopy.replaceBackup, isPresented: $confirmImport, titleVisibility: .visible) {
                Button(RecoveryCopy.importBackup, role: .destructive) { importPending() }
                Button(RecoveryCopy.close, role: .cancel) { pendingImport = nil }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    pendingImport = url
                    confirmImport = true
                case .failure:
                    message = RecoveryCopy.invalidBackup
                }
            }
            .sheet(isPresented: $showShare) {
                if let exportURL {
                    ActivityShare(url: exportURL)
                }
            }
            .fullScreenCover(isPresented: $showIntroduction) {
                NavigationStack {
                    OnboardingFlow(onFinished: { showIntroduction = false }, review: true)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(RecoveryCopy.close) { showIntroduction = false }
                            }
                        }
                }
            }
        }
    }

    private var reminders: some View {
        Section {
            Toggle(RecoveryCopy.dailyCheckInToggle, isOn: $remindersEnabled)
                .onChange(of: remindersEnabled) { _, enabled in
                    Task { await updateReminders(enabled: enabled) }
                }
            DatePicker(RecoveryCopy.time, selection: reminderDate, displayedComponents: .hourAndMinute)
            Toggle(RecoveryCopy.milestoneNotifications, isOn: $milestonesEnabled)
                .onChange(of: milestonesEnabled) { _, _ in
                    Task { await ReminderScheduler.refresh(context: modelContext) }
                }
            Toggle(RecoveryCopy.discreetNotifications, isOn: $discreet)
                .onChange(of: discreet) { _, _ in
                    Task { await ReminderScheduler.refresh(context: modelContext) }
                }
        } header: {
            Text(RecoveryCopy.settingsReminders)
        } footer: {
            Text(RecoveryCopy.discreetFooter)
        }
    }

    private var privacy: some View {
        Section(RecoveryCopy.privacySection) {
            if appLock.isAvailable {
                Toggle(appLock.lockLabel, isOn: lockEnabled)
            } else {
                Text(RecoveryCopy.noPasscodeNote)
                    .foregroundStyle(Color.tbTextSecondary)
            }
        }
    }

    private var appearance: some View {
        Section(RecoveryCopy.appearanceSection) {
            Picker(RecoveryCopy.appearanceSection, selection: $appearanceRaw) {
                Text(RecoveryCopy.systemAppearance).tag(AppAppearance.system.rawValue)
                Text(RecoveryCopy.lightAppearance).tag(AppAppearance.light.rawValue)
                Text(RecoveryCopy.darkAppearance).tag(AppAppearance.dark.rawValue)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var yourData: some View {
        Section(RecoveryCopy.yourData) {
            Button(RecoveryCopy.exportBackup) { exportBackup() }
            Button(RecoveryCopy.importBackup) { showImporter = true }
            Button(RecoveryCopy.deleteAll, role: .destructive) { confirmDelete = true }
                .accessibilityIdentifier(AccessibilityIdentifiers.settingsDeleteAll)
        }
    }

    private var support: some View {
        Section(RecoveryCopy.supportSection) {
            Button(RecoveryCopy.viewOnboarding) { showIntroduction = true }
                .accessibilityIdentifier(AccessibilityIdentifiers.settingsViewOnboarding)
            NavigationLink(RecoveryCopy.whatIsUrgeSurfing) { UrgeSurfingExplainer() }
                .accessibilityIdentifier(AccessibilityIdentifiers.settingsUrgeSurfing)
            NavigationLink(RecoveryCopy.getHelpNow) { CrisisResourcesView() }
                .accessibilityIdentifier(AccessibilityIdentifiers.settingsCrisisResources)
            Link(RecoveryCopy.contactSupport, destination: AppLinks.support)
            Link(RecoveryCopy.privacyPolicy, destination: AppLinks.privacy)
            Button(RecoveryCopy.rateUrgeBuddy) { requestReview() }
        }
    }

    private var about: some View {
        Section(RecoveryCopy.aboutSection) {
            LabeledContent(RecoveryCopy.version, value: versionText)
            Text(RecoveryCopy.disclaimer)
                .font(.footnote)
                .foregroundStyle(Color.tbTextSecondary)
            Link(RecoveryCopy.accessibilityStatement, destination: AppLinks.accessibility)
        }
    }

    private var lockEnabled: Binding<Bool> {
        Binding(get: { appLock.isEnabled }, set: { appLock.isEnabled = $0 })
    }

    private var reminderDate: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? Date()
            },
            set: { newValue in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = parts.hour ?? 20
                reminderMinute = parts.minute ?? 0
                Task { await ReminderScheduler.refresh(context: modelContext) }
            }
        )
    }

    private var messagePresented: Binding<Bool> {
        Binding(get: { message != nil }, set: { if !$0 { message = nil } })
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
    }

    private func updateReminders(enabled: Bool) async {
        if enabled {
            let allowed = await ReminderScheduler.requestAuthorization()
            if !allowed { remindersEnabled = false }
        }
        await ReminderScheduler.refresh(context: modelContext)
    }

    private func exportBackup() {
        do {
            let data = try BackupService.exportData(from: modelContext)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(BackupService.fileName(for: Date()))
            try data.write(to: url, options: .atomic)
            exportURL = url
            showShare = true
        } catch {
            message = RecoveryCopy.invalidBackup
        }
    }

    private func importPending() {
        guard let pendingImport else { return }
        let accessed = pendingImport.startAccessingSecurityScopedResource()
        defer {
            if accessed { pendingImport.stopAccessingSecurityScopedResource() }
            self.pendingImport = nil
        }
        do {
            let data = try Data(contentsOf: pendingImport)
            try BackupService.importData(data, into: RecoveryStore(context: modelContext))
            Task { await ReminderScheduler.refresh(context: modelContext) }
        } catch BackupError.newerVersion {
            message = RecoveryCopy.newerBackup
        } catch {
            message = RecoveryCopy.invalidBackup
        }
    }

    private func deleteAll() {
        guard persist("delete all data", { try RecoveryStore(context: modelContext).deleteAllData() }) != nil else { return }
        ReminderScheduler.cancelAll()
        appLock.isEnabled = false
        appLock.isLocked = false
    }
}

private struct ActivityShare: UIViewControllerRepresentable {
    var url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
