import AppKit
import Observation
import SwiftUI
import Video

/// The app's window: nothing but the iPhone screen, without title bar,
/// border or background, resizable only along the screen's proportions.
///
/// Created in AppKit: macOS draws a frame around every titled window, and a
/// SwiftUI window without one can never become key, so it would receive
/// neither ⌘W nor keyboard input.
final class PhoneWindow: NSWindow {
    init(connection: ConnectionMonitor) {
        super.init(
            contentRect: CGRect(x: 0, y: 0, width: 360, height: 780),
            styleMask: [.borderless, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        title = "PhoneMirror"
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        let hostingView = NSHostingView(rootView: MirrorWindowView(connection: connection))
        // The window's size is set here only, not from the SwiftUI content.
        hostingView.sizingOptions = []
        contentView = ResizingView(content: hostingView)
        center()
        setFrameAutosaveName("mirror")
        followScreenShape(of: connection.mirror)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    // Without title bar buttons to "click", these would only beep.
    override func performClose(_ sender: Any?) {
        if delegate?.windowShouldClose?(self) ?? true { close() }
    }

    override func performMiniaturize(_ sender: Any?) {
        miniaturize(sender)
    }

    /// Keeps the window at the screen's proportions as the iPhone rotates or
    /// another model is plugged in.
    private func followScreenShape(of mirror: MirrorSession) {
        let size = withObservationTracking {
            mirror.screenGeometry.size
        } onChange: { [weak self] in
            // Called before the change is made: read the new shape after it.
            Task { @MainActor in self?.followScreenShape(of: mirror) }
        }
        fit(aspectRatio: size)
    }

    /// Gives the window the screen's proportions, keeping its center and the
    /// length of the iPhone's short side, so that rotating the iPhone swaps
    /// the window's width and height.
    private func fit(aspectRatio: CGSize) {
        guard aspectRatio.width > 0, aspectRatio.height > 0 else { return }
        contentAspectRatio = aspectRatio

        let current = frame
        let shortSide = min(current.width, current.height)
        let ratio = max(aspectRatio.width, aspectRatio.height) / min(aspectRatio.width, aspectRatio.height)
        let longSide = (shortSide * ratio).rounded()
        let size = aspectRatio.width < aspectRatio.height
            ? CGSize(width: shortSide, height: longSide)
            : CGSize(width: longSide, height: shortSide)
        guard size != current.size else { return }

        var newFrame = CGRect(
            x: current.midX - size.width / 2,
            y: current.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        if let visibleFrame = screen?.visibleFrame {
            newFrame.origin.x = min(max(newFrame.minX, visibleFrame.minX), visibleFrame.maxX - newFrame.width)
            newFrame.origin.y = min(max(newFrame.minY, visibleFrame.minY), visibleFrame.maxY - newFrame.height)
        }
        setFrame(newFrame, display: true, animate: isVisible)
        invalidateShadow()
    }

    /// Follows the mouse until it is released, resizing the window from
    /// `edges` while keeping the screen's proportions and the opposite side
    /// in place.
    fileprivate func trackResize(from edges: ResizeEdges) {
        let start = frame
        let startMouse = NSEvent.mouseLocation
        let ratio = contentAspectRatio.height > 0 ? contentAspectRatio.width / contentAspectRatio.height : start.width / start.height
        let maxSize = screen?.visibleFrame.size ?? CGSize(width: CGFloat.infinity, height: .infinity)
        let (sx, sy) = (edges.horizontal, edges.vertical)

        while let event = nextEvent(matching: [.leftMouseDragged, .leftMouseUp]), event.type == .leftMouseDragged {
            let proposedWidth = start.width + sx * (NSEvent.mouseLocation.x - startMouse.x)
            let proposedHeight = start.height + sy * (NSEvent.mouseLocation.y - startMouse.y)

            // Follow whichever dimension the mouse moved the most.
            let followsWidth = sy == 0
                || (sx != 0 && abs(proposedWidth / start.width - 1) >= abs(proposedHeight / start.height - 1))
            var width = followsWidth ? proposedWidth : proposedHeight * ratio
            width = max(width, Self.minimumShortSide * max(1, ratio))
            width = min(width, maxSize.width, maxSize.height * ratio)
            let height = (width / ratio).rounded()
            width = width.rounded()

            let x = sx < 0 ? start.maxX - width : sx > 0 ? start.minX : start.midX - width / 2
            let y = sy < 0 ? start.maxY - height : sy > 0 ? start.minY : start.midY - height / 2
            setFrame(CGRect(x: x, y: y, width: width, height: height), display: true)
        }
        invalidateShadow()
    }

    private static let minimumShortSide: CGFloat = 160
}

private struct ResizeEdges: OptionSet {
    let rawValue: Int
    static let left = ResizeEdges(rawValue: 1 << 0)
    static let right = ResizeEdges(rawValue: 1 << 1)
    static let top = ResizeEdges(rawValue: 1 << 2)
    static let bottom = ResizeEdges(rawValue: 1 << 3)

    /// Direction in which each axis grows: -1 (left, bottom), 1 (right, top) or 0.
    var horizontal: CGFloat { contains(.left) ? -1 : contains(.right) ? 1 : 0 }
    var vertical: CGFloat { contains(.bottom) ? -1 : contains(.top) ? 1 : 0 }
}

/// Hosts the window's content, with resize handles over its corners and
/// edges: a window without frame cannot be resized otherwise.
private final class ResizingView: NSView {
    /// Corners are rounded off by the screen's shape, and clicks on
    /// transparent pixels go to the window behind: the corner handles must
    /// reach past the curve.
    private static let cornerSize: CGFloat = 36
    private static let edgeThickness: CGFloat = 5

    private let handles: [ResizeHandle] = [
        [.top, .left], [.top, .right], [.bottom, .left], [.bottom, .right],
        .top, .bottom, .left, .right,
    ].map { ResizeHandle(edges: $0) }

    init(content: NSView) {
        super.init(frame: .zero)
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.topAnchor.constraint(equalTo: topAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        handles.forEach(addSubview)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        let corner = Self.cornerSize
        let edge = Self.edgeThickness
        let b = bounds
        for handle in handles {
            // Corner handles are squares; edge handles span between them.
            let (sx, sy) = (handle.edges.horizontal, handle.edges.vertical)
            let width = sx == 0 ? b.width - 2 * corner : sy == 0 ? edge : corner
            let height = sy == 0 ? b.height - 2 * corner : sx == 0 ? edge : corner
            handle.frame = CGRect(
                x: sx < 0 ? b.minX : sx > 0 ? b.maxX - width : b.minX + corner,
                y: sy < 0 ? b.minY : sy > 0 ? b.maxY - height : b.minY + corner,
                width: width,
                height: height
            )
        }
    }
}

/// An invisible area the window is resized from. It must be a view of its
/// own: the window server moves the window by itself wherever views allow
/// it, before the app even sees the click.
private final class ResizeHandle: NSView {
    let edges: ResizeEdges

    init(edges: ResizeEdges) {
        self.edges = edges
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        (window as? PhoneWindow)?.trackResize(from: edges)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: cursor)
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        window?.invalidateCursorRects(for: self)
    }

    private var cursor: NSCursor {
        if #available(macOS 15, *) {
            let position: NSCursor.FrameResizePosition = switch edges {
            case [.top, .left]: .topLeft
            case [.top, .right]: .topRight
            case [.bottom, .left]: .bottomLeft
            case [.bottom, .right]: .bottomRight
            case .top: .top
            case .bottom: .bottom
            case .left: .left
            default: .right
            }
            return .frameResize(position: position, directions: .all)
        }
        return edges.vertical == 0 ? .resizeLeftRight
            : edges.horizontal == 0 ? .resizeUpDown
            : .crosshair
    }
}
