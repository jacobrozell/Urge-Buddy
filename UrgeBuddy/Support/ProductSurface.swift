import Foundation

enum ProductSurface {
    static var showsDebugTools: Bool {
        #if DEBUG
        return !ProcessInfo.processInfo.arguments.contains("-release_ui")
        #else
        return false
        #endif
    }
}
