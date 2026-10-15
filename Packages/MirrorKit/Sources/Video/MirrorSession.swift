import AVFoundation
import Observation

/// The live iPhone screen: what to display, and how it is doing.
@MainActor
@Observable
public final class MirrorSession {
    /// Size of the iPhone screen in pixels, once the first frame has arrived.
    /// Width and height swap when the iPhone rotates.
    public private(set) var videoSize: CGSize?
    public private(set) var framesPerSecond = 0.0
    public private(set) var pixelFormat = ""
    public private(set) var audioLevel: Float?

    /// Size of the iPhone screen in pixels and a small, recent picture of it.
    /// Both are kept once the video stops (iPhone locked, unplugged), so the
    /// window can still look like that iPhone. The picture is never saved.
    public private(set) var lastScreenSize: CGSize?
    public private(set) var lastSnapshot: CGImage?

    let displayLayer = AVSampleBufferDisplayLayer()

    @ObservationIgnored private var pipeline: CapturePipeline!
    @ObservationIgnored private var deviceID: String?

    init() {
        displayLayer.videoGravity = .resizeAspect
        displayLayer.backgroundColor = .black
        pipeline = CapturePipeline(
            renderer: displayLayer.sampleBufferRenderer,
            onStatistics: { [weak self] statistics in
                Task { @MainActor in self?.apply(statistics) }
            },
            onSnapshot: { [weak self] snapshot in
                Task { @MainActor in self?.lastSnapshot = snapshot }
            }
        )
    }

    /// Streams the given capture device, or stops streaming when `nil`.
    func show(_ device: AVCaptureDevice?) {
        guard device?.uniqueID != deviceID else { return }
        deviceID = device?.uniqueID
        if let deviceID {
            pipeline.start(deviceID: deviceID)
        } else {
            pipeline.stop()
        }
    }

    /// Plays the iPhone's sound on the Mac, or tries to leave it on the iPhone.
    public func playAudio(onMac: Bool) {
        pipeline.playAudio(onMac: onMac)
    }

    private func apply(_ statistics: CapturePipeline.Statistics?) {
        videoSize = statistics?.videoSize
        if let videoSize {
            lastScreenSize = videoSize
        }
        framesPerSecond = statistics?.framesPerSecond ?? 0
        pixelFormat = statistics?.pixelFormat ?? ""
        audioLevel = statistics?.audioLevel
    }
}
