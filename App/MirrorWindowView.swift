import SwiftUI
import Video

/// The single window of the app: the iPhone screen, or a status message
/// while there is nothing to show.
struct MirrorWindowView: View {
    let connection: ConnectionMonitor

    @AppStorage("showsDebugInfo") private var showsDebugInfo = false

    private var mirror: MirrorSession { connection.mirror }

    private var isShowingVideo: Bool {
        if case .connected = connection.state, mirror.videoSize != nil { true } else { false }
    }

    var body: some View {
        PhoneScreenView(geometry: mirror.screenGeometry) {
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
        .ignoresSafeArea()
        .environment(\.colorScheme, .dark)
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
    MirrorWindowView(connection: ConnectionMonitor())
}
