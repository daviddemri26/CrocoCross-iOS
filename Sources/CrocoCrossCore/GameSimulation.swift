import Foundation

/// A sprung rigid chassis with massless tires. Drive acts at the rear contact patch;
/// its moment arm below the centre of mass produces weight transfer and wheelies.
/// No angle target, upright torque, artificial crest impulse or SpriteKit physics is used.
public struct GameSimulation: Codable, Sendable {
    public static let engineVersion = PhysicsConfiguration.engineVersion
    public static let weeklyDistance = PhysicsConfiguration.weeklyDistance
    public static let timeStep = PhysicsConfiguration.timeStep
    public private(set) var state: SimulationState
    public let configuration: PhysicsConfiguration
    private let saveVersion: String
    private let terrain: TerrainGenerator
    private var stunt = StuntTracker()
    private var stuntScore = 0
    private var crashContactTicks = 0
    private var recoveryTicks = 0
    private var shieldTicks = 0
    private var checkpointX = PhysicsConfiguration.courseStartX
    private var airborneTicks = 0
    private static let startX = PhysicsConfiguration.courseStartX

    public init(mode: RunMode, seed: UInt32, configuration: PhysicsConfiguration = .init()) {
        precondition(configuration.isValid, "Invalid native physics configuration")
        self.configuration = configuration
        self.saveVersion = Self.engineVersion
        self.terrain = TerrainGenerator(seed: seed, style: configuration.terrainStyle)
        self.state = SimulationState(mode: mode, seed: seed)
        placeBike(at: Self.startX, speed: 0)
    }

