import SpriteKit
import UIKit

/// A bounded pool of atmospheric details gives each biome motion without allocations per frame.
@MainActor
final class AmbientNode: SKNode {
    private let particles = (0..<22).map { _ in SKShapeNode() }
    private let birds = (0..<3).map { _ in SKShapeNode() }
    private let wisps = (0..<4).map { _ in SKShapeNode() }
    private var currentID = ""

    override init() {
        super.init()
        particles.forEach { addChild($0) }
        birds.forEach { addChild($0) }
        wisps.forEach { addChild($0) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(world: World, size: CGSize, cameraX: Double, seconds: Double, reducedMotion: Bool) {
        if currentID != world.id { configure(world) }
        let time = reducedMotion ? 0 : seconds
        let width = size.width + 100, height = size.height * 0.75
        for (index, particle) in particles.enumerated() {
            let i = CGFloat(index)
            let speed: CGFloat = world.id == "arctic" ? 14 : world.id == "japan" ? 9 : 3
            let x = wrapped(i * 83.79 + CGFloat(time) * speed - CGFloat(cameraX) * 2.4, period: width) - 50
            let y = wrapped(i * 71.13 - CGFloat(time) * speed * 0.55, period: height) + size.height * 0.2
            particle.position = CGPoint(x: x + sin(CGFloat(time) * 0.7 + i) * 12, y: y)
            particle.zRotation = CGFloat(time) * 0.4 + i
            particle.alpha = world.id == "jungle" || world.id == "mine" ? 0.3 + 0.3 * sin(Double(index) + time * 1.3) : 0.4
        }
        for (index, bird) in birds.enumerated() {
            let i = CGFloat(index)
            bird.position = CGPoint(x: wrapped(i * 189 + CGFloat(time) * 16 - CGFloat(cameraX), period: width) - 50,
                                    y: size.height * (0.71 + i * 0.075) + sin(CGFloat(time) * 0.45 + i) * 12)
            let wing = reducedMotion ? CGFloat(3) : CGFloat(sin(time * 5 + Double(index))) * 4
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -8, y: wing))
            path.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: -4, y: 4))
            path.addQuadCurve(to: CGPoint(x: 8, y: wing), control: CGPoint(x: 4, y: 4))
            bird.path = path
        }
        for (index, wisp) in wisps.enumerated() {
            let i = CGFloat(index)
            wisp.position = CGPoint(x: wrapped(i * width / 3 + CGFloat(time) * 5 - CGFloat(cameraX) * 1.4, period: width + 320) - 160,
                                    y: size.height * (0.46 + i * 0.11))
            wisp.xScale = 1 + sin(CGFloat(time) * 0.15 + i) * 0.08
            wisp.alpha = world.id == "arctic" ? 0.13 + 0.06 * sin(time * 0.3 + Double(index)) : 0.12
        }
    }

    private func configure(_ world: World) {
        currentID = world.id
        for (index, particle) in particles.enumerated() {
            particle.strokeColor = .clear
            particle.glowWidth = 0
            switch world.id {
            case "japan":
                particle.path = CGPath(ellipseIn: CGRect(x: -3, y: -1.7, width: 6, height: 3.4), transform: nil)
                particle.fillColor = .hex(0xFFCCE4)
            case "arctic":
                particle.path = CGPath(ellipseIn: CGRect(x: -1.5, y: -1.5, width: 3, height: 3), transform: nil)
                particle.fillColor = .white
            case "jungle", "mine":
                particle.path = CGPath(ellipseIn: CGRect(x: -1.2, y: -1.2, width: 2.4, height: 2.4), transform: nil)
                particle.fillColor = world.accent
                particle.glowWidth = 3
            default:
                particle.path = CGPath(ellipseIn: CGRect(x: -1, y: -0.5, width: 2, height: 1), transform: nil)
                particle.fillColor = world.edge
            }
            particle.isHidden = (world.id == "clouds" || world.id == "sanfrancisco") && index > 5
        }
        for bird in birds {
            bird.isHidden = world.id == "mine" || world.id == "arctic"
            bird.strokeColor = world.deepEarth.withAlphaComponent(0.55)
            bird.fillColor = .clear
            bird.lineWidth = 1.4
            bird.lineCap = .round
        }
        for (index, wisp) in wisps.enumerated() {
            wisp.isHidden = world.id == "mine" || world.id == "japan"
            wisp.strokeColor = .clear
            wisp.fillColor = world.id == "arctic" ? world.accent : .white
            if world.id == "arctic" {
                let path = CGMutablePath()
                path.move(to: .zero)
                path.addCurve(to: CGPoint(x: 450, y: 80), control1: CGPoint(x: 120, y: -20), control2: CGPoint(x: 200, y: 150))
                path.addCurve(to: CGPoint(x: 0, y: 20), control1: CGPoint(x: 220, y: 180), control2: CGPoint(x: 110, y: 30))
                path.closeSubpath()
                wisp.path = path
            } else {
                wisp.path = CGPath(ellipseIn: CGRect(x: -150, y: -12, width: CGFloat(240 + index * 30), height: 22), transform: nil)
            }
        }
    }

    private func wrapped(_ value: CGFloat, period: CGFloat) -> CGFloat {
        let remainder = value.truncatingRemainder(dividingBy: period)
        return remainder < 0 ? remainder + period : remainder
    }
}
