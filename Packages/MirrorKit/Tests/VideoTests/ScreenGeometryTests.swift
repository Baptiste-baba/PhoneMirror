import CoreGraphics
import Testing
@testable import Video

struct ScreenGeometryTests {
    @Test func placesDynamicIslandInPortrait() throws {
        let geometry = ScreenGeometry(videoSize: CGSize(width: 1290, height: 2796))
        #expect(geometry.cornerRadius == 165)
        let island = try #require(geometry.dynamicIsland)
        #expect(island.midX == 645)
        #expect(island.minY == 33)
        #expect(island.width == 378)
    }

    @Test func omitsDynamicIslandInLandscape() {
        let geometry = ScreenGeometry(videoSize: CGSize(width: 2796, height: 1290))
        #expect(geometry.size == CGSize(width: 2796, height: 1290))
        #expect(geometry.cornerRadius == 165)
        #expect(geometry.dynamicIsland == nil)
    }

    @Test func roundsCornersOfUnknownModels() {
        let geometry = ScreenGeometry(videoSize: CGSize(width: 1170, height: 2532))
        #expect(geometry.cornerRadius > 0)
        #expect(geometry.dynamicIsland == nil)
    }
}
