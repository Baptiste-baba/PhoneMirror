import AppKit
import SwiftUI

/// Lets the window be dragged from SwiftUI content, which does not move the
/// window on its own (the video does, being an AppKit view).
struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView {
        DragView()
    }

    func updateNSView(_ nsView: DragView, context: Context) {}

    final class DragView: NSView {
        // Moved by the app rather than by the window server, so that SwiftUI
        // controls on top still get their clicks.
        override var mouseDownCanMoveWindow: Bool { false }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
