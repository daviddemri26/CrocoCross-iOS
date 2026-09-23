import Foundation
import CBox2D

/// Read-only diagnostics. These never feed a second collision or suspension solver.
public struct PhysicsDiagnostics: Sendable {
    public var bodyCount: Int = 0
    /// Box2D 3.1.1 reports process-wide tracked engine allocations, not per-world RSS.
    public var allocatedByteCount: Int = 0
    public var terrainChunkCount: Int = 0
    public var rebaseCount: Int = 0
    public var origin = Vector2()
    public var totalMass: Double = 0
    public var centerOfMass = Vector2()
    public var centerOfMassVelocity = Vector2()
    public var kineticEnergy: Double = 0
    public var angularMomentum: Double = 0
    public var pitchInertia: Double = 0
    public var rearNormalImpulse: Double = 0
    public var frontNormalImpulse: Double = 0
    public var attachmentForce: Double = 0
    public var peakImpactSpeed: Double = 0
    public var bodyContact = false
    public var chassisContact = false
    public var riderContact = false
    public var stepMilliseconds: Double = 0
}

/// Owns one C world. Only this object touches Box2D IDs; no ID escapes into a snapshot.
/// SpriteKit never participates in collisions, constraints, or integration.
final class Box2DBikeWorld {
    private let world: b2WorldId
    private let configuration: PhysicsConfiguration
    private let terrain: TerrainGenerator
    private var origin = Vector2()
    private var chunks: [Int: b2BodyId] = [:]
    private var bodies: [b2BodyId] = []
    private var chassis = b2BodyId()
    private var rear = b2BodyId()
    private var front = b2BodyId()
    private var pelvis = b2BodyId()
    private var torso = b2BodyId()
    private var rearSpring = b2JointId()
    private var frontSpring = b2JointId()
    private var attachment = b2JointId()
    private var hip = b2JointId()
    private(set) var attached = true
    private var posture = 0.0
    private var throttle = 0.0
    private var rearSupport = 0.0
    private var frontSupport = 0.0
    private(set) var bike = BikeState()
    private(set) var rider = RiderState()
    private(set) var diagnostics = PhysicsDiagnostics()
    private var contactBuffer = [b2ContactData](repeating: b2ContactData(), count: 16)
    private struct ContactSummary {
        var touching = false
        var impulse = 0.0
    }

    init(configuration: PhysicsConfiguration, terrain: TerrainGenerator, bike initial: BikeState) {
        self.configuration = configuration; self.terrain = terrain
        // A fixture can start far from zero; never convert its absolute position to Float.
        origin = .init(x: floor(initial.position.x / 256) * 256,
                       y: floor(initial.position.y / 256) * 256)
        var definition = b2DefaultWorldDef()
        definition.gravity = b2Vec2(x: 0, y: -Float(configuration.gravity))
        definition.enableSleep = false
        definition.enableContinuous = true
        definition.hitEventThreshold = 0.5
        world = b2CreateWorld(&definition)
        updateTerrain(near: initial.position.x)
        createRig(initial)
        readSnapshot()
    }

    deinit { b2DestroyWorld(world) }

