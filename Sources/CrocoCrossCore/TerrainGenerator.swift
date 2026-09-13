import Foundation

/// Independent sections have matching height, slope and curvature at their boundaries.
/// Sampling far ahead neither allocates preceding sections nor advances a random generator.
public struct TerrainGenerator: Codable, Sendable {
    public static let sectionLength = 48.0
    public static let entryLength = 24.0
    /// A sustained descent gives every hill a lower run-out. Individual ramps still
    /// climb, so jumps come from speed and crest curvature rather than launch impulses.
    public static let descentGrade = 0.10
    private static let entryHeight = -0.6
    public let seed: UInt32
    public let style: PhysicsConfiguration.TerrainStyle

    public init(seed: UInt32, style: PhysicsConfiguration.TerrainStyle = .hills) {
        self.seed = seed
        self.style = style
    }

    public func height(at x: Double) -> Double {
        guard style == .hills, x.isFinite, x > 12 else { return 0 }
        if x < Self.entryLength {
            return Self.blend(t: (x - 12) / 12, y0: 0, y1: Self.entryHeight,
                              slope0: 0, slope1: -Self.descentGrade, width: 12)
        }
        let section = floor((x - Self.entryLength) / Self.sectionLength)
        let local = x - Self.entryLength - section * Self.sectionLength
        let index = UInt32(truncatingIfNeeded: Int64(min(section, Double(Int64.max / 2))))
        let hash = Self.mix(seed ^ ((index &+ 1) &* 0x9e37_79b9))
        let profile = Self.profiles[section < 1 ? 0 : Int(hash % UInt32(Self.profiles.count))]
        let introduction = min(1, 0.72 + section * 0.07)
        let scale = introduction * (0.9 + Double((hash >> 8) % 101) / 500)
        let base = Self.entryHeight - Self.descentGrade * (x - Self.entryLength)
        for i in 0 ..< profile.count - 1 {
            let a = profile[i], b = profile[i + 1]
            if local <= b.x {
                let shape = Self.blend(t: (local - a.x) / (b.x - a.x), y0: a.y, y1: b.y,
                                       slope0: a.slope, slope1: b.slope, width: b.x - a.x)
                // Profiles are offsets from the downhill baseline. Their zero height,
                // slope and curvature at both ends preserve joins at every difficulty.
                return base + shape * scale
            }
        }
        return base
    }

    public func slope(at x: Double) -> Double {
        (height(at: x + 0.005) - height(at: x - 0.005)) / 0.01
    }

    private struct Knot: Sendable {
        let x: Double, y: Double, slope: Double
        init(_ x: Double, _ y: Double, _ slope: Double) { self.x = x; self.y = y; self.slope = slope }
    }

    // Each 48m section pairs a tall takeoff lip with a smaller roller after its
    // descending reception. Narrowing the lip creates real upward launch velocity;
    // the simulation still applies only gravity, suspension and tire contact forces.
    private static let profiles: [[Knot]] = [
        [.init(0, 0, 0), .init(4, 0, 0.05), .init(10, 3.2, 0.85), .init(13, 5.4, 0.65),
         .init(15, 5.8, -0.15), .init(28, -0.4, -0.25), .init(33, -0.7, 0.1),
         .init(38, 0.8, 0.22), .init(41, 1.0, -0.12), .init(48, 0, 0)],
        [.init(0, 0, 0), .init(5, -0.3, 0.05), .init(12, 3.5, 0.85), .init(15, 5.6, 0.60),
         .init(17, 5.9, -0.20), .init(31, -0.6, -0.15), .init(35, -0.5, 0.18),
         .init(39, 1.0, 0.2), .init(42, 1.1, -0.14), .init(48, 0, 0)],
        [.init(0, 0, 0), .init(4, 0, 0.1), .init(10, 3.6, 0.9), .init(13, 5.9, 0.60),
         .init(15, 6.2, -0.15), .init(29, -0.4, -0.20), .init(33, -0.6, 0.12),
         .init(38, 0.7, 0.18), .init(42, 0.8, -0.13), .init(48, 0, 0)],
        [.init(0, 0, 0), .init(6, 0.1, 0.1), .init(12, 3.6, 0.85), .init(15, 5.7, 0.60),
         .init(17, 6.0, -0.15), .init(31, -0.7, -0.15), .init(35, -0.5, 0.18),
         .init(40, 1.1, 0.10), .init(43, 0.9, -0.20), .init(48, 0, 0)],
        [.init(0, 0, 0), .init(4, -0.2, 0.1), .init(10, 3.0, 0.85), .init(13, 5.2, 0.65),
         .init(15, 5.7, -0.10), .init(29, -0.5, -0.20), .init(34, -0.6, 0.20),
         .init(39, 1.2, 0.15), .init(42, 1.0, -0.20), .init(48, 0, 0)]
    ]

    private static func blend(t: Double, y0: Double, y1: Double, slope0: Double, slope1: Double, width: Double) -> Double {
        let delta = y1 - y0, v0 = slope0 * width, v1 = slope1 * width
        return y0 + v0 * t + (10 * delta - 6 * v0 - 4 * v1) * pow(t, 3)
            + (-15 * delta + 8 * v0 + 7 * v1) * pow(t, 4)
            + (6 * delta - 3 * v0 - 3 * v1) * pow(t, 5)
    }

    private static func mix(_ value: UInt32) -> UInt32 {
        var h = value
        h ^= h >> 16; h = h &* 0x85eb_ca6b
        h ^= h >> 13; h = h &* 0xc2b2_ae35
        return h ^ (h >> 16)
    }
}
