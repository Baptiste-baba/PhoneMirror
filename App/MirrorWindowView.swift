import SwiftUI
import Video

/// The single window of the app: the iPhone screen, or a status message
/// while there is nothing to show.
struct MirrorWindowView: View {
    let connection: ConnectionMonitor

    var body: some View {
        StatusView(state: connection.state)
            .frame(minWidth: 240, maxWidth: .infinity, minHeight: 320, maxHeight: .infinity)
            .background(.black)
            .environment(\.colorScheme, .dark)
            .onAppear { connection.start() }
    }
}

#Preview {
    MirrorWindowView(connection: ConnectionMonitor())
}
