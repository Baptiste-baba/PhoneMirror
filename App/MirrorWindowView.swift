import SwiftUI
import Video

/// The single window of the app: the iPhone screen, or a status message
/// while there is nothing to show.
struct MirrorWindowView: View {
    @State private var connection = ConnectionMonitor()

    var body: some View {
        StatusView(state: connection.state)
            .frame(minWidth: 240, maxWidth: .infinity, minHeight: 320, maxHeight: .infinity)
            .background(.black)
            .environment(\.colorScheme, .dark)
            .onAppear { connection.start() }
            .task(id: connection.state) {
                // Ask for camera access only once there is an iPhone screen to show.
                if connection.state == .waitingForAuthorization(.cameraAccessNotDetermined) {
                    await connection.requestCameraAccess()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                connection.refreshCameraAccess()
            }
    }
}

#Preview {
    MirrorWindowView()
}
