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
        .background(Color.tbBackground)
        .preferredColorScheme(colorScheme)
        .overlay {
            if onboarded && appLock.isLocked && scenePhase == .active && !appLock.isAuthenticating {
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
        .onChange(of: appLock.isLocked) { _, locked in
            if locked { dismissCoverForLock() }
            guard !locked, onboarded else { return }
            router.flushPending()
            refreshCelebration()
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
        .onChange(of: router.presented) { _, newValue in
            syncCover()
            if newValue == nil { refreshCelebration() }
        }
        .onChange(of: cover?.id) { _, newID in
            if newID == nil, case .checkIn = router.presented { router.presented = nil }
        }
        .fullScreenCover(item: urgeBinding) { flow in
            if case .urge(let id) = flow {
                UrgeFlowView(metrics: metrics, preferredID: id) { router.finishUrge() }
                    .persistFailureAlert()
            }
        }
        .sheet(item: $cover) { item in
            switch item {
            case .checkIn:
                CheckInSheet(metrics: metrics, entries: entries)
                    .persistFailureAlert()
            case .celebration(let request):
                CelebrationView(request: request) {
                    celebration = nil
                    cover = nil
                    refreshCelebration()
                    syncCover()
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if BootstrapStoreRecovery.mode == .inMemoryFallback {
                StoreRecoveryBanner()
            }
        }
    }

    private var urgeBinding: Binding<PresentedFlow?> {
        Binding(
            get: {
                if case .urge = router.presented { return router.presented }
                return nil
            },
            set: { newValue in
                if newValue == nil, case .urge = router.presented { router.presented = nil }
            }
        )
    }

    private func syncCover() {
        let next: RootCover?
        if case .checkIn = router.presented {
            next = .checkIn
        } else if case .urge = router.presented {
            return
        } else if let celebration {
            next = .celebration(celebration)
        } else {
            next = nil
        }
        if next?.id != cover?.id { cover = next }
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
        .tint(Color.tbBrand)
    }
}

