import AVFoundation
import Testing
@testable import Video

struct ConnectionStateTests {
    @Test(arguments: [
        // Nothing plugged in: camera access does not matter yet.
        (nil, false, AVAuthorizationStatus.notDetermined, ConnectionState.noDevice),
        (nil, false, .denied, .noDevice),
        (nil, false, .authorized, .noDevice),
        // Plugged in, but the screen is not exposed (not trusting this Mac yet).
        (nil, true, .authorized, .waitingForAuthorization(.deviceNotReady)),
        (nil, true, .denied, .waitingForAuthorization(.deviceNotReady)),
        // Screen exposed: camera access decides.
        ("iPhone", true, .notDetermined, .waitingForAuthorization(.cameraAccessNotDetermined)),
        ("iPhone", true, .denied, .waitingForAuthorization(.cameraAccessDenied)),
        ("iPhone", true, .restricted, .waitingForAuthorization(.cameraAccessRestricted)),
        ("iPhone", true, .authorized, .connected(deviceName: "iPhone")),
        // A capture device wins even if USB presence lags behind.
        ("iPhone", false, .authorized, .connected(deviceName: "iPhone")),
    ] as [(String?, Bool, AVAuthorizationStatus, ConnectionState)])
    func derivesStateFromInputs(
        captureDeviceName: String?,
        isPhonePluggedIn: Bool,
        cameraAccess: AVAuthorizationStatus,
        expected: ConnectionState
    ) {
        let state = ConnectionState(
            captureDeviceName: captureDeviceName,
            isPhonePluggedIn: isPhonePluggedIn,
            cameraAccess: cameraAccess
        )
        #expect(state == expected)
    }
}
