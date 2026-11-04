import LocalAuthentication
import Observation

@MainActor
@Observable
final class AppLock {
    static let shared = AppLock()

    var isLocked: Bool
    var isAuthenticating = false
    private var biometry: LABiometryType = .none
    private var ownerAuthenticationAvailable = false

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
        refreshCapabilities()
    }

    /// Reads Face ID, Touch ID, or passcode once. The privacy page and Settings only read the stored result.
    func refreshCapabilities() {
        let context = LAContext()
        ownerAuthenticationAvailable = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        biometry = context.biometryType
    }

    var shouldHoldPresentations: Bool { isEnabled && isLocked }

    var isAvailable: Bool { ownerAuthenticationAvailable }

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
        case .faceID: ("faceid", RecoveryCopy.lockMethodFaceID)
        case .touchID: ("touchid", RecoveryCopy.lockMethodTouchID)
        case .opticID: ("opticid", RecoveryCopy.lockMethodOpticID)
        default: ("lock", RecoveryCopy.lockMethodPasscode)
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
