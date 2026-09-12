import SpriteKit
import UIKit

@MainActor
final class TrackNode: SKNode {
    private let crop = SKCropNode()
    private let mask = SKShapeNode()
    private let fill = SKSpriteNode()
    private let strata = (0..<4).map { _ in SKShapeNode() }
    private let material = SKShapeNode()
    private let seams = SKShapeNode()
    private let edgeShadow = SKShapeNode()
    private let edge = SKShapeNode()
    private let underground = SKNode()
    private let tunnel = SKShapeNode(rectOf: CGSize(width: 4.8, height: 1.4), cornerRadius: 0.7)
    private let inhabitant = SKNode()
    private let legs = SKShapeNode()
    private var currentID = ""

    override init() {
        super.init()
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask
        addChild(crop)
        crop.addChild(fill)
        strata.forEach { crop.addChild($0); $0.fillColor = .clear; $0.lineCap = .round }
        material.strokeColor = .clear
        seams.fillColor = .clear
        crop.addChild(material)
        crop.addChild(seams)
        crop.addChild(underground)
        underground.addChild(tunnel)
        underground.addChild(inhabitant)
        inhabitant.addChild(legs)
        addChild(edgeShadow)
        addChild(edge)
        edge.fillColor = .clear
        edge.lineCap = .round
        edgeShadow.fillColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(world: World, size: CGSize, left: Double, ppm: CGFloat, seconds: Double,
                 reducedMotion: Bool, ground: (Double) -> CGFloat) {
        if currentID != world.id { configure(world) }
        let right = left + Double(size.width / ppm)
        let sampleCount = max(90, Int(size.width / 4))
        let surface = CGMutablePath(), outline = CGMutablePath()
        let bands = (0..<4).map { _ in CGMutablePath() }
        for sample in 0...sampleCount {
            let x = CGFloat(sample) / CGFloat(sampleCount) * size.width
            let wx = left + Double(x / ppm)
            let y = ground(wx)
            if sample == 0 { surface.move(to: CGPoint(x: x, y: y)); outline.move(to: CGPoint(x: x, y: y)) }
            else { surface.addLine(to: CGPoint(x: x, y: y)); outline.addLine(to: CGPoint(x: x, y: y)) }
            for layer in 0..<4 {
                let wave = sin(wx * 0.72 + Double(layer)) * 0.11
                let point = CGPoint(x: x, y: y - (CGFloat(layer + 1) * 0.65 + CGFloat(wave)) * ppm)
                if sample == 0 { bands[layer].move(to: point) } else { bands[layer].addLine(to: point) }
            }
        }
        if world.id == "clouds" {
            for sample in stride(from: sampleCount, through: 0, by: -1) {
                let x = CGFloat(sample) / CGFloat(sampleCount) * size.width
                let wx = left + Double(x / ppm)
                surface.addLine(to: CGPoint(x: x, y: ground(wx) - ppm * (0.9 + CGFloat(sin(wx * 5)) * 0.14)))
            }
        } else {
            surface.addLine(to: CGPoint(x: size.width, y: -size.height))
            surface.addLine(to: CGPoint(x: 0, y: -size.height))
        }
        surface.closeSubpath()
        mask.path = surface
        fill.size = CGSize(width: size.width, height: size.height * 2)
        fill.position = CGPoint(x: size.width / 2, y: 0)
        for (index, band) in bands.enumerated() { strata[index].path = band; strata[index].lineWidth = index.isMultiple(of: 2) ? ppm * 0.18 : ppm * 0.07 }
        edgeShadow.path = outline
        edgeShadow.lineWidth = max(4, ppm * 0.14)
        edge.path = outline
        edge.lineWidth = max(2, ppm * 0.075)
        updateMaterial(world: world, left: left, right: right, ppm: ppm, ground: ground)
        updateUnderground(world: world, left: left, ppm: ppm, seconds: reducedMotion ? 0 : seconds, ground: ground)
    }

    private func configure(_ world: World) {
        currentID = world.id
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 256), format: format).image { context in
            let colours = [world.earth.cgColor, world.deepEarth.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colours, locations: [0, 1]) {
                context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 256), options: [])
            }
        }
        fill.texture = SKTexture(image: image)
        edge.strokeColor = world.edge
        edgeShadow.strokeColor = world.deepEarth
        for (index, band) in strata.enumerated() {
            band.strokeColor = (index.isMultiple(of: 2) ? world.edge : world.deepEarth).withAlphaComponent(0.22)
        }
        material.fillColor = world.edge.withAlphaComponent(world.id == "paris" ? 0.58 : 0.3)
        seams.strokeColor = (world.id == "japan" || world.id == "jungle")
            ? world.deepEarth.withAlphaComponent(0.4) : world.accent.withAlphaComponent(0.7)
        tunnel.fillColor = world.deepEarth.withAlphaComponent(0.8)
        tunnel.strokeColor = world.edge.withAlphaComponent(0.16)
        tunnel.lineWidth = 0.05
        tunnel.path = CGPath(roundedRect: CGRect(x: -2.4, y: -0.7, width: 4.8, height: 1.4), cornerWidth: 0.7, cornerHeight: 0.7, transform: nil)
        inhabitant.removeAllChildren()
        tunnel.removeAllChildren()
        if world.id == "mine" {
            let rails = SKShapeNode()
            let railPath = CGMutablePath()
            railPath.move(to: CGPoint(x: -2.3, y: -0.3))
            railPath.addLine(to: CGPoint(x: 2.3, y: -0.3))
            for index in 0..<15 {
                let x = CGFloat(index) * 0.32 - 2.25
                railPath.move(to: CGPoint(x: x, y: -0.32))
                railPath.addLine(to: CGPoint(x: x, y: -0.43))
            }
            rails.path = railPath
            rails.strokeColor = world.edge.withAlphaComponent(0.35)
            rails.lineWidth = 0.025
            tunnel.addChild(rails)
            for index in 0..<3 {
                let cart = SKShapeNode(rectOf: CGSize(width: 0.5, height: 0.35), cornerRadius: 0.04)
                cart.fillColor = .hex(0x927056)
                cart.strokeColor = .hex(0xDDB77E)
                cart.lineWidth = 0.025
                cart.position.x = CGFloat(index) * 0.6
                inhabitant.addChild(cart)
                for x in [-0.16, 0.16] {
                    let wheel = SKShapeNode(circleOfRadius: 0.085)
                    wheel.fillColor = .hex(0x1D2428)
                    wheel.strokeColor = .hex(0xB8A487)
                    wheel.lineWidth = 0.02
                    wheel.position = CGPoint(x: CGFloat(x) + cart.position.x, y: -0.21)
                    inhabitant.addChild(wheel)
                }
            }
            let light = SKShapeNode(circleOfRadius: 0.045)
            light.fillColor = .hex(0xFFDD8B)
            light.strokeColor = .clear
            light.glowWidth = 0.15
            light.position = CGPoint(x: 1.46, y: 0.08)
            inhabitant.addChild(light)
        } else if world.id == "clouds" {
            for i in 0..<4 {
                let bubble = SKShapeNode(ellipseOf: CGSize(width: 0.6, height: 0.3))
                bubble.fillColor = .white.withAlphaComponent(0.42)
                bubble.strokeColor = .clear
                bubble.position.x = CGFloat(i) * 0.4
                inhabitant.addChild(bubble)
            }
        } else {
            let body = SKShapeNode(ellipseOf: CGSize(width: 0.42, height: 0.19))
            body.fillColor = (world.id == "arctic" ? UIColor.white : world.accent).withAlphaComponent(0.7)
            body.strokeColor = .clear
            inhabitant.addChild(body)
            let head = SKShapeNode(circleOfRadius: 0.1)
            head.position = CGPoint(x: 0.25, y: 0.03)
            head.fillColor = body.fillColor
            head.strokeColor = .clear
            inhabitant.addChild(head)
            let eye = SKShapeNode(circleOfRadius: 0.016)
            eye.position = CGPoint(x: 0.28, y: 0.065)
            eye.fillColor = world.deepEarth
            eye.strokeColor = .clear
            inhabitant.addChild(eye)
            legs.strokeColor = body.fillColor
            legs.lineWidth = 0.028
            legs.fillColor = .clear
            inhabitant.addChild(legs)
            if world.id == "paris" || world.id == "sanfrancisco" || world.id == "arctic" {
                let ear = SKShapeNode(ellipseOf: CGSize(width: 0.07, height: 0.13))
                ear.position = CGPoint(x: 0.23, y: 0.14)
                ear.fillColor = body.fillColor
                ear.strokeColor = .clear
                inhabitant.addChild(ear)
            }
        }
        // Build vectors at a useful raster resolution before applying metre scaling.
        // Otherwise a .1-point animal part acquires a very blurry antialias fringe.
        underground.children.forEach { scaleArtwork($0, by: 64) }
    }

    private func updateMaterial(world: World, left: Double, right: Double, ppm: CGFloat, ground: (Double) -> CGFloat) {
        let details = CGMutablePath(), lines = CGMutablePath()
        let spacing: Double = world.id == "paris" ? 0.48 : world.id == "mine" ? 0.58 : 0.86
        let first = Int(floor(left / spacing)) - 1, last = Int(ceil(right / spacing)) + 1
        for index in first...last {
            let wx = Double(index) * spacing
            let x = CGFloat(wx - left) * ppm
            let y = ground(wx)
            let slope = atan2(ground(wx + 0.08) - ground(wx - 0.08), ppm * 0.16)
            var transform = CGAffineTransform(translationX: x, y: y).rotated(by: slope)
            switch world.id {
            case "paris":
                for row in 0..<3 {
                    let offset: CGFloat = row.isMultiple(of: 2) ? 0 : -0.23
                    let stone = CGPath(roundedRect: CGRect(x: offset * ppm, y: -CGFloat(row + 1) * 0.19 * ppm, width: ppm * 0.42, height: ppm * 0.14), cornerWidth: 2, cornerHeight: 2, transform: &transform)
                    details.addPath(stone)
                }
            case "sanfrancisco", "highway":
                if index.isMultiple(of: 2) {
                    lines.move(to: CGPoint(x: x, y: y - ppm * 0.19))
                    lines.addLine(to: CGPoint(x: x + ppm * 0.7, y: ground(wx + 0.7) - ppm * 0.19))
                }
                if world.id == "sanfrancisco" && index.isMultiple(of: 4) {
                    lines.move(to: CGPoint(x: x, y: y - ppm * 0.55))
                    lines.addLine(to: CGPoint(x: x, y: y - ppm * 1.85))
                    lines.addLine(to: CGPoint(x: x + ppm * 2.8, y: ground(wx + 2.8) - ppm * 0.55))
                }
            case "mine":
                details.addPath(CGPath(rect: CGRect(x: -ppm * 0.075, y: -ppm * 0.43, width: ppm * 0.15, height: ppm * 0.38), transform: &transform))
            case "clouds":
                details.addEllipse(in: CGRect(x: x, y: y - ppm * 0.56, width: ppm * 0.9, height: ppm * 0.4))
            case "arctic":
                let ice = CGMutablePath()
                ice.move(to: CGPoint(x: x, y: y - ppm * 0.16))
                ice.addLine(to: CGPoint(x: x + ppm * 0.1, y: y - ppm * 0.6))
                ice.addLine(to: CGPoint(x: x + ppm * 0.26, y: y - ppm * 0.19))
                ice.closeSubpath()
                details.addPath(ice)
            default:
                let depth = CGFloat(0.2 + abs(sin(Double(index) * 7.89)) * 1.8)
                details.addEllipse(in: CGRect(x: x, y: y - depth * ppm, width: ppm * (0.07 + abs(sin(CGFloat(index))) * 0.16), height: ppm * 0.075))
                if world.id == "jungle" || world.id == "japan" {
                    lines.move(to: CGPoint(x: x, y: y - ppm * 0.15))
                    lines.addCurve(to: CGPoint(x: x + ppm * 0.3, y: y - ppm * 0.9), control1: CGPoint(x: x - ppm * 0.2, y: y - ppm * 0.45), control2: CGPoint(x: x + ppm * 0.35, y: y - ppm * 0.5))
                }
            }
        }
        material.path = details
        if world.id == "mine" {
            for offset in [CGFloat(0.11), CGFloat(0.28)] {
                var started = false
                var wx = left
                while wx <= right + 0.1 {
                    let point = CGPoint(x: CGFloat(wx - left) * ppm, y: ground(wx) - offset * ppm)
                    if !started { lines.move(to: point); started = true }
                    else { lines.addLine(to: point) }
                    wx += 0.1
                }
            }
        }
        seams.path = lines
        seams.lineWidth = world.id == "sanfrancisco" ? 1.5 : max(1, ppm * 0.035)
    }

    private func updateUnderground(world: World, left: Double, ppm: CGFloat, seconds: Double, ground: (Double) -> CGFloat) {
        let section = floor((left + 6) / 22)
        let wx = section * 22 + 11
        let depth: CGFloat = world.id == "clouds" ? 0.55 : 2.5
        underground.position = CGPoint(x: CGFloat(wx - left) * ppm, y: ground(wx) - ppm * depth)
        underground.setScale(ppm / 64)
        tunnel.isHidden = world.id == "clouds"
        let travel = sin(seconds * (world.id == "mine" ? 0.18 : 0.4) + section)
        inhabitant.position.x = (CGFloat(travel) * 1.3 - (world.id == "mine" ? 0.6 : 0)) * 64
        inhabitant.yScale = 1 + CGFloat(sin(seconds * 5)) * 0.02
        if world.id != "mine" && world.id != "clouds" {
            inhabitant.xScale = cos(seconds * 0.4 + section) >= 0 ? 1 : -1
            let path = CGMutablePath()
            for i in 0..<4 {
                let x = CGFloat(i) * 0.1 - 0.16
                let sway = CGFloat(sin(seconds * 9 + Double(i) * 2)) * 0.04
                path.move(to: CGPoint(x: x, y: -0.05))
                path.addLine(to: CGPoint(x: x + sway, y: -0.16))
            }
            path.move(to: CGPoint(x: -0.2, y: 0))
            path.addQuadCurve(to: CGPoint(x: -0.48, y: 0.1), control: CGPoint(x: -0.4, y: -0.1 + CGFloat(sin(seconds * 3)) * 0.04))
            var transform = CGAffineTransform(scaleX: 64, y: 64)
            legs.path = path.copy(using: &transform)
        }
    }

    private func scaleArtwork(_ node: SKNode, by scale: CGFloat) {
        node.position = CGPoint(x: node.position.x * scale, y: node.position.y * scale)
        if let shape = node as? SKShapeNode {
            var transform = CGAffineTransform(scaleX: scale, y: scale)
            shape.path = shape.path?.copy(using: &transform)
            shape.lineWidth *= scale
            shape.glowWidth *= scale
        }
        node.children.forEach { scaleArtwork($0, by: scale) }
    }
}
