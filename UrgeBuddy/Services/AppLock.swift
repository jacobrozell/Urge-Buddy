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
        // Screenshot and UI-test launches pass -ui_testing. A leftover lock on the simulator
        // would cover the screen with the passcode prompt.
        if ProcessInfo.processInfo.arguments.contains("-ui_testing") {
            isEnabled = false
            isLocked = false
        } else {
            isEnabled = Preferences.appLockEnabled
            isLocked = Preferences.appLockEnabled
        }
    }

    var shouldHoldPresentations: Bool { isEnabled && isLocked }

    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    var lockLabel: String {
        switch biometry {
        case .faceID: return RecoveryCopy.lockFaceID
        case .touchID: return RecoveryCopy.lockTouchID
        case .opticID: return RecoveryCopy.lockOpticID
        default: return RecoveryCopy.lockPasscode
        }
    }

    /// Symbol and spoken method for the onboarding lock preview.
    var unlockPrompt: (symbol: String, method: String) {
        switch biometry {
        case .faceID: ("faceid", "Face ID")
        case .touchID: ("touchid", "Touch ID")
        case .opticID: ("opticid", "Optic ID")
        default: ("lock", "your passcode")
        }
    }

    private var biometry: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        return context.biometryType
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
