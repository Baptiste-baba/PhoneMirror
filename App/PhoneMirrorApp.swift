import SwiftUI

@main
struct PhoneMirrorApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @AppStorage("showsDebugInfo") private var showsDebugInfo = false
    @AppStorage("playsAudioOnMac") private var playsAudioOnMac = true

    var body: some Scene {
        // The window is created by `AppDelegate`: this scene only provides
        // the menu bar.
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {}
            CommandGroup(replacing: .saveItem) {
                Button("Fermer") { NSApp.keyWindow?.performClose(nil) }
                    .keyboardShortcut("w")
            }
            CommandGroup(after: .toolbar) {
                Toggle("Son de l'iPhone sur le Mac", isOn: $playsAudioOnMac)
                Toggle("Infos de débogage", isOn: $showsDebugInfo)
                    .keyboardShortcut("d", modifiers: [.command, .option])
            }
        }
        .onChange(of: playsAudioOnMac, initial: true) { _, onMac in
            appDelegate.connection.mirror.playAudio(onMac: onMac)
        }
    }
}
