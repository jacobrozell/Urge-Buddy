import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppLock.self) private var appLock
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("pref.appearance") private var appearanceRaw = AppAppearance.system.rawValue
    @Query(filter: #Predicate<Metric> { !$0.isArchived }, sort: \Metric.sortOrder) private var metrics: [Metric]
    @Query private var entries: [MetricEntry]
    @Query private var reasons: [Reason]
    @State private var onboarded = Preferences.hasCompletedOnboarding
    @State private var celebration: CelebrationRequest?
    @State private var cover: RootCover?
    /// Check-in is still dismissing. The urge cover waits so two presentations never overlap.
    @State private var blockUrgeCover = false
    /// The urge cover is still dismissing. The next sheet waits for that dismiss to finish.
    @State private var deferNextCover = false

    var body: some View {
        @Bindable var router = router
        Group {
            if onboarded {
                MainTabView()
            } else {
                OnboardingFlow { onboarded = true }
            }
        }
        .persistFailureAlert()
        .background(Color.tbBackground.ignoresSafeArea())
        .tbWindowChrome()
        .preferredColorScheme(colorScheme)
        .accessibilityHidden(showsLock)
        .overlay {
            if showsLock {
                LockScreen()
            }
        }
        .overlay {
            if appLock.isEnabled && scenePhase != .active {
                PrivacyCover()
            }
        }
        .task {
            SnapshotOrientationLock.applyIfNeeded()
            if let tab = LaunchConfiguration.initialTab {
                router.selectedTab = tab
            }
            if LaunchConfiguration.shouldSeedDemo {
                try? DemoData.seedIfEmpty(context: modelContext)
                refreshCelebration()
            }
            if let flow = LaunchConfiguration.initialPresentation {
                router.present(flow)
            }
            syncCover()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                appLock.lockIfEnabled()
                router.holdForLock()
                dismissCoverForLock()
            }
            guard phase == .active else { return }
            do {
                try RecoveryStore(context: modelContext).resolveAbandonedUrges()
            } catch {
                logger.logError(error, context: "Couldn't save: resolve abandoned urges")
            }
            if onboarded { router.flushPending() }
            refreshCelebration()
        }
        .onChange(of: onboarded) { _, isOnboarded in
            guard isOnboarded else { return }
            router.flushPending()
        }
        .onChange(of: appLock.isLocked) { _, locked in
            if locked { dismissCoverForLock() }
            guard !locked, onboarded else { return }
            blockUrgeCover = false
            deferNextCover = false
            router.flushPending()
            refreshCelebration()
            syncCover()
        }
        .onOpenURL { url in
            guard url.scheme == "trackboth" else { return }
            switch url.host {
            case "urge": router.present(.urge(nil))
            case "checkin": router.present(.checkIn)
            default: break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .recoveryDataChanged)) { _ in
            onboarded = Preferences.hasCompletedOnboarding
            refreshCelebration()
            syncCover()
            Task { await ReminderScheduler.refresh(context: modelContext) }
        }
        .onChange(of: router.presented) { oldValue, newValue in
            if isUrge(oldValue), !isUrge(newValue) { deferCoverUntilUrgeIsGone() }
            syncCover()
            if newValue == nil { refreshCelebration() }
        }
        .onChange(of: cover?.id) { _, newID in
            if newID == nil, case .checkIn = router.presented { router.presented = nil }
        }
        .fullScreenCover(item: urgeBinding, onDismiss: finishUrgeDismiss) { flow in
            if case .urge(let id) = flow {
                UrgeFlowView(metrics: metrics, preferredID: id) { router.finishUrge() }
                    .persistFailureAlert()
            }
        }
        .sheet(item: $cover, onDismiss: finishSheetDismiss) { item in
            switch item {
            case .checkIn:
                CheckInSheet(metrics: metrics, entries: entries)
                    .persistFailureAlert()
            case .celebration(let request):
                CelebrationView(request: request) {
                    celebration = nil
                    cover = nil
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if BootstrapStoreRecovery.mode == .inMemoryFallback {
                StoreRecoveryBanner()
            }
        }
        // Outermost, so onboarding and the sheets presented above pick up the theme tint too.
        .tint(Color.tbBrand)
    }

    private var urgeBinding: Binding<PresentedFlow?> {
        Binding(
            get: {
                if blockUrgeCover { return nil }
                if case .urge = router.presented { return router.presented }
                return nil
            },
            set: { newValue in
                if newValue == nil, case .urge = router.presented { router.presented = nil }
            }
        )
    }

    private func isUrge(_ flow: PresentedFlow?) -> Bool {
        if case .urge = flow { return true }
        return false
    }

    /// The check-in sheet finished leaving. The urge cover can show now.
    /// A celebration that just closed looks for the next one only after it is gone,
    /// so Keep going is not immediately covered by the same sheet.
    private func finishSheetDismiss() {
        if blockUrgeCover, !appLock.shouldHoldPresentations {
            blockUrgeCover = false
            syncCover()
            return
        }
        guard celebration == nil else { return }
        refreshCelebration()
    }

    /// The urge cover finished leaving. The next sheet can show now.
    private func finishUrgeDismiss() {
        guard deferNextCover, !appLock.shouldHoldPresentations else { return }
        deferNextCover = false
        syncCover()
    }

    /// `onDismiss` does not run when the sheet never appeared. Don't wait forever.
    private func blockUrgeUntilSheetIsGone() {
        blockUrgeCover = true
        cover = nil
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            guard blockUrgeCover, cover == nil, !appLock.shouldHoldPresentations else { return }
            blockUrgeCover = false
            syncCover()
        }
    }

    private func deferCoverUntilUrgeIsGone() {
        deferNextCover = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            guard deferNextCover, !appLock.shouldHoldPresentations else { return }
            deferNextCover = false
            syncCover()
        }
    }

    private func syncCover() {
        guard !appLock.shouldHoldPresentations else {
            if cover != nil { cover = nil }
            return
        }
        if case .urge = router.presented {
            if cover != nil { blockUrgeUntilSheetIsGone() }
            return
        }
        if blockUrgeCover || deferNextCover { return }
        let next: RootCover?
        if case .checkIn = router.presented {
            next = .checkIn
        } else if let celebration {
            next = .celebration(celebration)
        } else {
            next = nil
        }
        if next?.id != cover?.id { cover = next }
    }

    /// The lock is covering Today. Hide that content from VoiceOver so a locked phone cannot be read aloud.
    private var showsLock: Bool {
        onboarded && appLock.isLocked && scenePhase == .active && !appLock.isAuthenticating
    }

    private var colorScheme: ColorScheme? {
        switch AppAppearance(rawValue: appearanceRaw) ?? .system {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    /// Sheets (check-in, celebration) sit outside `AppRouter.presented`; hide them while the lock is active.
    private func dismissCoverForLock() {
        guard appLock.shouldHoldPresentations else { return }
        cover = nil
    }

    private func refreshCelebration() {
        guard !appLock.shouldHoldPresentations, router.presented == nil else { return }
        celebration = MilestoneCenter.pending(
            metrics: metrics,
            entries: entries,
            reasons: reasons,
            now: Date(),
            calendar: .current
        ).first
        syncCover()
    }
}

private enum RootCover: Identifiable {
    case checkIn
    case celebration(CelebrationRequest)

    var id: String {
        switch self {
        case .checkIn: "check-in"
        case .celebration(let request): "celebration-\(request.id)"
        }
    }
}

private struct MainTabView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            TodayScreen()
                .tabItem { Label("Today", systemImage: "sun.max").accessibilityIdentifier(AccessibilityIdentifiers.tabToday) }
                .tag(AppTab.today)
            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis").accessibilityIdentifier(AccessibilityIdentifiers.tabProgress) }
                .tag(AppTab.progress)
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape").accessibilityIdentifier(AccessibilityIdentifiers.tabSettings) }
                .tag(AppTab.settings)
        }
    }
}

