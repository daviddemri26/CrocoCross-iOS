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
        let canyonChecks = checks
        let viewports = [(402.0, 874.0), (874, 402), (1194, 834), (834, 1194), (320, 1024), (1600, 600)]
        for (width, height) in viewports {
            func jungle(_ travel: Double, _ elevation: Double, reduced: Bool = false, preview: Bool = false) -> BackgroundPanorama.Layout {
                BackgroundPanorama.jungle(viewportWidth: width, viewportHeight: height,
                    textureWidth: 1536 * BackgroundPanorama.jungleCropWidth, textureHeight: 1024,
                    worldTravel: travel, worldHeight: elevation,
                    reducedMotion: reduced, isPreview: preview)
            }
            let initial = jungle(0, 0)
            let cycle = initial.stride / BackgroundPanorama.junglePointsPerMetre
            for travel in [-1_000_000.0, -cycle - 0.001, -cycle, -cycle + 0.001, -60, 0, 60,
                           cycle - 0.001, cycle, cycle + 0.001, 4_000, 50_000, 1_000_000] {
                for elevation in [-1_000_000.0, -100, -6, 0, 6, 100, 1_000_000] {
                    let frame = jungle(travel, elevation)
                    let tiles = frame.tiles
                    precondition(tiles.count == 3 && tiles.allSatisfy { !$0.mirrored })
                    precondition(frame.height >= height * 2.4)
                    precondition(frame.centreY - frame.height / 2 <= -1.99)
                    precondition(frame.centreY + frame.height / 2 >= height + 1.99)
                    // Every fade is backed by the previous opaque painting.
                    let opaqueLeft = tiles[0].centre - frame.width / 2 + frame.width * BackgroundPanorama.jungleEdgeBlend
                    precondition(opaqueLeft <= 0 && tiles[2].centre + frame.width / 2 >= width)
                    for index in 1..<tiles.count {
                        let edge = tiles[index].centre - frame.width / 2 + frame.width * BackgroundPanorama.jungleEdgeBlend
                        let priorRight = tiles[index - 1].centre + frame.width / 2
                        precondition(abs(edge - priorRight) < 0.00001)
                    }
                    checks += 1
                }
                for delta in [-0.001, 0.001, 1] {
                    let before = jungle(travel, 0), after = jungle(travel + delta, 0)
                    let common = before.tiles.filter { tile in after.tiles.contains { $0.index == tile.index } }
                    precondition(common.count >= 2)
                    for tile in common {
                        let next = after.tiles.first { $0.index == tile.index }!
                        precondition(abs(next.centre - tile.centre + delta * BackgroundPanorama.junglePointsPerMetre) < 0.00001)
                    }
                    checks += 1
                }
                precondition(jungle(travel, 100, reduced: true) == jungle(0, 0, reduced: true))
                precondition(jungle(travel, -100, preview: true) == jungle(0, 0, preview: true))
                checks += 2
            }
        }
        var motion = BackgroundPanorama.WorldMotion()
        motion.update(x: 10, y: 2, seed: 42, tick: 0, isPreview: false)
        motion.update(x: 50_010, y: -200, seed: 42, tick: 1_000, isPreview: false)
        precondition(motion.travel == 50_000 && motion.height == -202)
        // Repeated global snapshots (including a physics-origin rebase or a
        // viewport/zoom-only change) cannot move the background.
        motion.update(x: 50_010, y: -200, seed: 42, tick: 1_000, isPreview: false)
        precondition(motion.travel == 50_000 && motion.height == -202)
        motion.update(x: 49_950, y: -198, seed: 42, tick: 1_001, isPreview: false)
        precondition(motion.travel == 49_940 && motion.height == -200)
        motion.update(x: 10, y: 2, seed: 42, tick: 0, isPreview: false)
        precondition(motion.travel == 0 && motion.height == 0)
        motion.update(x: 30, y: 6, seed: 99, tick: 0, isPreview: false)
        precondition(motion.travel == 0 && motion.height == 0)
        motion.update(x: 5, y: 1, seed: 99, tick: 0, isPreview: true)
        precondition(motion.travel == 0 && motion.height == 0)
        motion.update(x: 10, y: 2, seed: 99, tick: 0, isPreview: false)
        precondition(motion.travel == 0 && motion.height == 0)
        print("PASS: \(canyonChecks) unchanged Canyon checks, \(checks - canyonChecks) Jungle coverage/opacity, wrap/reverse and reduced-motion/preview cases across \(viewports.count) viewports; global motion, same-seed restart, new seed, preview and rebasing/zoom invariance checks passed")
    }
}
