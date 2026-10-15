/// What the app can currently show the user about the iPhone.
public enum ConnectionState: Equatable, Sendable {
    /// No iPhone is plugged in.
    case noDevice

    /// An iPhone may be there, but something must be allowed before the
    /// stream can start. The reason tells the user what to do.
    case waitingForAuthorization(WaitReason)

    /// The iPhone screen is available as a capture device.
    case connected(deviceName: String)

    public enum WaitReason: Equatable, Sendable {
        /// macOS has not asked for camera access yet.
        case cameraAccessNotDetermined
        /// Camera access was refused in System Settings.
        case cameraAccessDenied
        /// The iPhone is plugged in but not exposed as a capture device,
        /// most likely because it is locked or does not trust this Mac yet.
        case deviceNotReady
    }
}

extension ConnectionState {
    /// - Parameters:
    ///   - captureDeviceName: The iPhone exposed as a capture device, if any.
    ///   - isPhonePluggedIn: Whether an iPhone is seen on USB, ready or not.
    ///   - cameraAccess: Only matters once there is a screen to show, so the
    ///     user is not bothered about it before plugging an iPhone in.
    init(captureDeviceName: String?, isPhonePluggedIn: Bool, cameraAccess: CameraAccess) {
        switch (captureDeviceName, cameraAccess) {
        case (let name?, .granted):
            self = .connected(deviceName: name)
        case (.some, .notDetermined):
            self = .waitingForAuthorization(.cameraAccessNotDetermined)
        case (.some, .denied):
            self = .waitingForAuthorization(.cameraAccessDenied)
        case (nil, _):
            self = isPhonePluggedIn ? .waitingForAuthorization(.deviceNotReady) : .noDevice
        }
    }
}
