import Foundation

@main struct SceneryChecks {
    static func main() {
        let worlds = ["canyon", "japan", "highway", "jungle", "arctic", "mine", "sanfrancisco", "paris", "clouds"]
        for world in worlds {
            for layer in SceneryLayer.allCases {
                let placements = SceneryPlacement.visible(world: world, layer: layer,
                    lower: -1_000, upper: 100_000, seed: 1234)
                let rate = Double(placements.count) / (101_000 / layer.interval)
                precondition(rate > 0.55 && rate < 0.90, "Irregular selection rate: \(world)/\(layer)")
                precondition(Set(placements.map(\.variant)).count == layer.variantCount, "Missing variation")
                let gaps = zip(placements, placements.dropFirst()).map { $1.coordinate - $0.coordinate }
                precondition((gaps.min() ?? 0) > (layer == .sky ? 19 : layer == .ground ? 13 : 28), "Decorations crowd together")
                precondition(Set(gaps.map { Int($0) }).count > 20, "Repetitive spacing")
                for x in stride(from: -100.0, through: 10_000.0, by: 11.0) {
                    let narrow = SceneryPlacement.visible(world: world, layer: layer, lower: x, upper: x + 32, seed: 1234)
                    let wide = SceneryPlacement.visible(world: world, layer: layer, lower: x - 30, upper: x + 62, seed: 1234)
                    precondition(narrow.allSatisfy { p in wide.contains { $0.cell == p.cell && $0.coordinate == p.coordinate && $0.variant == p.variant } }, "Viewport shift changed existing artwork")
                    precondition(narrow.count <= 3, "Too many decorations in a viewport")
                }
                let differentRun = SceneryPlacement.visible(world: world, layer: layer,
                    lower: -1_000, upper: 100_000, seed: 5678)
                precondition(placements.map(\.coordinate) != differentRun.map(\.coordinate), "Runs repeat")
            }
        }
        // A painted point and its sprite must agree after any camera move, even
        // across a six-metre strip recycle boundary and at very long distances.
        for reducedMotion in [false, true] {
            let factor = SceneryMotion.foregroundFactor(reducedMotion: reducedMotion)
            for camera in [-100.0, 5.99, 6.01, 1234.0, 100_000.0] {
                for coordinate in [camera * factor, camera * factor + 6.7] {
                    let x = SceneryMotion.screenMetres(coordinate: coordinate, camera: camera, factor: factor)
                    let next = SceneryMotion.screenMetres(coordinate: coordinate, camera: camera + 1, factor: factor)
                    precondition(abs(next - x + factor) < 0.000001, "Parallax jumps while scrolling")
                    let material = SceneryMotion.coordinate(screenMetres: next, camera: camera + 1, factor: factor)
                    precondition(abs(material - coordinate) < 0.000001, "Object slides across its painted plane")
                }
            }
            precondition(factor == 1, "Ground must remain fixed to the course in both motion settings")
        }
        print("PASS: nine worlds, 54 variants, readable irregular gaps, viewport stability, new-run variation, fixed ground and object coordinates")
    }
}
