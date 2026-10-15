import SwiftUI
import Video

/// SwiftUI wrapper around the view showing the live iPhone screen.
struct VideoView: NSViewRepresentable {
    let session: MirrorSession

    func makeNSView(context: Context) -> DisplayView {
        DisplayView(session: session)
    }

    func updateNSView(_ nsView: DisplayView, context: Context) {}
}
