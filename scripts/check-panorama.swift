import Foundation
@main struct PanoramaChecks {
    static func main() {
        var checks = 0
        for viewport in [390.0, 852, 1194] {
            let width = max(viewport + 4, 960)
            for travel in [-20000.0, -120.5, 0, 120, 121, 4000, 100000] {
                let tiles = BackgroundPanorama.tiles(viewportWidth: viewport, tileWidth: width, travel: travel)
                precondition(tiles.count == 3)
                let sorted = tiles.sorted { $0.centre < $1.centre }
                precondition(sorted[0].centre - width / 2 <= 0)
                precondition(sorted[2].centre + width / 2 >= viewport)
                for i in 1..<3 {
                    precondition(abs(sorted[i].centre - sorted[i-1].centre - width) < 0.0001)
                    precondition(sorted[i].mirrored != sorted[i-1].mirrored)
                }
                checks += 1
            }
            // Travel must still move scenery after the old saturating distance.
            let a = BackgroundPanorama.tiles(viewportWidth: viewport, tileWidth: width, travel: 4000)
            let b = BackgroundPanorama.tiles(viewportWidth: viewport, tileWidth: width, travel: 4001)
            precondition(abs((a[1].centre - b[1].centre) - 8) < 0.0001)
            checks += 1
        }
        print("\(checks) panorama coverage, edge and continued-motion checks passed")
    }
}
