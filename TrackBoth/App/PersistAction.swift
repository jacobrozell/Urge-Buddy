import SwiftUI

/// Runs a write from a view. On failure it logs and asks the nearest
/// `.persistFailureAlert()` to tell the user.
struct PersistAction {
    var onFailure: @MainActor (Error) -> Void = { _ in }

    @MainActor
    @discardableResult
    func callAsFunction<T>(_ operation: String, _ work: () throws -> T) -> T? {
        do {
            return try work()
        } catch {
            logger.logError(error, context: "Couldn't save: \(operation)")
            onFailure(error)
            return nil
        }
    }
}

extension EnvironmentValues {
    @Entry var persist = PersistAction()
}

private struct PersistFailureAlert: ViewModifier {
    @State private var failed = false

    func body(content: Content) -> some View {
        content
            .environment(\.persist, PersistAction { _ in failed = true })
            .alert(RecoveryCopy.saveFailedTitle, isPresented: $failed) {
                Button(RecoveryCopy.ok, role: .cancel) {}
            } message: {
                Text(RecoveryCopy.saveFailedMessage)
            }
    }
}

extension View {
    /// Attach at the root of every screen and every sheet or cover that writes data.
    func persistFailureAlert() -> some View {
        modifier(PersistFailureAlert())
    }
}
