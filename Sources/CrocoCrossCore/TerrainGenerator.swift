import Foundation

/// Independent sections have matching height, slope and curvature at their boundaries.
/// Sampling far ahead neither allocates preceding sections nor advances a random generator.
public struct TerrainGenerator: Codable, Sendable {
    public static let sectionLength = 64.0
    public static let entryLength = 24.0
    public let seed: UInt32
    public let style: PhysicsConfiguration.TerrainStyle

    public init(seed: UInt32, style: PhysicsConfiguration.TerrainStyle = .hills) {
        self.seed = seed
        self.style = style
    }

    public func height(at x: Double) -> Double {
        guard style == .hills, x.isFinite, x > 12 else { return 0 }
        if x < Self.entryLength {
            return Self.blend(t: (x - 12) / 12, y0: 0, y1: 0, slope0: 0, slope1: -0.035, width: 12)
        }
        let section = floor((x - Self.entryLength) / Self.sectionLength)
        let local = x - Self.entryLength - section * Self.sectionLength
        let index = UInt32(truncatingIfNeeded: Int64(min(section, Double(Int64.max / 2))))
        let hash = Self.mix(seed ^ ((index &+ 1) &* 0x9e37_79b9))
        let profile = Self.profiles[section < 1 ? 0 : Int(hash % UInt32(Self.profiles.count))]
        let introduction = min(1, 0.72 + section * 0.065)
        let scale = introduction * (0.9 + Double((hash >> 8) % 101) / 500)
        let base = -section * 2.24
        for i in 0 ..< profile.count - 1 {
            let a = profile[i], b = profile[i + 1]
            if local <= b.x {
                let shape = Self.blend(t: (local - a.x) / (b.x - a.x), y0: a.y, y1: b.y,
                                       slope0: a.slope, slope1: b.slope, width: b.x - a.x)
                // Scale only the departure from the common baseline, preserving every join.
                return base - 0.035 * local + (shape + 0.035 * local) * scale
            }
        }
        return base - 2.24
    }

    public func slope(at x: Double) -> Double {
        (height(at: x + 0.005) - height(at: x - 0.005)) / 0.01
    }

    private struct Knot: Sendable {
        let x: Double, y: Double, slope: Double
        init(_ x: Double, _ y: Double, _ slope: Double) { self.x = x; self.y = y; self.slope = slope }
    }

    private static let profiles: [[Knot]] = [
        [.init(0, 0, -0.035), .init(12, -1.2, -0.14), .init(26, -2.7, 0), .init(40, -0.3, 0.18), .init(48, 0.5, 0), .init(64, -2.24, -0.035)],
        [.init(0, 0, -0.035), .init(10, -0.35, -0.03), .init(17, 1.1, 0.45), .init(20, 2.1, 0.22), .init(23, 2.4, -0.1), .init(33, -1.7, -0.55), .init(45, -4, -0.05), .init(56, -2, 0.22), .init(64, -2.24, -0.035)],
        [.init(0, 0, -0.035), .init(13, 0.8, 0.08), .init(22, 0.2, -0.25), .init(34, -4.4, -0.2), .init(44, -4.1, 0.3), .init(53, -1, 0.15), .init(64, -2.24, -0.035)],
        [.init(0, 0, -0.035), .init(11, 1.3, 0.24), .init(17, 2.6, 0.1), .init(23, 2, -0.3), .init(36, -2.8, -0.4), .init(46, -4, 0), .init(56, -2.4, 0.2), .init(64, -2.24, -0.035)]
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
