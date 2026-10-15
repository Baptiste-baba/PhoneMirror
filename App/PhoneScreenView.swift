import SwiftUI
import Video

/// Gives `content` the look of the iPhone screen: rounded corners and the
/// Dynamic Island. `content` is expected to fill the screen's proportions.
struct PhoneScreenView<Content: View>: View {
    let geometry: ScreenGeometry
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / geometry.size.width
            content
                .frame(width: proxy.size.width, height: proxy.size.height)
                .overlay(alignment: .topLeading) {
                    if let island = geometry.dynamicIsland {
                        Capsule()
                            .fill(.black)
                            .frame(width: island.width * scale, height: island.height * scale)
                            .offset(x: island.minX * scale, y: island.minY * scale)
                    }
                }
                .clipShape(.rect(cornerRadius: geometry.cornerRadius * scale, style: .continuous))
        }
    }
}
