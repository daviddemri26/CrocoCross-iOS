import SpriteKit
import UIKit

@MainActor
final class TrackNode: SKNode {
    private let crop = SKCropNode()
    private let mask = SKShapeNode()
    private let earth = TerrainMaterialNode(surface: false)
    private let road = TerrainMaterialNode(surface: true)
    private let edgeShadow = SKShapeNode()
    private let edge = SKShapeNode()
    private let underground = UndergroundSceneNode()
    private let sceneryCrop = SKCropNode()
    private let sceneryMask = SKShapeNode()
    private var currentID = ""

    override init() {
        super.init()
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask
        addChild(crop)
        crop.addChild(earth)
        crop.addChild(road)
        sceneryMask.fillColor = .white
        sceneryMask.strokeColor = .clear
        sceneryCrop.maskNode = sceneryMask
        addChild(sceneryCrop)
        sceneryCrop.addChild(underground)
        addChild(edgeShadow)
        addChild(edge)
        edge.fillColor = .clear
        edge.lineCap = .round
        edgeShadow.fillColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(world: World, size: CGSize, left: Double, ppm: CGFloat, seconds: Double,
                 reducedMotion: Bool, seed: UInt64, ground: (Double) -> CGFloat) {
        if currentID != world.id { configure(world) }
        let sampleCount = max(90, Int(size.width / 4))
        let surface = CGMutablePath(), outline = CGMutablePath()
        for sample in 0...sampleCount {
            let x = CGFloat(sample) / CGFloat(sampleCount) * size.width
            let wx = left + Double(x / ppm)
            let y = ground(wx)
            if sample == 0 { surface.move(to: CGPoint(x: x, y: y)); outline.move(to: CGPoint(x: x, y: y)) }
            else { surface.addLine(to: CGPoint(x: x, y: y)); outline.addLine(to: CGPoint(x: x, y: y)) }
        }
        // Artwork below Cloud Nine must remain visible below its thin floating road too.
        let belowRoad = surface.mutableCopy()!
        belowRoad.addLine(to: CGPoint(x: size.width, y: -size.height))
        belowRoad.addLine(to: CGPoint(x: 0, y: -size.height))
        belowRoad.closeSubpath()
        sceneryMask.path = belowRoad
        if world.id == "clouds" {
            for sample in stride(from: sampleCount, through: 0, by: -1) {
                let x = CGFloat(sample) / CGFloat(sampleCount) * size.width
                let wx = left + Double(x / ppm)
                let softness = 0.06 * sin(wx * 1.3) + 0.025 * sin(wx * 3.1 + 0.7)
                surface.addLine(to: CGPoint(x: x, y: ground(wx) - ppm * (0.85 + CGFloat(softness))))
            }
        } else {
            surface.addLine(to: CGPoint(x: size.width, y: -size.height))
            surface.addLine(to: CGPoint(x: 0, y: -size.height))
        }
        surface.closeSubpath()
        mask.path = surface
        earth.display(world: world, size: size, left: left, ppm: ppm, ground: ground)
        road.display(world: world, size: size, left: left, ppm: ppm, ground: ground)
        edgeShadow.path = outline
        edgeShadow.lineWidth = max(1.5, ppm * 0.05)
        edge.path = outline
        edge.lineWidth = max(0.8, ppm * 0.025)
        underground.display(world: world, size: size, left: left, ppm: ppm, seconds: seconds,
                            reducedMotion: reducedMotion, seed: seed, ground: ground)
    }

    private func configure(_ world: World) {
        currentID = world.id
        edge.strokeColor = world.edge.withAlphaComponent(0.72)
        edgeShadow.strokeColor = world.deepEarth.withAlphaComponent(0.65)
    }
}
