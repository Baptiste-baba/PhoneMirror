import Foundation
import IOKit
import IOKit.usb
import Observation
import os

/// Tells whether an iPhone is physically plugged in over USB, even when it
/// does not expose its screen yet (typically: not trusting this Mac).
@MainActor
@Observable
final class USBPresenceMonitor {
    var isPhonePluggedIn: Bool { !phoneRegistryIDs.isEmpty }

    private var phoneRegistryIDs: Set<UInt64> = []

    // Only touched on the main queue, and in deinit once nothing else can.
    @ObservationIgnored private nonisolated(unsafe) var notificationPort: IONotificationPortRef?
    @ObservationIgnored private nonisolated(unsafe) var iterators: [io_iterator_t] = []

    deinit {
        // Destroying the port stops the callbacks, which point to this instance.
        iterators.forEach { IOObjectRelease($0) }
        if let notificationPort {
            IONotificationPortDestroy(notificationPort)
        }
    }

    /// Starts watching USB devices. Calling it again has no effect.
    func start() {
        guard notificationPort == nil else { return }
        let port = IONotificationPortCreate(kIOMainPortDefault)
        IONotificationPortSetDispatchQueue(port, .main)
        notificationPort = port

        let arrivals = register(kIOFirstMatchNotification, on: port) { context, iterator in
            let monitor = USBPresenceMonitor.monitor(from: context)
            MainActor.assumeIsolated { monitor.phonesArrived(iterator) }
        }
        let removals = register(kIOTerminatedNotification, on: port) { context, iterator in
            let monitor = USBPresenceMonitor.monitor(from: context)
            MainActor.assumeIsolated { monitor.phonesLeft(iterator) }
        }
        iterators = [arrivals, removals]

        // Draining the iterators handles iPhones already plugged in and arms the notifications.
        phonesArrived(arrivals)
        phonesLeft(removals)
    }

    private func register(
        _ notification: String,
        on port: IONotificationPortRef?,
        callback: IOServiceMatchingCallback
    ) -> io_iterator_t {
        // Plain property matching: USB matching rules ignore a vendor ID
        // given without a product ID.
        let matching = IOServiceMatching(kIOUSBHostDeviceClassName) as NSMutableDictionary
        matching[kIOPropertyMatchKey] = [
            kUSBHostMatchingPropertyVendorID: kIOUSBAppleVendorID,
            kUSBHostDevicePropertyProductString: "iPhone",
        ]
        var iterator: io_iterator_t = 0
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOServiceAddMatchingNotification(port, notification, matching, callback, context, &iterator)
        return iterator
    }

    private nonisolated static func monitor(from context: UnsafeMutableRawPointer?) -> USBPresenceMonitor {
        Unmanaged<USBPresenceMonitor>.fromOpaque(context!).takeUnretainedValue()
    }

    private func phonesArrived(_ iterator: io_iterator_t) {
        for registryID in Self.drain(iterator) where phoneRegistryIDs.insert(registryID).inserted {
            Logger.video.info("iPhone plugged in over USB")
        }
    }

    private func phonesLeft(_ iterator: io_iterator_t) {
        for registryID in Self.drain(iterator) where phoneRegistryIDs.remove(registryID) != nil {
            Logger.video.info("iPhone unplugged from USB")
        }
    }

    /// Returns the registry IDs of the services in the iterator, releasing them.
    private static func drain(_ iterator: io_iterator_t) -> [UInt64] {
        var registryIDs: [UInt64] = []
        while case let service = IOIteratorNext(iterator), service != IO_OBJECT_NULL {
            var registryID: UInt64 = 0
            IORegistryEntryGetRegistryEntryID(service, &registryID)
            registryIDs.append(registryID)
            IOObjectRelease(service)
        }
        return registryIDs
    }
}
