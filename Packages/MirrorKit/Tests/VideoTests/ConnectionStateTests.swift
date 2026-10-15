import AVFoundation
import Testing
@testable import Video

struct ConnectionStateTests {
    @Test(arguments: [
        // Nothing plugged in: camera access does not matter yet.
        (nil, false, CameraAccess.notDetermined, ConnectionState.noDevice),
        (nil, false, .denied, .noDevice),
        (nil, false, .granted, .noDevice),
        // Plugged in, but the screen is not exposed (not trusting this Mac yet).
        (nil, true, .granted, .waitingForAuthorization(.deviceNotReady)),
        (nil, true, .denied, .waitingForAuthorization(.deviceNotReady)),
        // Screen exposed: camera access decides.
        ("iPhone", true, .notDetermined, .waitingForAuthorization(.cameraAccessNotDetermined)),
        ("iPhone", true, .denied, .waitingForAuthorization(.cameraAccessDenied)),
        ("iPhone", true, .granted, .connected(deviceName: "iPhone")),
        // A capture device wins even if USB presence lags behind.
        ("iPhone", false, .granted, .connected(deviceName: "iPhone")),
    ] as [(String?, Bool, CameraAccess, ConnectionState)])
    func derivesStateFromInputs(
        captureDeviceName: String?,
        isPhonePluggedIn: Bool,
        cameraAccess: CameraAccess,
        expected: ConnectionState
    ) {
        let state = ConnectionState(
            captureDeviceName: captureDeviceName,
            isPhonePluggedIn: isPhonePluggedIn,
            cameraAccess: cameraAccess
        )
        #expect(state == expected)
    }

    @Test(arguments: [
        (AVAuthorizationStatus.notDetermined, CameraAccess.notDetermined),
        (.authorized, .granted),
        (.denied, .denied),
        (.restricted, .denied),
    ])
    func mapsAuthorizationStatus(status: AVAuthorizationStatus, expected: CameraAccess) {
        #expect(CameraAccess(status) == expected)
    }
}
