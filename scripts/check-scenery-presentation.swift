import Foundation

@main struct SceneryPresentationChecks {
    static func main() throws {
        let worlds = ["canyon", "japan", "highway", "jungle", "arctic", "mine", "sanfrancisco", "paris", "clouds"]
        var report: [[String: Any]] = []
        for world in worlds {
            for layer in SceneryLayer.allCases {
                for variant in 1...layer.variantCount {
                    let item = SceneryPresentation.forImage(world: world, layer: layer, variant: variant)
                    precondition(!item.name.isEmpty && item.clearance > 0 && item.skyScale > 0 && item.skySpeed > 0)
                    if layer != .sky {
                        let large = layer == .ground && item.footingDepth != nil
                        precondition(item.width > 0 && item.width <= (large ? 12 : 5.5))
                        precondition(item.maxHeight > 0 && item.maxHeight <= (large ? 14 : 3.5))
                        if let footing = item.footingDepth {
                            precondition(layer == .ground && footing > 0 && footing < item.maxHeight)
                        }
                    }
                    report.append(["world": world, "layer": layer.rawValue, "variant": variant,
                                   "object": item.name, "widthMetres": item.width, "maxHeightMetres": item.maxHeight,
                                   "skyScale": item.skyScale, "skySpeed": item.skySpeed, "followsSlope": item.followsSlope,
                                   "footingDepth": item.footingDepth as Any? ?? NSNull()])
                }
            }
        }
        precondition(SceneryPresentation.catalog.count == 54 && report.count == 54)
        func ground(_ world: String, _ variant: Int) -> SceneryPresentation {
            .forImage(world: world, layer: .ground, variant: variant)
        }
        func sky(_ world: String, _ variant: Int) -> Double {
            SceneryPresentation.forImage(world: world, layer: .sky, variant: variant).skyScale
        }
        // At the most distant plane, even the small subjects retain a useful
        // phone silhouette. Vehicles have a distinctly larger canonical footprint.
        for world in worlds {
            for variant in 1...3 {
                let item = ground(world, variant)
                precondition(item.width * 23 * 0.68 * 0.94 >= 27, "Ground silhouette is too small to read")
                precondition(item.maxHeight * 23 * 0.68 * 0.94 >= 20, "Ground height budget is too small")
            }
            for variant in 1...2 {
                let item = SceneryPresentation.forImage(world: world, layer: .sky, variant: variant)
                let far = SkyPerspective(depth: 0, speed: item.skySpeed)
                let near = SkyPerspective(depth: 1, speed: item.skySpeed)
                precondition(far.scale < near.scale && far.duration > near.duration,
                    "Sky depth must link smaller size with slower movement")
                precondition(far.duration <= SkyPerspective.maximumDuration && near.duration >= 16)
                precondition(375 * 0.27 * sky(world, variant) * far.scale * 0.94 >= 32,
                    "Distant sky silhouette is too small")
            }
        }
        precondition(ground("highway", 1).width > ground("canyon", 1).width * 2)
        precondition(ground("highway", 3).width > ground("paris", 1).width * 2)
        precondition(ground("jungle", 2).width < ground("jungle", 1).width)
        precondition(ground("mine", 2).width < ground("mine", 1).width)
        let building = ground("paris", 3), car = ground("paris", 2)
        precondition(building.width > car.width * 2 && building.maxHeight > car.maxHeight * 4,
            "The Paris building must read as architecture beside a car")
        precondition(building.footingDepth != nil && car.footingDepth != nil)
        let lamp = SceneryPresentation.forImage(world: "mine", layer: .wayside, variant: 1)
        precondition(lamp.maxHeight >= 1 && !lamp.followsSlope, "Lantern visibility or upright alignment regressed")
        for world in ["japan", "paris"] {
            precondition(!SceneryPresentation.forImage(world: world, layer: .wayside, variant: 1).followsSlope)
        }
        print(String(decoding: try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self))
        fputs("PASS: 54 explicit image profiles, phone visibility budgets, subject size relationships and upright props\n", stderr)
    }
}
