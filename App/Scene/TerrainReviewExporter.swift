#if DEBUG
import SpriteKit
import UIKit

/// Opt-in native renders for inspecting texture scale, slopes, scrolling and rotation.
@MainActor
enum TerrainReviewExporter {
    static func export(in view: SKView, worldID: String?) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("terrain-review", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var report: [[String: Any]] = []
            for world in GameCatalog.worlds where worldID == nil || world.id == worldID {
                let roadLoaded = TerrainArtwork.texture(world: world.id, surface: true) != nil
                let earthLoaded = TerrainArtwork.texture(world: world.id, surface: false) != nil
                for portrait in [false, true] {
                    let size = portrait ? CGSize(width: 402, height: 874) : CGSize(width: 1180, height: 700)
                    let ppm: CGFloat = portrait ? 36 : 48
                    let scene = SKScene(size: size)
                    scene.backgroundColor = world.sky
                    let background = SKSpriteNode(texture: GameAssets.texture(named: world.assetName))
                    let dimensions = background.texture?.size() ?? size
                    let preferredHeight = world.id == "clouds" ? size.height + 64 : size.height * (portrait ? 0.82 : 1.03)
                    let backgroundHeight = max(preferredHeight, size.width * dimensions.height / dimensions.width)
                    background.size = CGSize(width: backgroundHeight * dimensions.width / dimensions.height,
                                             height: backgroundHeight)
                    background.position = CGPoint(x: size.width / 2,
                        y: world.id == "clouds" ? size.height / 2 : size.height - backgroundHeight / 2)
                    background.zPosition = -20
                    scene.addChild(background)
                    let track = TrackNode()
                    scene.addChild(track)
                    let rider = SKSpriteNode(texture: GameAssets.texture(named: "shiba-yamaha"))
                    rider.size = CGSize(width: ppm * 3.3, height: ppm * 2.2)
                    rider.anchorPoint = CGPoint(x: 0.5, y: 0.15)
                    rider.zPosition = 5
                    scene.addChild(rider)
                    for frame in 0..<3 {
                        let left = 4.75 + Double(frame) * 0.7
                        func ground(_ x: Double) -> CGFloat {
                            size.height * 0.39 + CGFloat(sin(x * 0.32) * 1.0 + sin(x * 0.91) * 0.34) * ppm
                        }
                        track.display(world: world, size: size, left: left, ppm: ppm, seconds: 0,
                                      reducedMotion: true, seed: 4321, ground: ground)
                        rider.position = CGPoint(x: size.width * 0.28,
                                                 y: ground(left + Double(size.width * 0.28 / ppm)))
                        let filename = "\(world.id)-\(portrait ? "portrait" : "landscape")-\(frame).png"
                        guard let texture = view.texture(from: scene, crop: CGRect(origin: .zero, size: size)),
                              let data = UIImage(cgImage: texture.cgImage()).pngData() else {
                            throw NSError(domain: "TerrainReview", code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "Could not render \(filename)"])
                        }
                        try data.write(to: directory.appendingPathComponent(filename))
                        report.append(["file": filename, "roadLoaded": roadLoaded, "earthLoaded": earthLoaded,
                                       "leftMetres": left, "pointsPerMetre": ppm])
                    }
                }
            }
            try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
                .write(to: directory.appendingPathComponent("report.json"))
            print("TERRAIN_REVIEW_COMPLETE \(report.count) \(directory.path)")
        } catch {
            print("TERRAIN_REVIEW_FAILED \(error)")
        }
    }
}
#endif
