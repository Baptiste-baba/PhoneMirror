import AppKit

/// Shows the live iPhone screen of a `MirrorSession`.
public final class DisplayView: NSView {
    public init(session: MirrorSession) {
        super.init(frame: .zero)
        // Layer-hosting view: the display layer is the view's own layer.
        layer = session.displayLayer
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
