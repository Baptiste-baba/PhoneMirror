import AppKit
import Video

/// Owns the app's single window (see `PhoneWindow` for why it is not a
/// SwiftUI scene).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // Owned by the app rather than the window: the app keeps running when the
    // window is closed, and reopening it must find the same connection.
    let connection = ConnectionMonitor()
    private lazy var window = PhoneWindow(connection: connection)

    func applicationDidFinishLaunching(_ notification: Notification) {
        connection.start()
        window.makeKeyAndOrderFront(nil)
    }

    /// Clicking the Dock icon brings back the closed window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            window.makeKeyAndOrderFront(nil)
        }
        return true
    }
}