    private func createRig(_ initial: BikeState) {
        let c = configuration, fraction = c.mass / 150
        let wheelMass = 8 * fraction, pelvisMass = 15 * fraction, torsoMass = 35 * fraction
        let chassisMass = c.mass - 2 * wheelMass - pelvisMass - torsoMass
        let loadedOffset = c.unloadedAxleOffset - c.suspensionSag * c.suspensionTravel
        let chassisCOM = -(pelvisMass * 0.10 + torsoMass * 0.36 - 2 * wheelMass * loadedOffset) / chassisMass
        let wheelI = 0.5 * wheelMass * c.wheelRadius * c.wheelRadius
        let remainingInertia = 2 * (wheelI + wheelMass * (pow(c.wheelbase * 0.5, 2) + loadedOffset * loadedOffset))
            + pelvisMass * 0.1 * 0.1 + torsoMass * 0.36 * 0.36 + 1.3 * fraction
            + chassisMass * chassisCOM * chassisCOM
        chassis = makeBody(local: .init(), initial: initial, mass: chassisMass,
                           inertia: max(20, c.inertia - remainingInertia), center: .init(x: 0, y: chassisCOM))
        addCapsule(chassis, a: .init(x: -0.43, y: -0.075), b: .init(x: 0.43, y: -0.075), radius: 0.115)
        // Underside follows the visible engine while allowing the complete .38m travel.
        addCapsule(chassis, a: .init(x: -0.20, y: -0.41), b: .init(x: 0.18, y: -0.41), radius: 0.10)
        rear = makeBody(local: .init(x: -c.wheelbase * 0.5, y: -loadedOffset), initial: initial,
                        mass: wheelMass, inertia: wheelI, wheel: true)
        front = makeBody(local: .init(x: c.wheelbase * 0.5, y: -loadedOffset), initial: initial,
                         mass: wheelMass, inertia: wheelI, wheel: true)
        addCircle(rear, local: .init(), radius: c.wheelRadius, tire: true)
        addCircle(front, local: .init(), radius: c.wheelRadius, tire: true)
        pelvis = makeBody(local: .init(x: 0, y: 0.10), initial: initial, mass: pelvisMass, inertia: 0.4 * fraction)
        addCapsule(pelvis, a: .init(x: -0.09, y: 0), b: .init(x: 0.09, y: 0), radius: 0.085)
        torso = makeBody(local: .init(x: 0, y: 0.36), initial: initial, mass: torsoMass, inertia: 0.9 * fraction)
        addCapsule(torso, a: .init(x: 0, y: -0.14), b: .init(x: 0, y: 0.06), radius: 0.12)
        addCircle(torso, local: .init(x: 0.26, y: 0.20), radius: 0.17)
        rearSpring = makeSuspension(rear, x: -c.wheelbase * 0.5)
        frontSpring = makeSuspension(front, x: c.wheelbase * 0.5)
        var mount = b2DefaultMotorJointDef()
        mount.bodyIdA = chassis; mount.bodyIdB = pelvis
        mount.linearOffset = rotated(.init(x: 0, y: 0.10), by: initial.angle).b2
        mount.maxForce = Float(c.mass * c.gravity * 6)
        mount.maxTorque = 300 * Float(fraction)
        mount.correctionFactor = 0.05
        attachment = b2CreateMotorJoint(world, &mount)
        var hinge = b2DefaultRevoluteJointDef()
        hinge.bodyIdA = pelvis; hinge.bodyIdB = torso
        hinge.localAnchorA = b2Vec2(x: 0, y: 0.06)
        hinge.localAnchorB = b2Vec2(x: 0, y: -0.20)
        hinge.enableLimit = true; hinge.lowerAngle = -0.35; hinge.upperAngle = 0.35
        hinge.enableMotor = true; hinge.maxMotorTorque = 220 * Float(fraction)
        // Muscle effort is capped by the motor. A parallel unbounded spring is deliberately absent.
        hinge.enableSpring = false
        hip = b2CreateRevoluteJoint(world, &hinge)
        b2Body_SetAngularVelocity(rear, Float(initial.angularVelocity - initial.velocity.x / c.wheelRadius))
        b2Body_SetAngularVelocity(front, Float(initial.angularVelocity - initial.velocity.x / c.wheelRadius))
    }

    private func makeBody(local: Vector2, initial: BikeState, mass: Double, inertia: Double,
                          center: Vector2 = .init(), wheel: Bool = false) -> b2BodyId {
        let offset = rotated(local, by: initial.angle)
        var def = b2DefaultBodyDef()
        def.type = b2_dynamicBody
        def.position = (initial.position + offset - origin).b2
        def.rotation = b2MakeRot(Float(initial.angle))
        // BodyDef velocity is the center-of-mass velocity. SetMassData does not
        // add the omega-cross-center term when moving that center from the origin.
        let massOffset = rotated(local + center, by: initial.angle)
        def.linearVelocity = (initial.velocity + .init(x: -initial.angularVelocity * massOffset.y,
                                                      y: initial.angularVelocity * massOffset.x)).b2
        def.angularVelocity = Float(initial.angularVelocity)
        def.enableSleep = false; def.allowFastRotation = wheel
        let body = b2CreateBody(world, &def)
        // Shapes have zero density; the measured rig's masses and inertias are explicit.
        b2Body_SetMassData(body, b2MassData(mass: Float(mass), center: center.b2, rotationalInertia: Float(inertia)))
        bodies.append(body)
        return body
    }

