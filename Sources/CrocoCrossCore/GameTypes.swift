import Foundation

public enum RunMode: String, Codable, CaseIterable, Sendable { case weekly, endless }
public enum RunStatus: String, Codable, Sendable { case active, recovering, crashed, finished }

/// Simulation uses metres, seconds and a positive-up Y axis. Rendering never mutates physics.
public struct Vector2: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double = 0, y: Double = 0) { self.x = x; self.y = y }
}

public struct ControlInput: Codable, Equatable, Sendable {
    public var throttle: Double
    public var brake: Double
    /// Positive shifts the rider backward (nose up), negative forward (nose down).
    /// Balance authority grows as either tire leaves the surface.
    public var lean: Double
    public init(throttle: Double = 0, brake: Double = 0, lean: Double = 0) {
        self.throttle = throttle; self.brake = brake; self.lean = lean
    }
    public static let neutral = ControlInput()
}

public struct WheelState: Codable, Equatable, Sendable {
    public var position = Vector2()
    public var velocity = Vector2()
    public var angle: Double = 0
    public var angularVelocity: Double = 0
    public var compression: Double = 0
    public var contact = false
    public init() {}
}

/// A value copy of a physical body's origin pose and centre-of-mass velocity, in global SI units.
public struct RigidBodyState: Codable, Equatable, Sendable {
    public var position: Vector2
    public var velocity: Vector2
    public var angle: Double
    public var angularVelocity: Double
    public init(position: Vector2 = .init(), velocity: Vector2 = .init(), angle: Double = 0,
                angularVelocity: Double = 0) {
        self.position = position; self.velocity = velocity
        self.angle = angle; self.angularVelocity = angularVelocity
    }
}

public struct RiderState: Codable, Equatable, Sendable {
    public var pelvis: RigidBodyState
    public var torso: RigidBodyState
    public var isAttached: Bool
    public init(pelvis: RigidBodyState = .init(), torso: RigidBodyState = .init(), isAttached: Bool = true) {
        self.pelvis = pelvis; self.torso = torso; self.isAttached = isAttached
    }
}

public struct BikeState: Codable, Equatable, Sendable {
    public var position = Vector2()
    /// Linear velocity of the physical chassis centre of mass.
    public var velocity = Vector2()
    public var angle: Double = 0
    public var angularVelocity: Double = 0
    public var rear = WheelState()
    public var front = WheelState()
    public var throttle: Double = 0
    public init() {}
    public var grounded: Bool { rear.contact || front.contact }
}

public struct SimulationState: Codable, Equatable, Sendable {
    public var bike = BikeState()
    public var rider = RiderState()
    public var mode: RunMode
    public var seed: UInt32
    public var status: RunStatus = .active
    public var tick: Int = 0
    public var distance: Double = 0
    public var score: Int = 0
    public var flips: Int = 0
    public var lives: Int
    public init(mode: RunMode, seed: UInt32) {
        self.mode = mode; self.seed = seed; self.lives = mode == .weekly ? 1 : 3
    }
    public var elapsed: Double { Double(tick) / 120 }
}

public enum GameEvent: Equatable, Sendable {
    case landed(impact: Double)
    case crashed
    case respawned
    case flip(Int)
    case finished
}
