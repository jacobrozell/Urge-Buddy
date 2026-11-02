import Foundation
import Observation

enum AppTab: Hashable {
    case today, progress, settings
}

enum PresentedFlow: Identifiable, Equatable {
    case urge(UUID?)
    case checkIn
    case celebration(UUID)

    var id: String {
        switch self {
        case .urge(let metricID): "urge-\(metricID?.uuidString ?? "any")"
        case .checkIn: "check-in"
        case .celebration(let metricID): "celebration-\(metricID.uuidString)"
        }
    }
}

@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()

    var selectedTab: AppTab = .today
    var presented: PresentedFlow?
    var pendingQuickAction: PresentedFlow?
    var resumeCheckInAfterUrge = false

    func present(_ flow: PresentedFlow) {
        if AppLock.shared.shouldHoldPresentations {
            pendingQuickAction = flow
            return
        }
        if case .urge = flow, case .checkIn = presented {
            resumeCheckInAfterUrge = true
        }
        presented = flow
    }

    func finishUrge() {
        if resumeCheckInAfterUrge {
            resumeCheckInAfterUrge = false
            presented = .checkIn
        } else {
            presented = nil
        }
    }

    /// Pull a visible flow behind the lock so a sheet cannot sit on top of it.
    func holdForLock() {
        guard AppLock.shared.shouldHoldPresentations, let presented else { return }
        pendingQuickAction = presented
        self.presented = nil
    }

    func flushPending() {
        guard !AppLock.shared.shouldHoldPresentations, let pending = pendingQuickAction else { return }
        pendingQuickAction = nil
        present(pending)
    }

    @discardableResult
    func handleQuickAction(type: String) -> Bool {
        guard type == "com.jacobrozell.TrackBoth.urge" else { return false }
        present(.urge(nil))
        return true
    }
}