    private func shapeDefinition(tire: Bool = false) -> b2ShapeDef {
        var def = b2DefaultShapeDef()
        def.density = 0; def.updateBodyMass = false
        def.material.friction = Float(tire ? configuration.tireGrip : 0.25)
        def.material.restitution = 0
        def.material.rollingResistance = tire ? 0.002 : 0
        def.filter.categoryBits = 2; def.filter.maskBits = 1
        def.filter.groupIndex = -1
        def.enableContactEvents = true; def.enableHitEvents = true
        return def
    }

    private func addCircle(_ body: b2BodyId, local: Vector2, radius: Double, tire: Bool = false) {
        var definition = shapeDefinition(tire: tire)
        var shape = b2Circle(center: local.b2, radius: Float(radius))
        _ = b2CreateCircleShape(body, &definition, &shape)
    }

    private func addCapsule(_ body: b2BodyId, a: Vector2, b: Vector2, radius: Double) {
        var definition = shapeDefinition()
        var shape = b2Capsule(center1: a.b2, center2: b.b2, radius: Float(radius))
        _ = b2CreateCapsuleShape(body, &definition, &shape)
    }

    private func makeSuspension(_ wheel: b2BodyId, x: Double) -> b2JointId {
        var def = b2DefaultWheelJointDef()
        def.bodyIdA = chassis; def.bodyIdB = wheel
        def.localAnchorA = b2Vec2(x: Float(x), y: -Float(configuration.unloadedAxleOffset))
        def.localAnchorB = b2Vec2(x: 0, y: 0)
        def.localAxisA = b2Vec2(x: 0, y: 1)
        def.enableSpring = true
        def.hertz = Float(configuration.suspensionHertz)
        def.dampingRatio = Float(configuration.suspensionDampingRatio)
        def.enableLimit = true; def.lowerTranslation = 0; def.upperTranslation = Float(configuration.suspensionTravel)
        return b2CreateWheelJoint(world, &def)
    }

    func advance(input: ControlInput) {
        updateTerrain(near: bike.position.x)
        let dt = PhysicsConfiguration.timeStep
        if attached {
            let requested = bounded(input.throttle, 0, 1)
            let response = requested > throttle ? 0.18 : 0.065
            throttle += (requested - throttle) * (1 - exp(-dt / response))
            controls(brake: bounded(input.brake, 0, 1), lean: bounded(input.lean, -1, 1))
        }
        b2World_Step(world, Float(dt), PhysicsConfiguration.substeps)
        readSnapshot()
        // Events and contacts have been copied before any origin change.
        rebaseIfNeeded()
    }

