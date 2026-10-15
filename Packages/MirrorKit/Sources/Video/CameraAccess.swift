import AVFoundation

/// Whether the app may open capture devices, as decided by the user in
/// System Settings › Privacy & Security › Camera. The iPhone screen is a
/// capture device, so it falls under the camera permission.
enum CameraAccess: Equatable, Sendable {
    case notDetermined
    case denied
    case granted

    init(_ status: AVAuthorizationStatus) {
        switch status {
        case .authorized: self = .granted
        case .notDetermined: self = .notDetermined
        case .denied, .restricted: self = .denied
        @unknown default: self = .denied
        }
    }

    static var current: CameraAccess {
        CameraAccess(AVCaptureDevice.authorizationStatus(for: .video))
    }

    /// Shows the system prompt if the user has not decided yet.
    static func request() async -> CameraAccess {
        _ = await AVCaptureDevice.requestAccess(for: .video)
        return current
    }
}
