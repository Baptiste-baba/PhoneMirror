import Observation
import os

/// Combines everything the app knows about the iPhone into one `ConnectionState`.
@MainActor
@Observable
public final class ConnectionMonitor {
    private let captureDevices = CaptureDeviceMonitor()
    private let usbPresence = USBPresenceMonitor()
    private var cameraAccess = CameraAccess.current

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
        usbPresence.start()
        captureDevices.start()
    }

    /// Shows the system camera prompt if the user has not decided yet.
    public func requestCameraAccess() async {
        cameraAccess = await CameraAccess.request()
        Logger.video.info("Camera access after prompt: \(String(describing: self.cameraAccess), privacy: .public)")
    }

    /// Picks up a change made in System Settings while the app was in the background.
    public func refreshCameraAccess() {
        cameraAccess = .current
    }
}