    private func controls(brake: Double, lean: Double) {
        let c = configuration, dt = PhysicsConfiguration.timeStep
        posture += (lean - posture) * (1 - exp(-dt / 0.16))
        // In Box2D 3.1.1 linearOffset is WORLD-space, unlike angularOffset.
        // Convert our chassis-local posture every step; never target world-up.
        b2MotorJoint_SetLinearOffset(attachment, rotated(.init(x: -posture * 0.12, y: 0.10), by: bike.angle).b2)
        b2MotorJoint_SetAngularOffset(attachment, Float(posture * 0.08))
        let error = posture * 0.25 - Double(b2RevoluteJoint_GetAngle(hip))
        b2RevoluteJoint_SetMotorSpeed(hip, Float(bounded(error * 12, -3, 3)))
        b2RevoluteJoint_SetMaxMotorTorque(hip, Float(c.mass / 150 * 220))

        // Engine torque is an equal/opposite pair inside the bike. Braking is
        // independently solved by each wheel joint's zero-speed motor. This also
        // handles reverse travel: brake and engine add, never cancel by mistake.
        let rearRelativeSpeed = Double(b2Body_GetAngularVelocity(rear) - b2Body_GetAngularVelocity(chassis))
        let driveSpeed = max(0, bike.velocity.x, -rearRelativeSpeed * c.wheelRadius)
        let drive = throttle * c.maximumDriveForce * c.wheelRadius * max(0, 1 - pow(driveSpeed / c.motorTopSpeed, 2))
        b2Body_ApplyTorque(rear, -Float(drive), true)
        b2Body_ApplyTorque(chassis, Float(drive), true)
        motor(rearSpring, speed: 0, torque: brake * c.brakeForce * c.rearBrakeShare * c.wheelRadius)
        motor(frontSpring, speed: 0, torque: brake * c.brakeForce * (1 - c.rearBrakeShare) * c.wheelRadius)

        // Rider effort remains usable with either wheel clear. This is a deliberate
        // player command, never an angle target or an automatic landing correction.
        let gaps = [rear, front].map { body -> Double in
            let p = snapshot(body).position
            let n = hypot(1, terrain.slope(at: p.x))
            let gap = (p.y - terrain.height(at: p.x)) / n - c.wheelRadius
            let t = bounded(gap / c.leanClearance, 0, 1)
            return t * t * (3 - 2 * t)
        }
        let freedom = (gaps[0] + gaps[1]) * 0.5
        rearSupport += ((bike.rear.contact ? 1.0 : 0) - rearSupport) * 0.25
        frontSupport += ((bike.front.contact ? 1.0 : 0) - frontSupport) * 0.25
        let boost = lean < 0 ? (c.forwardWheelieBalance - 1) * 0.5 * gaps[1] * rearSupport : 0
        let authority = lean * bike.angularVelocity > 0 ? max(0, 1 - abs(bike.angularVelocity) / c.maximumAirSpin) : 1
        b2Body_ApplyTorque(chassis, Float(lean * c.airControlTorque * (freedom + boost) * authority), true)
        // Small aerodynamic drag, never a clamp preserving or imposing speed at impact.
        for body in bodies {
            let velocity = b2Body_GetLinearVelocity(body)
            let fraction = Double(b2Body_GetMass(body)) / c.mass
            b2Body_ApplyForceToCenter(body, b2Vec2(x: Float(-0.05 * Double(velocity.x) * abs(Double(velocity.x)) * fraction), y: 0), true)
        }
    }

    private func motor(_ joint: b2JointId, speed: Double, torque: Double) {
        b2WheelJoint_EnableMotor(joint, torque > 0.0001)
        b2WheelJoint_SetMotorSpeed(joint, Float(speed))
        b2WheelJoint_SetMaxMotorTorque(joint, Float(torque))
    }

    func coast() {
        throttle = 0
        bike.throttle = 0
        motor(rearSpring, speed: 0, torque: 0)
        motor(frontSpring, speed: 0, torque: 0)
    }

    func detach() {
        guard attached else { return }
        attached = false; throttle = 0
        b2DestroyJoint(attachment); attachment = b2JointId()
        motor(rearSpring, speed: 0, torque: 0); motor(frontSpring, speed: 0, torque: 0)
        b2RevoluteJoint_SetMotorSpeed(hip, 0)
        b2RevoluteJoint_SetMaxMotorTorque(hip, 1.5)
        // All existing linear and angular velocities are preserved. Rider/moto
        // self-collision stays disabled, so overlapping artwork cannot cause an ejection impulse.
        rider.isAttached = false; bike.throttle = 0
    }

    private func snapshot(_ body: b2BodyId) -> RigidBodyState {
        .init(position: Vector2(b2Body_GetPosition(body)) + origin,
              velocity: Vector2(b2Body_GetLinearVelocity(body)),
              angle: Double(b2Rot_GetAngle(b2Body_GetRotation(body))),
              angularVelocity: Double(b2Body_GetAngularVelocity(body)))
    }

