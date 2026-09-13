import SpriteKit

/// One occasional painted silhouette crosses the sky, with long quiet intervals.
@MainActor
final class AmbientNode: SKNode {
    private let actors = (0..<2).map { _ in SceneryActor() }

    override init() {
        super.init()
        actors.forEach { addChild($0) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(world: World, size: CGSize, cameraX: Double, seconds: Double,
                 reducedMotion: Bool, seed: UInt64) {
        actors.forEach { $0.isHidden = true }
        // Reduce Motion keeps a sparse world-anchored sky image instead of a timed fly-by.
        let clock = reducedMotion ? cameraX * 0.24 : seconds
        let duration = 15.0
        let events = SceneryPlacement.visible(world: world.id, layer: .sky,
            lower: clock - duration, upper: clock, seed: seed)
        for (actor, event) in zip(actors, events) {
            let progress = (clock - event.coordinate) / duration
            let style = SceneryPresentation.forImage(world: world.id, layer: .sky, variant: event.variant)
            actor.configure(world: world.id, layer: .sky, variant: event.variant,
                width: min(88, size.width * 0.13) * event.scale * style.skyScale,
                maxHeight: size.height * 0.13 * style.skyScale)
            let margin = actor.size.width / 2 + 12
            // With Reduce Motion the camera passes a stationary image. Otherwise the
            // crossing follows the painted silhouette (the pelican faces left).
            let movesLeft = reducedMotion || (world.id == "sanfrancisco" && event.variant == 2)
            let travel = CGFloat(movesLeft ? 1 - progress : progress)
            let x = -margin + travel * (size.width + margin * 2)
            let bob = reducedMotion ? 0 : sin(seconds * 0.45 + event.phase) * min(3, actor.size.height * 0.08)
            actor.position = CGPoint(x: x, y: size.height * (style.skyAltitude + event.depth * 0.08) + bob)
            actor.zRotation = reducedMotion ? 0 : sin(seconds * 0.28 + event.phase) * 0.018
            actor.alpha = 0.88
        }
    }
}
