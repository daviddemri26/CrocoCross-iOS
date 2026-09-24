import Foundation

/// Physical units are metres, kilograms, seconds and radians. Rendering never changes these values.
public struct PhysicsConfiguration: Codable, Equatable, Sendable {
    // Rules revision: 2,600 m Weekly and fresh records; physical tuning is unchanged.
    public static let engineVersion = "box2d-2"
    public static let backendVersion = "3.1.1"
    public static let simulationFrequency = 120
    public static let timeStep = 1.0 / Double(simulationFrequency)
    public static let substeps: Int32 = 4
    public static let courseStartX = 3.0
    public static let weeklyDistance = 2_600.0
    public enum TerrainStyle: String, Codable, Sendable { case hills, flat, japanMountains }
    public var terrainStyle: TerrainStyle = .hills
    /// Total mass and nominal total pitch inertia, including the rider and wheels.
    public var mass: Double = 150
    public var inertia: Double = 125
    public var gravity: Double = 9.81
    public var wheelbase: Double = 1.58
    public var wheelRadius: Double = 0.32
    public var unloadedAxleOffset: Double = 0.608
    public var suspensionTravel: Double = 0.38
    public var suspensionSag: Double = 0.30
    /// Calibrated on the complete five-body rig, not on an isolated light wheel.
    public var suspensionHertz: Double = 4.57
    public var suspensionDampingRatio: Double = 5.0
    public var leanClearance: Double = 0.18
    public var forwardWheelieBalance: Double = 1.8
    public var tireGrip: Double = 1.85
    public var maximumDriveForce: Double = 1_450
    public var motorTopSpeed: Double = 24
    public var brakeForce: Double = 2_800
    public var rearBrakeShare: Double = 0.65
    /// Deliberate player-controlled air effort; never targets an upright world angle.
    public var airControlTorque: Double = 550
    public var maximumAirSpin: Double = 7.2
    public init() {}
    public var restingRideHeight: Double {
        unloadedAxleOffset + wheelRadius - suspensionTravel * suspensionSag
    }
    var isValid: Bool {
        [mass, inertia, gravity, wheelbase, wheelRadius, unloadedAxleOffset, suspensionTravel,
         suspensionSag, suspensionHertz, suspensionDampingRatio, leanClearance, forwardWheelieBalance,
         tireGrip, maximumDriveForce, motorTopSpeed, brakeForce, rearBrakeShare, airControlTorque,
         maximumAirSpin].allSatisfy { $0.isFinite && $0 > 0 } &&
        (50...500).contains(mass) && (20...1_000).contains(inertia) && (1...30).contains(gravity) &&
        (0.8...3).contains(wheelbase) && (0.1...1).contains(wheelRadius) &&
        (0.2...1.5).contains(unloadedAxleOffset) && (0.05...0.8).contains(suspensionTravel) &&
        suspensionTravel < unloadedAxleOffset && (0.1...0.5).contains(suspensionSag) &&
        (0.5...20).contains(suspensionHertz) && suspensionDampingRatio <= 10 &&
        (0.02...0.5).contains(leanClearance) && (1...3).contains(forwardWheelieBalance) &&
        tireGrip < 5 && maximumDriveForce < 20_000 && (5...50).contains(motorTopSpeed) &&
        brakeForce < 30_000 && rearBrakeShare <= 1 && airControlTorque < 5_000 && maximumAirSpin <= 14
    }
}
