import SwiftUI

@main
struct PhoneMirrorApp: App {
    var body: some Scene {
        Window("PhoneMirror", id: "mirror") {
            MirrorWindowView()
        }
        .defaultSize(width: 360, height: 740)
        .windowResizability(.contentMinSize)
    }
}
