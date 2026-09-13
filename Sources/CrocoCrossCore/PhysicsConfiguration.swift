import Foundation

/// The tuning belongs to the native game. It intentionally does not emulate the web engine.
public struct PhysicsConfiguration: Codable, Equatable, Sendable {
    public static let engineVersion = "native-3"
    public static let simulationFrequency = 120
    public static let timeStep = 1.0 / Double(simulationFrequency)
    /// World-space X coordinate of the zero-metre line, shared with visual markers.
    public static let courseStartX = 3.0
    public static let weeklyDistance = 4_000.0

    public enum TerrainStyle: String, Codable, Sendable { case hills, flat }

    public var terrainStyle: TerrainStyle = .hills
    public var mass: Double = 150
    public var inertia: Double = 125
    public var gravity: Double = 9.81
    public var wheelbase: Double = 1.58
    public var wheelRadius: Double = 0.32
    /// Wheel-centre offset below the chassis centre with unloaded suspension.
    public var unloadedAxleOffset: Double = 0.54
    public var suspensionTravel: Double = 0.23
    public var springRate: Double = 28_000
    public var damping: Double = 2_200
    public var tireGrip: Double = 1.85
    public var maximumDriveForce: Double = 1_550
    /// Motor torque tapers towards this speed; a descent can still carry the bike faster.
    public var motorTopSpeed: Double = 22
    public var brakeForce: Double = 2_800
    /// Rear-biased pressure catches over-acceleration without an excessive front
    /// braking impulse when the wheelie lands. Front braking remains
    /// available only at its actual tire contact; neither brake targets a body angle.
    public var rearBrakeShare: Double = 0.65
    public var airControlTorque: Double = 550
    public var maximumAirSpin: Double = 7.2

    public init() {}

    public var restingRideHeight: Double {
        unloadedAxleOffset + wheelRadius - mass * gravity / (2 * springRate)
    }

    var isValid: Bool {
        [mass, inertia, gravity, wheelbase, wheelRadius, unloadedAxleOffset, suspensionTravel,
         springRate, damping, tireGrip, maximumDriveForce, motorTopSpeed, brakeForce,
         airControlTorque, maximumAirSpin, rearBrakeShare].allSatisfy { $0.isFinite && $0 > 0 } &&
        (50 ... 500).contains(mass) && (20 ... 1_000).contains(inertia) &&
        (1 ... 30).contains(gravity) && (0.8 ... 3).contains(wheelbase) &&
        (0.1 ... 1).contains(wheelRadius) && (0.1 ... 2).contains(unloadedAxleOffset) &&
        suspensionTravel < unloadedAxleOffset && springRate < 200_000 && damping < 30_000 &&
        tireGrip < 5 && maximumDriveForce < 20_000 && (5 ... 50).contains(motorTopSpeed) &&
        brakeForce < 30_000 && rearBrakeShare <= 1 && airControlTorque < 5_000 && maximumAirSpin <= 14 && restingRideHeight > wheelRadius
    }
}
