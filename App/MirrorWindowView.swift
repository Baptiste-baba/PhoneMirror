import SwiftUI
import Video

/// The single window of the app: the iPhone screen, or a status message
/// while there is nothing to show.
struct MirrorWindowView: View {
    // Fixed for now; driven by device detection from step 1 onwards.
    private let state: ConnectionState = .noDevice

    var body: some View {
        StatusView(state: state)
            .frame(minWidth: 240, maxWidth: .infinity, minHeight: 320, maxHeight: .infinity)
            .background(.black)
            .environment(\.colorScheme, .dark)
    }
}

#Preview {
    MirrorWindowView()
}
