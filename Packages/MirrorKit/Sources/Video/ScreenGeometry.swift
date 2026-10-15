import CoreGraphics

/// Physical shape of the iPhone screen, in the video's pixels: its rounded
/// corners and, on models that have one, the Dynamic Island.
///
/// The video only carries what the screen displays: the corners and the
/// Dynamic Island must be drawn over it to look like the real screen.
public struct ScreenGeometry: Equatable, Sendable {
    /// Screen size in pixels, in the current orientation.
    public let size: CGSize
    public let cornerRadius: CGFloat
    /// `nil` in landscape too: the video does not tell which side it is on.
    public let dynamicIsland: CGRect?

    public init(videoSize: CGSize) {
        size = videoSize
        let isPortrait = videoSize.height >= videoSize.width
        let portraitSize = isPortrait ? videoSize : CGSize(width: videoSize.height, height: videoSize.width)
        guard let model = Self.models.first(where: { $0.size == portraitSize }) else {
            // Unknown model, likely one with a notch: close enough corners, no island.
            cornerRadius = 0.12 * portraitSize.width
            dynamicIsland = nil
            return
        }
        cornerRadius = model.cornerRadius * Self.scale
        dynamicIsland = isPortrait ? CGRect(
            x: (portraitSize.width - Self.islandSize.width * Self.scale) / 2,
            y: model.islandTop * Self.scale,
            width: Self.islandSize.width * Self.scale,
            height: Self.islandSize.height * Self.scale
        ) : nil
    }

    /// Shape shown before the first frame arrives (iPhone 15, 16).
    public static let placeholder = ScreenGeometry(videoSize: CGSize(width: 1179, height: 2556))

    /// Every iPhone with a Dynamic Island is a 3x screen.
    private static let scale: CGFloat = 3
    private static let islandSize = CGSize(width: 126, height: 37.33)

    /// Models with a Dynamic Island: portrait screen size in pixels, then
    /// corner radius and island position in points.
    private static let models: [(size: CGSize, cornerRadius: CGFloat, islandTop: CGFloat)] = [
        (CGSize(width: 1179, height: 2556), 55, 11),  // 14 Pro, 15, 15 Pro, 16
        (CGSize(width: 1290, height: 2796), 55, 11),  // 14 Pro Max, 15 Plus, 15 Pro Max, 16 Plus
        (CGSize(width: 1206, height: 2622), 62, 14),  // 16 Pro, 17, 17 Pro
        (CGSize(width: 1320, height: 2868), 62, 14),  // 16 Pro Max, 17 Pro Max
        (CGSize(width: 1260, height: 2736), 62, 14),  // Air
    ]
}
