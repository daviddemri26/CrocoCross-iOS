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
    private var animatedCrouch: CGFloat = 0
    private var animatedLean: CGFloat = 0
    private var landingAge: Double = 2
    private var lastScenicTime: Double = 0
    private let wheelRadius = CGFloat(PhysicsConfiguration().wheelRadius)
    private let warpSource = (0..<45).map { SIMD2<Float>(Float($0 % 5) / 4, Float($0 / 5) / 8) }

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
                 project: (Vector2) -> CGPoint, terrain: (Double) -> Double, reducedMotion: Bool,
                 seconds: Double = 0, isPreview: Bool = false) {
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

        let elapsed = min(0.05, max(0, isPreview ? seconds - lastScenicTime : Double(state.tick - lastTick) / 120))
        lastScenicTime = seconds
        if state.tick < lastTick { resetAnimation() }
        if bike.grounded && !previousGrounded {
            reactToLanding(intensity: min(1, abs(bike.velocity.y) / 9 + 0.18))
        }
        landingAge += elapsed
        landingImpulse *= CGFloat(exp(-elapsed * 7))
        previousGrounded = bike.grounded
        lastTick = state.tick
        if !reducedMotion {
            // The rider absorbs impact with a damped crouch, extends at the apex,
            // and shifts weight as the chassis pitches. Axles and tyre art stay fixed.
            let suspension = CGFloat(bike.rear.compression + bike.front.compression) / 0.46
            let airborne = bike.grounded ? CGFloat(0) : CGFloat(tanh(bike.velocity.y * 0.14))
            let rebound = landingImpulse * CGFloat(cos(landingAge * 19))
            let profile = motionProfile
            let motionTime = isPreview ? seconds : state.elapsed
            let breathing = CGFloat(sin(motionTime * profile.tempo)) * profile.breath
            let targetCrouch = (suspension * 0.016 + rebound * 0.036 + airborne * 0.009) * profile.absorption + breathing
            let targetLean = (CGFloat(tanh(bike.angularVelocity * 0.35)) * 0.024
                + CGFloat(bike.throttle) * 0.004) * profile.sway
            let blend = CGFloat(1 - exp(-elapsed * 15))
            animatedCrouch += (targetCrouch - animatedCrouch) * blend
            animatedLean += (targetLean - animatedLean) * blend
            warpRider(crouch: animatedCrouch, lean: animatedLean,
                      secondary: CGFloat(sin(motionTime * profile.tempo + 0.8)) * profile.secondary,
                      headX: profile.headX)
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
        guard let image = GameAssets.image(named: rider.assetName), let layers = RiderArtwork.layers(for: rider) else { return }
        artworkSize = image.size
        let geometry = rider.geometry
        let rear = CGPoint(x: geometry.rearX * artworkSize.width, y: geometry.rearY * artworkSize.height)
        let front = CGPoint(x: geometry.frontX * artworkSize.width, y: geometry.frontY * artworkSize.height)
        wheelbaseInArtwork = hypot(front.x - rear.x, front.y - rear.y)
        let centre = CGPoint(x: (rear.x + front.x) / 2, y: (rear.y + front.y) / 2)
        let sourceScale = artworkSize.width / 1536
        let rotorArt = RotorArtwork.riders[rider.id] ?? []
        body.texture = SKTexture(image: layers.body)
        body.size = artworkSize
        body.anchorPoint = CGPoint(x: centre.x / artworkSize.width, y: 1 - centre.y / artworkSize.height)
        body.zRotation = atan2(front.y - rear.y, front.x - rear.x)

        for index in 0..<2 {
            if geometry.hasPaintedWheels {
                guard rotorArt.indices.contains(index) else { continue }
                let artwork = rotorArt[index]
                let diameter = artwork.radius * sourceScale * 2
                rotors[index].texture = SKTexture(image: layers.wheels[index].rotor)
                rotors[index].size = CGSize(width: diameter, height: diameter)
                hubs[index].texture = SKTexture(image: layers.wheels[index].hardware)
                hubs[index].size = CGSize(width: diameter, height: diameter)
                // The original wheel-axis tilt is corrected along with the whole bike.
                hubs[index].zRotation = body.zRotation
            } else {
                // Shape nodes cache a raster at their local size. A two-unit circle
                // magnified for the hero would have a huge antialiased fringe.
                let tyre = SKSpriteNode(texture: SKTexture(image: layers.wheels[index].tyre!))
                tyre.size = CGSize(width: 2, height: 2)
                wheels[index].addChild(tyre)
                rotors[index].texture = SKTexture(image: layers.wheels[index].rotor)
                rotors[index].size = CGSize(width: 1.45, height: 1.45)
                hubs[index].texture = SKTexture(image: layers.wheels[index].hardware)
                hubs[index].size = CGSize(width: 0.22, height: 0.22)
                hubs[index].zRotation = 0
            }
            rotors[index].zPosition = 1
            hubs[index].zPosition = 2
            wheels[index].addChild(rotors[index])
            wheels[index].addChild(hubs[index])
        }
    }

    func reactToLanding(intensity: Double) {
        landingImpulse = max(landingImpulse, CGFloat(min(1, max(0, intensity))))
        landingAge = 0
    }

    func resetAnimation() {
        landingImpulse = 0
        landingAge = 2
        animatedCrouch = 0
        animatedLean = 0
        previousGrounded = true
    }

    private struct MotionProfile {
        let absorption: CGFloat
        let sway: CGFloat
        let breath: CGFloat
        let secondary: CGFloat
        let tempo: Double
        let headX: CGFloat
    }

    // Cosmetic rig parameters respect each silhouette: compact/heavy riders settle
    // slowly, long necks follow through, and exposed tails/feathers lag gently.
    private var motionProfile: MotionProfile {
        switch rider.id {
        case "polar": .init(absorption:0.72,sway:0.65,breath:0.0025,secondary:0.0018,tempo:1.55,headX:0.63)
        case "tiger": .init(absorption:1.12,sway:0.88,breath:0.003,secondary:0.003,tempo:1.9,headX:0.61)
        case "flamingo": .init(absorption:1.05,sway:1.25,breath:0.004,secondary:0.007,tempo:1.75,headX:0.59)
        case "toucan": .init(absorption:0.92,sway:1.12,breath:0.0035,secondary:0.005,tempo:2.15,headX:0.6)
        case "eagle": .init(absorption:0.9,sway:0.95,breath:0.003,secondary:0.004,tempo:1.8,headX:0.58)
        case "axolotl": .init(absorption:1.1,sway:1.1,breath:0.004,secondary:0.006,tempo:2.2,headX:0.61)
        case "shiba": .init(absorption:0.85,sway:0.78,breath:0.0025,secondary:0.0035,tempo:2.1,headX:0.65)
        case "raccoon": .init(absorption:1,sway:1,breath:0.0035,secondary:0.004,tempo:1.95,headX:0.6)
        default: .init(absorption:1,sway:0.95,breath:0.003,secondary:0.0045,tempo:1.85,headX:0.56)
        }
    }

    private func warpRider(crouch: CGFloat, lean: CGFloat, secondary: CGFloat, headX: CGFloat) {
        var destinations: [SIMD2<Float>] = []
        destinations.reserveCapacity(45)
        for row in 0...8 {
            for column in 0...4 {
                let x = Float(column) / 4, y = Float(row) / 8
                let height = max(0, (y - 0.4) / 0.6)
                let influence = height * height * (3 - 2 * height)
                let head = max(0, (y - 0.65) / 0.35) * max(0, 1 - abs(x - Float(headX)) / 0.38)
                let tail = max(0, 1 - abs(x - 0.22) / 0.22) * max(0, 1 - abs(y - 0.55) / 0.2)
                destinations.append(SIMD2(x + Float(lean) * influence + Float(secondary) * head,
                                          y - Float(crouch) * influence + Float(secondary) * tail * 0.6))
            }
        }
        body.warpGeometry = SKWarpGeometryGrid(columns: 4, rows: 8, sourcePositions: warpSource, destinationPositions: destinations)
    }
}