    /// Fixture/restoration entry point used by core tests; app saves encode the full simulation.
    init(state: SimulationState, configuration: PhysicsConfiguration) {
        self.configuration = configuration
        self.saveVersion = Self.engineVersion
        self.terrain = TerrainGenerator(seed: state.seed, style: configuration.terrainStyle)
        self.state = state
        refreshWheels()
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        saveVersion = try values.decode(String.self, forKey: .saveVersion)
        state = try values.decode(SimulationState.self, forKey: .state)
        configuration = try values.decode(PhysicsConfiguration.self, forKey: .configuration)
        terrain = try values.decode(TerrainGenerator.self, forKey: .terrain)
        stunt = try values.decode(StuntTracker.self, forKey: .stunt)
        stuntScore = try values.decode(Int.self, forKey: .stuntScore)
        crashContactTicks = try values.decode(Int.self, forKey: .crashContactTicks)
        recoveryTicks = try values.decode(Int.self, forKey: .recoveryTicks)
        shieldTicks = try values.decode(Int.self, forKey: .shieldTicks)
        checkpointX = try values.decode(Double.self, forKey: .checkpointX)
        airborneTicks = try values.decode(Int.self, forKey: .airborneTicks)
        guard isValidSavedState else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                   debugDescription: "Unsupported or invalid CrocoCross run save."))
        }
    }

    /// Decoding rejects a corrupted or incompatible save before it reaches the frame loop.
    public var isValidSavedState: Bool {
        let bike = state.bike
        let points = [bike.position, bike.velocity, bike.rear.position, bike.front.position]
        guard saveVersion == Self.engineVersion, configuration.isValid, stunt.isValid,
              terrain.seed == state.seed, terrain.style == configuration.terrainStyle,
              points.allSatisfy({ $0.x.isFinite && $0.y.isFinite && abs($0.x) < 1e12 && abs($0.y) < 1e12 }),
              [bike.angle, bike.angularVelocity, bike.throttle, bike.rear.angle, bike.front.angle,
               bike.rear.compression, bike.front.compression, state.distance, checkpointX].allSatisfy(\.isFinite),
              abs(bike.angle) <= .pi + 0.001, abs(bike.angularVelocity) < 100,
              (0 ... 1).contains(bike.throttle), bike.rear.compression >= 0, bike.front.compression >= 0,
              state.tick >= 0, state.tick < 1_000_000_000_000, state.distance >= 0, state.distance < 1e12,
              state.score >= 0, state.flips >= 0, state.flips <= state.tick, state.flips < 1_000_000_000,
              stuntScore >= 0, stuntScore < 1_000_000_000_000,
              state.lives >= 0, state.lives <= (state.mode == .weekly ? 1 : 3),
              checkpointX >= Self.startX, checkpointX <= state.distance + Self.startX + 2,
              (0 ... 216).contains(recoveryTicks), (0 ... 120).contains(shieldTicks),
              crashContactTicks >= 0, crashContactTicks < 1_000_000, airborneTicks >= 0,
              state.mode != .weekly || state.distance <= Self.weeklyDistance else { return false }
        switch state.status {
        case .active: return state.lives > 0
        case .recovering: return state.mode == .endless && state.lives > 0 && recoveryTicks > 0
        case .crashed: return state.lives == 0
        case .finished: return state.mode == .weekly && state.lives == 1 && state.distance == Self.weeklyDistance
        }
    }

    public func terrainHeight(at x: Double) -> Double { terrain.height(at: x) }

    @discardableResult
    public mutating func step(input: ControlInput) -> [GameEvent] {
        guard state.status == .active || state.status == .recovering else { return [] }
        state.tick += 1
        if state.status == .recovering {
            recoveryTicks -= 1
            if recoveryTicks <= 0 {
                placeBike(at: checkpointX, speed: 3.5)
                state.status = .active; shieldTicks = 120; crashContactTicks = 0
                return [.respawned]
            }
            return []
        }

        let c = configuration, dt = Self.timeStep
        let throttle = bounded(input.throttle, 0, 1), brake = bounded(input.brake, 0, 1)
        let lean = bounded(input.lean, -1, 1)
        let beforeIntegration = state.bike
        var bike = beforeIntegration
        let wasGrounded = bike.grounded
        let previousAngle = bike.angle
        let response = throttle > bike.throttle ? 0.16 : 0.065
        bike.throttle += (throttle - bike.throttle) * (1 - exp(-dt / response))

        var force = Vector2(x: -0.38 * bike.velocity.x * abs(bike.velocity.x), y: -c.mass * c.gravity)
        var torque = -bike.angularVelocity * (wasGrounded ? 9 : 5)
        var greatestImpact = 0.0
        for rear in [true, false] {
            let contact = contactFor(bike: bike, rear: rear)
            guard contact.compression > 0 else { continue }
            let lever = contact.patch - bike.position
            let patchVelocity = bike.velocity + Vector2(x: -bike.angularVelocity * lever.y, y: bike.angularVelocity * lever.x)
            let normalVelocity = patchVelocity.dot(contact.normal)
            greatestImpact = max(greatestImpact, -normalVelocity)
            let normalForce = bounded(c.springRate * contact.compression - c.damping * normalVelocity, 0, c.mass * c.gravity * 8)
            let tangentVelocity = patchVelocity.dot(contact.tangent)
            let driveRatio = max(0, tangentVelocity) / c.motorTopSpeed
            let drive = rear ? bike.throttle * c.maximumDriveForce * max(0, 1 - driveRatio * driveRatio) : 0
            let inverseMass = 1 / c.mass + pow(lever.cross(contact.tangent), 2) / c.inertia
            let braking = min(brake * c.brakeForce * (rear ? 0.42 : 0.58), abs(tangentVelocity) / (dt * inverseMass)) * sign(tangentVelocity)
            let rolling = normalForce * 0.012 * tanh(tangentVelocity * 2)
            let traction = bounded(drive - braking - rolling, -c.tireGrip * normalForce, c.tireGrip * normalForce)
            let tireForce = contact.normal * normalForce + contact.tangent * traction
            force = force + tireForce
            torque += lever.cross(tireForce)
        }

        if !wasGrounded {
            // The same two pedals control attitude only in flight. On the ground,
            // wheelies come entirely from the rear contact force and weight transfer.
            let sameDirection = lean * bike.angularVelocity > 0
            let authority = sameDirection ? max(0, 1 - abs(bike.angularVelocity) / c.maximumAirSpin) : 1
            torque += lean * c.airControlTorque * authority
        }
        bike.velocity = bike.velocity + force * (dt / c.mass)
        bike.angularVelocity += torque / c.inertia * dt
        // Finite caps protect restoration/numerical failures, not normal rider balance.
        bike.angularVelocity = bounded(bike.angularVelocity, -14, 14)
        bike.velocity.x = bounded(bike.velocity.x, -70, 90)
        bike.velocity.y = bounded(bike.velocity.y, -70, 70)
        bike.position = bike.position + bike.velocity * dt
        bike.angle = wrapped(bike.angle + bike.angularVelocity * dt)

        // A suspension bottom-out is a contact impulse, not an upright correction.
        for _ in 0 ..< 2 {
            for rear in [true, false] {
                let contact = contactFor(bike: bike, rear: rear)
                let excess = contact.compression - c.suspensionTravel
                guard excess > 0 else { continue }
                let lever = contact.patch - bike.position
                let cross = lever.cross(contact.normal)
                let effectiveMass = 1 / (1 / c.mass + cross * cross / c.inertia)
                let normalVelocity = (bike.velocity + Vector2(x: -bike.angularVelocity * lever.y, y: bike.angularVelocity * lever.x)).dot(contact.normal)
                if normalVelocity < 0 {
                    let impulse = -normalVelocity * effectiveMass * 1.035
                    bike.velocity = bike.velocity + contact.normal * (impulse / c.mass)
                    bike.angularVelocity += cross * impulse / c.inertia
                }
                let correction = excess * 0.65 * effectiveMass
                bike.position = bike.position + contact.normal * (correction / c.mass)
                bike.angle = wrapped(bike.angle + cross * correction / c.inertia)
            }
        }
        state.bike = bike
        refreshWheels()
        advanceWheelAngles(dt: dt)
        let grounded = state.bike.grounded
        airborneTicks = grounded ? 0 : airborneTicks + 1
        var events: [GameEvent] = []
        if grounded && !wasGrounded {
            for rear in [true, false] {
                let contact = contactFor(bike: state.bike, rear: rear)
                guard contact.compression >= -0.002 else { continue }
                let lever = contact.patch - beforeIntegration.position
                let velocity = beforeIntegration.velocity + Vector2(x: -beforeIntegration.angularVelocity * lever.y,
                                                                     y: beforeIntegration.angularVelocity * lever.x)
                greatestImpact = max(greatestImpact, -velocity.dot(contact.normal))
            }
            if greatestImpact > 1.2 { events.append(.landed(impact: greatestImpact)) }
        }

        if shieldTicks > 0 { shieldTicks -= 1 }
        let hit = bodyHitsTerrain()
        crashContactTicks = hit ? crashContactTicks + 1 : 0
        let traveled = max(0, state.bike.position.x - Self.startX)
        state.distance = max(state.distance, state.mode == .weekly ? min(Self.weeklyDistance, traveled) : traveled)
        if state.bike.rear.contact && state.bike.front.contact && !hit &&
            abs(wrapped(state.bike.angle - atan(terrain.slope(at: state.bike.position.x)))) < 0.2 &&
            abs(state.bike.angularVelocity) < 0.75 && state.bike.position.x > checkpointX + 12 {
            checkpointX = state.bike.position.x
        }
        if shieldTicks == 0 && crashContactTicks >= 3 {
            state.lives -= 1; stunt.clear(); airborneTicks = 0
            state.status = state.lives > 0 ? .recovering : .crashed
            recoveryTicks = state.lives > 0 ? 216 : 0
            state.bike.velocity = .init(); state.bike.angularVelocity = 0; state.bike.throttle = 0
            events.append(.crashed)
        } else {
            let finishing = state.mode == .weekly && state.distance >= Self.weeklyDistance
            let safe = grounded && !hit && cos(state.bike.angle) >= cos(Double.pi * 75 / 180)
            let landed = stunt.advance(delta: wrapped(state.bike.angle - previousAngle), orientation: state.bike.angle,
                                       airborne: !grounded, safeContact: safe, terminal: finishing)
            if landed > 0 {
                state.flips += landed
                stuntScore += 1_000 * ((1 << min(landed, 16)) - 1)
                events.append(.flip(landed))
            }
            if finishing { state.status = .finished; events.append(.finished) }
        }
        state.score = Int(floor(state.distance * 10)) + stuntScore + (state.status == .finished ? 1_000 : 0)
        return events
    }

    private struct Contact {
        let center: Vector2
        let patch: Vector2
        let normal: Vector2
        let tangent: Vector2
        let compression: Double
    }

    private func contactFor(bike: BikeState, rear: Bool) -> Contact {
        let c = configuration
        let unloaded = bike.position + rotated(Vector2(x: (rear ? -0.5 : 0.5) * c.wheelbase, y: -c.unloadedAxleOffset), by: bike.angle)
        let slope = terrain.slope(at: unloaded.x), length = hypot(1, slope)
        let normal = Vector2(x: -slope / length, y: 1 / length)
        let distance = (unloaded.y - terrain.height(at: unloaded.x)) / length
        let compression = c.wheelRadius - distance
        let center = unloaded + normal * bounded(compression, 0, c.suspensionTravel)
        return Contact(center: center, patch: center - normal * c.wheelRadius, normal: normal,
                       tangent: .init(x: 1 / length, y: slope / length), compression: compression)
    }

    private mutating func refreshWheels() {
        for rear in [true, false] {
            let contact = contactFor(bike: state.bike, rear: rear)
            var wheel = rear ? state.bike.rear : state.bike.front
            wheel.position = contact.center
            wheel.compression = bounded(contact.compression, 0, configuration.suspensionTravel)
            wheel.contact = contact.compression > -0.002
            if rear { state.bike.rear = wheel } else { state.bike.front = wheel }
        }
    }

    private mutating func advanceWheelAngles(dt: Double) {
        for rear in [true, false] {
            var wheel = rear ? state.bike.rear : state.bike.front
            let slope = terrain.slope(at: wheel.position.x)
            let speed = (state.bike.velocity.x + state.bike.velocity.y * slope) / hypot(1, slope)
            wheel.angle = wrapped(wheel.angle - speed / configuration.wheelRadius * dt)
            if rear { state.bike.rear = wheel } else { state.bike.front = wheel }
        }
    }

    private func bodyHitsTerrain() -> Bool {
        // Helmet, torso and chassis. Tires alone may land at large recoverable angles.
        let samples: [(Vector2, Double)] = [(.init(x: 0.06, y: 0.56), 0.17), (.init(x: 0, y: 0.13), 0.2),
                                          (.init(x: 0.42, y: -0.1), 0.12), (.init(x: -0.4, y: -0.1), 0.12)]
        return samples.contains { local, radius in
            let point = state.bike.position + rotated(local, by: state.bike.angle)
            let slope = terrain.slope(at: point.x)
            return (point.y - terrain.height(at: point.x)) / hypot(1, slope) < radius
        }
    }

    private mutating func placeBike(at x: Double, speed: Double) {
        let angle = atan(terrain.slope(at: x))
        state.bike = BikeState()
        state.bike.position = .init(x: x, y: terrain.height(at: x) + configuration.restingRideHeight / cos(angle))
        state.bike.angle = angle
        state.bike.velocity = .init(x: cos(angle) * speed, y: sin(angle) * speed)
        stunt.clear(); refreshWheels()
    }

    private enum CodingKeys: String, CodingKey {
        case state, configuration, saveVersion, terrain, stunt, stuntScore, crashContactTicks,
             recoveryTicks, shieldTicks, checkpointX, airborneTicks
    }
}

private func bounded(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
    value.isFinite ? min(upper, max(lower, value)) : 0
}
private func sign(_ value: Double) -> Double { value > 0 ? 1 : value < 0 ? -1 : 0 }
private func wrapped(_ angle: Double) -> Double { atan2(sin(angle), cos(angle)) }
private func rotated(_ v: Vector2, by angle: Double) -> Vector2 {
    .init(x: v.x * cos(angle) - v.y * sin(angle), y: v.x * sin(angle) + v.y * cos(angle))
}
private extension Vector2 {
    static func + (a: Self, b: Self) -> Self { .init(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: Self, b: Self) -> Self { .init(x: a.x - b.x, y: a.y - b.y) }
    static func * (a: Self, b: Double) -> Self { .init(x: a.x * b, y: a.y * b) }
    func dot(_ other: Self) -> Double { x * other.x + y * other.y }
    func cross(_ other: Self) -> Double { x * other.y - y * other.x }
}
