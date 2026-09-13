import SpriteKit

/// Three possible painted vignettes, shown individually and sparsely below the exact road mask.
@MainActor
final class UndergroundSceneNode: SKNode {
    private let actors = (0..<3).map { _ in SceneryActor() }
    override init() {
        super.init()
        actors.forEach { addChild($0) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(world: World, size: CGSize, left: Double, ppm: CGFloat, seconds: Double,
                 reducedMotion: Bool, seed: UInt64, ground: (Double) -> CGFloat) {
        actors.forEach { $0.isHidden = true }
        let right = left + Double(size.width / ppm)
        let scenes = SceneryPlacement.visible(world: world.id, layer: .ground,
            lower: left - 4, upper: right + 4, seed: seed)
        for (actor, scene) in zip(actors, scenes) {
            let x = scene.coordinate
            let style = SceneryPresentation.forImage(world: world.id, layer: .ground, variant: scene.variant)
            actor.configure(world: world.id, layer: .ground, variant: scene.variant,
                width: ppm * style.width * scene.scale, maxHeight: ppm * style.maxHeight * scene.scale)
            // Sample both sides as well as the centre to keep the complete image under steep ramps.
            let halfWidth = Double(actor.size.width / ppm / 2)
            let ceiling = min(ground(x), ground(x - halfWidth), ground(x + halfWidth))
            let clearance = max(style.clearance, Double(TerrainStyle.forWorld(world.id).roadDepth) + 0.10)
            let depth = ppm * (clearance + scene.depth * 0.22) + actor.size.height / 2
            let bob = world.id == "clouds" && !reducedMotion ? sin(seconds * 0.35 + scene.phase) * 2 : 0
            actor.position = CGPoint(x: CGFloat(x - left) * ppm, y: ceiling - depth + bob)
            actor.zRotation = 0
            actor.alpha = world.id == "clouds" ? 1 : 0.97
        }
    }
}