    private func contacts(_ body: b2BodyId) -> ContactSummary {
        let capacity = b2Body_GetContactCapacity(body)
        guard capacity > 0 else { return .init() }
        if contactBuffer.count < Int(capacity) {
            contactBuffer.append(contentsOf: repeatElement(b2ContactData(), count: Int(capacity) - contactBuffer.count))
        }
        let count = b2Body_GetContactData(body, &contactBuffer, capacity)
        var result = ContactSummary()
        for entry in contactBuffer.prefix(Int(count)) {
            for index in 0..<Int(entry.manifold.pointCount) {
                let point = index == 0 ? entry.manifold.points.0 : entry.manifold.points.1
                if point.separation <= 0.008 && point.totalNormalImpulse > 0 {
                    result.touching = true
                    result.impulse += Double(point.totalNormalImpulse)
                }
            }
        }
        return result
    }

    private func readSnapshot() {
        let chassisState = snapshot(chassis)
        bike.position = chassisState.position; bike.velocity = chassisState.velocity
        bike.angle = chassisState.angle; bike.angularVelocity = chassisState.angularVelocity; bike.throttle = throttle
        let rearContact = contacts(rear), frontContact = contacts(front)
        bike.rear = wheelSnapshot(rear, joint: rearSpring, contact: rearContact.touching)
        bike.front = wheelSnapshot(front, joint: frontSpring, contact: frontContact.touching)
        rider = .init(pelvis: snapshot(pelvis), torso: snapshot(torso), isAttached: attached)
        diagnostics.rearNormalImpulse = rearContact.impulse
        diagnostics.frontNormalImpulse = frontContact.impulse
        diagnostics.chassisContact = contacts(chassis).touching
        diagnostics.riderContact = contacts(pelvis).touching || contacts(torso).touching
        diagnostics.bodyContact = diagnostics.chassisContact || diagnostics.riderContact
        diagnostics.attachmentForce = attached ? Double(b2Length(b2Joint_GetConstraintForce(attachment))) : 0
        let events = b2World_GetContactEvents(world)
        diagnostics.peakImpactSpeed = 0
        if let hits = events.hitEvents {
            for index in 0..<Int(events.hitCount) {
                diagnostics.peakImpactSpeed = max(diagnostics.peakImpactSpeed, Double(hits[index].approachSpeed))
            }
        }
        diagnostics.totalMass = bodies.reduce(0) { $0 + Double(b2Body_GetMass($1)) }
        var massPosition = Vector2(), momentum = Vector2()
        diagnostics.kineticEnergy = 0
        for body in bodies {
            let mass = Double(b2Body_GetMass(body))
            let p = Vector2(b2Body_GetWorldCenterOfMass(body)) + origin
            let v = Vector2(b2Body_GetLinearVelocity(body))
            let w = Double(b2Body_GetAngularVelocity(body))
            let inertia = Double(b2Body_GetRotationalInertia(body))
            massPosition = massPosition + p * mass; momentum = momentum + v * mass
            diagnostics.kineticEnergy += 0.5 * mass * v.dot(v) + 0.5 * inertia * w * w
        }
        diagnostics.centerOfMass = massPosition * (1 / diagnostics.totalMass)
        diagnostics.centerOfMassVelocity = momentum * (1 / diagnostics.totalMass)
        diagnostics.pitchInertia = bodies.reduce(0) { total, body in
            let p = Vector2(b2Body_GetWorldCenterOfMass(body)) + origin - diagnostics.centerOfMass
            return total + Double(b2Body_GetRotationalInertia(body)) + Double(b2Body_GetMass(body)) * p.dot(p)
        }
        diagnostics.angularMomentum = bodies.reduce(0) { total, body in
            let p = Vector2(b2Body_GetWorldCenterOfMass(body)) + origin - diagnostics.centerOfMass
            let v = Vector2(b2Body_GetLinearVelocity(body)) - diagnostics.centerOfMassVelocity
            return total + Double(b2Body_GetMass(body)) * p.cross(v)
                + Double(b2Body_GetRotationalInertia(body)) * Double(b2Body_GetAngularVelocity(body))
        }
        let counters = b2World_GetCounters(world)
        diagnostics.bodyCount = Int(counters.bodyCount)
        diagnostics.allocatedByteCount = Int(counters.byteCount)
        diagnostics.terrainChunkCount = chunks.count
        diagnostics.origin = origin
        diagnostics.stepMilliseconds = Double(b2World_GetProfile(world).step)
    }

