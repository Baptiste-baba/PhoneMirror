import AVFoundation

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
        /// Camera access is blocked by a configuration profile or parental
        /// controls, which the user cannot change.
        case cameraAccessRestricted
        /// The iPhone is plugged in but not exposed as a capture device,
        /// most likely because it does not trust this Mac yet. A locked iPhone
        /// that already trusts this Mac is still exposed.
        case deviceNotReady
    }
}

extension ConnectionState {
    /// - Parameters:
    ///   - captureDeviceName: The iPhone exposed as a capture device, if any.
    ///   - isPhonePluggedIn: Whether an iPhone is seen on USB, ready or not.
    ///   - cameraAccess: Only matters once there is a screen to show, so the
    ///     user is not bothered about it before plugging an iPhone in.
    ///     The iPhone screen is a capture device, so it falls under the camera permission.
    init(captureDeviceName: String?, isPhonePluggedIn: Bool, cameraAccess: AVAuthorizationStatus) {
        guard let captureDeviceName else {
            self = isPhonePluggedIn ? .waitingForAuthorization(.deviceNotReady) : .noDevice
            return
        }
        switch cameraAccess {
        case .authorized: self = .connected(deviceName: captureDeviceName)
        case .notDetermined: self = .waitingForAuthorization(.cameraAccessNotDetermined)
        case .restricted: self = .waitingForAuthorization(.cameraAccessRestricted)
        case .denied: self = .waitingForAuthorization(.cameraAccessDenied)
        @unknown default: self = .waitingForAuthorization(.cameraAccessDenied)
        }
    }
}
