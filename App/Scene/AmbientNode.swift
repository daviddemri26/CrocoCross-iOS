import SpriteKit

/// Stable depth gives each painted sky silhouette its own size and crossing speed.
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
        // Search the longest crossing, then filter by each event's own duration.
        // Short fly-bys must not consume an actor slot after they have left the view.
        let events = SceneryPlacement.visible(world: world.id, layer: .sky,
            lower: clock - SkyPerspective.maximumDuration, upper: clock, seed: seed)
        var actorIndex = 0
        for event in events {
            let style = SceneryPresentation.forImage(world: world.id, layer: .sky, variant: event.variant)
            let perspective = SkyPerspective(depth: event.depth, speed: style.skySpeed)
            let progress = (clock - event.coordinate) / perspective.duration
            guard progress >= 0 && progress <= 1 else { continue }
            guard actorIndex < actors.count else { break }
            let actor = actors[actorIndex]
            actorIndex += 1
            let scale = event.scale * style.skyScale * perspective.scale
            actor.configure(world: world.id, layer: .sky, variant: event.variant,
                width: min(132, size.width * 0.27) * scale,
                maxHeight: min(110, size.height * 0.22) * scale)
            let margin = actor.size.width / 2 + 12
            // With Reduce Motion the camera passes a stationary image. Otherwise the
            // crossing follows the painted silhouette (the pelican faces left).
            let movesLeft = reducedMotion || (world.id == "sanfrancisco" && event.variant == 2)
            let travel = CGFloat(movesLeft ? 1 - progress : progress)
            let x = -margin + travel * (size.width + margin * 2)
            let bob = reducedMotion ? 0 : sin(seconds * 0.45 + event.phase) * min(3, actor.size.height * 0.08)
            actor.position = CGPoint(x: x, y: size.height * (style.skyAltitude + (1 - event.depth) * 0.08) + bob)
            actor.zRotation = reducedMotion ? 0 : sin(seconds * 0.28 + event.phase) * 0.018
            actor.zPosition = event.depth
            actor.alpha = 0.96
        }
    }
}
