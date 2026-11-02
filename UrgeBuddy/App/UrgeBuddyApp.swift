import SwiftUI
import SwiftData

@main
struct UrgeBuddyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let container = BootstrapStoreRecovery.makeContainer()

    init() {
        LaunchConfiguration.applyArguments()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(AppRouter.shared)
                .environment(AppLock.shared)
        }
        .modelContainer(container)
    }
}
