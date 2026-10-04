import SpriteKit

/// Surface vignettes seen in the foreground, with their feet below the riding line in perspective.
/// A stable depth selects both size and distance below the road. All dimensions
/// stay in world metres so scrolling, zoom and time cannot move their footing.
@MainActor
final class ForegroundSceneryNode: SKNode {
    private var actors: [SceneryActor] = []
    override init() {
        super.init()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(world: World, size: CGSize, left: Double, ppm: CGFloat, seconds: Double,
                 reducedMotion: Bool, seed: UInt64, ground: (Double) -> CGFloat,
                 supportsFootprint: ((Double, Double) -> Bool)? = nil) {
        actors.forEach { $0.isHidden = true }
        let factor = SceneryMotion.foregroundFactor(reducedMotion: reducedMotion)
        let start = SceneryMotion.coordinate(screenMetres: 0, camera: left, factor: factor)
        let visibilityMargin = world.id == "jungle" ? 9.0 : 8
        // Include a complete predecessor neighbourhood so waterfall selection
        // cannot change when a camera or zoom boundary enters a scenery cell.
        let spacingLookback = world.id == "jungle" ? 36.0 : 0
        let scenes = SceneryPlacement.visible(world: world.id, layer: .ground,
            lower: start - visibilityMargin - spacingLookback,
            upper: start + Double(size.width / ppm) + visibilityMargin, seed: seed)
        // Reuse enough sprites for every candidate, including large silhouettes
        // entering at either edge of a wide viewport.
        while actors.count < scenes.count {
            let actor = SceneryActor()
            actor.anchorPoint = CGPoint(x: 0.5, y: 0)
            addChild(actor)
            actors.append(actor)
        }
        for (actor, scene) in zip(actors, scenes) {
            let style = SceneryPresentation.forImage(world: world.id, layer: .ground, variant: scene.variant)
            guard scene.coordinate >= start - visibilityMargin else { continue }
            if style.minimumSeparation > 0 && scenes.contains(where: {
                $0.variant == scene.variant && $0.coordinate < scene.coordinate
                    && scene.coordinate - $0.coordinate < style.minimumSeparation
            }) { continue }
            let perspective = 0.68 + scene.depth * 0.32
            let scale = scene.scale * perspective
            actor.configure(world: world.id, layer: .ground, variant: scene.variant,
                width: ppm * style.width * scale,
                maxHeight: ppm * style.maxHeight * scale)
            let screenX = SceneryMotion.screenMetres(coordinate: scene.coordinate, camera: left, factor: factor)
            let x = left + screenX
            let halfWidth = Double(actor.size.width / ppm / 2)
            // Use the complete painted width, including its base and a small lip
            // margin. An animal or waterfall must never hang across a void.
            if let supportsFootprint, !supportsFootprint(x - halfWidth - style.supportMargin, x + halfWidth + style.supportMargin) {
                actor.isHidden = true
                continue
            }
            // This orientation-dependent depth is stable through scrolling and zoom.
            let depth = scene.depth * (size.width > size.height ? 1.0 : 2.4)
            // Keep the complete painted base below even a steep ramp.
            // Sampling the fixed world footprint also prevents footing drift on zoom.
            let support = (0...8).map { ground(x + (Double($0) / 4 - 1) * halfWidth) }.min()!
            let y: CGFloat
            if let anchor = style.roadAnchor(at: scene.depth) {
                // Align the opening, rather than the painted top, with the road.
                // The centre stays fixed on hills as the large footprint crosses slopes.
                y = ground(x) - actor.size.height * anchor
            } else if let footing = style.footing(at: scene.depth) {
                // Anchor the feet, not the top: a building or mast can rise
                // above the road and briefly occlude the bike in the foreground.
                y = support - ppm * (footing + depth)
            } else {
                let clearance = max(style.clearance, Double(TerrainStyle.forWorld(world.id).roadDepth) + 0.12)
                y = support - ppm * (clearance + 0.15 + depth) - actor.size.height
            }
            actor.position = CGPoint(x: screenX * Double(ppm), y: y)
            // Waterfalls, pools and all other foreground paintings pass in front
            // of the rider. Their reserved ledge margin keeps platform edges clear.
            actor.zPosition = scene.depth
            actor.zRotation = 0
            actor.alpha = 1
        }
    }
}
