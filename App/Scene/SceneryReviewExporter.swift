#if DEBUG
import CrocoCrossCore
import SpriteKit
import UIKit

/// Opt-in simulator contact renders: launch with -scenery-review or -scenery-review=canyon.
/// Exercises the same image loader, node layout, terrain clipping and scheduling as gameplay.
@MainActor
enum SceneryReviewExporter {
    static func export(in view: SKView, worldID: String?) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("scenery-review", isDirectory: true)
        do {
            WaysideNode.validatePlacement()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let worlds = GameCatalog.worlds.filter { worldID == nil || $0.id == worldID }
            var report: [[String: Any]] = []
            for world in worlds {
                for layer in SceneryLayer.allCases {
                    for variant in 1...layer.variantCount {
                        let seed: UInt64 = 1234
                        guard let event = SceneryPlacement.visible(world: world.id, layer: layer,
                            lower: 0, upper: 20_000, seed: seed).first(where: { $0.variant == variant }) else { continue }
                        for portrait in [false, true] {
                            try autoreleasepool {
                                let size = portrait ? CGSize(width: 402, height: 874) : CGSize(width: 1180, height: 700)
                                if layer == .sky {
                                    let stillSky = AmbientNode()
                                    let camera = (event.coordinate + 7.5) / 0.24
                                    stillSky.display(world: world, size: size, cameraX: camera, seconds: 0,
                                                     reducedMotion: true, seed: seed)
                                    if let actor = stillSky.children.first(where: { !$0.isHidden }) {
                                        let initial = actor.position
                                        stillSky.display(world: world, size: size, cameraX: camera, seconds: 100,
                                                         reducedMotion: true, seed: seed)
                                        precondition(actor.position == initial, "Reduced Motion drifted with time")
                                        stillSky.display(world: world, size: size, cameraX: camera + 1, seconds: 100,
                                                         reducedMotion: true, seed: seed)
                                        precondition(actor.position.x < initial.x, "Reduced Motion moved against the camera")
                                    }
                                }
                                let ppm: CGFloat = portrait ? 38 : 48
                                let left = layer == .sky ? 0 : event.coordinate - Double(size.width * 0.58 / ppm)
                                let seconds = layer == .sky ? event.coordinate + 7.5 : 0
                                func ground(_ x: Double) -> CGFloat {
                                    if layer == .wayside {
                                        return size.height * 0.40 + CGFloat(sin((x - left) * 0.16)) * ppm * 0.12
                                    }
                                    return size.height * 0.40 + CGFloat(sin((x - left) * 0.16)) * ppm * 0.8 + CGFloat(sin((x - left) * 0.53)) * ppm * 0.3
                                }
                                let scene = SKScene(size: size)
                                scene.anchorPoint = .zero
                                scene.backgroundColor = world.sky
                                let background = SKSpriteNode(texture: GameAssets.texture(named: world.assetName))
                                let dimensions = background.texture?.size() ?? size
                                let preferredHeight = world.id == "clouds" ? size.height + 64 : size.height * (portrait ? 0.82 : 1.03)
                                let backgroundHeight = max(preferredHeight, size.width * dimensions.height / dimensions.width)
                                background.size = CGSize(width: backgroundHeight * dimensions.width / dimensions.height, height: backgroundHeight)
                                background.position = CGPoint(x: size.width / 2, y: world.id == "clouds" ? size.height / 2 : size.height - backgroundHeight / 2)
                                background.zPosition = -20
                                scene.addChild(background)
                                let sky = AmbientNode()
                                sky.zPosition = -10
                                scene.addChild(sky)
                                sky.display(world: world, size: size, cameraX: left, seconds: seconds,
                                            reducedMotion: false, seed: seed)
                                let wayside = WaysideNode()
                                wayside.zPosition = -1
                                scene.addChild(wayside)
                                wayside.display(world: world, size: size, left: left, ppm: ppm, seed: seed, ground: ground)
                                let track = TrackNode()
                                scene.addChild(track)
                                track.display(world: world, size: size, left: left, ppm: ppm, seconds: seconds,
                                              reducedMotion: false, seed: seed, ground: ground)
                                if layer == .ground {
                                    let checked = UndergroundSceneNode()
                                    checked.display(world: world, size: size, left: left, ppm: ppm, seconds: seconds,
                                                    reducedMotion: true, seed: seed, ground: ground)
                                    precondition(checked.children.contains { !$0.isHidden }, "Ground review is empty")
                                    for actor in checked.children where !actor.isHidden {
                                        let x = left + Double(actor.position.x / ppm)
                                        let halfWidth = Double(actor.frame.width / ppm / 2)
                                        let ceiling = min(ground(x), ground(x - halfWidth), ground(x + halfWidth))
                                        let roadBottom = ceiling - ppm * TerrainStyle.forWorld(world.id).roadDepth
                                        precondition(actor.frame.maxY <= roadBottom - ppm * 0.09,
                                                     "Ground image overlaps the road material")
                                    }
                                }
                                if layer == .sky {
                                    precondition(sky.children.contains { !$0.isHidden }, "Sky review is empty")
                                }
                                let rider = SKSpriteNode(texture: GameAssets.texture(named: "shiba-yamaha"))
                                let geometry = GameCatalog.rider("shiba").geometry
                                let riderWidth = CGFloat(PhysicsConfiguration().wheelbase) / geometry.axleDistance * ppm
                                rider.size = CGSize(width: riderWidth, height: riderWidth * 2 / 3)
                                rider.anchorPoint = CGPoint(x: 0.5, y: 0.15)
                                rider.position = CGPoint(x: size.width * 0.24, y: ground(left + Double(size.width * 0.24 / ppm)))
                                rider.zPosition = 5
                                scene.addChild(rider)
                                let filename = "\(world.id)-\(layer.rawValue)-\(variant)-\(portrait ? "portrait" : "landscape").png"
                                guard let texture = view.texture(from: scene, crop: CGRect(origin: .zero, size: size)),
                                      let data = UIImage(cgImage: texture.cgImage()).pngData() else {
                                    throw NSError(domain: "SceneryReview", code: 1,
                                                  userInfo: [NSLocalizedDescriptionKey: "Could not render \(filename)"])
                                }
                                try data.write(to: directory.appendingPathComponent(filename))
                                let asset = SceneryArtwork.texture(world: world.id, layer: layer, variant: variant)
                                let style = SceneryPresentation.forImage(world: world.id, layer: layer, variant: variant)
                                let measurement = SceneryActor()
                                let requestedWidth = layer == .sky ? min(88, size.width * 0.13) * event.scale * style.skyScale : ppm * style.width * event.scale
                                let maxHeight = layer == .sky ? size.height * 0.13 * style.skyScale : ppm * style.maxHeight * event.scale
                                measurement.configure(world: world.id, layer: layer, variant: variant, width: requestedWidth, maxHeight: maxHeight)
                                precondition(asset != nil, "Missing scenery image")
                                if layer == .wayside {
                                    precondition(wayside.children.contains { !$0.isHidden }, "Wayside review is empty")
                                    for actor in wayside.children where !actor.isHidden {
                                        precondition(style.followsSlope || actor.zRotation == 0, "Upright object tilted")
                                        if world.id == "mine" { precondition(actor.frame.height / ppm <= 0.59, "Handheld lantern is oversized") }
                                    }
                                }
                                report.append(["file": filename, "asset": "\(world.id)/\(layer.rawValue)-\(variant)",
                                               "object": style.name, "assetLoaded": asset != nil,
                                               "textureWidth": asset?.size().width ?? 0, "textureHeight": asset?.size().height ?? 0,
                                               "displayWidthPoints": measurement.size.width, "displayHeightPoints": measurement.size.height,
                                               "pointsPerMetre": ppm])
                            }
                        }
                    }
                }
            }
            try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
                .write(to: directory.appendingPathComponent("report.json"), options: .atomic)
            print("SCENERY_REVIEW_COMPLETE \(report.count) \(directory.path)")
        } catch {
            print("SCENERY_REVIEW_FAILED \(error)")
        }
    }
}
#endif
