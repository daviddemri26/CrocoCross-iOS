import Foundation

public enum RunMode: String, Codable, CaseIterable, Sendable { case weekly, endless }
public enum RunStatus: String, Codable, Sendable { case active, recovering, crashed, finished }

/// Simulation uses metres, seconds and a positive-up Y axis. Rendering never mutates physics.
public struct Vector2: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double = 0, y: Double = 0) { self.x = x; self.y = y }
}

public struct ControlInput: Codable, Sendable {
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

public struct WheelState: Codable, Sendable {
    public var position = Vector2()
    public var angle: Double = 0
    public var compression: Double = 0
    public var contact = false
    public init() {}
}

public struct BikeState: Codable, Sendable {
    public var position = Vector2()
    public var velocity = Vector2()
    public var angle: Double = 0
    public var angularVelocity: Double = 0
    public var rear = WheelState()
    public var front = WheelState()
    public var throttle: Double = 0
    public init() {}
    public var grounded: Bool { rear.contact || front.contact }
}

public struct SimulationState: Codable, Sendable {
    public var bike = BikeState()
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

public enum GameEvent: Sendable {
    case landed(impact: Double)
    case crashed
    case respawned
    case flip(Int)
    case finished
}
