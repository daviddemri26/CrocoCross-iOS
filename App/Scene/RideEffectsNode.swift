import CrocoCrossCore
import SpriteKit
import UIKit

/// Cosmetic effects are driven by simulation events, never inferred from rendered positions.
/// Two preallocated bursts bound both node count and texture memory during repeated retries.
@MainActor
final class RideEffectsNode: SKNode {
    @MainActor private final class Burst {
        let root = SKNode()
        let frames = [SKSpriteNode(), SKSpriteNode()]
        let ring = SKShapeNode()
        let sparks = (0..<34).map { _ in SKShapeNode() }
        var worldPosition = Vector2()
        var started: Double = -.infinity
        var intensity: CGFloat = 1
        var landing = false
        init() {
            frames.forEach {
                root.addChild($0)
                $0.blendMode = .alpha
            }
            root.addChild(ring)
            ring.fillColor = .clear
            ring.strokeColor = .hex(0xFFCF86)
            sparks.forEach {
                root.addChild($0)
                $0.lineCap = .round
                $0.fillColor = .clear
            }
        }
    }
    private let bursts = [Burst(), Burst()]
    private var textures: [SKTexture] = []
    private var nextBurst = 0
    private let frameTimes = [0.0, 0.06, 0.14, 0.25, 0.46, 0.72, 1.10, 1.45, 1.80]

    override init() {
        super.init()
        bursts.forEach {
            addChild($0.root)
            $0.root.isHidden = true
        }
        if let sheet = GameAssets.texture(named: "explosion-sheet") {
            let size = sheet.size()
            for index in 0..<8 {
                let rect = CGRect(
                    x: CGFloat(index % 4) / 4 + 2 / size.width,
                    y: CGFloat(1 - index / 4) / 2 + 2 / size.height,
                    width: 0.25 - 4 / size.width, height: 0.5 - 4 / size.height)
                textures.append(SKTexture(rect: rect, in: sheet))
            }
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func play(at position: Vector2, intensity: Double, landing: Bool, time: Double) {
        let burst = bursts[nextBurst]
        nextBurst = (nextBurst + 1) % bursts.count
        burst.worldPosition = position
        burst.intensity = CGFloat(min(1, max(0.1, intensity)))
        burst.started = time
        burst.landing = landing
        burst.root.isHidden = false
    }

    func clear() {
        bursts.forEach {
            $0.started = -.infinity
            $0.root.isHidden = true
        }
    }

    func display(
        time: Double, ppm: CGFloat, world: World, reducedMotion: Bool,
        project: (Vector2) -> CGPoint
    ) {
        for burst in bursts {
            let age = time - burst.started
            let lifetime = burst.landing ? 0.65 : 1.8
            burst.root.isHidden = age < 0 || age >= lifetime
            guard !burst.root.isHidden else { continue }
            burst.root.position = project(burst.worldPosition)
            // Author at 64 points/metre, then scale once so sparks stay crisp at every viewport size.
            burst.root.setScale(ppm / 64)
            let t = CGFloat(age)
            let extent = burst.landing ? CGFloat(0.65) : 1
            let count = reducedMotion ? (burst.landing ? 4 : 10) : (burst.landing ? 16 : 34)
            for (index, spark) in burst.sparks.enumerated() {
                let life =
                    burst.landing ? CGFloat(0.38 + Double(index % 4) * 0.07) : CGFloat(1 + Double(index % 5) * 0.13)
                spark.isHidden = index >= count || t >= life
                guard !spark.isHidden else { continue }
                let angle = CGFloat(index) * 2.39996
                let speed = (80 + CGFloat(index * 47 % 150)) * extent * burst.intensity
                let vx = cos(angle) * speed
                let vy = (abs(sin(angle)) * speed + 30) * (burst.landing ? 0.3 : 1)
                let previous = max(0, t - 0.028)
                let path = CGMutablePath()
                path.move(to: CGPoint(x: vx * previous, y: vy * previous - 160 * previous * previous))
                path.addLine(to: CGPoint(x: vx * t, y: vy * t - 160 * t * t))
                spark.path = path
                spark.strokeColor = burst.landing ? world.edge : .hex(index.isMultiple(of: 3) ? 0xFFE7A7 : 0xFFAD42)
                spark.alpha = max(0, 1 - t / life) * (reducedMotion ? 0.6 : 1)
                spark.lineWidth = burst.landing ? 3.5 : (index.isMultiple(of: 4) ? 3 : 2)
            }
            burst.ring.isHidden = age > (burst.landing ? 0.35 : 0.6) || reducedMotion
            if !burst.ring.isHidden {
                let radius = (burst.landing ? 16 : 25) + t * (burst.landing ? 90 : 230)
                burst.ring.path = CGPath(
                    ellipseIn: CGRect(x: -radius, y: -8 - t * 24, width: radius * 2, height: 16 + t * 48),
                    transform: nil)
                burst.ring.alpha = max(0, 1 - t / 0.6) * (burst.landing ? 0.22 : 0.55)
                burst.ring.lineWidth = max(0.5, 4 * (1 - t / 0.6))
                burst.ring.strokeColor = burst.landing ? world.edge : .hex(0xFFCF86)
            }
            burst.frames.forEach { $0.isHidden = burst.landing || textures.isEmpty }
            guard !burst.landing, textures.count == 8 else { continue }
            let index = min(7, max(0, (1..<frameTimes.count).first { age < frameTimes[$0] }.map { $0 - 1 } ?? 7))
            let blend = CGFloat((age - frameTimes[index]) / (frameTimes[index + 1] - frameTimes[index]))
            let width: CGFloat = (reducedMotion ? 225 : 285) * (0.85 + burst.intensity * 0.15)
            for slot in 0..<2 {
                let node = burst.frames[slot]
                node.texture = textures[min(7, index + slot)]
                node.size = CGSize(width: width, height: width * 4 / 3)
                node.position.y = width * 0.21
                node.alpha = (slot == 0 ? 1 - blend : blend) * CGFloat(min(1, (1.8 - age) / 0.3))
            }
        }
    }
}
