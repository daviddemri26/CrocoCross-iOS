import Foundation

/// Cosmetic randomness is independent of the course seed, physics and score validation.
enum SceneryLayer: String, CaseIterable {
    case ground, sky, wayside

    var variantCount: Int { self == .ground ? 3 : self == .sky ? 2 : 1 }
    var interval: Double { self == .ground ? 26 : self == .wayside ? 54 : 32 }
    var probability: Double { self == .ground ? 0.80 : self == .wayside ? 0.66 : 0.84 }
}

struct SceneryPlacement {
    let cell: Int
    let coordinate: Double
    let variant: Int
    let scale: Double
    let depth: Double
    let phase: Double

    static func sample(world: String, layer: SceneryLayer, cell: Int, seed: UInt64) -> Self? {
        var hash = seed ^ UInt64(bitPattern: Int64(cell))
        for byte in (world + "/" + layer.rawValue).utf8 { hash = (hash ^ UInt64(byte)) &* 0x100000001b3 }
        func random() -> Double {
            hash &+= 0x9e3779b97f4a7c15
            var value = hash
            value = (value ^ (value >> 30)) &* 0xbf58476d1ce4e5b9
            value = (value ^ (value >> 27)) &* 0x94d049bb133111eb
            value ^= value >> 31
            return Double(value >> 11) / 9_007_199_254_740_992
        }
        guard random() < layer.probability else { return nil }
        // Empty cells and independent offsets prevent a visible repeating cadence.
        let offset = layer == .sky ? 0.08 + random() * 0.40 : 0.26 + random() * 0.48
        return Self(cell: cell, coordinate: (Double(cell) + offset) * layer.interval,
                    variant: 1 + Int(random() * Double(layer.variantCount)),
                    scale: 0.94 + random() * 0.14, depth: random(), phase: random() * .pi * 2)
    }

    static func visible(world: String, layer: SceneryLayer, lower: Double, upper: Double, seed: UInt64) -> [Self] {
        guard lower.isFinite, upper.isFinite, upper >= lower else { return [] }
        let first = Int(floor(lower / layer.interval)) - 1
        let last = Int(floor(upper / layer.interval)) + 1
        return (first...last).compactMap { sample(world: world, layer: layer, cell: $0, seed: seed) }
            .filter { $0.coordinate >= lower && $0.coordinate <= upper }
    }
}

/// Painted ground and its objects remain attached to the course. Perspective
/// comes from fixed depth and size, never from a separate scrolling speed.
enum SceneryMotion {
    static func foregroundFactor(reducedMotion: Bool) -> Double { 1 }
    static func coordinate(screenMetres: Double, camera: Double, factor: Double) -> Double {
        screenMetres + camera * factor
    }
    static func screenMetres(coordinate: Double, camera: Double, factor: Double) -> Double {
        coordinate - camera * factor
    }
}

/// A placement keeps the same apparent depth for its complete sky crossing.
/// Far images are smaller and slower; subject pace distinguishes a balloon from a plane.
struct SkyPerspective {
    static let maximumDuration = 36.0
    let scale: Double
    let duration: Double

    init(depth: Double, speed: Double = 1) {
        let proximity = min(1, max(0, depth))
        scale = 0.62 + proximity * 0.38
        duration = min(Self.maximumDuration, max(16, (32 - proximity * 14) / max(0.5, speed)))
    }
}
