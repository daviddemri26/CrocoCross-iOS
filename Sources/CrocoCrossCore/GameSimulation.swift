import Foundation

/// One owner for one Box2D world. Reproduce runs from the versioned seed and inputs;
/// snapshots never pretend to restore the solver's private contact caches.
public final class GameSimulation {
    public static let engineVersion = PhysicsConfiguration.engineVersion
    public static let backendVersion = PhysicsConfiguration.backendVersion
    public static let weeklyDistance = PhysicsConfiguration.weeklyDistance
    public static let timeStep = PhysicsConfiguration.timeStep
    public static func flipBonus(for count: Int) -> Int {
        guard count > 0 else { return 0 }
        return 1_000 * ((1 << min(count, 16)) - 1)
    }
    public private(set) var state: SimulationState
    public let configuration: PhysicsConfiguration
    private let terrain: TerrainGenerator
    private var physics: Box2DBikeWorld
    private var stunt = StuntTracker()
    private var stuntScore = 0
    private var crashContactTicks = 0
    private var recoveryTicks = 0
    private var shieldTicks = 0
    private var presentationTicks = 0
    private var checkpointX = PhysicsConfiguration.courseStartX
    public var diagnostics: PhysicsDiagnostics { physics.diagnostics }

    public init(mode: RunMode, seed: UInt32, configuration: PhysicsConfiguration = .init()) {
        precondition(configuration.isValid, "Invalid Box2D physics configuration")
        self.configuration = configuration
        terrain = TerrainGenerator(seed: seed, style: configuration.terrainStyle)
        state = SimulationState(mode: mode, seed: seed)
        let x = PhysicsConfiguration.courseStartX
        let angle = atan(terrain.slope(at: x))
        var bike = BikeState()
        bike.position = .init(x: x, y: terrain.height(at: x) + configuration.restingRideHeight / cos(angle))
        bike.angle = angle
        physics = Box2DBikeWorld(configuration: configuration, terrain: terrain, bike: bike)
        copySnapshot()
    }

    /// Test fixture, not a solver restoration API. It creates a new independent world.
    init(state: SimulationState, configuration: PhysicsConfiguration) {
        precondition(configuration.isValid)
        self.configuration = configuration; self.state = state
        terrain = TerrainGenerator(seed: state.seed, style: configuration.terrainStyle)
        physics = Box2DBikeWorld(configuration: configuration, terrain: terrain, bike: state.bike)
        stuntScore = max(0, state.score - Int(floor(state.distance * 10)))
        checkpointX = max(PhysicsConfiguration.courseStartX, state.bike.position.x)
        copySnapshot()
    }

    public func terrainHeight(at x: Double) -> Double { terrain.height(at: x) }

    @discardableResult
    public func step(input: ControlInput) -> [GameEvent] {
        guard state.status == .active || state.status == .recovering else { return [] }
        state.tick += 1
        if state.status == .recovering {
            physics.advance(input: .neutral); copySnapshot()
            recoveryTicks -= 1
            if recoveryTicks <= 0 {
                placeBike(at: checkpointX, speed: 3.5)
                state.status = .active; shieldTicks = 120; crashContactTicks = 0
                return [.respawned]
            }
            return []
        }
        let previous = state.bike
        physics.advance(input: input); copySnapshot()
        let grounded = state.bike.grounded
        var events: [GameEvent] = []
        if grounded && !previous.grounded && diagnostics.peakImpactSpeed > 1.2 {
            events.append(.landed(impact: diagnostics.peakImpactSpeed))
        }
        if shieldTicks > 0 { shieldTicks -= 1 }
        let hit = diagnostics.bodyContact
        crashContactTicks = hit ? crashContactTicks + 1 : 0
        let traveled = max(0, state.bike.position.x - PhysicsConfiguration.courseStartX)
        state.distance = max(state.distance, state.mode == .weekly ? min(Self.weeklyDistance, traveled) : traveled)
        if state.bike.rear.contact && state.bike.front.contact && !hit &&
            abs(wrapped(state.bike.angle - atan(terrain.slope(at: state.bike.position.x)))) < 0.2 &&
            abs(state.bike.angularVelocity) < 0.75 && state.bike.position.x > checkpointX + 12 {
            checkpointX = state.bike.position.x
        }
        if shieldTicks == 0 && crashContactTicks >= 3 {
            state.lives -= 1; stunt.clear()
            state.status = state.lives > 0 ? .recovering : .crashed
            recoveryTicks = state.lives > 0 ? 216 : 0
            presentationTicks = 0
            physics.detach(); copySnapshot()
            events.append(.crashed)
        } else {
            let finishing = state.mode == .weekly && state.distance >= Self.weeklyDistance
            let safe = grounded && !hit && cos(state.bike.angle) >= cos(Double.pi * 75 / 180)
            let landed = stunt.advance(delta: wrapped(state.bike.angle - previous.angle), orientation: state.bike.angle,
                                       airborne: !grounded, safeContact: safe, terminal: finishing)
            if landed > 0 {
                state.flips += landed; stuntScore += Self.flipBonus(for: landed)
                events.append(.flip(landed))
            }
            if finishing { state.status = .finished; events.append(.finished) }
        }
        state.score = Int(floor(state.distance * 10)) + stuntScore + (state.status == .finished ? 1_000 : 0)
        return events
    }

    /// A bounded results animation. No game clock, life, distance or score advances.
    public func stepPresentation() {
        guard state.status == .crashed, presentationTicks < 216 else { return }
        presentationTicks += 1
        physics.advance(input: .neutral); copySnapshot()
    }

    private func copySnapshot() {
        state.bike = physics.bike; state.rider = physics.rider
    }

    private func placeBike(at x: Double, speed: Double) {
        let angle = atan(terrain.slope(at: x))
        var bike = BikeState()
        bike.position = .init(x: x, y: terrain.height(at: x) + configuration.restingRideHeight / cos(angle))
        bike.angle = angle
        bike.velocity = .init(x: cos(angle) * speed, y: sin(angle) * speed)
        physics = Box2DBikeWorld(configuration: configuration, terrain: terrain, bike: bike)
        stunt.clear(); copySnapshot()
    }

    /// Internal fixture operation exercises the production atomic rebase path.
    func rebaseForTesting(by shift: Vector2) { physics.translateOrigin(by: shift) }
}
