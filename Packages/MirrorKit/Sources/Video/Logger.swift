import Foundation
import os

extension Logger {
    /// Watch with `make logs`.
    static let video = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PhoneMirror", category: "Video")
}
