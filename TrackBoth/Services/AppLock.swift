import LocalAuthentication
import Observation

@MainActor
@Observable
final class AppLock {
    static let shared = AppLock()

    var isLocked: Bool
    var isAuthenticating = false

    var isEnabled: Bool {
        didSet {
            Preferences.appLockEnabled = isEnabled
            if !isEnabled { isLocked = false }
        }
    }

    private init() {
        isEnabled = Preferences.appLockEnabled
        isLocked = Preferences.appLockEnabled
    }

    var shouldHoldPresentations: Bool { isEnabled && isLocked }

    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    var lockLabel: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .faceID: return RecoveryCopy.lockFaceID
        case .touchID: return RecoveryCopy.lockTouchID
        case .opticID: return RecoveryCopy.lockOpticID
        default: return RecoveryCopy.lockPasscode
        }
    }

    func lockIfEnabled() {
        if isEnabled { isLocked = true }
    }

    func unlock() async {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            isLocked = false
            return
        }
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            if try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: RecoveryCopy.unlockReason) {
                isLocked = false
            }
        } catch {
            isLocked = true
        }
    }
}
