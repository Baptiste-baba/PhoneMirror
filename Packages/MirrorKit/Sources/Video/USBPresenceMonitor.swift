import Foundation
import IOKit
import IOKit.usb
import Observation
import os

/// Tells whether an iPhone is physically plugged in over USB, even when it
/// does not expose its screen yet (typically: not trusting this Mac).
///
/// Lives for the whole app session: notifications are never torn down.
@MainActor
@Observable
final class USBPresenceMonitor {
    private(set) var isPhonePluggedIn = false

    @ObservationIgnored private var notificationPort: IONotificationPortRef?
    @ObservationIgnored private var iterators: [io_iterator_t] = []
    @ObservationIgnored private var phoneRegistryIDs: Set<UInt64> = []

    /// Starts watching USB devices. Calling it again has no effect.
    func start() {
        guard notificationPort == nil else { return }
        let port = IONotificationPortCreate(kIOMainPortDefault)
        IONotificationPortSetDispatchQueue(port, .main)
        notificationPort = port

        let context = Unmanaged.passUnretained(self).toOpaque()
        for (notification, isArrival) in [(kIOFirstMatchNotification, true), (kIOTerminatedNotification, false)] {
            var iterator: io_iterator_t = 0
            IOServiceAddMatchingNotification(
                port,
                notification,
                Self.appleUSBDevices(),
                isArrival ? Self.devicesArrived : Self.devicesLeft,
                context,
                &iterator
            )
            iterators.append(iterator)
            // Draining the iterator handles devices already plugged in and arms the notification.
            update(from: iterator, isArrival: isArrival)
        }
    }

    // IOKit calls these on the main queue, set as the port's dispatch queue in `start()`.
    private static let devicesArrived: IOServiceMatchingCallback = { context, iterator in
        let monitor = monitor(from: context)
        MainActor.assumeIsolated { monitor.update(from: iterator, isArrival: true) }
    }

    private static let devicesLeft: IOServiceMatchingCallback = { context, iterator in
        let monitor = monitor(from: context)
        MainActor.assumeIsolated { monitor.update(from: iterator, isArrival: false) }
    }

    private nonisolated static func monitor(from context: UnsafeMutableRawPointer?) -> USBPresenceMonitor {
        Unmanaged<USBPresenceMonitor>.fromOpaque(context!).takeUnretainedValue()
    }

    private static func appleUSBDevices() -> CFMutableDictionary {
        let matching = IOServiceMatching(kIOUSBHostDeviceClassName) as NSMutableDictionary
        // Plain property matching: USB matching rules ignore a vendor ID
        // given without a product ID.
        matching[kIOPropertyMatchKey] = [kUSBVendorID: 0x05AC]  // Apple
        return matching
    }

    private func update(from iterator: io_iterator_t, isArrival: Bool) {
        while case let service = IOIteratorNext(iterator), service != IO_OBJECT_NULL {
            defer { IOObjectRelease(service) }
            var registryID: UInt64 = 0
            IORegistryEntryGetRegistryEntryID(service, &registryID)

            if isArrival {
                let productName = IORegistryEntryCreateCFProperty(
                    service, kUSBProductString as CFString, kCFAllocatorDefault, 0
                )?.takeRetainedValue() as? String
                guard productName == "iPhone" else { continue }
                phoneRegistryIDs.insert(registryID)
                Logger.video.info("iPhone plugged in over USB")
            } else if phoneRegistryIDs.remove(registryID) != nil {
                Logger.video.info("iPhone unplugged from USB")
            }
        }
        isPhonePluggedIn = !phoneRegistryIDs.isEmpty
    }
}
