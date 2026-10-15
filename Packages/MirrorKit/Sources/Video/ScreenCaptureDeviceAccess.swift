import CoreMediaIO

/// Opts the process in to iOS screen capture devices: once enabled, an iPhone
/// plugged in over USB shows up as an `AVCaptureDevice`, as in QuickTime Player.
enum ScreenCaptureDeviceAccess {
    struct Failure: Error {
        let status: OSStatus
    }

    /// Must run before looking for capture devices. The device then appears
    /// asynchronously, usually within a few seconds.
    static func enable() throws(Failure) {
        // The SDK documents 1 as the default, but iPhones historically only
        // appear after setting it explicitly, so we always do.
        var address = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        var allow: UInt32 = 1
        let status = CMIOObjectSetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<UInt32>.size),
            &allow
        )
        guard status == kCMIOHardwareNoError else {
            throw Failure(status: status)
        }
    }
}
