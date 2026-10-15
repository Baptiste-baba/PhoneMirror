import AVFoundation
import Observation
import os

/// Tracks the iPhone exposed as a capture device, as it is plugged in and out.
@MainActor
@Observable
public final class CaptureDeviceMonitor {
    /// The iPhone currently available for screen capture, if any.
    /// With several iPhones plugged in, the one in use stays selected until
    /// it is unplugged.
    private(set) var device: AVCaptureDevice?

    public var deviceName: String? { device?.localizedName }

    @ObservationIgnored private var discovery: AVCaptureDevice.DiscoverySession?
    @ObservationIgnored private var devicesObservation: NSKeyValueObservation?
    @ObservationIgnored private var startDate: Date?

    public init() {}

    /// Starts watching for iPhones. Calling it again has no effect.
    public func start() {
        guard discovery == nil else { return }
        startDate = .now

        do {
            try ScreenCaptureDeviceAccess.enable()
        } catch {
            Logger.video.error("Could not enable screen capture devices (CoreMediaIO status \(error.status))")
        }

        // iOS screen capture devices are external devices carrying muxed
        // audio and video; this also leaves out Continuity Camera.
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external],
            mediaType: .muxed,
            position: .unspecified
        )
        self.discovery = discovery
        devicesObservation = discovery.observe(\.devices, options: [.initial]) { [weak self] _, _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    private func refresh() {
        let available = discovery?.devices ?? []
        let current = available.first { $0.uniqueID == device?.uniqueID } ?? available.first
        guard current?.uniqueID != device?.uniqueID else { return }

        if let device {
            Logger.video.info("iPhone disconnected: \(device.localizedName, privacy: .private)")
        }
        if let current {
            let delay = startDate.map { Date.now.timeIntervalSince($0) } ?? 0
            Logger.video.info("""
                iPhone connected: \(current.localizedName, privacy: .private) \
                (model \(current.modelID, privacy: .public)), \
                \(delay, format: .fixed(precision: 1), privacy: .public) s after start
                """)
        }
        device = current
    }
}
