import AppKit
import AVFoundation
import Observation
import os

/// Combines everything the app knows about the iPhone into one `ConnectionState`.
@MainActor
@Observable
public final class ConnectionMonitor {
    private let captureDevices = CaptureDeviceMonitor()
    private let usbPresence = USBPresenceMonitor()
    private var cameraAccess = AVCaptureDevice.authorizationStatus(for: .video)

    @ObservationIgnored private var activationObserver: (any NSObjectProtocol)?

    public init() {}

    public var state: ConnectionState {
        ConnectionState(
            captureDeviceName: captureDevices.deviceName,
            isPhonePluggedIn: usbPresence.isPhonePluggedIn,
            cameraAccess: cameraAccess
        )
    }

    /// Starts watching for iPhones. Calling it again has no effect.
    public func start() {
        guard activationObserver == nil else { return }

        // Picks up a change made in System Settings while the app was in the background.
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.cameraAccess = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }

        // Asks for camera access only once there is an iPhone screen to show.
        captureDevices.onDeviceChange = { [weak self] in
            self?.requestCameraAccessIfNeeded()
        }

        usbPresence.start()
        captureDevices.start()
    }

    private func requestCameraAccessIfNeeded() {
        guard captureDevices.device != nil, cameraAccess == .notDetermined else { return }
        Task {
            await AVCaptureDevice.requestAccess(for: .video)
            cameraAccess = AVCaptureDevice.authorizationStatus(for: .video)
            Logger.video.info("Camera access after prompt: \(self.cameraAccess.rawValue, privacy: .public)")
        }
    }
}
