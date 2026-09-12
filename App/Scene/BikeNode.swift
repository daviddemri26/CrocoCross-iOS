import CrocoCrossCore
import SpriteKit
import UIKit
import simd

/// The render rig follows the simulated wheel centres. It never changes collisions.
@MainActor
final class BikeNode: SKNode {
    private let chassis = SKNode()
    private let body = SKSpriteNode()
    private let wheels = [SKNode(), SKNode()]
    private let rotors = [SKSpriteNode(), SKSpriteNode()]
    private let hubs = [SKSpriteNode(), SKSpriteNode()]
    private let shadow = SKShapeNode(ellipseOf: CGSize(width: 1.9, height: 0.14))
    private var currentID = ""
    private var rider = GameCatalog.riders[0]
    private var wheelbaseInArtwork: CGFloat = 1
    private var artworkSize = CGSize(width: 1, height: 1)
    private var previousGrounded = true
    private var landingImpulse: CGFloat = 0
    private var lastTick = 0
    private let wheelRadius = CGFloat(PhysicsConfiguration().wheelRadius)
    private let warpSource = (0..<15).map { SIMD2<Float>(Float($0 % 3) / 2, Float($0 / 3) / 4) }

    override init() {
        super.init()
        shadow.fillColor = UIColor.black.withAlphaComponent(0.22)
        shadow.strokeColor = .clear
        shadow.zPosition = -1
        addChild(shadow)
        wheels.forEach { addChild($0) }
        addChild(chassis)
        chassis.addChild(body)
        chassis.zPosition = 2
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(_ state: SimulationState, rider: Rider, pointsPerMetre: CGFloat,
                 project: (Vector2) -> CGPoint, terrain: (Double) -> Double, reducedMotion: Bool) {
        if currentID != rider.id { configure(rider) }
        let bike = state.bike
        let rear = project(bike.rear.position), front = project(bike.front.position)
        let axleAngle = atan2(front.y - rear.y, front.x - rear.x)
        let axleDistance = max(0.1, hypot(front.x - rear.x, front.y - rear.y))
        let imageScale = axleDistance / wheelbaseInArtwork
        // Original tyres have slightly different cosmetic sizes. Keep their tread on
        // the physical contact surface without redrawing or doubling the artwork.
        let radiusCorrection = rider.geometry.hasPaintedWheels ? rider.geometry.radius * artworkSize.width * imageScale - wheelRadius * pointsPerMetre : 0
        let correction = CGPoint(x: -sin(axleAngle) * radiusCorrection, y: cos(axleAngle) * radiusCorrection)
        chassis.position = CGPoint(x: (rear.x + front.x) / 2 + correction.x, y: (rear.y + front.y) / 2 + correction.y)
        chassis.zRotation = axleAngle
        chassis.setScale(imageScale)

        for (index, wheel) in [bike.rear, bike.front].enumerated() {
            let centre = index == 0 ? rear : front
            wheels[index].position = CGPoint(x: centre.x + correction.x, y: centre.y + correction.y)
            wheels[index].setScale(rider.geometry.hasPaintedWheels ? imageScale : pointsPerMetre * wheelRadius)
            wheels[index].zRotation = axleAngle
            rotors[index].zRotation = CGFloat(wheel.angle) - axleAngle
        }

        let advanced = state.tick != lastTick
        if advanced {
            if bike.grounded && !previousGrounded { landingImpulse = min(1, CGFloat(abs(bike.velocity.y)) * 0.08 + 0.25) }
            landingImpulse *= 0.91
            previousGrounded = bike.grounded
            lastTick = state.tick
        }
        if !reducedMotion {
            // Soft tissue and clothing move; tyre positions and track never do.
            let crouch = min(0.025, CGFloat(bike.rear.compression + bike.front.compression) * 0.035 + landingImpulse * 0.016)
            let lean = min(0.014, max(-0.014, CGFloat(bike.angularVelocity) * 0.002))
            warpRider(crouch: crouch, lean: lean)
        } else { body.warpGeometry = nil }

        let groundPoint = project(Vector2(x: bike.position.x, y: terrain(bike.position.x)))
        let altitude = max(0, bike.position.y - terrain(bike.position.x) - 0.8)
        shadow.position = CGPoint(x: groundPoint.x, y: groundPoint.y + 1)
        shadow.xScale = pointsPerMetre * max(0.5, 1 - CGFloat(altitude) * 0.05)
        shadow.yScale = pointsPerMetre
        shadow.alpha = max(0.03, 0.7 - CGFloat(altitude) * 0.08)
        alpha = state.status == .recovering ? 0.55 + 0.2 * sin(Double(state.tick) * 0.13) : 1
    }

    private func configure(_ rider: Rider) {
        self.rider = rider
        currentID = rider.id
        wheels.forEach { $0.removeAllChildren() }
        guard let image = GameAssets.image(named: rider.assetName) else { return }
        artworkSize = image.size
        let geometry = rider.geometry
        let rear = CGPoint(x: geometry.rearX * artworkSize.width, y: geometry.rearY * artworkSize.height)
        let front = CGPoint(x: geometry.frontX * artworkSize.width, y: geometry.frontY * artworkSize.height)
        wheelbaseInArtwork = hypot(front.x - rear.x, front.y - rear.y)
        let centre = CGPoint(x: (rear.x + front.x) / 2, y: (rear.y + front.y) / 2)
        let sourceScale = artworkSize.width / 1536
        let rotorArt = RotorArtwork.riders[rider.id] ?? []
        body.texture = geometry.hasPaintedWheels ? bodyTexture(image, centres: [rear, front], radii: rotorArt.map { $0.radius * sourceScale }) : SKTexture(image: image)
        body.size = artworkSize
        body.anchorPoint = CGPoint(x: centre.x / artworkSize.width, y: 1 - centre.y / artworkSize.height)
        body.zRotation = atan2(front.y - rear.y, front.x - rear.x)

        for (index, centre) in [rear, front].enumerated() {
            if geometry.hasPaintedWheels {
                guard rotorArt.indices.contains(index) else { continue }
                let artwork = rotorArt[index]
                let diameter = artwork.radius * sourceScale * 2
                rotors[index].texture = rotorTexture(image, centre: centre, artwork: artwork)
                rotors[index].size = CGSize(width: diameter, height: diameter)
                hubs[index].texture = hardwareTexture(image, centre: centre, artwork: artwork)
                hubs[index].size = CGSize(width: diameter, height: diameter)
                // The original wheel-axis tilt is corrected along with the whole bike.
                hubs[index].zRotation = body.zRotation
            } else {
                // Shape nodes cache a raster at their local size. A two-unit circle
                // magnified for the hero would have a huge antialiased fringe.
                let tyre = SKSpriteNode(texture: generatedTyre())
                tyre.size = CGSize(width: 2, height: 2)
                wheels[index].addChild(tyre)
                rotors[index].texture = generatedSpokes()
                rotors[index].size = CGSize(width: 1.45, height: 1.45)
                hubs[index].texture = generatedHub()
                hubs[index].size = CGSize(width: 0.22, height: 0.22)
                hubs[index].zRotation = 0
            }
            rotors[index].zPosition = 1
            hubs[index].zPosition = 2
            wheels[index].addChild(rotors[index])
            wheels[index].addChild(hubs[index])
        }
    }

    private func warpRider(crouch: CGFloat, lean: CGFloat) {
        var destinations: [SIMD2<Float>] = []
        for row in 0...4 {
            for column in 0...2 {
                let x = Float(column) / 2, y = Float(row) / 4
                let influence = max(0, (y - 0.38) / 0.62)
                destinations.append(SIMD2(x + Float(lean) * influence, y - Float(crouch) * influence))
            }
        }
        body.warpGeometry = SKWarpGeometryGrid(columns: 2, rows: 4, sourcePositions: warpSource, destinationPositions: destinations)
    }

    // Runtime texture assembly leaves the source assets intact and happens once per selection.
    private func bodyTexture(_ image: UIImage, centres: [CGPoint], radii: [CGFloat]) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: image.size, format: format).image { context in
            image.draw(at: .zero)
            context.cgContext.setBlendMode(.clear)
            for (centre, radius) in zip(centres, radii) {
                context.cgContext.fillEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
            }
        }
        return SKTexture(image: rendered)
    }

    private func rotorTexture(_ image: UIImage, centre: CGPoint, artwork: RotorArtwork) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return SKTexture(image: UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).image { context in
            let cg = context.cgContext
            let scale = 128 / (artwork.radius * image.size.width / 1536)
            cg.translateBy(x: 128, y: 128)
            let start = artwork.sectorStart * .pi / 180
            let arc = .pi * 2 / CGFloat(artwork.sectors)
            for sector in 0..<artwork.sectors {
                cg.saveGState()
                cg.rotate(by: CGFloat(sector) * arc)
                cg.move(to: .zero)
                cg.addArc(center: .zero, radius: 128, startAngle: start - 0.002, endAngle: start + arc + 0.002, clockwise: false)
                cg.closePath()
                cg.clip()
                image.draw(in: CGRect(x: -centre.x * scale, y: -centre.y * scale, width: image.size.width * scale, height: image.size.height * scale))
                cg.restoreGState()
            }
        })
    }

    private func hardwareTexture(_ image: UIImage, centre: CGPoint, artwork: RotorArtwork) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return SKTexture(image: UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).image { context in
            let cg = context.cgContext
            cg.addEllipse(in: CGRect(x: 0, y: 0, width: 256, height: 256))
            cg.clip()
            let sourceScale = image.size.width / 1536
            let scale = 128 / (artwork.radius * sourceScale)
            let mask = CGMutablePath()
            for polygon in artwork.hardware {
                for (index, p) in polygon.enumerated() {
                    let point = CGPoint(x: 128 + (p.x * sourceScale - centre.x) * scale, y: 128 + (p.y * sourceScale - centre.y) * scale)
                    if index == 0 { mask.move(to: point) } else { mask.addLine(to: point) }
                }
                mask.closeSubpath()
            }
            let hubRadius = artwork.hub * sourceScale * scale
            mask.addEllipse(in: CGRect(x: 128 - hubRadius, y: 128 - hubRadius, width: hubRadius * 2, height: hubRadius * 2))
            cg.addPath(mask)
            cg.clip()
            image.draw(in: CGRect(x: 128 - centre.x * scale, y: 128 - centre.y * scale, width: image.size.width * scale, height: image.size.height * scale))
        })
    }

    private func generatedSpokes() -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return SKTexture(image: UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128), format: format).image { context in
            let cg = context.cgContext
            cg.setStrokeColor(UIColor.hex(0xB9D0C5).cgColor)
            cg.setLineWidth(5)
            cg.strokeEllipse(in: CGRect(x: 5, y: 5, width: 118, height: 118))
            cg.setLineWidth(2)
            for index in 0..<12 {
                let angle = CGFloat(index) * .pi / 6
                cg.move(to: CGPoint(x: 64, y: 64))
                cg.addLine(to: CGPoint(x: 64 + cos(angle) * 57, y: 64 + sin(angle) * 57))
            }
            cg.strokePath()
        })
    }

    private func generatedTyre() -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return SKTexture(image: UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).image { context in
            let cg = context.cgContext
            cg.setFillColor(UIColor.hex(0x101A17).cgColor)
            cg.fillEllipse(in: CGRect(x: 0, y: 0, width: 256, height: 256))
            cg.setStrokeColor(UIColor.hex(0x3D4943).cgColor)
            cg.setLineWidth(3)
            cg.strokeEllipse(in: CGRect(x: 17, y: 17, width: 222, height: 222))
            cg.setStrokeColor(UIColor.hex(0x070D0A).cgColor)
            cg.setLineWidth(4)
            cg.strokeEllipse(in: CGRect(x: 28, y: 28, width: 200, height: 200))
            cg.translateBy(x: 128, y: 128)
            for index in 0..<36 {
                cg.saveGState()
                cg.rotate(by: CGFloat(index) * .pi / 18)
                cg.setFillColor(UIColor.hex(index.isMultiple(of: 2) ? 0x29342E : 0x080F0C).cgColor)
                cg.fill(CGRect(x: -3.5, y: 116, width: 7, height: 9))
                cg.restoreGState()
            }
        })
    }

    private func generatedHub() -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return SKTexture(image: UIGraphicsImageRenderer(size: CGSize(width: 48, height: 48), format: format).image { context in
            let cg = context.cgContext
            cg.setFillColor(UIColor.hex(0xF08A45).cgColor)
            cg.fillEllipse(in: CGRect(x: 0, y: 0, width: 48, height: 48))
            cg.setFillColor(UIColor.hex(0xC2D2C9).cgColor)
            cg.fillEllipse(in: CGRect(x: 13, y: 13, width: 22, height: 22))
            cg.setFillColor(UIColor.hex(0x293A31).cgColor)
            cg.fillEllipse(in: CGRect(x: 20, y: 20, width: 8, height: 8))
        })
    }
}
