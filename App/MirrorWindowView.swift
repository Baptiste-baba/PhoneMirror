import SwiftUI
import Video

/// The single window of the app: the iPhone screen, or a status message
/// while there is nothing to show.
struct MirrorWindowView: View {
    @State private var deviceMonitor = CaptureDeviceMonitor()

    private var state: ConnectionState {
        if let deviceName = deviceMonitor.deviceName {
            .connected(deviceName: deviceName)
        } else {
            .noDevice
        }
    }

    var body: some View {
        StatusView(state: state)
            .frame(minWidth: 240, maxWidth: .infinity, minHeight: 320, maxHeight: .infinity)
            .background(.black)
            .environment(\.colorScheme, .dark)
            .onAppear { deviceMonitor.start() }
    }
}

#Preview {
    MirrorWindowView()
}
