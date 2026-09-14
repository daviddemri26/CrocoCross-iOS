import SpriteKit

/// Rare, fixed painted accents meet the road and never affect collisions.
@MainActor
final class WaysideNode: SKNode {
    private let actors = (0..<3).map { _ in SceneryActor() }
    override init() {
        super.init()
        actors.forEach { $0.anchorPoint = CGPoint(x: 0.5, y: 0); addChild($0) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(world: World, size: CGSize, left: Double, ppm: CGFloat, seed: UInt64,
                 ground: (Double) -> CGFloat) {
        actors.forEach { $0.isHidden = true }
        let right = left + Double(size.width / ppm)
        let accents = SceneryPlacement.visible(world: world.id, layer: .wayside,
            lower: left - 3, upper: right + 3, seed: seed)
        for (actor, accent) in zip(actors, accents) {
            let x = accent.coordinate
            let style = SceneryPresentation.forImage(world: world.id, layer: .wayside, variant: 1)
            actor.configure(world: world.id, layer: .wayside, variant: 1,
                width: min(size.width * 0.24, ppm * style.width * accent.scale),
                maxHeight: min(size.height * 0.22, ppm * style.maxHeight * accent.scale))
            guard let footing = Self.footing(x: x, width: Double(actor.size.width / ppm),
                height: Double(actor.size.height / ppm), followsSlope: style.followsSlope,
                inset: style.roadInset, ground: { Double(ground($0) / ppm) }) else {
                actor.isHidden = true
                continue
            }
            actor.position = CGPoint(x: CGFloat(x - left) * ppm, y: footing.height * ppm)
            actor.zRotation = footing.angle
            actor.alpha = 0.94
        }
    }

    /// All distances are metres. Reject steep locations instead of moving a sparse accent.
    private static func footing(x: Double, width: Double, height: Double,
                                followsSlope: Bool, inset: Double,
                                ground: (Double) -> Double) -> (height: Double, angle: Double)? {
        guard width > 0, height > 0 else { return nil }
        let offsets = (0...4).map { (Double($0) / 4 - 0.5) * width }
        let levels = offsets.map { ground(x + $0) }
        let maxGrade = followsSlope ? 0.35 : 0.12
        guard zip(levels, levels.dropFirst()).allSatisfy({ abs($1 - $0) <= width / 4 * maxGrade })
        else { return nil }
        let angle = followsSlope ? atan2(levels[4] - levels[0], width) : 0
        // Compare the complete rotated base with the road, then seat its lowest support.
        let supports = offsets.map { ground(x + $0 * cos(angle)) - $0 * sin(angle) }
        let low = supports.min()!, high = supports.max()!
        guard high - low <= min(0.10, height * 0.12) else { return nil }
        return (low - inset, angle)
    }

}
