import AVFoundation
import CoreImage
import os

/// The AVFoundation part of the mirror: reads frames from the iPhone capture
/// device and hands them to a video renderer, off the main thread.
///
/// `@unchecked Sendable`: the capture session is only touched on
/// `sessionQueue`, and frame statistics only on `videoQueue`.
final class CapturePipeline: NSObject, @unchecked Sendable {
    struct Statistics: Sendable {
        var videoSize: CGSize
        var framesPerSecond: Double
        var pixelFormat: String
        /// Average level of the iPhone's sound in dB, when it is captured.
        var audioLevel: Float?
    }

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let audioOutput = AVCaptureAudioPreviewOutput()
    private let renderer: AVSampleBufferVideoRenderer
    private let onStatistics: @Sendable (Statistics?) -> Void
    private let onSnapshot: @Sendable (CGImage) -> Void

    private let sessionQueue = DispatchQueue(label: "PhoneMirror.capture.session")
    private let videoQueue = DispatchQueue(label: "PhoneMirror.capture.video", qos: .userInteractive)

    // sessionQueue only.
    private var deviceID: String?
    private var playsAudioOnMac = true

    // videoQueue only.
    private var statistics: Statistics?
    private var frameCount = 0
    private var countingSince = ContinuousClock.now
    private var lastSnapshot: ContinuousClock.Instant?
    private let snapshotContext = CIContext(options: [.cacheIntermediates: false])

    /// - Parameters:
    ///   - onStatistics: Called on an arbitrary queue when the video size
    ///     changes, about once per second while frames arrive, and with `nil`
    ///     once capture stops.
    ///   - onSnapshot: Called on an arbitrary queue about once per second with
    ///     a small picture of the screen, skipping nearly black ones.
    init(
        renderer: AVSampleBufferVideoRenderer,
        onStatistics: @escaping @Sendable (Statistics?) -> Void,
        onSnapshot: @escaping @Sendable (CGImage) -> Void
    ) {
        self.renderer = renderer
        self.onStatistics = onStatistics
        self.onSnapshot = onSnapshot
        super.init()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoQueue)
        audioOutput.volume = 1
    }

    /// While capturing, iOS sends the iPhone's sound to the Mac instead of its
    /// own speaker. Plays it on the Mac, or turns the capture's audio off.
    func playAudio(onMac: Bool) {
        sessionQueue.async { [self] in
            guard onMac != playsAudioOnMac else { return }
            playsAudioOnMac = onMac
            if let deviceID {
                startSession(deviceID: deviceID)
            }
        }
    }

    /// Starts streaming from the capture device with this unique ID,
    /// replacing any previous one.
    func start(deviceID: String) {
        sessionQueue.async { [self] in startSession(deviceID: deviceID) }
    }

    func stop() {
        sessionQueue.async { [self] in
            stopSession()
            deviceID = nil
        }
    }

    private func startSession(deviceID: String) {
        stopSession()
        self.deviceID = deviceID
        guard let device = AVCaptureDevice(uniqueID: deviceID) else { return }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            for port in input.ports where port.mediaType == .audio {
                port.isEnabled = playsAudioOnMac
            }
            session.beginConfiguration()
            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(output) { session.addOutput(output) }
            if playsAudioOnMac {
                if session.canAddOutput(audioOutput) { session.addOutput(audioOutput) }
            } else if session.outputs.contains(audioOutput) {
                session.removeOutput(audioOutput)
            }
            session.commitConfiguration()
            session.startRunning()
            Logger.video.info("Capture started, audio on \(self.playsAudioOnMac ? "Mac" : "iPhone", privacy: .public)")
        } catch {
            Logger.video.error("Could not open the iPhone screen: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func stopSession() {
        guard !session.inputs.isEmpty else { return }
        session.stopRunning()
        session.beginConfiguration()
        session.inputs.forEach(session.removeInput)
        session.commitConfiguration()
        renderer.flush(removingDisplayedImage: true, completionHandler: nil)
        videoQueue.async { [self] in
            statistics = nil
            onStatistics(nil)
        }
        Logger.video.info("Capture stopped")
    }
}

extension CapturePipeline: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Live video: show each frame as soon as it arrives instead of
        // scheduling it against a timebase.
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true) as? [NSMutableDictionary] {
            attachments.first?[kCMSampleAttachmentKey_DisplayImmediately] = true
        }
        if renderer.status == .failed || renderer.requiresFlushToResumeDecoding {
            renderer.flush()
        }
        renderer.enqueue(sampleBuffer)
        updateStatistics(with: sampleBuffer)
        takeSnapshotIfDue(of: sampleBuffer)
    }

    /// Keeps a recent picture of the screen to show, blurred, once the video
    /// stops. Nearly black frames are skipped: the screen goes black right
    /// before the iPhone locks.
    private func takeSnapshotIfDue(of sampleBuffer: CMSampleBuffer) {
        guard lastSnapshot.map({ .now - $0 >= .seconds(1) }) ?? true,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastSnapshot = .now

        let frame = CIImage(cvPixelBuffer: pixelBuffer)
        let scale = Self.snapshotWidth / frame.extent.width
        let snapshot = frame.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let average = snapshot.applyingFilter("CIAreaAverage", parameters: [
            kCIInputExtentKey: CIVector(cgRect: snapshot.extent),
        ])
        var pixel = [UInt8](repeating: 0, count: 4)
        snapshotContext.render(
            average, toBitmap: &pixel, rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil
        )
        let brightness = (Int(pixel[0]) + Int(pixel[1]) + Int(pixel[2])) / 3
        guard brightness > 12, let image = snapshotContext.createCGImage(snapshot, from: snapshot.extent) else { return }
        onSnapshot(image)
    }

    /// Enough for a blurred background.
    private static let snapshotWidth: CGFloat = 160

    private func updateStatistics(with sampleBuffer: CMSampleBuffer) {
        guard let format = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
        let dimensions = CMVideoFormatDescriptionGetDimensions(format)
        let size = CGSize(width: Int(dimensions.width), height: Int(dimensions.height))
        frameCount += 1

        let elapsed = ContinuousClock.now - countingSince
        let sizeChanged = statistics?.videoSize != size
        guard sizeChanged || elapsed >= .seconds(1) else { return }

        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) * 1e-18
        let current = Statistics(
            videoSize: size,
            framesPerSecond: statistics == nil ? 0 : Double(frameCount) / seconds,
            pixelFormat: Self.fourCC(CMFormatDescriptionGetMediaSubType(format)),
            audioLevel: audioOutput.connections.first?.audioChannels.map(\.averagePowerLevel).max()
        )
        Logger.video.debug("""
            \(current.framesPerSecond, format: .fixed(precision: 1), privacy: .public) fps, \
            audio \(current.audioLevel.map { "\($0) dB" } ?? "off", privacy: .public), \
            audio connections \(self.audioOutput.connections.map { "active=\($0.isActive) enabled=\($0.isEnabled)" }, privacy: .public)
            """)
        if sizeChanged {
            Logger.video.info("""
                Video size \(Int(size.width), privacy: .public)×\(Int(size.height), privacy: .public), \
                format \(current.pixelFormat, privacy: .public)
                """)
        }
        statistics = current
        frameCount = 0
        countingSince = .now
        onStatistics(current)
    }

    private static func fourCC(_ code: FourCharCode) -> String {
        String(decoding: [24, 16, 8, 0].map { UInt8((code >> $0) & 0xFF) }, as: UTF8.self)
    }
}
