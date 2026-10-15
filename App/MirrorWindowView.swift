import SwiftUI
import Video

/// The single window of the app: the iPhone screen, or a status message
/// while there is nothing to show.
struct MirrorWindowView: View {
    let connection: ConnectionMonitor
    /// Called with the screen's size, so the window can take its proportions.
    let onScreenSizeChange: (CGSize) -> Void

    @AppStorage("showsDebugInfo") private var showsDebugInfo = false
    @AppStorage("playsAudioOnMac") private var playsAudioOnMac = true

    private var mirror: MirrorSession { connection.mirror }

    private var isShowingVideo: Bool {
        if case .connected = connection.state, mirror.videoSize != nil { true } else { false }
    }

    /// Keeps the shape of the last iPhone seen while there is no video.
    private var screenGeometry: ScreenGeometry {
        if let size = (isShowingVideo ? mirror.videoSize : nil) ?? mirror.lastScreenSize {
            ScreenGeometry(videoSize: size)
        } else {
            .placeholder
        }
    }

    var body: some View {
        PhoneScreenView(geometry: screenGeometry) {
            if isShowingVideo {
                VideoView(session: mirror)
                    .overlay(alignment: .bottom) {
                        if showsDebugInfo {
                            DebugInfoView(mirror: mirror)
                                .padding(.bottom, 24)
                        }
                    }
            } else {
                StatusView(state: connection.state)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background { BlurredScreenView(snapshot: mirror.lastSnapshot) }
            }
        }
        .frame(minWidth: 160, maxWidth: .infinity, minHeight: 160, maxHeight: .infinity)
        .ignoresSafeArea()
        .environment(\.colorScheme, .dark)
        .onAppear { connection.start() }
        .onChange(of: screenGeometry.size, initial: true) { _, size in
            onScreenSizeChange(size)
        }
        .onChange(of: playsAudioOnMac, initial: true) { _, onMac in
            mirror.playAudio(onMac: onMac)
        }
    }
}

/// Stands for the iPhone screen while there is no video: its last picture,
/// blurred, or a plain gradient if there was none yet.
private struct BlurredScreenView: View {
    let snapshot: CGImage?

    var body: some View {
        Group {
            if let snapshot {
                Image(decorative: snapshot, scale: 1)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 24, opaque: true)
            } else {
                LinearGradient(
                    colors: [Color(red: 0.18, green: 0.22, blue: 0.34), Color(red: 0.05, green: 0.06, blue: 0.10)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .overlay(.black.opacity(0.3))
    }
}

/// Stream statistics, toggled with ⌥⌘D.
private struct DebugInfoView: View {
    let mirror: MirrorSession

    var body: some View {
        VStack(alignment: .leading) {
            if let size = mirror.videoSize {
                Text("\(Int(size.width)) × \(Int(size.height)) \(mirror.pixelFormat)")
            }
            Text("\(mirror.framesPerSecond, format: .number.precision(.fractionLength(1))) i/s")
            if let audioLevel = mirror.audioLevel {
                Text("Son \(Int(audioLevel)) dB")
            }
        }
        .font(.caption.monospacedDigit())
        .padding(6)
        .background(.black.opacity(0.6), in: .rect(cornerRadius: 6))
        .padding(8)
    }
}

#Preview {
    MirrorWindowView(connection: ConnectionMonitor()) { _ in }
}