    private func wheelSnapshot(_ body: b2BodyId, joint: b2JointId, contact: Bool) -> WheelState {
        let pose = snapshot(body)
        var result = WheelState()
        result.position = pose.position; result.velocity = pose.velocity
        result.angle = pose.angle; result.angularVelocity = pose.angularVelocity; result.contact = contact
        let anchorA = b2Body_GetWorldPoint(chassis, b2Joint_GetLocalAnchorA(joint))
        let anchorB = b2Body_GetWorldPoint(body, b2Joint_GetLocalAnchorB(joint))
        let axis = b2Body_GetWorldVector(chassis, b2Vec2(x: 0, y: 1))
        result.compression = max(0, Double(b2Dot(b2Sub(anchorB, anchorA), axis)))
        return result
    }

    private func updateTerrain(near x: Double) {
        let first = Int(floor((x - 128) / 64)), last = Int(floor((x + 256) / 64))
        for index in chunks.keys.sorted() where index < first || index > last {
            if let body = chunks.removeValue(forKey: index) { b2DestroyBody(body) }
        }
        for index in first...last where chunks[index] == nil {
            let baseX = Double(index) * 64, baseY = terrain.height(at: baseX)
            var bodyDef = b2DefaultBodyDef()
            bodyDef.position = (Vector2(x: baseX, y: baseY) - origin).b2
            let body = b2CreateBody(world, &bodyDef)
            // Reverse winding makes one-sided surface normals point up. Adjacent
            // chains share three global grid vertices. Ghost edges do not collide.
            let points = stride(from: index * 256 + 257, through: index * 256 - 1, by: -1).map { grid -> b2Vec2 in
                let globalX = Double(grid) * 0.25
                return b2Vec2(x: Float(globalX - baseX), y: Float(terrain.height(at: globalX) - baseY))
            }
            var material = b2SurfaceMaterial()
            material.friction = Float(configuration.tireGrip); material.restitution = 0
            var chain = b2DefaultChainDef()
            chain.filter.categoryBits = 1; chain.filter.maskBits = 2
            chain.count = Int32(points.count); chain.materialCount = 1
            points.withUnsafeBufferPointer { buffer in
                chain.points = buffer.baseAddress
                withUnsafePointer(to: &material) { materials in
                    chain.materials = materials
                    _ = b2CreateChain(body, &chain)
                }
            }
            chunks[index] = body
        }
    }

    private func rebaseIfNeeded() {
        let local = bike.position - origin
        guard abs(local.x) > 512 || abs(local.y) > 512 else { return }
        translateOrigin(by: .init(x: abs(local.x) > 512 ? (local.x / 256).rounded(.towardZero) * 256 : 0,
                                  y: abs(local.y) > 512 ? (local.y / 256).rounded(.towardZero) * 256 : 0))
    }

    /// Test seam for the same production rebasing operation; never changes velocities or joints.
    func translateOrigin(by shift: Vector2) {
        for body in bodies + chunks.keys.sorted().compactMap({ chunks[$0] }) {
            let position = b2Body_GetPosition(body)
            b2Body_SetTransform(body, b2Vec2(x: position.x - Float(shift.x), y: position.y - Float(shift.y)),
                                b2Body_GetRotation(body))
        }
        origin = origin + shift
        diagnostics.rebaseCount += 1; diagnostics.origin = origin
        // Global snapshots stay unchanged. Contact events from the preceding step
        // have already been read; no stale world-space event is exposed afterward.
    }
}
