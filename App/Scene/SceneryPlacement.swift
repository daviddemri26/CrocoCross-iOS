import Foundation

/// Cosmetic randomness is independent of the course seed, physics and score validation.
enum SceneryLayer: String, CaseIterable {
    case ground, sky, wayside

    var variantCount: Int { self == .ground ? 3 : self == .sky ? 2 : 1 }
    var interval: Double { self == .ground ? 64 : self == .wayside ? 92 : 44 }
    var probability: Double { self == .ground ? 0.58 : self == .wayside ? 0.48 : 0.72 }
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
        let offset = layer == .sky ? 0.08 + random() * 0.40 : 0.18 + random() * 0.64
        return Self(cell: cell, coordinate: (Double(cell) + offset) * layer.interval,
                    variant: 1 + Int(random() * Double(layer.variantCount)),
                    scale: 0.84 + random() * 0.28, depth: random(), phase: random() * .pi * 2)
    }

    static func visible(world: String, layer: SceneryLayer, lower: Double, upper: Double, seed: UInt64) -> [Self] {
        guard lower.isFinite, upper.isFinite, upper >= lower else { return [] }
        let first = Int(floor(lower / layer.interval)) - 1
        let last = Int(floor(upper / layer.interval)) + 1
        return (first...last).compactMap { sample(world: world, layer: layer, cell: $0, seed: seed) }
            .filter { $0.coordinate >= lower && $0.coordinate <= upper }
    }
}
