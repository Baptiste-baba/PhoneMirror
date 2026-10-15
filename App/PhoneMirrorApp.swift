import SwiftUI
import Video

@main
struct PhoneMirrorApp: App {
    // Owned by the app rather than the window: the app keeps running when the
    // window is closed, and reopening it must find the same connection.
    @State private var connection = ConnectionMonitor()

    var body: some Scene {
        Window("PhoneMirror", id: "mirror") {
            MirrorWindowView(connection: connection)
        }
        .defaultSize(width: 360, height: 740)
        .windowResizability(.contentMinSize)
    }
}
